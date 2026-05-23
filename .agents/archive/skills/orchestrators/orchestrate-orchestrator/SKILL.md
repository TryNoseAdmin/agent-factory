# /orchestrate-orchestrator — Meta Orchestrator

## Purpose
Read global state and auto-decide which orchestrator to trigger next. This is the system brain for autonomous workflows.

## Execution Flow

### Step 1: Read State
```bash
cat .agents/project-data/state/nose/state.json
cat .agents/project-data/state/nose/config.json
```

### Step 2: Health Check (Cleanup)
```bash
python3 -c "
import json
from datetime import datetime, timezone

c = json.load(open('.agents/project-data/state/nose/config.json'))
next_cleanup = c.get('cleanup', {}).get('next_cleanup')
if next_cleanup:
    due = datetime.now(timezone.utc) > datetime.fromisoformat(next_cleanup)
    print('CLEANUP_DUE' if due else 'CLEANUP_OK')
else:
    print('CLEANUP_UNSET')
"
```

If `CLEANUP_DUE`: spawn `agent-cleanup` to run an audit. It will report findings and ask for approval before any destructive action. It does NOT auto-delete. After the audit completes (regardless of approvals), proceed to Step 3.
If thresholds breached (memory >500 lines, history >100): spawn `agent-cleanup` for priority audit. Still requires user approval for all actions.

### Step 3: Decide Next Action

| State Condition | Trigger |
|-----------------|---------|
| `current_phase == "not_started"` | `/orchestrate-plan` |
| `current_phase == "planned"` | `/orchestrate-build` |
| `current_phase == "built"` | `/orchestrate-test` |
| `current_phase == "tested"` | `/orchestrate-review` |
| `review_feedback.verdict == "NEEDS_FIXES"` | `/orchestrate-build` (fix mode) |
| `current_phase == "reviewed"` | `/orchestrate-ship` |
| `current_phase == "shipped"` | `/orchestrate-release` |

### Step 4: Trigger Next Orchestrator
Spawn the appropriate orchestrator agent with state context.

### Step 5: Loop or Stop
- If user said "autonomous mode" → continue looping
- If user said "one step at a time" → stop and wait for approval

## Post-flight
```
Meta-Orchestrator Decision:
Current Phase: [phase]
Cleanup: [due / ok / ran]
Next Action: [orchestrator-name]
Reason: [why this was chosen]

Execute? [Yes / No / Override to X]
```

---

## Responsibilities

See `.agents/rules/orchestrator-responsibilities.md` for Task Distribution, State Update handling, Rule Update handling, Agent Memory verification, Output Styles, and Project State update protocols.
