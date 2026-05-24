# Changelog

All notable changes to the agent-factory infrastructure.

## [1.0.0] — 2026-05-24

### Added
- Generalized `AGENTS.md` — universal infrastructure entry point
- `.mcp.json` — generic MCP server configuration
- `.graphifyignore` — graphify tooling ignore patterns
- `.gitignore` — ignore `.DS_Store`, env files, session handoffs
- `memory/` structure:
  - `memory/agent-factory/` — ops memory + infrastructure state
  - `memory/projects/` — project registry (nose, cureyt, qrgen)
  - `memory/rules/` — universal cross-project rules
- `docs/SKILL_ARCHITECTURE.md` — orchestrator + agent skill architecture spec
- `docs/STATE_SCHEMA.md` — `.project-state.json` schema definition
- `VERSION` — semantic versioning tracking
- `CHANGELOG.md` — this file

### Changed
- Standardized loose skill files into proper folders:
  - `debug-issue.md` → `debug-issue/SKILL.md`
  - `explore-codebase.md` → `explore-codebase/SKILL.md`
  - `refactor-safely.md` → `refactor-safely/SKILL.md`
  - `review-changes.md` → `review-changes/SKILL.md`

### Removed
- `.agents/.DS_Store` and `.agents/skills/.DS_Store` from tracking
