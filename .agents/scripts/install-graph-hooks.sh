#!/bin/bash
# Install graphify + code-review-graph git hooks for automatic knowledge graph rebuilds.
# Run this after cloning the repo. Safe to run multiple times.

set -e

cd "$(git rev-parse --show-toplevel 2>/dev/null || echo .)"

# Graphify hooks
echo "[graphify] Installing post-commit and post-checkout hooks..."
if command -v graphify >/dev/null 2>&1; then
    graphify hook install
    echo "[graphify] Hooks installed."
else
    echo "[graphify] WARNING: graphify CLI not found. Skipping."
    echo "  Install: pip install graphify  # or pipx install graphify"
fi

# Code-review-graph hooks (appended to graphify hooks)
echo "[code-review-graph] Appending to post-commit and post-checkout hooks..."
if command -v code-review-graph >/dev/null 2>&1; then
    # post-commit
    cat >> .git/hooks/post-commit << 'CRG_HOOK'

# code-review-graph-hook-start
if command -v code-review-graph >/dev/null 2>&1; then
    echo "[code-review-graph hook] Incremental update..."
    code-review-graph update || echo "[code-review-graph hook] Update failed (non-blocking)"
fi
# code-review-graph-hook-end
CRG_HOOK

    # post-checkout
    cat >> .git/hooks/post-checkout << 'CRG_HOOK'

# code-review-graph-checkout-hook-start
if [ "$BRANCH_SWITCH" = "1" ] && command -v code-review-graph >/dev/null 2>&1; then
    echo "[code-review-graph] Branch switched - updating..."
    code-review-graph update || echo "[code-review-graph] Update failed (non-blocking)"
fi
# code-review-graph-checkout-hook-end
CRG_HOOK

    echo "[code-review-graph] Hooks installed."
else
    echo "[code-review-graph] WARNING: code-review-graph CLI not found. Skipping."
    echo "  Install: pip install code-review-graph  # or pipx install code-review-graph"
fi

echo ""
echo "Auto-rebuild configured for:"
echo "  - graphify: every commit + branch switch"
echo "  - code-review-graph: every commit + branch switch"
echo ""

# Initial builds
if command -v graphify >/dev/null 2>&1; then
    echo "[graphify] Initial build..."
    graphify update . || true
fi

if command -v code-review-graph >/dev/null 2>&1; then
    echo "[code-review-graph] Initial build..."
    code-review-graph build || true
fi

echo ""
echo "Done."
echo "  graphify: graphify-out/GRAPH_REPORT.md"
echo "  code-review-graph: .code-review-graph/graph.db"
