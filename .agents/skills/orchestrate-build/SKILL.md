# /orchestrate-build — Build Orchestrator

## Purpose
Read a Notion ticket, classify scope, spawn domain-specific agents (frontend, backend, database) with TDD, and synthesize results into a single build outcome.

## Pre-flight

1. **Read state:** `.agents/project-data/state/nose/state.json`
2. **Read ticket:** Fetch ticket via `skills/ticket` utility provided by the user
3. **Classify scope** — determine which agents to spawn:
   - FE-only → `agent-frontend-dev`
   - BE-only → `agent-backend-dev` (+ `agent-database-dev` if schema changes)
   - Full-stack → all 3
   - DB-only → `agent-database-dev`

## Spawn Protocol

For EACH agent you spawn, construct the prompt as:

```
{ReadFile('.agents/rules/universal.md')}

---

{ReadFile('.project-context.md')}

---

{ReadFile('.agents/agents/agent-<name>.md')}

---

## Task Context
[Ticket summary, acceptance criteria, specific files to modify]
```

Spawn agents in parallel when possible. Wait for all results before proceeding.

## Execution Flow

### Step 1: Spawn Domain Agents
Spawn the classified agents simultaneously using the Agent tool.

| Scope | Agents |
|-------|--------|
| Frontend | `agent-frontend-dev` |
| Backend | `agent-backend-dev` |
| Database | `agent-database-dev` |

### Step 2: Collect Results
Parse each agent's output:
```
FE Status: COMPLETE | PARTIAL | BLOCKED
BE Status: COMPLETE | PARTIAL | BLOCKED
DB Status: COMPLETE | PARTIAL | BLOCKED
```

If any agent reports **BLOCKED**, stop and ask the user before proceeding.

### Step 3: Run Automated Standards Check
```bash
# nose-fe
cd ~/Documents/GitHub/TryNose/nose-fe
npx eslint src/ --max-warnings 0
npx tsc --noEmit
npm test -- --watchAll=false

# nose-be
cd ~/Documents/GitHub/TryNose/nose-be
python -m ruff check backend/app/
python -m ruff format --check backend/app/
python -m mypy backend/app/ --ignore-missing-imports
python -m pytest tests/ -v
```

**Optional:** Spawn `agent-compliance-auditor` if the change touches auth, payments, PII, or external APIs.

**Utility skills available:** `shadcn-ui`, `react-components`, `pdf` (report generation)

### Step 4: Verify Acceptance Criteria
Check each AC from the ticket:
```
✅ [Criterion 1] — [how verified]
✅ [Criterion 2] — [how verified]
⬜ [Criterion 3] — [what's missing]
```

### Step 5: Commit
```bash
git add [specific files — never git add -A]
git commit -m "feat(TASK-XXX): [description]"
```

### Step 6: Update State
```python
import json
from datetime import datetime, timezone

with open('.agents/project-data/state/nose/state.json', 'r') as f:
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

with open('.agents/project-data/state/nose/state.json', 'w') as f:
    json.dump(state, f, indent=2)
```

## Post-flight

Report to user:
```
Build complete: [TASK-XXX]
- Frontend: [status] — [files]
- Backend: [status] — [files]
- Database: [status] — [migrations]
- Tests: [pass/fail counts]
- Lint: [pass/fail]

Ready for /orchestrate-review
```

## Decision Tree

```
Any agent BLOCKED? → STOP, ask user
Any test failing? → Re-spawn failing agent in fix mode
Any lint failing? → Re-spawn failing agent in fix mode
All green? → Commit + update state + prompt for review
```

---


---

## Responsibilities

See `.agents/rules/orchestrator-responsibilities.md` for Task Distribution, State Update handling, Rule Update handling, Agent Memory verification, Output Styles, and Project State update protocols.
