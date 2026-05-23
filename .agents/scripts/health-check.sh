#!/bin/bash
# Session health check — run manually or on agent cold start
# Reads project state/config from project root (not from .agents/)
set -e

cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# 1. state validation
python3 << 'PYEOF'
import json, sys
from pathlib import Path
p = Path(".project-state.json")
if not p.exists(): print("STATE: MISSING"); sys.exit(0)
try: s = json.load(p.open())
except: print("STATE: CORRUPT"); sys.exit(0)
missing = [f for f in ["current_phase","version","last_updated"] if f not in s]
print(f"STATE: INCOMPLETE ({','.join(missing)})" if missing else f"STATE: OK | phase={s.get('current_phase')} | version={s.get('version')}")
PYEOF

# 2. git health
echo "BRANCH: $(git branch --show-current)"
git diff --quiet && echo "WT: CLEAN" || echo "WT: DIRTY ($(git status --short | wc -l | xargs) files)"

# 3. cleanup flag
python3 << 'PYEOF'
import json
from datetime import datetime, timezone
from pathlib import Path
p = Path(".project-config.json")
if not p.exists(): print("CONFIG: MISSING"); exit(0)
c = json.load(p.open())
n = c.get("cleanup", {}).get("next_cleanup")
if not n: print("CLEANUP_UNSET"); exit(0)
due = datetime.now(timezone.utc) > datetime.fromisoformat(n)
print("CLEANUP_DUE" if due else "CLEANUP_OK")
PYEOF
