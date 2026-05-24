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

## Spawn Protocol

For EACH agent you spawn, construct the prompt as:

```
{ReadFile('~/.agents/rules/universal.md')}

---

{ReadFile('.project-context.md')}

---

{ReadFile('~/.agents/agents/agent-<name>.md')}

---

{ReadFile('~/.agents/skills/agent-<name>/SKILL.md')}

---

## Task Context
[Ticket summary, acceptance criteria, specific files to modify]
```

Spawn agents in parallel when possible. Wait for all results before proceeding.

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

### Step 1: Read the Ticket

Fetch the ticket via Notion MCP or `skills/ticket`. Extract:
- **What to Do** — functional requirements
- **How to Do** — implementation guidance
- **Success Criteria** / Acceptance Criteria — the build target
- **Files Affected** — scope hint
- **Dependencies** — blockers

If no ticket ID, ask: "What are we building? Share the TASK number or describe the feature."

### Step 2: Delegate Domain Pre-flight Gates

**Do NOT run domain-specific gates in the orchestrator.** Each spawned agent runs its own pre-flight checks from its skill file:

| Agent | Gate it runs |
|---|---|
| `agent-frontend-dev` | Design System Contract Gate |
| `agent-backend-dev` | External-Data & Queue Gate |
| `agent-database-dev` | Schema safety gate (migrations, rollbacks) |

The orchestrator's job is to **verify the agent reported PASS** in its output. If an agent reports `BLOCKED` or fails its own gate, stop and escalate.

Note in state:
- `design_contract_gate`: `"delegated"` (frontend agent owns it)
- `external_data_gate`: `"delegated"` (backend agent owns it)

### Step 3: Update State — Build Started

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

### Step 4: Spawn Domain Agents

Spawn the classified agents simultaneously:

| Scope | Agents |
|-------|--------|
| Frontend | `agent-frontend-dev` |
| Backend | `agent-backend-dev` |
| Database | `agent-database-dev` |

### Step 5: Collect Results

Parse each agent's output:
```
FE Status: COMPLETE | PARTIAL | BLOCKED
BE Status: COMPLETE | PARTIAL | BLOCKED
DB Status: COMPLETE | PARTIAL | BLOCKED
```

If any agent reports **BLOCKED**, stop and ask the user before proceeding.

### Step 6: Run Automated Standards Check

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

### Step 7: Verify Acceptance Criteria

Check each AC from the ticket:
```
✅ [Criterion 1] — [how verified]
✅ [Criterion 2] — [how verified]
⬜ [Criterion 3] — [what's missing]
```

### Step 8: Commit

```bash
git add [specific files — never git add -A]
git commit -m "feat(TASK-XXX): [description]"
```

### Step 9: Update State — Build Complete

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
- Design contract gate: [delegated → agent reported pass/fail]
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
