#!/bin/bash
# Install pre-commit hook for .agents/ validation.
# Warns on issues but NEVER blocks commits.

HOOK=".git/hooks/pre-commit"

cat > "$HOOK" << 'HOOK_EOF'
#!/bin/sh
# .agents/ validation — WARN ONLY, never block commits
# Installed by: .agents/scripts/install-precommit-hook.sh

WARN=0

# Check 1: empty agent memory files
EMPTY=$(find .agents/agent-memory -name "*.md" -size 0 2>/dev/null)
if [ -n "$EMPTY" ]; then
  echo ""
  echo "⚠️  EMPTY AGENT MEMORY FILES:"
  echo "$EMPTY" | sed 's/^/   /'
  WARN=$((WARN + 1))
fi

# Check 2: line count violations (orchestrators + agents only)
for f in .agents/skills/orchestrate-*/SKILL.md .agents/agents/agent-*.md; do
  [ -f "$f" ] || continue
  lines=$(wc -l < "$f")
  if [ "$lines" -gt 150 ]; then
    echo ""
    echo "⚠️  LINE COUNT OVER 150: $f ($lines lines)"
    WARN=$((WARN + 1))
  fi
done

# Check 3: broken references to archived orchestrators
ARCHIVED="orchestrate-brainstorm orchestrate-brand-voice orchestrate-content orchestrate-design orchestrate-process orchestrate-qa orchestrate-seo orchestrate-ticket orchestrate-setup orchestrate-orchestrator"
for ref in $ARCHIVED; do
  if grep -rq "$ref" .agents/rules/ .agents/agents/ .agents/skills/orchestrate-*/ 2>/dev/null; then
    echo ""
    echo "⚠️  ARCHIVED REFERENCE FOUND: $ref"
    grep -rn "$ref" .agents/rules/ .agents/agents/ .agents/skills/orchestrate-*/ 2>/dev/null | head -3 | sed 's/^/   /'
    WARN=$((WARN + 1))
  fi
done

# Check 4: health check (state, git sanity, cleanup)
if [ -f ".agents/scripts/health-check.sh" ]; then
  HEALTH=$(bash .agents/scripts/health-check.sh 2>/dev/null)
  if echo "$HEALTH" | grep -q "STATE: MISSING\|STATE: CORRUPT\|STATE: INCOMPLETE"; then
    echo ""
    echo "⚠️  STATE ISSUE:"
    echo "$HEALTH" | grep "STATE:" | sed 's/^/   /'
    WARN=$((WARN + 1))
  fi
  if echo "$HEALTH" | grep -q "CLEANUP_DUE"; then
    echo ""
    echo "⚠️  CLEANUP IS DUE — run agent-cleanup"
    WARN=$((WARN + 1))
  fi
fi

if [ "$WARN" -gt 0 ]; then
  echo ""
  echo "Found $WARN warning(s) in .agents/. Review before pushing."
  echo ""
fi

# NEVER block the commit
exit 0
HOOK_EOF

chmod +x "$HOOK"
echo "Pre-commit hook installed at $HOOK"
echo "It warns on .agents/ issues but NEVER blocks commits."
