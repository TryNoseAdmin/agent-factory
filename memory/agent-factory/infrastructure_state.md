# Agent-Factory Infrastructure State

**Last updated:** 2026-05-24

## Active Components

| Component | Location | Status |
|-----------|----------|--------|
| Orchestrators | `~/.agents/skills/orchestrate-*` | Active |
| Agent Personas | `~/.agents/agents/agent-*.md` | Active |
| Universal Rules | `~/.agents/rules/universal.md` | Active |
| Scripts | `~/.agents/scripts/` | Active |
| Output Styles | `~/.agents/output-styles/` | Active |

## Known Gaps / TODO

- [ ] `.project-state.json` schema validation script
- [ ] Automated cleanup job for `agent-memory/` bloat
- [ ] CI workflow for skill linting on PR

## Recent Changes

- 2026-05-24: Moved `.agents/` from `nose` → `agent-factory`. Created generalized `AGENTS.md`.
