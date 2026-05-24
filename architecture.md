here's the full architecture, end to end:

  ┌─────────────────────────────────────────────────────────────────────────────┐
  │                              USER INPUT                                      │
  │  "build TASK-042"  /  "review this PR"  /  "plan the search feature"        │
  └─────────────────────────────────────────────────────────────────────────────┘
                                        │
                                        ▼
  ┌─────────────────────────────────────────────────────────────────────────────┐
  │                           ORCHESTRATOR ROUTER                                │
  │                                                                               │
  │   /orchestrate-plan ──┐                                                      │
  │   /orchestrate-build ─┼──► reads ~/.agents/rules/universal.md                │
  │   /orchestrate-review─┤      reads .project-context.md (project overlay)     │
  │   /orchestrate-test ──┤      reads .project-state.json (session state)       │
  │   /orchestrate-debug ─┤      loads its own SKILL.md                          │
  │   /orchestrate-ship ──┤                                                      │
  │   /orchestrate-release┘                                                      │
  └─────────────────────────────────────────────────────────────────────────────┘
                                        │
                      ┌─────────────────┼─────────────────┐
                      ▼                 ▼                 ▼
             ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
             │  THICK SKILL │  │  THICK SKILL │  │  THICK SKILL │
             │  (process)   │  │  (process)   │  │  (process)   │
             └──────────────┘  └──────────────┘  └──────────────┘


  ═══════════════════════════════════════════════════════════════════════════════
                           EXAMPLE: /orchestrate-build
  ═══════════════════════════════════════════════════════════════════════════════

  ┌─────────────────────────────────────────────────────────────────────────────┐
  │                    ORCHESTRATE-BUILD (303 lines)                             │
  │                                                                               │
  │  CROSS-CUTTING GATES (stays in orchestrator)                                 │
  │  ├── 🚧 Anti-Fabrication Gate (4 rules)                                      │
  │  │      ├── Rule 1: doc claims MUST match code                               │
  │  │      ├── Rule 2: external API claims need citations                       │
  │  │      └── Rule 3: unverified plan claims → stop/scope/ask                  │
  │  ├── Coding Standards Gate (architecture, quality, errors, tests, security)  │
  │  └── Decision Tree (blocked? → tests? → lint? → gate? → commit)              │
  │                                                                               │
  │  PROCESS (what the orchestrator DOES)                                        │
  │  ├── Step 0: Read state (.project-state.json)                                │
  │  ├── Step 1: Read ticket (Notion MCP)                                        │
  │  ├── Step 2: Delegate domain pre-flight gates ◄─── NEW                       │
  │  ├── Step 3: Update state → "build"                                          │
  │  ├── Step 4: Spawn domain agents (parallel)                                  │
  │  ├── Step 5: Collect results (COMPLETE | PARTIAL | BLOCKED)                  │
  │  ├── Step 6: Run automated standards check (tsc, eslint, pytest, ruff)       │
  │  ├── Step 7: Verify acceptance criteria                                      │
  │  ├── Step 8: Commit                                                          │
  │  └── Step 9: Update state → "ready_to_review"                                │
  │                                                                               │
  │  WHAT IT DOES NOT DO ANYMORE:                                                │
  │  ✗ design system contract gate (moved to agent-frontend-dev)                 │
  │  ✗ external-data & queue gate (moved to agent-backend-dev)                   │
  └─────────────────────────────────────────────────────────────────────────────┘
                                        │
                                        ▼
                      ┌─────────────────────────────────────┐
                      │      SPAWN PROTOCOL (injected)      │
                      │                                     │
                      │  1. ~/.agents/rules/universal.md    │
                      │     (rules 1-5, memory protocol,    │
                      │      state protocol, routing)        │
                      │                                     │
                      │  2. ./.project-context.md           │
                      │     (project name, repos, stack,     │
                      │      brand voice, SEO patterns)      │
                      │                                     │
                      │  3. ~/.agents/agents/agent-*.md     │
                      │     (thin persona: identity,         │
                      │      constraints, output format)     │
                      │                                     │
                      │  4. ~/.agents/skills/agent-*/SKILL  │
                      │     (thick domain expertise,         │
                      │      commands, checklists, patterns) │
                      │                                     │
                      │  5. Task Context (ticket, diff, etc)│
                      └─────────────────────────────────────┘
                                        │
                      ┌─────────────────┼─────────────────┐
                      ▼                 ▼                 ▼
             ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
             │  AGENT       │  │  AGENT       │  │  AGENT       │
             │  FRONTEND    │  │  BACKEND     │  │  DATABASE    │
             │  DEVELOPER   │  │  DEVELOPER   │  │  DEVELOPER   │
             └──────────────┘  └──────────────┘  └──────────────┘


  ═══════════════════════════════════════════════════════════════════════════════
                           AGENT: FRONTEND DEVELOPER
  ═══════════════════════════════════════════════════════════════════════════════

  ┌─────────────────────────────────────────────────────────────────────────────┐
  │                    AGENT PERSONA (thin: ~20 lines)                           │
  │  ~/.agents/agents/agent-frontend-dev.md                                      │
  │                                                                               │
  │  "You are a Next.js 15 frontend specialist for $PROJECT_NAME..."             │
  │  Identity → Workflow summary → Constraints → Output format                   │
  │  References: ~/.agents/skills/agent-frontend-dev/SKILL.md                    │
  └─────────────────────────────────────────────────────────────────────────────┘
                                        │
                                        ▼
  ┌─────────────────────────────────────────────────────────────────────────────┐
  │                    AGENT SKILL (thick: 116 lines)                            │
  │  ~/.agents/skills/agent-frontend-dev/SKILL.md                                │
  │                                                                               │
  │  ┌─────────────────────────────────────────────────────────────────────────┐ │
  │  │  PRE-FLIGHT: DESIGN SYSTEM CONTRACT GATE ◄─── MOVED HERE                │ │
  │  │  ├── Verify ticket has: element → class + CSS variable tokens           │ │
  │  │  ├── Every token must exist in tokens.css / globals.css                 │ │
  │  │  ├── No raw hex, no rgba literals, no inline styles                     │ │
  │  │  └── If missing: FE Status: BLOCKED → escalate to orchestrator          │ │
  │  └─────────────────────────────────────────────────────────────────────────┘ │
  │                                                                               │
  │  WORKFLOW                                                                     │
  │  ├── 1. Read globals.css (single source of truth)                           │
  │  ├── 2. Implement with TDD (red → green → refactor)                         │
  │  └── 3. Run standards check (eslint, tsc, prettier, tests)                  │
  │                                                                               │
  │  CONSTRAINTS                                                                  │
  │  ├── Stack: Next.js 15, TypeScript strict, CSS Modules, Tailwind            │
  │  ├── Design: Inter-only, white glass, custom SVGs, NO Lucide/Material       │
  │  ├── Anti-patterns: hardcoded hex, inline styles, `any` types               │
  │  └── Output: FE Status, files, tests, notes                                 │
  └─────────────────────────────────────────────────────────────────────────────┘
                                        │
                                        ▼
                             nose-fe/src/components/*
                             nose-fe/src/app/*
                             nose-fe/src/styles/*


  ═══════════════════════════════════════════════════════════════════════════════
                           AGENT: BACKEND DEVELOPER
  ═══════════════════════════════════════════════════════════════════════════════

  ┌─────────────────────────────────────────────────────────────────────────────┐
  │                    AGENT SKILL (thick: 163 lines)                            │
  │  ~/.agents/skills/agent-backend-dev/SKILL.md                                 │
  │                                                                               │
  │  ┌─────────────────────────────────────────────────────────────────────────┐ │
  │  │  PRE-FLIGHT: EXTERNAL-DATA & QUEUE GATE ◄─── MOVED HERE                │ │
  │  │  ├── Parsing: defusedxml (not stdlib), Pydantic validation             │ │
  │  │  ├── SSRF: validate URLs, no private ranges, httpx follow_redirects=F  │ │
  │  │  ├── Downloads: max_bytes cap, magic-byte sniff, no path traversal     │ │
  │  │  ├── DB writes: enum-validate, length-cap, no raw feed values          │ │
  │  │  ├── Async: all HTTP calls await'd, no blocking httpx.get()            │ │
  │  │  ├── Queue: SKIP LOCKED, backoff, stale-lock reaper, idempotency       │ │
  │  │  ├── Tests: concurrency, retry exhaustion, idempotency                 │ │
  │  │  ├── JSONB: Pydantic model per payload shape                           │ │
  │  │  └── State: no module-level _cache dicts                               │ │
  │  │                                                                           │ │
  │  │  If any unchecked: BE Status: BLOCKED → escalate                       │ │
  │  └─────────────────────────────────────────────────────────────────────────┘ │
  │                                                                               │
  │  WORKFLOW                                                                     │
  │  ├── 1. Read existing API patterns                                          │
  │  ├── 2. Implement with TDD (pytest, async)                                  │
  │  └── 3. Run standards check (pytest, ruff, mypy)                            │
  │                                                                               │
  │  CONSTRAINTS                                                                  │
  │  ├── Stack: FastAPI, Python 3.11+, SQLAlchemy 2.0, Pydantic v2, structlog  │
  │  ├── Patterns: thin routes → thick services, no print(), no raw SQL         │
  │  ├── Anti-patterns: business logic in routes, SELECT-count-UPDATE races     │
  │  └── Output: BE Status, files, tests, API changes, notes                    │
  └─────────────────────────────────────────────────────────────────────────────┘
                                        │
                                        ▼
                             nose-be/backend/app/*


  ═══════════════════════════════════════════════════════════════════════════════
                           REVIEW PHASE: /orchestrate-review
  ═══════════════════════════════════════════════════════════════════════════════

  ┌─────────────────────────────────────────────────────────────────────────────┐
  │                    ORCHESTRATE-REVIEW (243 lines)                            │
  │                                                                               │
  │  CROSS-CUTTING GATE: Fabrication-Detection (last line of defense)            │
  │                                                                               │
  │  PROCESS                                                                      │
  │  ├── Step 0: Read state                                                      │
  │  ├── Step 1: Get diff (multi-repo)                                           │
  │  ├── Step 1.25: Load acceptance criteria (load-bearing, gates verdict)       │
  │  ├── Step 1.5: Run automated static analysis (eslint, tsc, ruff, mypy)      │
  │  ├── Step 1.75: Classify diff → pick reviewer set                            │
  │  │      fe_code → engineering + security + design + adversarial + AC         │
  │  │      be_code → engineering + security + adversarial + AC                  │
  │  │      docs    → adversarial + AC                                           │
  │  ├── Step 2: Spawn selected reviewers (parallel)                             │
  │  ├── Step 3: Synthesize findings (severity-ranked)                           │
  │  ├── Step 4: Gate decision (CRITICAL → NEEDS_FIXES, else APPROVED)           │
  │  └── Step 5: Update state                                                    │
  └─────────────────────────────────────────────────────────────────────────────┘
                                        │
                      ┌─────────────────┼─────────────────┐
                      ▼                 ▼                 ▼
             ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
             │  REVIEWER    │  │  REVIEWER    │  │  REVIEWER    │
             │  ENGINEERING │  │  SECURITY    │  │  DESIGN      │
             │  (41 lines)  │  │  (42 lines)  │  │  (32 lines)  │
             └──────────────┘  └──────────────┘  └──────────────┘
                                        │
                      ┌─────────────────┼─────────────────┐
                      ▼                 ▼                 ▼
             ┌──────────────┐  ┌──────────────┐
             │  REVIEWER    │  │  REVIEWER    │
             │  ADVERSARIAL │  │  ACCEPTANCE  │
             │              │  │  CRITERIA    │
             └──────────────┘  └──────────────┘


  ═══════════════════════════════════════════════════════════════════════════════
                      REVIEWER: SECURITY (expanded: 12 checks)
  ═══════════════════════════════════════════════════════════════════════════════

  ┌─────────────────────────────────────────────────────────────────────────────┐
  │  WHAT THEY CHECK (aligned with agent-backend-dev's gate):                    │
  │                                                                               │
  │  1-7.  Classic: injection, auth, secrets, access control, CORS, deps, input │
  │  8.    SSRF / URL handling ──────┐                                           │
  │  9.    File downloads ───────────┼──► these 5 came from the                  │
  │  10.   Queue / workers ──────────┤    external-data gate                     │
  │  11.   External data persistence─┘    (moved to agent skill)                │
  │  12.   Async safety                                                           │
  │                                                                               │
  │  Output: Security Review Status: PASS | NEEDS FIX                            │
  │          [SEVERITY] Finding — file:line                                       │
  │            Exploit: [how]                                                     │
  │            Fix: [what to change]                                              │
  └─────────────────────────────────────────────────────────────────────────────┘


  ═══════════════════════════════════════════════════════════════════════════════
                      REVIEWER: DESIGN (expanded: 9 checks)
  ═══════════════════════════════════════════════════════════════════════════════

  ┌─────────────────────────────────────────────────────────────────────────────┐
  │  WHAT THEY CHECK (aligned with agent-frontend-dev's gate):                   │
  │                                                                               │
  │  1.    Design System Contract ◄──► "Did the ticket specify tokens?          │
  │                                     Does the diff follow the contract?"      │
  │  2.    Brand tokens                                                         │
  │  3.    Icon imports (no Lucide/Material)                                    │
  │  4.    Brand voice copy                                                     │
  │  5.    CSS modules (no inline styles)                                       │
  │  6.    Glassmorphism (white frosted tier)                                   │
  │  7.    Accessibility (WCAG 2.1 AA)                                          │
  │  8.    Responsive (touch targets ≥ 44px)                                    │
  │  9.    Performance (next/image, lazy loading)                               │
  │                                                                               │
  │  Output: Design/A11y Review Status: PASS | NEEDS FIX                         │
  │          [SEVERITY] Issue — file:line                                         │
  │            Fix: [CSS variable or component to use]                           │
  └─────────────────────────────────────────────────────────────────────────────┘


  ═══════════════════════════════════════════════════════════════════════════════
                           THREE-LAYER MEMORY SYSTEM
  ═══════════════════════════════════════════════════════════════════════════════

  ┌─────────────────────────────────────────────────────────────────────────────┐
  │  LAYER 1: GLOBAL RULES (~/.agents/rules/)                                    │
  │  ├── universal.md ───────────────► rules 1-5, spawn protocol, routing        │
  │  ├── orchestrator-responsibilities.md ──► task distribution, state updates   │
  │  ├── coding-standards.md ────────► language-specific patterns                │
  │  ├── security.md ────────────────► OWASP, auth, secrets handling             │
  │  ├── testing.md ─────────────────► TDD, coverage, CI expectations            │
  │  └── brand-voice.md ─────────────► copy rules, tone constraints              │
  │                                                                               │
  │  LAYER 2: PROJECT MEMORY (~/Documents/GitHub/Trynose/nose/memory/nose/)      │
  │  ├── MEMORY.md ──────────────────► index of all project patterns             │
  │  ├── feedback_*.md ──────────────► production incident learnings             │
  │  └── latest_session_handoff.md ──► per-session context (gitignored)          │
  │                                                                               │
  │  LAYER 3: AGENT MEMORY (~/.agents/agent-memory/)                             │
  │  ├── agent-frontend-dev.md ──────► frontend-specific learnings               │
  │  ├── agent-backend-dev.md ───────► backend-specific learnings                │
  │  └── [23 files total] ───────────► one per active agent                      │
  └─────────────────────────────────────────────────────────────────────────────┘


  ═══════════════════════════════════════════════════════════════════════════════
                           PROJECT STATE LIFECYCLE
  ═══════════════════════════════════════════════════════════════════════════════

      ┌─────────┐     ┌─────────┐     ┌─────────┐     ┌─────────┐     ┌─────────┐
      │  plan   │────►│  build  │────►│ review  │────►│   test  │────►│  ship   │
      └─────────┘     └─────────┘     └─────────┘     └─────────┘     └─────────┘
           │               │               │               │               │
           ▼               ▼               ▼               ▼               ▼
      .project-state.json updated at each phase transition
      - current_phase
      - ticket_id
      - branch
      - review_feedback (critical/high/medium/low)
      - qa_results (score, rating, failures)
      - history[] (audit trail)


  ═══════════════════════════════════════════════════════════════════════════════
                           FILE ARCHITECTURE SUMMARY
  ═══════════════════════════════════════════════════════════════════════════════

  ~/.agents/  (symlink → agent-factory/.agents/)
  ├── agents/
  │   └── agent-*.md          ◄── 23 thin personas (identity, constraints)
  ├── skills/
  │   ├── orchestrate-*/      ◄── 7 thick process skills (build, review, test...)
  │   │   └── SKILL.md
  │   ├── agent-*/            ◄── 21 thick domain skills (frontend, backend, qa...)
  │   │   └── SKILL.md
  │   └── nose-*/             ◄── 10 legacy NOSE-specific skills (deprecated soon)
  │       └── SKILL.md
  ├── rules/
  │   └── *.md                ◄── 7 global rule files (universal, security, testing...)
  ├── agent-memory/
  │   └── agent-*.md          ◄── 23 agent learning files (empty templates)
  └── scripts/
      └── *.sh                ◄── 5 helper scripts

  nose/  (project brain repo)
  ├── AGENTS.md               ◄── canonical entry point for agents
  ├── .project-context.md     ◄── project overlay (injected into every spawn)
  └── .project-state.json     ◄── session state (read/written by orchestrators)

  ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

  key principle: the orchestrator is a traffic cop — it decides who runs when, collects results, and gates progression. the agents are specialists — they know their domain deeply, including what to check
  before they start building. the reviewers are auditors — they verify the specialist actually followed their own rules.