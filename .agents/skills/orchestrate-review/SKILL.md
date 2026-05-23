# /orchestrate-review — Review Orchestrator

## Purpose
Classify a diff, spawn ONLY the reviewers that apply, synthesize findings into a severity-ranked report, and gate the merge decision.

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
[specific task, ticket, diff, etc.]
```

Spawn agents in parallel when possible. Wait for all results before proceeding.


## Pre-flight
1. Read state: `.agents/project-data/state/nose/state.json`
2. Fetch the diff (PR or local branch)
3. Classify the diff to determine reviewer set

### Classification Rules

| PR Shape | Spawn These Reviewers |
|----------|----------------------|
| Frontend-only (`.tsx`, `.css`) | Engineering, Security, Design & A11y, Adversarial, Design Consistency, Coding Standards, AC |
| Backend-only (`.py`, SQL) | Engineering, Security, Adversarial, Coding Standards, AC |
| Full-stack | ALL reviewers |
| Docs-only | Adversarial, AC |
| Design-only | Design & A11y, Design Consistency, AC |

**Always spawn:** Adversarial + Acceptance Criteria
**Always skip if not applicable:** Design reviewers on backend-only PRs, Security on docs-only PRs

## Execution Flow

### Step 1: Spawn Selected Reviewers in Parallel
Spawn only the classified set simultaneously:

| # | Agent | When |
|---|-------|------|
| 1 | `agent-reviewer-engineering` | Code changes |
| 2 | `agent-reviewer-security` | Code changes |
| 3 | `agent-reviewer-design` | FE changes |
| 4 | `agent-reviewer-adversarial` | Always |
| 5 | `agent-reviewer-acceptance-criteria` | Always |
| 6 | `agent-compliance-auditor` | Auth, payment, PII, or external API changes |

### Step 2: Synthesize Findings
Merge all reviewer outputs into a unified severity-ranked report:
```
🔴 CRITICAL: [count] — [list]
🟡 HIGH: [count] — [list]
🟠 MEDIUM: [count] — [list]
🟢 LOW: [count] — [list]
```

### Step 3: Gate Decision
- Any **CRITICAL** finding = automatic NEEDS FIXES
- Any **NOT MET** AC = automatic NEEDS FIXES
- All findings ≤ MEDIUM + all ACs MET = APPROVED

### Step 4: Update State
```python
state['review_feedback'] = {
    'verdict': 'APPROVED' | 'NEEDS_FIXES',
    'findings': [...],
    'iteration': N
}
```

## Post-flight
```
Review complete: [PR #N]
Verdict: [APPROVED | NEEDS_FIXES]
Findings: [count by severity]

If NEEDS_FIXES:
  - Re-spawn /orchestrate-build in fix mode
  - Then re-run /orchestrate-review
```

---


---

## Responsibilities

See `.agents/rules/orchestrator-responsibilities.md` for Task Distribution, State Update handling, Rule Update handling, Agent Memory verification, Output Styles, and Project State update protocols.
