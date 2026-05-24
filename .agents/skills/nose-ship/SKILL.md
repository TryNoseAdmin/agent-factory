> ⚠️ **DEPRECATED** — This skill has been superseded by the agent-orchestrator architecture.
> Use `/orchestrate-*` skills instead. This file is kept for backward compatibility and will be removed in a future release.
> See `~/.agents/skills/orchestrate-*/SKILL.md` for the new thin orchestrators and `~/.agents/agents/agent-*.md` for domain agents.

---
name: nose-ship
version: 2.0.0
description: |
  NOSE ship workflow. Merges base branch, runs tests, bumps version, updates CHANGELOG, commits, pushes, and creates PR. Use when asked to "ship", "create PR", "push", "ready to merge", or "land this". Assumes /review has already passed.
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Grep
  - Glob
  - AskUserQuestion
---

# /ship — NOSE Ship Workflow (v2)

You are the NOSE ship workflow. Run sequentially — each step must pass before the next. Auto-generates PR description from shared state for complete, contextual pull requests.

**State file:** `.project-state.json`

**Prerequisites:** `/review` must show APPROVED or APPROVED WITH NOTES. State phase must be `ready_to_ship`. Never ship with CRITICAL findings.

## Step 0: Read State and Validate Gate

```bash
if [ -f .project-state.json ]; then
  cat .project-state.json
else
  echo "ERROR: No state file. Run /nose-plan and /review first."
  exit 1
fi
```

Validate the ship gate from state:
- `review_feedback.verdict` must be `APPROVED` or `APPROVED_WITH_NOTES` — never ship `NEEDS_FIXES`
- `current_phase` must be `ready_to_ship`
- `qa_results.recommendation` must be `proceed` (if QA was run)

If gate fails:
```
❌ SHIP GATE BLOCKED
Review verdict: [NEEDS_FIXES] — fix critical/high issues first with /build
Run /review to get updated verdict before shipping.
```

## Step 1: Verify State

```bash
# Check we're on a feature branch
BRANCH=$(git branch --show-current)
if [[ "$BRANCH" == "main" ]]; then
  echo "ERROR: Cannot ship from main. Create a feature branch first."
  exit 1
fi
echo "Shipping from branch: $BRANCH"

# Verify no uncommitted changes
git status --porcelain
```

If there are uncommitted changes, ask: "There are uncommitted changes. Should I commit them first, or is something unfinished?"

## Step 2: Merge Base Branch

```bash
# Fetch latest main
git fetch origin main

# Check for conflicts
git merge-base --is-ancestor origin/main HEAD || echo "BEHIND_MAIN"
```

If behind main:
```bash
git merge origin/main --no-edit
```

If merge conflicts exist, stop: "There are merge conflicts that need manual resolution. Fix them and re-run `/ship`."

## Step 3: Run Full Test Suite

**Multi-repo:** Run tests in each repo that has changes on the feature branch.

```bash
# Frontend tests (nose-fe)
FEATURE_BRANCH=$(cat PROJECT:brain-repo/.project-state.json | python3 -c "import sys,json; print(json.load(sys.stdin).get('branch',''))")

cd PROJECT:frontend-repo
if git show-ref --verify --quiet refs/heads/$FEATURE_BRANCH 2>/dev/null || git show-ref --verify --quiet refs/remotes/origin/$FEATURE_BRANCH 2>/dev/null; then
  git checkout $FEATURE_BRANCH 2>/dev/null || true
  npm test -- --watchAll=false --passWithNoTests 2>&1
fi

# Backend tests (nose-be)
cd PROJECT:backend-repo
if git show-ref --verify --quiet refs/heads/$FEATURE_BRANCH 2>/dev/null || git show-ref --verify --quiet refs/remotes/origin/$FEATURE_BRANCH 2>/dev/null; then
  git checkout $FEATURE_BRANCH 2>/dev/null || true
  python -m pytest tests/ -v 2>&1 || true
fi

cd PROJECT:brain-repo
```

If any tests fail, STOP. "Tests are failing — fix them before shipping. Run the failing tests to see details."

## Step 4: Determine Version Bump

Read current VERSION:
```bash
cat VERSION
```

Ask or infer from the changes:
- **patch** (0.0.X) — Bug fixes, small improvements, no new features
- **minor** (0.X.0) — New features, backward compatible
- **major** (X.0.0) — Breaking changes, major redesigns

Default: **patch** for small changes, **minor** for features.

Bump VERSION:
```bash
# Example: 0.2.0 → 0.2.1 (patch) or 0.3.0 (minor)
NEW_VERSION="0.X.Y"
echo "$NEW_VERSION" > VERSION
```

## Step 5: Update CHANGELOG

Read `CHANGELOG.md` and add an entry for this version.

Use NOSE brand voice — write as if documenting a luxury product update, not a technical changelog.

Template:
```markdown
## [X.Y.Z] - YYYY-MM-DD

### Added
- **[Feature Name]** — [What it does and why it matters to users]
  - [Specific detail]
  - [Specific detail]

### Changed
- `path/to/file` — [What changed and why]

### Fixed
- [Bug description] — [What was happening, what now happens]

### Technical Details
- [Implementation notes relevant to other developers]
```

## Step 6: Commit

**Multi-repo:** Commit in each repo that has changes. VERSION and CHANGELOG live in `nose` (brain) repo.

```bash
COMMIT_MSG="feat(TASK-XXX): [feature description]

- [Key change 1]
- [Key change 2]

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"

# nose-fe (if has frontend changes)
cd PROJECT:frontend-repo
if ! git diff --quiet HEAD 2>/dev/null || git diff --cached --quiet HEAD 2>/dev/null; then
  git add src/ tests/
  git commit -m "$COMMIT_MSG"
fi

# nose-be (if has backend changes)
cd PROJECT:backend-repo
if ! git diff --quiet HEAD 2>/dev/null || git diff --cached --quiet HEAD 2>/dev/null; then
  git add backend/ database/ scripts/
  git commit -m "$COMMIT_MSG"
fi

# nose (VERSION + CHANGELOG always go here)
cd PROJECT:brain-repo
git add VERSION CHANGELOG.md docs/
git commit -m "$COMMIT_MSG"
```

## Step 7: Push

Push each repo that had commits:

```bash
# Push nose-fe (if changes)
cd PROJECT:frontend-repo && git push -u origin HEAD

# Push nose-be (if changes)
cd PROJECT:backend-repo && git push -u origin HEAD

# Push nose (always — VERSION/CHANGELOG)
cd PROJECT:brain-repo && git push -u origin HEAD
```

If push fails due to upstream divergence:
- If safe: `git pull --rebase origin main` then push again
- If unclear: ask the user before any force operations

## Step 8: Create Pull Request from State

Read state to build a rich, contextual PR description:

```bash
python3 -c "
import json

with open('.project-state.json', 'r') as f:
    state = json.load(f)

ticket_id = state.get('ticket_id', 'N/A')
feature_name = state.get('feature_name', 'Feature update')
ticket_notion_url = state.get('ticket_notion_url', '')
branch = state.get('branch', '')
version = state.get('version', '')
qa_score = state.get('qa_results', {}).get('score', 'N/A')
qa_rating = state.get('qa_results', {}).get('rating', 'N/A')
review_verdict = state.get('review_feedback', {}).get('verdict', 'N/A')
completed_tasks = state.get('progress', {}).get('completed', [])

tasks_md = chr(10).join([f'- {t}' for t in completed_tasks]) if completed_tasks else '- Feature implemented'

print(f'''## Summary
- {feature_name}
- Ticket: {ticket_id}
- Version: {version}

## What changed
{tasks_md}

## Quality gates
- Review: {review_verdict}
- QA Health Score: {qa_score}/100 ({qa_rating})

## Test plan
- [ ] All tests pass (\`npm test\`)
- [ ] Backend tests pass (\`pytest\`)
- [ ] Manually tested: {feature_name}
- [ ] \`/review\` passed — verdict: {review_verdict}
- [ ] \`/qa\` passed — score: {qa_score}/100

## Notion ticket
[{ticket_id}](https://www.notion.so/8a82f4d7c75f49699c8984d0074e89fb)

🤖 Generated with [Claude Code](https://claude.com/claude-code)''')
"
```

Then create the PR:
```bash
TICKET_ID=$(python3 -c "import json; s=json.load(open('.project-state.json')); print(s.get('ticket_id','N/A'))")
FEATURE_NAME=$(python3 -c "import json; s=json.load(open('.project-state.json')); print(s.get('feature_name','Feature update'))")

gh pr create \
  --title "feat($TICKET_ID): $FEATURE_NAME" \
  --body "$(python3 -c "
import json
with open('.project-state.json') as f:
    state = json.load(f)
ticket_id = state.get('ticket_id', 'N/A')
feature_name = state.get('feature_name', 'Feature update')
qa_score = state.get('qa_results', {}).get('score', 'N/A')
qa_rating = state.get('qa_results', {}).get('rating', 'N/A')
review_verdict = state.get('review_feedback', {}).get('verdict', 'N/A')
completed = state.get('progress', {}).get('completed', [])
tasks = chr(10).join([f'- {t}' for t in completed]) if completed else '- Feature implemented'
print(f'''## Summary
{tasks}

## Quality gates
- Review: {review_verdict}
- QA Health Score: {qa_score}/100 ({qa_rating})

## Test plan
- [ ] All tests pass
- [ ] /review passed — verdict: {review_verdict}
- [ ] /qa passed — score: {qa_score}/100

## Notion ticket
[{ticket_id}](https://www.notion.so/8a82f4d7c75f49699c8984d0074e89fb)

🤖 Generated with [Claude Code](https://claude.com/claude-code)''')
")"
```

## Step 9: Update State — Shipped

```bash
python3 -c "
import json
from datetime import datetime, timezone

with open('.project-state.json', 'r') as f:
    state = json.load(f)

state['current_phase'] = 'shipped'
state['updated_at'] = datetime.now(timezone.utc).isoformat()
state['history'].append({
    'timestamp': datetime.now(timezone.utc).isoformat(),
    'phase': 'ship',
    'action': 'shipped',
    'detail': 'PR created, ready for review and merge'
})

with open('.project-state.json', 'w') as f:
    json.dump(state, f, indent=2)

print('State: shipped. PR created.')
"
```

## Step 10: Done

Output:
```
✅ Shipped!

Branch: feature/task-XXX-[slug]
Version: X.Y.Z → X.Y.Z+1
PR: [GitHub PR URL]

Next steps:
• User reviews PR on GitHub
• After approval, merge on GitHub
• Run /release to close the Notion ticket and update docs
```

Or if using autonomous mode: "State updated to `shipped`. `/nose-orchestrator` will auto-chain to `/release` after PR is merged."

## NOSE-Specific Rules

- **Never commit to main** — always feature branches
- **Never force-push without asking** — ask the user first
- **Never skip tests** — if tests fail, fix them or ask the user
- **VERSION file always updated** — even for small fixes
- **CHANGELOG always updated** — using brand voice, not technical jargon
- **Ship gate required** — state.review_feedback.verdict must be APPROVED or APPROVED_WITH_NOTES
