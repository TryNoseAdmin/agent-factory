# /orchestrate-build — Build Orchestrator

## Purpose
Read a ticket, classify scope, spawn domain-specific agents with TDD, run gates and checks, and synthesize into a single build outcome.

## Pre-flight

1. **Read state:** `.project-state.json`
2. **Read ticket:** Fetch via `skills/ticket` or Notion MCP
3. **Classify scope** — determine which agents to spawn:
   - FE-only → `agent-frontend-dev`
   - BE-only → `agent-backend-dev` (+ `agent-database-dev` if schema changes)
   - Full-stack → all 3
   - DB-only → `agent-database-dev`

## Task File Protocol (Orchestrator Responsibility)

**The orchestrator does NOT write long agent prompts. The orchestrator writes task files.**

### Step A: Write Task Files
Before spawning any agent, write ONE task file per agent:
```
PROJECT:frontend-repo/.agents/tasks/TASK-001-fe-dashboard.md
PROJECT:frontend-repo/.agents/tasks/TASK-002-be-webhook.md
PROJECT:brain-repo/.agents/tasks/TASK-003-db-schema.md
```

Each task file MUST follow the schema defined in `~/.agents/rules/universal.md` → "Task File Protocol".

### Step B: Spawn Agents
Agent spawn prompt is a ONE-LINER:
```
Your task file is at: [path/to/TASK-XXX-name.md]
Read it. Execute it. Report back with the output format specified in the file.
```

That's it. The task file contains everything the agent needs.

### Step C: Collect Results
Parse each agent's output against the "Output Format" section in their task file.

Spawn agents in parallel when they have no dependencies. Wait for all results before proceeding.

---

## 🚧 NON-NEGOTIABLE: Anti-Fabrication Gate

**Before writing any code, enforce these rules:**

### Rule 1 — Documentation MUST match implementation
If a docstring, comment, or PR description claims a behavior, the diff MUST contain code that produces that behavior. **No "intent" comments without backing code.**

Banned patterns:
- Docstring says "uses caching" — no `cache_control` field in the diff
- Function named `enableXFeature()` whose body is `return null`
- Tests that "cover" a feature by asserting a constant

**If caught mid-build:** implement properly OR delete the claim. Never ship doc-only features.

### Rule 2 — External API claims need citations
Before writing code that depends on a third-party API feature:
1. **WebFetch the provider's actual docs**
2. **Paste the relevant quote** as a code comment
3. **Or mark as `[UNVERIFIED — TODO confirm]`**

Forbidden: "Provider X is OpenAI-compatible, so it must support Y" — verify Y specifically.

### Rule 3 — Do NOT silently implement unverified plan claims
If upstream plan output contains `[UNVERIFIED]` claims:
- **Verify now** (WebFetch + paste quote)
- **Scope out of this PR** (move to follow-up)
- **STOP and ask the user**

---

## Coding Standards Gate

Before writing any code, verify every item below:

### Architecture
- [ ] UI / API / DB logic isolated — no mixing layers
- [ ] Business logic in services layer, NOT in route handlers or components
- [ ] Components use hooks — no direct API/DB calls in React components

### Code Quality
- [ ] Single responsibility — one function = one purpose
- [ ] Max 30 lines per function
- [ ] Max nesting depth 3 — early returns
- [ ] No magic numbers — use named constants
- [ ] No hardcoded values — env vars or config
- [ ] Descriptive names — no `data`, `temp`, `thing`
- [ ] DRY — extract shared logic

### Error Handling
- [ ] Structured try/catch — never empty catch blocks
- [ ] Meaningful error messages with context
- [ ] Fail fast on critical errors
- [ ] Errors propagate properly

### Testing
- [ ] Unit tests for all service functions
- [ ] Integration tests for all API routes
- [ ] Component tests for all new React components
- [ ] Tests are independent — no shared state
- [ ] Tests verify behavior, not implementation

### Security
- [ ] All user inputs validated
- [ ] No secrets in code
- [ ] SQL uses ORM/parameterized queries
- [ ] No sensitive data logged

### Documentation
- [ ] JSDoc on every exported FE function/hook/component
- [ ] Docstring on every BE service function and route

### YAGNI / KISS
- [ ] No speculative abstractions
- [ ] No "just in case" parameters
- [ ] Simplest solution that passes AC

---

## Execution Flow

### Step 0: Read State

```bash
if [ -f .project-state.json ]; then
  cat .project-state.json
else
  echo "No state file. Initialize with /orchestrate-plan first."
  exit 1
fi

# Artifact Input Gate
if [ ! -f DESIGN.md ] && [ ! -f ARCHITECTURE.md ]; then
  echo "CRITICAL ERROR: Missing Plan artifacts. Run /plan first to generate DESIGN.md and ARCHITECTURE.md."
  exit 1
fi
```

Check:
- `current_phase` — should be `ready_to_build`, `build`, or `fix`
- `ticket_id` — use if set; otherwise use what user provided
- `review_feedback` — if `current_phase == "fix"`, contains issues to fix

If in **fix mode** (after review failures):
- Read `state.review_feedback.critical` and `state.review_feedback.high`
- Focus ONLY on fixing those issues
- Do NOT add new features during a fix pass

### Step 1: Read the Ticket + Classify Scope

Fetch the ticket via Notion MCP or `skills/ticket`. Extract:
- **What to Do** — functional requirements
- **How to Do** — implementation guidance
- **Success Criteria** / Acceptance Criteria — the build target
- **Files Affected** — scope hint
- **Dependencies** — blockers

Classify which agents are needed:
- FE-only → `agent-frontend-dev`
- BE-only → `agent-backend-dev` (+ `agent-database-dev` if schema changes)
- Full-stack → all 3
- DB-only → `agent-database-dev`

If no ticket ID, ask: "What are we building? Share the TASK number or describe the feature."

### Step 2: Write Task Files

**Write one task file per agent BEFORE spawning anyone.**

If frontend work is involved, write the frontend task file first. If it requires design discovery, the task file itself instructs the agent to run its Design Discovery step (from `agent-ui-designer/SKILL.md`).

Task file location:
```bash
mkdir -p PROJECT:frontend-repo/.agents/tasks/
mkdir -p PROJECT:brain-repo/.agents/tasks/
```

Task file naming: `TASK-001-[domain]-[short-name].md`

### Step 3: Design Discovery Gate (Frontend Work Only)

**If the ticket involves any frontend work:**

The frontend agent's task file MUST include the Design Discovery step. The agent runs it, produces `DESIGN_CONTRACT.md`, and continues only if it passes.

**Block condition:**
```
If agent-ui-designer (spawned via task file) reports BLOCKED or Design Discovery FAIL:
  → STOP. Do not spawn other agents.
  → Report to user: "Design discovery found critical gaps. Fix design system before coding."
  → Include DESIGN_GAP_REPORT.md contents.
```

Backend-only tickets: skip this gate.

### Step 4: Delegate Domain Pre-flight Gates

**Do NOT run domain-specific gates in the orchestrator.** Each spawned agent runs its own pre-flight checks from its skill file, guided by its task file.

| Agent | Gate it runs |
|---|---|
| `agent-frontend-dev` | Design System Contract Gate (reads task file for contract spec) |
| `agent-backend-dev` | External-Data & Queue Gate |
| `agent-database-dev` | Schema safety gate (migrations, rollbacks) |

The orchestrator's job is to **verify the agent reported PASS** in its output. If an agent reports `BLOCKED` or fails its own gate, stop and escalate.

Note in state:
- `design_contract_gate`: `"delegated"` (frontend agent owns it)
- `external_data_gate`: `"delegated"` (backend agent owns it)

### Step 5: Update State — Build Started

```python
import json
from datetime import datetime, timezone

with open('.project-state.json', 'r') as f:
    state = json.load(f)

state['current_phase'] = 'build'
state['updated_at'] = datetime.now(timezone.utc).isoformat()
state['history'].append({
    'timestamp': datetime.now(timezone.utc).isoformat(),
    'phase': 'build',
    'action': 'build_started',
    'detail': f"Building ticket: {state.get('ticket_id', 'unknown')}"
})

with open('.project-state.json', 'w') as f:
    json.dump(state, f, indent=2)
```

### Step 6: Spawn Domain Agents

Spawn the classified agents simultaneously with one-liner prompts pointing to their task files:

```
Your task file is at: PROJECT:frontend-repo/.agents/tasks/TASK-001-fe-dashboard.md
Read it. Execute it. Report back.
```

| Scope | Agents | Pre-requisite |
|-------|--------|---------------|
| Frontend | `agent-frontend-dev` (task file includes design discovery) | Task file written |
| Backend | `agent-backend-dev` | Task file written |
| Database | `agent-database-dev` | Task file written |
| Full-stack | All 3 dev agents in parallel | All task files written |

### Step 7: Collect Results

Parse each agent's output against the "Output Format" in their task file:
```
FE Status: COMPLETE | PARTIAL | BLOCKED
BE Status: COMPLETE | PARTIAL | BLOCKED
DB Status: COMPLETE | PARTIAL | BLOCKED
```

If any agent reports **BLOCKED**, stop and ask the user before proceeding.

### Step 8: Run Automated Standards Check

```bash
# Frontend (read `.project-context.md` for repo location)
cd <PROJECT:frontend-repo>
npx tsc --noEmit
npx eslint src/ --max-warnings 0
npm test -- --watchAll=false

# Backend (read `.project-context.md` for repo location)
cd <PROJECT:backend-repo>
python -m ruff check app/
python -m ruff format --check app/
python -m mypy app/ --ignore-missing-imports
python -m pytest tests/ -v
```

**Optional:** Spawn `agent-compliance-auditor` if the change touches auth, payments, PII, or external APIs.

### Step 9: Verify Acceptance Criteria

Check each AC from the ticket:
```
✅ [Criterion 1] — [how verified]
✅ [Criterion 2] — [how verified]
⬜ [Criterion 3] — [what's missing]
```

### Step 10: Commit

```bash
git add [specific files — never git add -A]
git commit -m "feat(TASK-XXX): [description]"
```

### Step 10.5: Artifact Output Gate
Before completing the `/build` phase, ensure you generate the physical artifacts required for review.
- Create `TEST_COVERAGE.md`
- Create `BUILD_SUMMARY.md`

```bash
if [ ! -f TEST_COVERAGE.md ] || [ ! -f BUILD_SUMMARY.md ]; then
  echo "CRITICAL ERROR: Build artifacts missing. You must generate TEST_COVERAGE.md and BUILD_SUMMARY.md."
  exit 1
fi
```

### Step 11: Update State — Build Complete

```python
import json
from datetime import datetime, timezone

with open('.project-state.json', 'r') as f:
    state = json.load(f)

state['current_phase'] = 'ready_to_review'
state['progress']['percent'] = 100
state['updated_at'] = datetime.now(timezone.utc).isoformat()
state['history'].append({
    'timestamp': datetime.now(timezone.utc).isoformat(),
    'phase': 'build',
    'action': 'build_complete',
    'detail': 'All domain agents finished'
})

with open('.project-state.json', 'w') as f:
    json.dump(state, f, indent=2)
```

## Post-flight

```
Build complete: [TASK-XXX]
- Frontend: [status] — [files]
- Backend: [status] — [files]
- Database: [status] — [migrations]
- Tests: [pass/fail counts]
- Lint: [pass/fail]
- Anti-fabrication gate: [pass/fail]
- Design discovery gate: [agent-ui-designer spawned first → PASS / FAIL / SKIP]
- Design contract gate: [delegated → frontend agent reported pass/fail]
- External-data gate: [delegated → agent reported pass/fail]

Ready for /orchestrate-review
```

## Decision Tree

```
Any agent BLOCKED? → STOP, ask user
Any test failing? → Re-spawn failing agent in fix mode
Any lint failing? → Re-spawn failing agent in fix mode
Any gate failing? → Fix gate issue, re-run from Step 6
All green? → Commit + update state + prompt for review
```

---

## Responsibilities

See `~/.agents/rules/orchestrator-responsibilities.md` for Task Distribution, State Update handling, Rule Update handling, Agent Memory verification, Output Styles, and Project State update protocols.
