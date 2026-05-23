> **DEPRECATED** — Merged into `orchestrate-plan` or `orchestrate-test` or downgraded to utility skill.
>
# /orchestrate-qa — QA Orchestrator

## Purpose
Spawn 4 parallel QA testers (functional, visual, performance, accessibility) against the live app and produce a unified health score report.

## Spawn Protocol

For EACH agent you spawn, construct the prompt as:

```
{ReadFile('.agents/rules/universal.md')}

---

{ReadFile('.agents/agents/agent-<name>.md')}

---

## Task Context
[specific task, ticket, diff, etc.]
```

Spawn agents in parallel when possible. Wait for all results before proceeding.


## Pre-flight
1. Read state: `.agents/project-data/state/nose/state.json`
2. Determine deployment target (preview URL or local)
3. Read `docs/design/DESIGN_CHECKLIST.md` for pass/fail criteria

## Execution Flow

### Step 1: Spawn 4 QA Testers in Parallel
Spawn simultaneously. Each uses the `/browse` skill for navigation.

| # | Agent | Focus |
|---|-------|-------|
| 1 | `agent-qa-functional` | User flows, forms, navigation, error states |
| 2 | `agent-qa-visual` | Brand consistency, responsive, dark mode |
| 3 | `agent-qa-performance` | Core Web Vitals, bundle size, API latency |
| 4 | `agent-qa-accessibility` | WCAG 2.1 AA, keyboard nav, screen reader |

### Step 2: Synthesize Results
Calculate health score:
```
Health Score = (PASS checks / Total checks) × 100
```

| Score | Verdict |
|-------|---------|
| 90-100 | ✅ GREEN — ship it |
| 75-89 | 🟡 YELLOW — fix MEDIUMs, then ship |
| < 75 | 🔴 RED — fix HIGHs+CRITICALs, re-run QA |

### Step 3: Update State
```python
state['qa_score'] = score
state['current_phase'] = 'qa_complete' if score >= 75 else 'qa_failed'
```

## Post-flight
```
QA Report: [Score]/100

Functional: [PASS/FAIL/PARTIAL]
Visual: [PASS/FAIL/PARTIAL]
Performance: [PASS/SLOW/FAIL]
Accessibility: [PASS/FAIL]

If score < 85:
  - Spawn /orchestrate-debug → /orchestrate-build fix → re-QA
```

---


---

## Responsibilities

See `.agents/rules/orchestrator-responsibilities.md` for Task Distribution, State Update handling, Rule Update handling, Agent Memory verification, Output Styles, and Project State update protocols.
