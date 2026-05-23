#!/bin/bash
# Setup script for projects using the agent-factory
# Run this from your project root to create symlinks to the shared agent framework

set -e

PROJECT_ROOT="$(pwd)"
FACTORY_DIR="$(cd "$(dirname "$0")/../.." && pwd)"

echo "Setting up agent-factory symlinks for project: $PROJECT_ROOT"
echo "Factory location: $FACTORY_DIR"

# Create .agents/ directory with symlinks to factory subdirectories
mkdir -p "$PROJECT_ROOT/.agents"
cd "$PROJECT_ROOT/.agents"

# Calculate relative path from project .agents/ to factory .agents/
REL_PATH="$(python3 -c "import os.path; print(os.path.relpath('$FACTORY_DIR/.agents', '$PROJECT_ROOT/.agents'))")"

echo "Relative path: $REL_PATH"

# Symlink shared framework components
ln -sf "$REL_PATH/agents" agents 2>/dev/null || echo "agents symlink already exists"
ln -sf "$REL_PATH/skills" skills 2>/dev/null || echo "skills symlink already exists"
ln -sf "$REL_PATH/rules" rules 2>/dev/null || echo "rules symlink already exists"
ln -sf "$REL_PATH/scripts" scripts 2>/dev/null || echo "scripts symlink already exists"
ln -sf "$REL_PATH/output-styles" output-styles 2>/dev/null || echo "output-styles symlink already exists"
ln -sf "$REL_PATH/archive" archive 2>/dev/null || echo "archive symlink already exists"

# Create local directories (not symlinked)
mkdir -p agent-memory

echo ""
echo "✅ Symlinks created:"
ls -la "$PROJECT_ROOT/.agents/"

echo ""
echo "Next steps:"
echo "1. Create .project-context.md in your project root"
echo "2. Create .project-state.json in your project root"
echo "3. Create .project-config.json in your project root"
echo ""
echo "See agent-factory/README.md for integration guide."
