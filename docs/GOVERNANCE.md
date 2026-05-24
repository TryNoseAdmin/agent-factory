# Agent-Factory Governance & Doc Ownership

**Version:** 1.0
**Date:** 2026-05-24

This document maps every file in the agent-factory + project brain repos to the agent that owns it, the trigger that updates it, and the gate that validates the change.

---

## Ownership Model

| Symbol | Meaning |
|--------|---------|
| **W** | Writes (creates/updates) |
| **R** | Reads (uses as input) |
| **V** | Validates (reviews for correctness/compliance) |
| **A** | Audits (periodic health checks) |

---

## Agent-Factory Files (Infrastructure)

| File | Owner | Trigger | Gate |
|------|-------|---------|------|
| `AGENTS.md` | `agent-rule-keeper` (V) | Any agent proposes a Rule Update Request | `agent-rule-keeper` validates no conflicts/dupes before merge |
| `docs/SKILL_ARCHITECTURE.md` | `agent-analyst-architecture` (W) | New skill added, skill deprecated, spawn protocol changes | PR review by `agent-reviewer-engineering` |
| `docs/STATE_SCHEMA.md` | `agent-analyst-architecture` (W) | Schema field added/removed, validation rules change | PR review by `agent-reviewer-engineering` |
| `docs/GOVERNANCE.md` | `agent-rule-keeper` (W) | Ownership changes, new file types introduced | PR review by `agent-reviewer-engineering` |
| `VERSION` | `orchestrate-ship` (W) | Every PR merge to main | Auto-bump; human confirms major/minor |
| `CHANGELOG.md` | `orchestrate-release` (W) | Every PR merge to main | None (append-only) |
| `memory/agent-factory/` | `agent-cleanup` (A), orchestrators (W) | End of session, weekly cleanup schedule | `agent-cleanup` spots stale entries |
| `memory/projects/` | `agent-project-analyst` (W) | New project onboarded, project archived | `agent-rule-keeper` validates schema |
| `memory/rules/` | Any agent (W via Rule Update Request) | Production incident, retro finding | `agent-rule-keeper` validates |
| `.agents/skills/` | Human + `agent-rule-keeper` (V) | New skill, skill update, deprecation | PR review |
| `.agents/agents/` | Human + agents (self-update) | Agent memory growth, persona drift | `agent-cleanup` audits |
| `.agents/rules/` | Human + `agent-rule-keeper` (V) | Universal rule changes | PR review |
| `.agents/scripts/` | Human + `agent-backend-dev` (W) | New automation, script bug | PR review |

---

## Project Brain Repo Files (Per-Project)

| File | Owner | Trigger | Gate |
|------|-------|---------|------|
| `PROJECT.md` | `agent-brand-auditor` (W brand voice), `agent-seo-specialist` (W SEO), `agent-ui-designer` (W design tokens), `agent-project-analyst` (W epics) | Brand pivot, SEO strategy change, design system update, epic completed/added | `agent-reviewer-design` validates brand consistency |
| `.project-context.md` | `agent-analyst-architecture` (W stack), `agent-backend-dev` / `agent-frontend-dev` (W test commands) | New dependency, repo split, testing tool change | `agent-reviewer-engineering` validates |
| `.project-state.json` | Orchestrators (W), agents suggest via State Update Request | Every skill completion | Auto-validation on read (schema check) |
| `.project-config.json` | Orchestrators (W) | New integration, cleanup schedule change | None (orchestrator-only) |
| `CHANGELOG.md` | `orchestrate-release` (W) | Every PR merge to main | None (append-only) |
| `VERSION` | `orchestrate-ship` (W) | Every PR merge to main | Auto-bump; human confirms major/minor |
| `memory/MEMORY.md` | All agents (W their own memory) | Every agent execution | `agent-cleanup` audits for stale entries |
| `docs/PROJECT_BRIEFING.md` | `agent-analyst-strategy` (W) | Pivot, new target market, scope change | `agent-analyst-strategy` self-validates against market data |
| `docs/TECH_STACK.md` | `agent-analyst-architecture` (W) | Infrastructure change, new service, deprecation | `agent-reviewer-engineering` validates |
| `docs/REPOS.md` | `agent-analyst-architecture` (W) | New repo, repo archived, routing change | `agent-reviewer-engineering` validates |

---

## Update Triggers Explained

### Rule Update Request (RUR)

Any agent can propose a rule change during work:

```
Agent discovers issue/pattern during work
  → flags Rule Update Request in output:
      "RUR: Add 'never use inline SVG' to universal rules.
       Rationale: 8 instances found across 3 PRs."
  → Orchestrator collects RURs
  → agent-rule-keeper validates (no conflicts, no dupes, no contradictions)
  → applies to memory/rules/ or .agents/rules/
  → next spawned agent inherits improved rules
```

**RURs are batched** — not applied immediately. The orchestrator collects them across a session and applies them in a single `agent-rule-keeper` pass before session end.

### State Update Request (SUR)

Any agent can propose a state change:

```
Agent completes task
  → flags State Update Request in output:
      "SUR: Mark TASK-001 build_completion_pct = 100"
  → Orchestrator validates (phase consistency, no regression)
  → applies to .project-state.json
  → commits with conventional commit message
```

**SURs are applied immediately** — state must stay current for the next skill to read.

### Memory Write

Every agent reads and writes its own memory file on spawn/exit:

```
Agent spawn:
  → reads ~/.agents/agent-memory/agent-<name>.md
  → loads past patterns, known issues, user preferences

Agent exit:
  → appends new findings to ~/.agents/agent-memory/agent-<name>.md
  → updates effectiveness scores
```

**Memory writes are agent-autonomous** — no gate. `agent-cleanup` audits quarterly for stale entries.

---

## Session Lifecycle & File Touch Points

```
Session Start
  └── Read: AGENTS.md, memory/agent-factory/MEMORY.md, <project>/.project-context.md
      Read: <project>/.project-state.json, <project>/memory/MEMORY.md

/plan
  └── Read: docs/SKILL_ARCHITECTURE.md, <project>/PROJECT.md (SEO section)
      Write: docs/plans/TASK-XXX-plan.md
      SUR: Update .project-state.json → phase = "plan"

/build
  └── Read: docs/SKILL_ARCHITECTURE.md, .agents/rules/coding-standards.md
      Read: <project>/.project-context.md (test commands)
      Write: Code in <project>-fe / <project>-be
      SUR: Update .project-state.json → phase = "build"

/review
  └── Read: <project>/PROJECT.md (brand voice, design tokens)
      Write: Review report (stdout)
      SUR: Update .project-state.json → review_feedback appended

/ship
  └── Read: <project>/.project-state.json (verify review passed)
      Write: VERSION bumped, CHANGELOG.md appended
      SUR: Update .project-state.json → phase = "ship"

/release
  └── Read: <project>/.project-state.json, CHANGELOG.md
      Write: CHANGELOG.md polished, docs cross-references updated
      Write: Git tag
      SUR: Update .project-state.json → phase = "release", ticket closed

Session End
  └── Write: memory/*/latest_session_handoff.md (auto via /handoff)
      Write: ~/.agents/agent-memory/agent-<name>.md (per-agent memory)
      RUR batch: agent-rule-keeper processes collected rule updates
```

---

## Cross-Cutting Concerns

### What if two agents conflict?

`agent-rule-keeper` resolves conflicts in this priority order:
1. **Universal rules** (`memory/rules/`) > Project rules
2. **Recent feedback** > Older feedback (last 30 days weighted higher)
3. **Human override** > Any agent proposal

### What if a file goes stale?

`agent-cleanup` runs on the cleanup schedule (default: weekly). It checks:
- `memory/*/latest_session_handoff.md` — older than 7 days? Archive.
- `~/.agents/agent-memory/*.md` — entries unreferenced in 30 days? Flag for review.
- `.project-state.json` — orphaned blockers older than 14 days? Escalate.
- `docs/` — cross-references broken? Update or archive.

### What if a new file type is introduced?

1. Add it to `docs/GOVERNANCE.md` (this file)
2. Update `agent-factory/AGENTS.md` §New Project Bootstrap
3. Update `memory/agent-factory/infrastructure_state.md` known gaps
4. Assign an owner agent via RUR

---

## Quick Reference: "Who Owns What?"

| Question | Answer |
|----------|--------|
| "Brand voice is wrong on the homepage" | `agent-brand-auditor` → updates `<project>/PROJECT.md` |
| "New epic needs to be tracked" | `agent-project-analyst` → updates `<project>/PROJECT.md` epics |
| "We switched from Redis to Postgres" | `agent-analyst-architecture` → updates `<project>/docs/TECH_STACK.md` + `.project-context.md` |
| "Review found hardcoded colors" | `agent-reviewer-design` → flags RUR for `memory/rules/` if pattern repeats |
| "Agent keeps making the same mistake" | `agent-cleanup` → audits agent memory, proposes RUR for rule update |
| "New project onboarding" | `agent-project-analyst` → scaffolds files per AGENTS.md §New Project Bootstrap |
| "Skill spawn protocol changed" | `agent-analyst-architecture` → updates `docs/SKILL_ARCHITECTURE.md` |
| "State schema needs a new field" | `agent-analyst-architecture` → updates `docs/STATE_SCHEMA.md` + `.project-state.json` validation |
