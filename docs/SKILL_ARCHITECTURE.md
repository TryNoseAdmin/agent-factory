# Agent-Factory Skill Architecture

**Version:** 1.0
**Date:** 2026-05-24
**Status:** Active

---

## Philosophy

8 **core** user-facing skills handle the plan → build → ship → release → QA lifecycle. 10 **specialized** skills extend that lifecycle with brand voice, SEO, content, research, ideation, and orchestration. Everything else is internal to those 18.

```
Idea → /plan → /ticket → /build → /review → /ship → /release
                              │
                          /design  /qa
```

Each skill is an **orchestrator** that spawns specialist sub-agents in parallel, synthesizes results, and returns a unified output. The user only needs to remember 8 commands.

---

## The 8 Skills

### 1. `/plan` — Think through it

**Trigger keywords:** "plan", "new feature", "I want to build", "let's think about", "idea"

**Pattern:** 4 parallel analysts → synthesized plan document

```
/plan "add user dashboard feature"
   │
   ├─► Strategy Analyst (parallel)          ← market fit, user value, feasibility
   ├─► Architect (parallel)                 ← architecture, api-design, data model
   ├─► Design Strategist (parallel)         ← UX research, design direction
   └─► SEO Analyst (parallel)              ← URL slugs, keywords, schema, sitemap

   SYNTHESIZE → docs/plans/TASK-XXX.md (includes SEO Plan section)
   AUTO-CREATE → tickets via /ticket
```

**Output:** Single plan doc with: problem statement, user story, architecture decisions, UI direction, implementation phases, acceptance criteria.

---

### 2. `/ticket` — Manage work items

**Trigger keywords:** "create ticket", "create epic", "what's next", "update ticket", "sprint board", "ticket status", "epics"

**Pattern:** Direct skill (no sub-agents) — thin wrapper over ticket system MCP

```
/ticket list                    → sprint board: epics + tasks grouped by status
/ticket epics                   → show all epics with child task counts
/ticket next                    → highest priority Not Started task
/ticket create [title]          → new task with template (prompts for parent epic)
/ticket create-epic [title]     → new epic entry
/ticket link TASK-XXX EPIC-XXX  → set parent epic on a task
/ticket done TASK-XXX           → mark completed + add implementation summary
/ticket status TASK-XXX         → show details including parent epic
/ticket start TASK-XXX          → mark In Progress, output branch name
```

**Two-level hierarchy:** Every task lives under a parent Epic. Epics = product initiatives. Tasks = concrete units of work with branches and PRs.

**Operations:** CRUD on epics + tasks, priority sorting, status transitions, epic→task linking, branch/PR linking.

---

### 3. `/build` — Code it

**Trigger keywords:** "build", "implement", "start coding", "develop TASK-XXX", "code this"

**Pattern:** Reads ticket → Standards Gate → routes to domain specialists → TDD → linter check

```
/build TASK-XXX
   │
   ├── Read ticket + docs/CODING_STANDARDS.md
   │
   ├── STANDARDS GATE (before writing any code)
   │   Checks: architecture separation, SOLID, DRY, KISS, error handling,
   │           logging, testing, security, docs, YAGNI
   │
   ├── Multi-repo routing:
   │   Frontend scope? → <project>-fe
   │   Backend scope?  → <project>-be
   │   State/docs?     → <project>
   │
   ├── Frontend Dev Agent (in <project>-fe)
   │   References: react-patterns, nextjs-app-router-patterns,
   │               typescript-expert, tailwind-patterns,
   │               frontend-dev-guidelines, frontend-security-coder
   │
   ├── Backend Dev Agent (in <project>-be)
   │   References: fastapi-pro, python-pro, api-design-principles,
   │               backend-dev-guidelines, error-handling-patterns,
   │               backend-security-coder
   │
   ├── Database Dev Agent (in <project>-be/database)
   │   References: postgresql, database-migrations
   │
   ├── Tests: Written INLINE with each agent (TDD — not a separate pass)
   │   References: test-driven-development, verification-before-completion
   │
   └── AUTOMATED LINTER STEP (before completion, zero tolerance)
       <project>-fe: eslint --max-warnings 0, tsc --noEmit, prettier --check
       <project>-be: ruff check, ruff format --check, mypy
```

**Output:** Committed code on feature branch, tests passing, linters clean, ready for `/review`.

---

### 4. `/design` — Design it

**Trigger keywords:** "design", "mockup", "UI for", "redesign", "component for", "what should it look like"

**Pattern:** Sequential (each step feeds the next)

```
/design "user dashboard page"
   │
   ├─► UX Researcher (first)        ← competitor analysis, user flows
   │   Output: Research brief
   │
   ├─► UI Designer (after research) ← design system tokens, brand guidelines
   │   Plugins: figma MCP, Stitch MCP
   │   Output: Visual design
   │
   └─► Design Auditor (after design) ← token compliance + brand alignment
       Output: Brand alignment report
```

**Key constraints:** Each project defines its own design system in `.project-context.md` and `AGENTS.md`.

---

### 5. `/review` — Check it before merge

**Trigger keywords:** "review", "check this", "ready for review", "PR review", "pre-merge"

**Pattern:** Static analysis pre-gate → 6 specialists in parallel → unified severity-ranked report

```
/review
   │
   ├── STATIC ANALYSIS PRE-GATE (auto-CRITICAL if violations found)
   │   <project>-fe: eslint --max-warnings 0, tsc --noEmit
   │   <project>-be: ruff check, mypy
   │   Multi-repo: collects diffs from all project repos
   │
   ├─► Reviewer 1: Engineering (parallel)
   │   Checks: architecture, code quality, performance, test coverage, DRY
   │   Output: [CRITICAL/HIGH/MEDIUM/LOW] findings
   │
   ├─► Reviewer 2: Security (parallel)
   │   Checks: OWASP Top 10, SQL injection, auth bypass, secrets, input validation
   │   Output: [CRITICAL/HIGH/MEDIUM/LOW] findings
   │
   ├─► Reviewer 3: Design & Accessibility (parallel)
   │   Checks: brand tokens, icon imports, brand voice, a11y, responsive, WCAG 2.1 AA
   │   Output: [CRITICAL/HIGH/MEDIUM/LOW] findings
   │
   ├─► Reviewer 4: Design Consistency (parallel)
   │   Checks: interaction states, cognitive load, UX patterns, data viz
   │   Output: [CRITICAL/HIGH/MEDIUM/LOW] findings
   │
   ├─► Reviewer 5: Adversarial (parallel)
   │   Checks: edge cases, race conditions, failure modes, error handling
   │   Output: [FIXABLE/INVESTIGATE] findings
   │
   └─► Reviewer 6: Acceptance Criteria (parallel)
       Checks: ticket ACs met, no scope creep, test coverage for ACs
       Output: [PASS/FAIL] per AC

   SYNTHESIZE → Unified Review Report:
   ┌─────────────────────────────────────────────┐
   │ REVIEW REPORT — feature/TASK-XXX            │
   │ HIGH CONFIDENCE (≥2 reviewers agree):        │
   │  • [CRITICAL] SQL injection in search API    │
   │ ENGINEERING / SECURITY / DESIGN /            │
   │ DESIGN CONSISTENCY / ADVERSARIAL /           │
   │ ACCEPTANCE CRITERIA: ...                     │
   │ VERDICT: N CRITICAL — must fix before merge  │
   └─────────────────────────────────────────────┘
```

---

### 6. `/ship` — Merge and push

**Trigger keywords:** "ship", "create PR", "push", "ready to merge", "land this"

**Pattern:** Sequential safety checks → PR creation

```
/ship
   │
   ├── Merge base branch (no conflicts?)
   ├── Run test suite (all green?)
   ├── Bump VERSION (patch/minor/major)
   ├── Update CHANGELOG.md
   ├── Commit with conventional commit message
   ├── Push to remote
   └── Create PR (with description from plan doc)
       Auto-link to ticket
```

**Note:** Does NOT re-run review (that's `/review`'s job). Ship assumes review already passed.

---

### 7. `/release` — Post-merge housekeeping

**Trigger keywords:** "release", "close ticket", "update docs", "post-merge", "wrap up"

**Pattern:** Sequential cleanup after PR merges to main

```
/release
   │
   ├── Update affected docs (cross-reference diff)
   ├── Close ticket with implementation summary
   ├── Polish CHANGELOG voice
   ├── Cross-doc consistency check
   └── Git tag for version
```

---

### 8. `/qa` — Test the live app

**Trigger keywords:** "qa", "test the app", "check production", "user flows", "test live"

**Pattern:** 4 specialists in parallel → QA health score report

```
/qa [url]
   │
   ├─► Functional QA (parallel)
   │   Tests: user flows, forms, navigation, error states, 404s
   │   Plugin: playwright
   │
   ├─► Visual QA (parallel)
   │   Tests: brand consistency, responsive (mobile/tablet/desktop), dark mode
   │   Plugin: chrome-devtools (screenshots)
   │
   ├─► Performance QA (parallel)
   │   Tests: Core Web Vitals (LCP, CLS, INP), bundle size, API latency
   │   Plugin: chrome-devtools (lighthouse, LCP audit)
   │
   └─► Accessibility QA (parallel)
       Tests: WCAG 2.1 AA, keyboard nav, screen reader compatibility
       Plugin: chrome-devtools (a11y-debugging)

   SYNTHESIZE → QA Report with health score (0-100)
```

---

## Specialized Skills (User-facing, scope-specific)

These skills extend the core lifecycle for specialized work. Invoked on demand, each replaces a longer manual workflow with an agent-driven pass.

| Skill | Purpose |
|-------|---------|
| `/brainstorm` | Pre-design exploration — generates 3–5 distinct directions with pros/cons before any `/design` run. |
| `/brand-voice` | Copy validation against the project's brand voice table. Generates micro-copy for UI moments. |
| `/content` | Marketing content engine — social posts, blog drafts, automation hooks. |
| `/seo` | Keyword research, on-page audit, competitor analysis, technical SEO. |
| `/process` | Workflow analysis, bottleneck detection, documentation audit. |
| `/browse` | Fast headless browser for QA testing and deployment dogfooding. ~100ms per command. |
| `/debug` | Systematic root-cause analysis with 4-phase flow (investigate → analyze → hypothesize → implement). Iron-law: no fix without > 70% root-cause confidence. |
| `/orchestrator` | Autonomous workflow orchestrator — chains plan → build → review → fix → QA → ship → release with state-driven decisions. |
| `/test` | Test-suite maintainer — writes new tests, repairs outdated ones, authors CI workflows. Scoped to source-code tests, not live-app QA. |
| `/graphify` | Builds a knowledge graph from the codebase. Queryable for architecture questions, refactor planning, test-coverage audits. |

---

## Internal Skills (Not User-Facing)

These remain available but are invoked BY the 8 skills above, not directly by the user.

### Agent Skills (Used Internally)
| Skill | Used By |
|-------|---------|
| `plan-strategy` | `/plan` → Strategy Analyst |
| `plan-architecture` | `/plan` → Architect |
| `plan-design` | `/plan` → Design Strategist |
| `investigate` / `debug` | `/review` → Adversarial, `/build` (debugging) |
| `design-consultation` | `/design` → UX Researcher |
| `design-review` | `/review` → Design Reviewer, `/qa` → Visual QA |
| `review` | `/review` → Engineering Reviewer |
| `security-review` | `/review` → Security Reviewer |
| `ship` | `/ship` (core logic) |
| `qa` | `/qa` → Functional QA |
| `benchmark` | `/qa` → Performance QA |
| `react-components` | `/build` → Frontend Dev Agent |
| `shadcn-ui` | `/build` → Frontend Dev Agent |

### Plugins (Always Available)
| Plugin | Used By |
|--------|---------|
| `figma` | `/design`, `/build` (design-to-code) |
| `playwright` | `/qa` → Functional QA |
| `chrome-devtools-mcp` | `/qa` → Visual/Performance/A11y QA, `/review` → Design Reviewer |
| `code-review-graph` | All skills (codebase exploration, impact analysis) |

---

## Skill File Locations

```
~/.agents/skills/
├── orchestrate-plan/     → /plan orchestrator
├── orchestrate-ticket/   → /ticket orchestrator
├── orchestrate-build/    → /build orchestrator
├── orchestrate-design/   → /design orchestrator
├── orchestrate-review/   → /review orchestrator
├── orchestrate-ship/     → /ship orchestrator
├── orchestrate-release/  → /release orchestrator
├── orchestrate-test/     → /test orchestrator
├── orchestrate-debug/    → /debug orchestrator
├── browse/               → /browse utility
├── graphify/             → /graphify utility
├── handoff/              → /handoff utility
├── debug/                → /debug utility
├── design-md/            → /design-md utility
└── ... (agent skills)
```

Each skill directory contains:
- `SKILL.md` — The skill definition (triggers, instructions, sub-agent spawning)

---

## Workflow Cheat Sheet

```
┌──────────────────────────────────────────────────┐
│         AGENT-FACTORY DEVELOPMENT WORKFLOW        │
│                                                  │
│  /plan    — Think through it (4 parallel)        │
│  /ticket  — Create/manage tickets                │
│  /build   — Code it (frontend/backend/database)  │
│  /design  — Design it (research→create→audit)    │
│  /review  — Check it (6 parallel reviewers)      │
│  /ship    — Ship it (tests→version→PR)           │
│  /release — Close it (docs→ticket→tag)           │
│  /qa      — Test live (4 parallel testers)       │
│                                                  │
│  8 commands. Everything else is internal.         │
└──────────────────────────────────────────────────┘
```

---

## Implementation Status

| Skill | Blueprint | Built | Tested |
|-------|-----------|-------|--------|
| `/plan` | ✅ | ✅ | ⬜ |
| `/ticket` | ✅ | ✅ | ⬜ |
| `/build` | ✅ | ✅ | ⬜ |
| `/design` | ✅ | ✅ | ⬜ |
| `/review` | ✅ | ✅ | ⬜ |
| `/ship` | ✅ | ✅ | ⬜ |
| `/release` | ✅ | ✅ | ⬜ |
| `/qa` | ✅ | ✅ | ⬜ |
