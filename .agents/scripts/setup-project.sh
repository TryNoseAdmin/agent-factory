#!/bin/bash
# Global setup for agent-factory
# Run once to create ~/.agents symlink pointing to the factory

set -e

FACTORY_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
TARGET="$HOME/.agents"

echo "Factory location: $FACTORY_DIR"

if [ -L "$TARGET" ]; then
  CURRENT="$(readlink "$TARGET")"
  if [ "$CURRENT" = "$FACTORY_DIR/.agents" ]; then
    echo "✅ ~/.agents already points to factory. Nothing to do."
    exit 0
  else
    echo "⚠️  ~/.agents exists but points elsewhere: $CURRENT"
    echo "   Replacing with factory path..."
    rm -f "$TARGET"
  fi
elif [ -e "$TARGET" ]; then
  echo "❌ ~/.agents exists but is not a symlink. Remove it manually first."
  exit 1
fi

ln -sf "$FACTORY_DIR/.agents" "$TARGET"
echo "✅ Created ~/.agents → $FACTORY_DIR/.agents"

echo ""
echo "Global agent framework is now available."
echo "All projects reference ~/.agents/ for agents, skills, rules, scripts."
