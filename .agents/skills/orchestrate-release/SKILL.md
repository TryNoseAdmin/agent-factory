# /orchestrate-release — Release Orchestrator

## Purpose
Post-merge release workflow for the nose repo. Updates docs, polishes CHANGELOG, creates git tag.

## Execution Flow

### Step 1: Identify What Merged
```bash
git log --oneline -5
git diff HEAD~1...HEAD --stat
```

### Step 2: Update Affected Documentation
| If this changed... | Update this doc... |
|--------------------|--------------------|
| API endpoints | `docs/NOSE_PRODUCTION_ARCHITECTURE.md` |
| Database schema | `docs/schema/perfume-schema-v2.md` |
| Tech stack | `docs/TECH_STACK.md` |
| Deployment | `docs/REPOS.md` |
| Brand/design | `docs/brand_guidelines.md` |

### Step 3: Cross-Doc Consistency Check
```bash
grep -r "v0\.[0-9]\." docs/ --include="*.md" | grep -v CHANGELOG
grep -r "TODO\|FIXME" docs/ --include="*.md"
```

### Step 4: Polish CHANGELOG Entry
Apply brand voice polish to the latest entry. Active voice, specific, user-value focused.

### Step 5: Bump VERSION
```bash
echo "X.Y.Z" > VERSION
```

### Step 6: Create Git Tag
```bash
VERSION=$(cat VERSION)
git tag -a "v$VERSION" -m "Release v$VERSION — $(date +%Y-%m-%d)"
git push origin "v$VERSION"
```

### Step 7: Update Notion Ticket (if applicable)
Call `skills/ticket` to mark ticket as Completed with implementation summary.

### Step 8: Session Handoff (Optional)
If this is the end of a session, call `skills/handoff` to generate a structured handoff for the next agent.

## Post-flight
```
✅ Release complete!

Version: v[X.Y.Z]
Ticket: [TASK-XXX → Completed]
Docs updated: [list]
Tag: v[X.Y.Z]

The scent has been bottled. 🫧
```

---


---

## Responsibilities

See `.agents/rules/orchestrator-responsibilities.md` for Task Distribution, State Update handling, Rule Update handling, Agent Memory verification, Output Styles, and Project State update protocols.
