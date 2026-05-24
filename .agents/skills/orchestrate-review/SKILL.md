# /orchestrate-review — Review Orchestrator

## Purpose
Classify a diff, spawn ONLY the reviewers that apply, synthesize findings into a severity-ranked report, and gate the merge decision.

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

---

## 🚧 NON-NEGOTIABLE: Fabrication-Detection Gate

**This gate is the LAST line of defense against doc-only features and unverified claims reaching main.**

### Reviewers MUST flag these patterns

1. **Doc-only features** — docstring/comment claims a behavior, but no code produces it:
   - Docstring says "uses caching" — no `cache_control` field in diff
   - Function name implies behavior (`enableX()`) — body is `return` or noop
   - Test name implies coverage — assertion only checks a constant

2. **Unverified external API claims** — code asserts a third-party service does X without citation:
   - "Provider supports Y" with no docs link
   - Pricing constants hardcoded without source
   - Provider-confusion: copy-pasted from different provider's example

3. **Plan claims that didn't survive verification** — `[UNVERIFIED]` claims from upstream that got silently inherited

### How the AC reviewer enforces this

For every claimed feature, ask: **"Does the code actually do this, or only document the intent?"**

If a criterion says "uses caching" / "saves N tokens" / "supports feature X" and the diff has only a docstring, mark as **❌ NOT MET (doc-only)**.

### Severity rules

- Doc-only feature claim where user could believe it works → **CRITICAL**
- Unverified external API/pricing claim → **HIGH**
- "Cache-friendly" / "performance-optimised" prose with no measurement → **MEDIUM**

---

## Execution Flow

### Step 0: Read State

```bash
cat .project-state.json 2>/dev/null || echo "No state file"
```

Check:
- `current_phase` — should be `ready_to_review`
- `review_feedback.iteration` — if > 0, this is a re-review after fix pass
- `ticket_id` and `branch` — for context

If `iteration > 0`, check if previously flagged issues were resolved.

### Step 1: Get the Diff

**Multi-repo:** Collect diffs from all repos that have changes on the feature branch.

```bash
BRANCH=$(python3 -c "import json; print(json.load(open('.project-state.json')).get('branch',''))")

# For each repo listed in .project-context.md:
# cd <repo-path>
# git fetch origin main 2>/dev/null
# git diff main...$BRANCH --stat
# git diff main...$BRANCH
```

If no changes found, ask: "What should I review? Share the branch name or describe the changes."

### Step 1.25: Load Acceptance Criteria

**Every review MUST verify acceptance criteria.** No exceptions.

Read the ticket's spec from Notion via MCP. Extract:
- **Acceptance Criteria** (or "Success Criteria" / "Definition of Done")
- **What to Do** — functional requirements
- **Design Spec** (if present) — required tokens/classes/copy

Write each criterion to a numbered list. If the ticket has no explicit AC, ask the user: "This ticket has no acceptance criteria — what's the definition of done?" Do not proceed without a list.

### Step 1.5: Run Automated Static Analysis

Run linters first — violations here are automatic CRITICAL findings:

```bash
# Frontend (read `.project-context.md` for repo location)
cd <PROJECT:frontend-repo>
npx eslint src/ --max-warnings 0 2>&1 | head -50
npx tsc --noEmit 2>&1 | head -30

# Backend (read `.project-context.md` for repo location)
cd <PROJECT:backend-repo>
python -m ruff check app/ 2>&1 | head -50
python -m mypy app/ --ignore-missing-imports 2>&1 | head -30
```

Any violations = CRITICAL findings that block approval.

### Step 1.75: Classify the Diff → Pick the Reviewer Set

Collect changed paths from all repos, then classify:

| Bucket | Path pattern |
|---|---|
| **fe_code** | `src/app/**`, `src/components/**`, `src/hooks/**`, `src/lib/**`, `src/styles/**`, `**/*.tsx`, `**/*.ts`, `**/*.css` |
| **be_code** | `backend/**/*.py`, `scripts/**/*.py`, `alembic/**` |
| **tests** | `**/tests/**`, `**/__tests__/**`, `**/*test*.py`, `**/*.test.ts`, `**/*.test.tsx` |
| **config** | `*.yml`, `*.yaml`, `*.toml`, `*.json`, `.github/**`, `Dockerfile*` |
| **docs** | `docs/**/*.md`, `CHANGELOG.md`, `README.md`, `*.md` under root |

One path can hit multiple buckets.

### Reviewer selection rules

Apply these in order; a reviewer runs if ANY rule adds it.

| # | Reviewer | Runs when |
|---|---|---|
| 1 | Engineering | `fe_code` OR `be_code` OR `config` |
| 2 | Security | `fe_code` OR `be_code` OR `config` |
| 3 | Design | `fe_code` |
| 4 | Adversarial | **ALWAYS** |
| 5 | Acceptance Criteria | **ALWAYS** — load-bearing, gates the verdict |

### Common PR shapes → reviewer set

| PR shape | Spawned reviewers |
|---|---|
| Full-stack FE + BE | 1, 2, 3, 4, 5 |
| Backend-only | 1, 2, 4, 5 — skip 3 |
| Frontend-only | 1, 2, 3, 4, 5 |
| Config / CI only | 1, 2, 4, 5 |
| Docs-only | 4, 5 — skip 1, 2, 3 |
| Tests-only | 1, 4, 5 — skip 2, 3 |

State which reviewers you're spawning and why in one line before Step 2.

If classification is ambiguous, err on the side of including the reviewer. When in doubt, spawn.

### Step 2: Spawn Selected Reviewers in Parallel

Spawn only the classified set simultaneously:

| # | Agent | When |
|---|-------|------|
| 1 | `agent-reviewer-engineering` | Code changes |
| 2 | `agent-reviewer-security` | Code changes |
| 3 | `agent-reviewer-design` | FE changes |
| 4 | `agent-reviewer-adversarial` | Always |
| 5 | `agent-reviewer-acceptance-criteria` | Always |

### Step 3: Synthesize Findings

Merge all reviewer outputs into a unified severity-ranked report:
```
🔴 CRITICAL: [count] — [list]
🟡 HIGH: [count] — [list]
🟠 MEDIUM: [count] — [list]
🟢 LOW: [count] — [list]
```

### Step 4: Gate Decision

- Any **CRITICAL** finding = automatic NEEDS FIXES
- Any **NOT MET** AC = automatic NEEDS FIXES
- All findings ≤ MEDIUM + all ACs MET = APPROVED

### Step 5: Update State

```python
import json
from datetime import datetime, timezone

with open('.project-state.json', 'r') as f:
    state = json.load(f)

state['review_feedback'] = {
    'verdict': 'APPROVED' | 'NEEDS_FIXES',
    'iteration': state['review_feedback'].get('iteration', 0) + 1,
    'acceptance_criteria': [...],
    'critical': [...],
    'high': [...],
    'medium': [...],
    'low': [...]
}
state['updated_at'] = datetime.now(timezone.utc).isoformat()
state['history'].append({
    'timestamp': datetime.now(timezone.utc).isoformat(),
    'phase': 'review',
    'action': 'review_complete',
    'detail': f"Verdict: {state['review_feedback']['verdict']}"
})

with open('.project-state.json', 'w') as f:
    json.dump(state, f, indent=2)
```

## Post-flight

```
Review complete: [PR #N]
Verdict: [APPROVED | NEEDS_FIXES]
Findings: [count by severity]
Iteration: [N]

If NEEDS_FIXES:
  - Re-spawn /orchestrate-build in fix mode
  - Then re-run /orchestrate-review
```

---

## Responsibilities

See `~/.agents/rules/orchestrator-responsibilities.md` for Task Distribution, State Update handling, Rule Update handling, Agent Memory verification, Output Styles, and Project State update protocols.
