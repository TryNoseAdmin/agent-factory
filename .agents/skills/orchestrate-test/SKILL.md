# /orchestrate-test — Test Orchestrator

## Purpose
Comprehensive testing phase. Runs automated checks, spawns parallel QA testers, synthesizes results into a health report, and gates the next phase.

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

## Pre-flight
1. Read state: `.project-state.json`
2. Identify what changed (from build output or diff)

## Execution Flow

### Step 1: Automated Checks
```bash
# Frontend (read `.project-context.md` for repo location)
cd <PROJECT:frontend-repo>
npx tsc --noEmit
npx eslint src/ --max-warnings 0
npm test -- --watchAll=false
npx playwright test

# Backend (read `.project-context.md` for repo location)
cd <PROJECT:backend-repo>
python -m pytest tests/ -v
python -m ruff check app/
python -m mypy app/ --ignore-missing-imports
```

### Step 2: Spawn Testers in Parallel
| Agent | Focus |
|-------|-------|
| `agent-qa-functional` | User flows, forms, navigation, error states |
| `agent-qa-visual` | Brand consistency, responsive, dark mode |
| `agent-qa-performance` | Core Web Vitals, bundle size, API latency |
| `agent-qa-accessibility` | WCAG 2.1 AA, keyboard nav, screen reader |
| `agent-metrics-analyst` | Performance metrics, benchmark analysis, regression detection |

### Step 3: Synthesize Results
Merge findings into QA health report:
```
QA Health Report
- Functional: [score] — [PASS/FAIL]
- Visual: [score] — [PASS/FAIL]
- Performance: [score] — [PASS/FAIL]
- Accessibility: [score] — [PASS/FAIL]
- Overall: [score] — [PASS/FAIL]
```

### Step 4: Regression Check
Verify no existing functionality broke:
```bash
# Run full test suite (not just changed files)
cd <PROJECT:frontend-repo>
npm test -- --watchAll=false

cd <PROJECT:backend-repo>
python -m pytest tests/ -v
```

### Step 5: Update State
```python
import json
from datetime import datetime, timezone

with open('.project-state.json', 'r') as f:
    state = json.load(f)

state['qa_results'] = {
    'score': [overall_score],
    'rating': 'PASS' | 'FAIL',
    'recommendation': 'Proceed' | 'Fix and re-test' | 'Debug required',
    'iteration': state['qa_results'].get('iteration', 0) + 1,
    'failures': {
        'critical': [...],
        'high': [...],
        'medium': [...],
        'low': [...]
    }
}
state['updated_at'] = datetime.now(timezone.utc).isoformat()
state['history'].append({
    'timestamp': datetime.now(timezone.utc).isoformat(),
    'phase': 'test',
    'action': 'qa_complete',
    'detail': f"Score: {state['qa_results']['score']} — {state['qa_results']['rating']}"
})

with open('.project-state.json', 'w') as f:
    json.dump(state, f, indent=2)
```

### Step 6: Decision
| Overall Score | Action |
|---------------|--------|
| ≥ 85 | Proceed to review |
| 70-84 | Fix issues, re-test |
| < 70 | Spawn debug agent, stop |

## Post-flight
```
Test complete: [Feature Name]
- Automated: [pass/fail counts]
- QA Score: [overall]
- Critical Issues: [N]
- Warnings: [N]

[Ready for review | Blocked — issues found]
```

---

## Responsibilities

See `.agents/rules/orchestrator-responsibilities.md` for Task Distribution, State Update handling, Rule Update handling, Agent Memory verification, Output Styles, and Project State update protocols.
