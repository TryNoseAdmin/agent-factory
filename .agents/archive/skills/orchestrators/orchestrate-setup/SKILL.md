# /orchestrate-setup — Session Bootstrap

## Purpose
Quick health check. Validates state, git, and dependencies. Flags issues. Does NOT auto-fix — that's the agent's call.

## Execution Flow

### Step 1: State Check
```bash
python3 -c '
import json
from pathlib import Path
p = Path(".agents/project-data/state/nose/state.json")
if not p.exists(): print("STATE: MISSING"); exit(1)
try: s = json.load(p.open())
except: print("STATE: CORRUPT"); exit(1)
missing = [f for f in ["current_phase","version","last_updated"] if f not in s]
print(f"STATE: INCOMPLETE ({\",\".join(missing)})" if missing else f"STATE: OK | phase={s.get(\"current_phase\")} | version={s.get(\"version\")}")
'
```

### Step 2: Git Check
```bash
echo "BRANCH: $(git branch --show-current)"
git diff --quiet && echo "WT: CLEAN" || echo "WT: DIRTY ($(git status --short | wc -l | xargs) files)"
```

### Step 3: Dependency Check
```bash
python3 -c 'import json; c=json.load(open(".agents/project-data/state/nose/config.json")); print(f"NOTION: {c.get(\"notion_connected\", False)}")' 2>/dev/null || echo "CONFIG: MISSING"
graphify hook status 2>/dev/null | grep -q installed && echo "GRAPHIFY: OK" || echo "GRAPHIFY: NO HOOKS"
python3 -c '
import sqlite3, os
from pathlib import Path
db = Path(".code-review-graph/graph.db")
if db.exists():
    age_days = (os.path.getmtime(".git/hooks/post-commit") - os.path.getmtime(db)) / 86400 if Path(".git/hooks/post-commit").exists() else 0
    print(f"CODE_REVIEW_GRAPH: OK (db age: {age_days:.0f} days)")
else:
    print("CODE_REVIEW_GRAPH: MISSING")
' 2>/dev/null || echo "CODE_REVIEW_GRAPH: CHECK_FAILED"
python3 -c '
import json
from datetime import datetime, timezone

c = json.load(open(".agents/project-data/state/nose/config.json"))
next_cleanup = c.get("cleanup", {}).get("next_cleanup")
if next_cleanup:
    due = datetime.now(timezone.utc) > datetime.fromisoformat(next_cleanup)
    print("CLEANUP_DUE" if due else "CLEANUP_OK")
else:
    print("CLEANUP_UNSET")
' 2>/dev/null
```

### Step 4: Inventory
```bash
ls .agents/skills/*/SKILL.md 2>/dev/null | wc -l | xargs echo "SKILLS:"
ls .agents/agents/agent-*.md 2>/dev/null | wc -l | xargs echo "AGENTS:"
```

**Need a skill you don't see?** Call `skills/find-skills` to search the skill registry.

## Red Flags (stop and fix before proceeding)

| Flag | What to do |
|------|-----------|
| `STATE: MISSING/CORRUPT/INCOMPLETE` | Read `project-data/state/nose/template.json` or create minimal state manually |
| `BRANCH: main` + `WT: DIRTY` | Commit or stash. Never work on dirty main. |
| `CONFIG: MISSING` | Create `.agents/project-data/state/nose/config.json` with `{"notion_connected": false}` |
| `GRAPHIFY: NO HOOKS` | Run `.agents/scripts/install-graph-hooks.sh` |
| `CLEANUP_DUE` | Run `/orchestrate-orchestrator` → spawn `agent-cleanup` |

## Responsibilities

See `.agents/rules/orchestrator-responsibilities.md`.
