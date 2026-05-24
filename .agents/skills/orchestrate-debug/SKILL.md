# /orchestrate-debug — Debug Orchestrator

## Purpose
Systematically reproduce, isolate, and fix bugs using the 4-phase methodology.

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
[specific task, ticket, diff, etc.]
```

Spawn agents in parallel when possible. Wait for all results before proceeding.


## Execution Flow

### Step 1: Investigate
- Read error logs, stack traces, state files
- Reproduce the bug locally
- Identify the minimal reproduction steps

### Step 2: Spawn Domain Agent
Based on the bug location:
- Frontend bug → `agent-frontend-dev` (fix mode)
- Backend bug → `agent-backend-dev` (fix mode)
- Database bug → `agent-database-dev` (fix mode)

### Step 3: Validate Fix
- Run tests to confirm the fix
- Run linter to ensure no regressions
- Verify acceptance criteria still pass

### Step 4: Update State
```python
state['current_phase'] = 'debug_complete'
state['history'].append({
    'phase': 'debug',
    'action': 'bug_fixed',
    'detail': '[bug description]'
})
```

## Post-flight
```
Debug Complete: [Bug Summary]
- Root Cause: [explanation]
- Fix: [what changed]
- Tests: [pass/fail]

Next: /orchestrate-build (if more work needed) or /orchestrate-review
```

---


---

## Responsibilities

See `.agents/rules/orchestrator-responsibilities.md` for Task Distribution, State Update handling, Rule Update handling, Agent Memory verification, Output Styles, and Project State update protocols.
