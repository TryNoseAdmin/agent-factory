#!/bin/bash
# Setup script for projects using the agent-factory
# Run this from your project root to create symlinks to the shared agent framework

set -e

PROJECT_ROOT="$(pwd)"
PROJECT_NAME="$(basename "$PROJECT_ROOT")"

# Try to find factory relative to this script
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -f "$SCRIPT_DIR/../../.agents/agents/agent-frontend-dev.md" ]; then
  FACTORY_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
else
  # Factory not found locally — try to clone from GitHub
  PARENT_DIR="$(dirname "$PROJECT_ROOT")"
  FACTORY_DIR="$PARENT_DIR/agent-factory"
  if [ ! -d "$FACTORY_DIR/.git" ]; then
    echo "Factory not found. Cloning from GitHub..."
    git clone git@github.com:TryNoseAdmin/agent-factory.git "$FACTORY_DIR" 2>/dev/null || \
    git clone https://github.com/TryNoseAdmin/agent-factory.git "$FACTORY_DIR"
  fi
fi

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

# Scaffold project files if missing
if [ ! -f "$PROJECT_ROOT/.project-context.md" ]; then
  cat > "$PROJECT_ROOT/.project-context.md" << 'EOF'
# Project Context: $PROJECT_NAME

## Identity
- **Name:** $PROJECT_NAME
- **Description:** [Fill in project description]
- **Domain:** [Fill in domain]

## Repos
| Role | Local Path | Language / Framework |
|------|-----------|---------------------|
| Frontend | `[Fill in]` | [e.g. Next.js, React, Vue] |
| Backend | `[Fill in]` | [e.g. FastAPI, Express, Rails] |

## Tech Stack
- **Frontend:** [Framework, styling, state management]
- **Backend:** [Framework, ORM, API style]
- **Testing:** [Test frameworks]
- **Images/Assets:** [Hosting/CDN]
- **Auth:** [Provider]

## Design System
- **Tokens:** [Path to design tokens]
- **Globals:** [Path to global styles]
- **Font:** [Font family]
- **Icons:** [Icon system]

## Brand Voice
| Moment | Use | Never |
|--------|-----|-------|
| Loading | "..." | "Loading..." |

## Docs
- **Coding Standards:** [Path]
- **Architecture:** [Path]

## State & Config
- **State:** `.project-state.json`
- **Config:** `.project-config.json`
- **Agent Memory:** `.agents/agent-memory/`

## Integrations
- **Project Management:** [Tool, database ID]
- **GitHub:** [Org/owner]

## SEO
- **Target Market:** [Market]
- **URL Patterns:**
  - `[pattern]` — [description]
EOF
  echo "Created: $PROJECT_ROOT/.project-context.md"
fi

if [ ! -f "$PROJECT_ROOT/.project-state.json" ]; then
  cat > "$PROJECT_ROOT/.project-state.json" << EOF
{
  "session_id": "session-$(date +%Y%m%d)-init",
  "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "updated_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "current_phase": "idle",
  "feature_name": null,
  "ticket_id": null,
  "branch": "main",
  "version": "0.1.0",
  "progress": {
    "tasks": [],
    "completed": [],
    "current_task": null,
    "percent": 0
  },
  "review_feedback": {
    "verdict": null,
    "iteration": 0,
    "acceptance_criteria": [],
    "critical": [],
    "high": [],
    "medium": [],
    "low": []
  },
  "qa_results": {
    "score": 0,
    "rating": "",
    "recommendation": "",
    "iteration": 0,
    "failures": { "critical": [], "high": [], "medium": [], "low": [] }
  },
  "debug_context": {
    "active": false,
    "root_cause": "",
    "confidence": 0,
    "fix_applied": false
  },
  "blockers": [],
  "memory": {
    "past_bugs": [],
    "patterns": [],
    "decisions": []
  },
  "history": [],
  "last_updated": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
  echo "Created: $PROJECT_ROOT/.project-state.json"
fi

if [ ! -f "$PROJECT_ROOT/.project-config.json" ]; then
  cat > "$PROJECT_ROOT/.project-config.json" << 'EOF'
{
  "project_name": "$PROJECT_NAME",
  "cleanup": {
    "last_cleanup": null,
    "next_cleanup": null,
    "interval_days": 7
  },
  "integrations": {
    "notion_connected": false,
    "github_connected": false
  }
}
EOF
  echo "Created: $PROJECT_ROOT/.project-config.json"
fi

echo ""
echo "✅ Setup complete. Symlinks created:"
ls -la "$PROJECT_ROOT/.agents/"

echo ""
echo "Next steps:"
echo "1. Edit .project-context.md with your project's specific values"
echo "2. Review .project-state.json and update version/phase as needed"
echo "3. See agent-factory/README.md for full integration guide"
