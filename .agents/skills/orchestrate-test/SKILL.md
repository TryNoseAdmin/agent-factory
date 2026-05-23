# /orchestrate-test — Test Orchestrator

## Purpose
Comprehensive testing phase. Spawns parallel testers for functional, visual, performance, and accessibility verification. Includes unit/integration tests and E2E testing.

## Pre-flight
1. Read state: `.agents/project-data/state/nose/state.json`
2. Identify what changed (from build output or diff)

## Execution Flow

### Step 1: Automated Checks
```bash
# Frontend
cd ~/Documents/GitHub/TryNose/nose-fe
npx tsc --noEmit
npx eslint src/ --max-warnings 0
npm test -- --watchAll=false
npx playwright test

# Backend
cd ~/Documents/GitHub/TryNose/nose-be
python -m pytest tests/ -v
python -m ruff check backend/app/
python -m mypy backend/app/ --ignore-missing-imports
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

### Step 4: Decision
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
