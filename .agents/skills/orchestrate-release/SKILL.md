# /orchestrate-release — Release Orchestrator

## Purpose
Post-merge release workflow. Updates docs, polishes CHANGELOG, creates git tag.

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

### Step 1: Identify What Merged
```bash
git log --oneline -5
git diff HEAD~1...HEAD --stat
```

### Step 2: Update Affected Documentation
| If this changed... | Update this doc... |
|--------------------|--------------------|
| API endpoints | `docs/ARCHITECTURE.md` or equivalent |
| Database schema | `docs/schema/` or equivalent |
| Tech stack | `docs/TECH_STACK.md` or equivalent |
| Deployment | `docs/DEPLOYMENT.md` or equivalent |
| Brand/design | `docs/brand_guidelines.md` or equivalent |

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

Release complete. 🚀
```

---


---

## Responsibilities

See `.agents/rules/orchestrator-responsibilities.md` for Task Distribution, State Update handling, Rule Update handling, Agent Memory verification, Output Styles, and Project State update protocols.
