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

### Step 2: Design System Contract Gate (FE work only)

If this ticket touches frontend UI, verify the ticket contains a **Design System Contract**:
- Element → utility class + CSS variable tokens
- Every token must exist in the project's token file
- No raw hex, no rgba literals, no inline styles

**If contract is missing:**
```
STOP. Do not write FE code. Output:
"This ticket has frontend work but no Design System Contract.
Please run /orchestrate-plan to add the contract to the ticket."
```

Backend-only tickets: skip. Note in state: `design_contract_gate: "n/a"`.

### Step 3: External-Data & Queue Gate (BE work only)

If the ticket touches external feeds, remote downloads, background workers, or HTTP calls to third-party hosts:

**Parsing untrusted input:**
- [ ] XML: use `defusedxml` — NEVER stdlib `xml.etree` on external bytes
- [ ] JSON: use Pydantic `.model_validate(dict)` — never bare `.get()` chains

**URL handling (SSRF prevention):**
- [ ] Validate URLs BEFORE fetching — reject non-https, private ranges, loopback
- [ ] `httpx.AsyncClient(..., follow_redirects=False)` or re-validate each target
- [ ] Re-validate affiliate/retailer URLs before DB write

**Downloading remote content:**
- [ ] `max_bytes` cap (e.g. 10 MB images, 50 MB feeds)
- [ ] Magic-byte sniff on first 8–12 bytes — NEVER trust `Content-Type` header
- [ ] Re-check key does not contain `..` segments before CDN upload

**External field values written to DB:**
- [ ] Enum-validate string fields consumed by code
- [ ] Length-cap free-text fields at boundary
- [ ] Never persist raw feed values without validator

**Async correctness:**
- [ ] If ANY function is `async def`, ALL HTTP calls must be `await client.get(...)` — never blocking `httpx.get()`
- [ ] If mixing sync + async, document WHY inline

**Queue / worker completeness:**
- [ ] Run-loop: claim → dispatch → mark complete/failed
- [ ] Dispatch table — explicit mapping. No `eval`, no dynamic imports
- [ ] SKIP LOCKED claim: `UPDATE … WHERE id = (SELECT … FOR UPDATE SKIP LOCKED LIMIT 1) RETURNING *`
- [ ] Exponential backoff + max_attempts → permanent `failed`
- [ ] Stale-lock reaper for crashed workers
- [ ] Handler idempotency — re-running must not duplicate effects

**Required tests:**
- [ ] Two-worker concurrency — only one wins the same row
- [ ] Retry exhaustion — fails N times → `failed`
- [ ] Stale-lock reaper — lock older than threshold resets
- [ ] Each handler — happy path + validation-error + missing-row
- [ ] Idempotency — run twice → identical DB state

**JSONB payloads:**
- [ ] Every payload shape has a Pydantic model
- [ ] Validation errors → permanent fail (do not retry)

**No global mutable state:**
- [ ] No module-level `_cache = …` dicts
- [ ] Own cache lifecycle in a class with DI

**If any checkbox is unchecked, STOP and fix before application code.**

### Step 4: Update State — Build Started

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

### Step 5: Spawn Domain Agents

Spawn the classified agents simultaneously:

| Scope | Agents |
|-------|--------|
| Frontend | `agent-frontend-dev` |
| Backend | `agent-backend-dev` |
| Database | `agent-database-dev` |

### Step 6: Collect Results

Parse each agent's output:
```
FE Status: COMPLETE | PARTIAL | BLOCKED
BE Status: COMPLETE | PARTIAL | BLOCKED
DB Status: COMPLETE | PARTIAL | BLOCKED
```

If any agent reports **BLOCKED**, stop and ask the user before proceeding.

### Step 7: Run Automated Standards Check

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

### Step 8: Verify Acceptance Criteria

Check each AC from the ticket:
```
✅ [Criterion 1] — [how verified]
✅ [Criterion 2] — [how verified]
⬜ [Criterion 3] — [what's missing]
```

### Step 9: Commit

```bash
git add [specific files — never git add -A]
git commit -m "feat(TASK-XXX): [description]"
```

### Step 10: Update State — Build Complete

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
- Design contract gate: [pass/skip]
- External-data gate: [pass/skip]

Ready for /orchestrate-review
```

## Decision Tree

```
Any agent BLOCKED? → STOP, ask user
Any test failing? → Re-spawn failing agent in fix mode
Any lint failing? → Re-spawn failing agent in fix mode
Any gate failing? → Fix gate issue, re-run from Step 7
All green? → Commit + update state + prompt for review
```

---

## Responsibilities

See `~/.agents/rules/orchestrator-responsibilities.md` for Task Distribution, State Update handling, Rule Update handling, Agent Memory verification, Output Styles, and Project State update protocols.
