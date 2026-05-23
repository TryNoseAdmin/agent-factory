# /orchestrate-ship — Ship Orchestrator

## Purpose
Create PR, run final checks, and merge to main. The gate before release.

## Execution Flow

### Step 1: Final Pre-Flight Checks
```bash
git status
git diff --stat
```
Ensure branch is clean and only intended files are modified.

### Step 2: Create PR
```bash
gh pr create --base main --title "feat(TASK-XXX): [description]" --body "[description + test plan + checklist]"
```

### Step 3: Run /orchestrate-review
Do NOT merge until review passes. Any unmet AC = blocker.

### Step 4: Merge
```bash
gh pr merge --squash --delete-branch
```

### Step 5: Update State
```python
state['current_phase'] = 'shipped'
state['history'].append({
    'phase': 'ship',
    'action': 'pr_merged',
    'detail': 'PR #N merged to main'
})
```

## Post-flight
```
Ship Complete: PR #[N]
- Branch: [feature/name]
- Merged: [date]
- Review: [passed]

Next: /orchestrate-release
```

---


---

## Responsibilities

See `.agents/rules/orchestrator-responsibilities.md` for Task Distribution, State Update handling, Rule Update handling, Agent Memory verification, Output Styles, and Project State update protocols.
