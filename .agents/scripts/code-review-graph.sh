#!/bin/bash
# code-review-graph.sh — Shell wrapper for .code-review-graph/graph.db
# Usage: code-review-graph.sh <command> [arg]
# No MCP required. Works via python3 sqlite3.

DB=".code-review-graph/graph.db"

if [ ! -f "$DB" ]; then
  echo "ERROR: $DB not found. Run 'code-review-graph build' first."
  exit 1
fi

if ! python3 -c "import sqlite3" 2>/dev/null; then
  echo "ERROR: python3 with sqlite3 not found."
  exit 1
fi

CMD="${1:-help}"

pyquery() {
  python3 -c "
import sqlite3, sys
conn = sqlite3.connect('$DB')
conn.row_factory = sqlite3.Row
cur = conn.cursor()
try:
    cur.execute('''$1''')
    rows = cur.fetchall()
    if not rows:
        print('(no results)')
        sys.exit(0)
    cols = [d[0] for d in cur.description]
    print(' | '.join(cols))
    print('-' * 60)
    for row in rows:
        vals = [str(row[c])[:40] for c in cols]
        print(' | '.join(vals))
except Exception as e:
    print(f'Error: {e}', file=sys.stderr)
    sys.exit(1)
"
}

case "$CMD" in
  search)
    TERM="${2:-}"
    if [ -z "$TERM" ]; then echo "Usage: search <term>"; exit 1; fi
    pyquery "SELECT kind, name, qualified_name, file_path, line_start FROM nodes WHERE rowid IN (SELECT rowid FROM nodes_fts WHERE nodes_fts MATCH '${TERM//\'/\'\'}') ORDER BY kind, name LIMIT 20;"
    ;;

  callers)
    NAME="${2:-}"
    if [ -z "$NAME" ]; then echo "Usage: callers <name>"; exit 1; fi
    pyquery "SELECT DISTINCT n.kind, n.name, n.file_path, n.line_start, e.kind as edge FROM edges e JOIN nodes n ON e.source_qualified = n.qualified_name WHERE e.target_qualified LIKE '%${NAME//\'/\'\'}%' ORDER BY n.file_path, n.line_start LIMIT 20;"
    ;;

  callees)
    NAME="${2:-}"
    if [ -z "$NAME" ]; then echo "Usage: callees <name>"; exit 1; fi
    pyquery "SELECT DISTINCT n.kind, n.name, n.file_path, n.line_start, e.kind as edge FROM edges e JOIN nodes n ON e.target_qualified = n.qualified_name WHERE e.source_qualified LIKE '%${NAME//\'/\'\'}%' ORDER BY n.file_path, n.line_start LIMIT 20;"
    ;;

  impact)
    NAME="${2:-}"
    if [ -z "$NAME" ]; then echo "Usage: impact <name>"; exit 1; fi
    echo "=== CALLERS ==="
    pyquery "SELECT DISTINCT n.kind, n.name, n.file_path FROM edges e JOIN nodes n ON e.source_qualified = n.qualified_name WHERE e.target_qualified LIKE '%${NAME//\'/\'\'}%' LIMIT 15;"
    echo ""
    echo "=== CALLEES ==="
    pyquery "SELECT DISTINCT n.kind, n.name, n.file_path FROM edges e JOIN nodes n ON e.target_qualified = n.qualified_name WHERE e.source_qualified LIKE '%${NAME//\'/\'\'}%' LIMIT 15;"
    ;;

  tests)
    NAME="${2:-}"
    if [ -z "$NAME" ]; then echo "Usage: tests <name>"; exit 1; fi
    pyquery "SELECT name, file_path, line_start FROM nodes WHERE is_test = 1 AND (name LIKE '%${NAME//\'/\'\'}%' OR qualified_name LIKE '%test%${NAME//\'/\'\'}%') ORDER BY file_path LIMIT 15;"
    ;;

  file)
    PATH_ARG="${2:-}"
    if [ -z "$PATH_ARG" ]; then echo "Usage: file <path>"; exit 1; fi
    pyquery "SELECT kind, name, line_start, line_end, signature FROM nodes WHERE file_path LIKE '%${PATH_ARG//\'/\'\'}%' ORDER BY line_start LIMIT 30;"
    ;;

  stats)
    echo "=== NODES ==="
    pyquery "SELECT kind, COUNT(*) as count FROM nodes GROUP BY kind ORDER BY count DESC;"
    echo ""
    echo "=== EDGES ==="
    pyquery "SELECT kind, COUNT(*) as count FROM edges GROUP BY kind ORDER BY count DESC;"
    echo ""
    echo "=== TOP FILES BY NODE COUNT ==="
    pyquery "SELECT file_path, COUNT(*) as nodes FROM nodes GROUP BY file_path ORDER BY nodes DESC LIMIT 10;"
    ;;

  help|*)
    cat << 'EOF'
code-review-graph.sh — Shell wrapper for code-review-graph SQLite db

Commands:
  search <term>       Full-text search for nodes
  callers <name>      Who calls this function/class
  callees <name>      What this function/class calls
  impact <name>       Full impact radius (callers + callees)
  tests <name>        Find tests for a function/class
  file <path>         List nodes in a file
  stats               Graph statistics

Examples:
  code-review-graph.sh search "handle_login"
  code-review-graph.sh callers "run_pipeline"
  code-review-graph.sh impact "backend.app.auth"
  code-review-graph.sh file "routes.py"
EOF
    ;;
esac
