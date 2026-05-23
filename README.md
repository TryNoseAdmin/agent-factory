# Agent Factory

Reusable agent infrastructure for any software project. Symlink into your repo, provide a `.project-context.md`, and get the full agent orchestration system.

## Quick Start

```bash
# From your project root
bash /path/to/agent-factory/.agents/scripts/setup-project.sh
```

This creates symlinks:
```
your-project/
├── .agents/
│   ├── agents -> ../../agent-factory/.agents/agents
│   ├── skills -> ../../agent-factory/.agents/skills
│   ├── rules -> ../../agent-factory/.agents/rules
│   ├── scripts -> ../../agent-factory/.agents/scripts
│   ├── output-styles -> ../../agent-factory/.agents/output-styles
│   ├── archive -> ../../agent-factory/.agents/archive
│   └── agent-memory/          ← local, not symlinked
```

## Project Context

Create `.project-context.md` in your project root. This is injected into every agent spawn.

```markdown
# Project Context: YOUR_PROJECT

## Identity
- **Name:** YourProject
- **Description:** What your project does

## Repos
| Role | Local Path | Language / Framework |
|------|-----------|---------------------|
| Frontend | `~/path/to/frontend/` | Next.js, React, TypeScript |
| Backend | `~/path/to/backend/` | FastAPI, Python |

## Design System
- **Tokens:** `frontend/src/styles/tokens.css`
- **Font:** Inter only

## State & Config
- **State:** `.project-state.json`
- **Config:** `.project-config.json`
```

## State & Config

Move your project state out of `.agents/`:

```bash
# From .agents/project-data/state/your-project/state.json
# To: .project-state.json

# From .agents/project-data/state/your-project/config.json
# To: .project-config.json
```

## What's Included

| Component | Description |
|-----------|-------------|
| **agents/** | 26 generic agent templates (dev, QA, review, domain, meta) |
| **skills/** | 7 orchestrators (plan, build, test, review, ship, release, debug) |
| **rules/** | Universal rules, spawn protocol, agent footer |
| **scripts/** | Health check, graph hooks, pre-commit installer |
| **output-styles/** | Report templates (standup, review, QA, design) |

## Architecture

```
Project Repo                    Agent Factory (shared)
├── .agents/    ────────────>   ├── agents/
│   ├── agents (symlink)        ├── skills/
│   ├── skills (symlink)        ├── rules/
│   ├── rules (symlink)         ├── scripts/
│   ├── scripts (symlink)       └── output-styles/
│   └── agent-memory/ (local)
├── .project-context.md
├── .project-state.json
└── .project-config.json
```

## Spawn Protocol

Every agent receives:
```
1. .agents/rules/universal.md        (generic rules)
2. .project-context.md                (project-specific context)
3. .agents/agents/agent-<name>.md     (agent template)
4. Task context                       (specific instructions)
```

## Customizing Agents

To override a factory agent with a project-specific version:

```bash
# Create local override
mkdir -p .agents-local/agents
cp .agents/agents/agent-frontend-dev.md .agents-local/agents/
# Edit the local copy
```

The orchestrator searches `.agents-local/` before `.agents/` for agent files.
