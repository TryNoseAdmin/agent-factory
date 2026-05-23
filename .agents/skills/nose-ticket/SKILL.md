> ⚠️ **DEPRECATED** — This skill has been superseded by the agent-orchestrator architecture.
> Use `/orchestrate-*` skills instead. This file is kept for backward compatibility and will be removed in a future release.
> See `.agents/skills/orchestrate-*/SKILL.md` for the new thin orchestrators and `.agents/agents/agent-*.md` for domain agents.

---
name: nose-ticket
version: 1.1.0
description: |
  NOSE Notion ticket manager. Create, list, update, and close epics and tickets in the NOSE Sprint Tracker. Use when asked to "create ticket", "create epic", "list tickets", "what's next", "update ticket", "mark done", "sprint board", "ticket status", or "show epics".
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Grep
  - Glob
  - AskUserQuestion
---

# /ticket — NOSE Notion Ticket Manager

You manage epics and tickets in the NOSE Sprint Tracker Notion database.

**Notion Sprint Tracker:** https://www.notion.so/8a82f4d7c75f49699c8984d0074e89fb
**Data Source ID:** `847f3552-71bb-430b-9f52-f6b6938670ab`

## Two-Level Hierarchy

```
Epic (Type=Epic, no branch)
  └── Task (Type=Task, Parent Epic → Epic, has branch + PR)
```

All tasks **MUST** have a parent epic. Never create orphan tasks. If no existing epic fits, create a new epic first, then link the task.

Epics group related tasks under a product initiative.

### Epics

| Epic ID | Name | Priority | Notion Page |
|---------|------|----------|-------------|
| EPIC-001 | Homepage & Discovery UX | P1 | 33572d76-7579-8182-8ddb-c0562fbc9dfe |
| EPIC-002 | Smart Search / AI Core | P0 | 33572d76-7579-81b9-9375-fc7caaddf3e0 |
| EPIC-003 | Data Quality & Enrichment | P1 | 33572d76-7579-8183-bb72-fcded3f100a0 |
| EPIC-004 | Platform Reliability | P2 | 33572d76-7579-8126-bc29-f5d3c946312c |
| EPIC-005 | Monetization | P2 | 33572d76-7579-8161-8aed-ebb4e2558cd2 |
| EPIC-006 | Auth & User Accounts | P2 | 33572d76-7579-8105-a117-d9a65b01c174 |
| EPIC-007 | Buy Smart / Price Comparison | P2 | 33572d76-7579-8157-8903-deb8cf8e8dcf |

---

## Commands

Parse the user's intent and execute the matching operation:

---

### `list` — Show sprint board

Show all tickets grouped by status, with epic context. Format:

```
📋 NOSE Sprint Board
════════════════════

🔴 IN PROGRESS (N)
  • [EPIC-001] TASK-XXX — [Title] [P1]

⬜ NOT STARTED (N) — by priority
  • [EPIC-002] TASK-XXX — [Title] [P0]
  • [EPIC-003] TASK-XXX — [Title] [P1]

✅ COMPLETED (N)
  • TASK-XXX — [Title] — Done [date]
```

---

### `epics` — Show epic overview

Show all 7 epics with status and child task counts:

```
🗺️  NOSE Epics
════════════════════

🟣 EPIC-001 — Homepage & Discovery UX [P1] [In Progress]
   Tasks: TASK-022 ✅  TASK-023 ✅  TASK-024 ⬜  TASK-025 ⬜

🟣 EPIC-002 — Smart Search / AI Core [P0] [Not Started]
   Tasks: TASK-012 ⬜  TASK-019 ⬜
...
```

---

### `next` — Get highest priority ticket

Return the highest priority `Not Started` task (skip Epics):

```
🎯 Next ticket: TASK-XXX
Title: [Title]
Epic: EPIC-XXX — [Epic Name]
Priority: P0 / P1 / P2 / P3
Effort: S / M / L / XL
Status: Not Started

What to Do:
[description]

Ready to start? Type: /ticket start TASK-XXX
```

---

### `create [title]` — Create new task

Create a new task. Gather or infer:
1. **Title** (if not provided)
2. **Parent Epic** — which EPIC-XXX does this belong to? (REQUIRED — never create without one. If no epic fits, create a new epic first.)
3. **Priority** (P0/P1/P2/P3)
4. **Effort** (S=<4h, M=1-2d, L=3-5d, XL=>1w)
5. **Description** (What to Do, How to Do, Success Criteria)
6. **Design Spec** (REQUIRED for any ticket that touches frontend — see below)

**Epic assignment is NON-NEGOTIABLE.** If context makes the epic obvious, assign it automatically. Only ask the user if genuinely ambiguous.

Auto-assign next TASK-XXX or FEAT-XXX number by finding the highest existing number.
Set Type=Task and link Parent Epic.

Task template:
```
Task ID:  TASK-XXX
Type:     Task
Status:   Not Started
Priority: [P0-P3]
Effort:   [S/M/L/XL]
Parent Epic: EPIC-XXX — [Epic Name]
Branch:   feature/task-XXX-short-slug

What to Do:
[description]

How to Do:
[implementation approach]

Design Spec:                          ← REQUIRED for all FE tickets
[See "Frontend Design Spec" section below]

Success Criteria:
- [ ] [criterion]
- [ ] [criterion]
```

## Frontend Design Spec (NON-NEGOTIABLE for FE tickets)

**Every ticket that creates or modifies frontend UI MUST include a Design Spec section.**
This prevents the build agent from guessing colors, typography, spacing, or surfaces.

**Source of truth (in priority order):**
1. `~/Documents/GitHub/TryNose/nose-fe/src/app/globals.css` — **authoritative**; what the app actually uses. The ticket MUST cite tokens/classes that exist here.
2. `~/Documents/GitHub/TryNose/nose/docs/design/Design Tokens.md` — canonical design intent; use to understand which token family applies.
3. `~/Documents/GitHub/TryNose/nose/docs/design/UI Blueprint.md` — component patterns, interaction states.

**Before writing the Design Spec, READ globals.css first.** If the intent requires a token not in globals.css, list it under "New tokens required" — it must be added to globals.css before `/nose-build` runs.

### Required Design Spec Fields

The ticket MUST include a **Design System Contract** table. Every cell references a **token name** or **utility class** from globals.css — never a raw hex, never an `rgba(...)` literal.

```
Design System Contract:

| Element              | Utility Class        | Surface / BG Token     | Text Token              | Font Token              | Control Size           | Notes                  |
|----------------------|----------------------|------------------------|-------------------------|-------------------------|------------------------|------------------------|
| [Card name]          | .glass-card          | --elysian-glass-bg     | --elysian-glass-text    | --font-elysian-display  | —                      | Glass tier 1           |
| [Primary CTA]        | .btn-primary         | --elysian-cta-bg       | —                       | --font-elysian-body     | --control-height-lg    | Pill radius            |
| [Secondary CTA]      | .btn-secondary       | —                      | —                       | --font-elysian-body     | --control-height-md    | Glass pill             |
| [Section heading]    | —                    | —                      | --color-text-primary    | --font-elysian-display  | —                      | —                      |
| [Body copy]          | —                    | —                      | --color-text-secondary  | --font-elysian-body     | —                      | —                      |
| [Note pill]          | .note-pill .note-[x] | --note-[family]        | —                       | --font-elysian-body     | --control-height-sm    | Family from note name  |
| [Icon]               | —                    | —                      | —                       | —                       | —                      | Cloudflare R2 URL only |

Spacing: use --space-N tokens (--space-1 through --space-20)
Radii: use --radius-* tokens (.glass-card = --radius-lg, .btn-primary = --radius-full)
Shadows: use --shadow-* or --shadow-violet-* tokens

New tokens required: [list tokens NOT in globals.css that must be added, or write "none"]

Non-negotiables for this feature:
- Glassmorphism surfaces → .glass / .glass-card or --elysian-glass-* — never solid white, never rgba(255,255,255,0.xx)
- Every button/input → --control-height-* token — no hardcoded heights
- Every icon → Cloudflare R2 URL (`https://images.trynose.in/...`) — no inline <svg>, no Lucide/Heroicons
- Every color in CSS/TSX → var(--token) — no raw hex outside globals.css

States:
- Loading: [copy + which surface/class]
- Empty: [copy + which surface/class]
- Error: [copy + which surface/class]

Mobile:
- Breakpoint behavior at 375px: [what changes]
- Touch targets: min 44×44px (use --control-height-md or --control-height-lg)
```

### When Design Spec Can Be Brief

- **Backend-only tickets**: No design spec needed — note "No UI changes — design spec N/A"
- **Minor copy changes**: List old → new text + which voice rule applies (e.g. "Distilling results..." not "Loading...")
- **Bug fixes with no UI change**: Note "No UI changes — design spec N/A"

### When User Doesn't Provide Design Details

If the user describes a feature without design specifics, the ticket agent MUST:
1. Read `~/Documents/GitHub/TryNose/nose-fe/src/app/globals.css` — identify existing tokens/classes that match the intent
2. Read `~/Documents/GitHub/TryNose/nose/docs/design/Design Tokens.md` and `UI Blueprint.md` — for intent on surfaces/patterns not yet in globals.css
3. Fill the Design System Contract table with token names/classes from globals.css
4. If a needed token doesn't exist, list it under "New tokens required" — do NOT write a raw hex in the contract
5. **Never leave the Design Spec blank, write "TBD", or use raw hex/rgba values**

---

### `create-epic [title]` — Create new epic

Create a new epic entry. Ask for:
1. **Title**
2. **Priority**
3. **What the epic delivers** (high-level goal)
4. **Initial tasks** (if known)

Auto-assign next EPIC-XXX number. Set Type=Epic, no branch.

---

### `link TASK-XXX EPIC-XXX` — Set parent epic

Update the Parent Epic relation on a task to point to the given epic.

---

### `status TASK-XXX` — Show ticket details

Display full ticket details including parent epic, all fields, and comments.

---

### `start TASK-XXX` — Begin work on ticket

1. Update status to `In Progress`
2. Show the git command to create the branch:
   ```bash
   git checkout -b feature/task-XXX-[slug]
   ```
3. Remind: "Run `/nose-build TASK-XXX` to start implementing"

---

### `done TASK-XXX` — Close ticket

1. Ask for a brief implementation summary (2-3 sentences)
2. Update status to `Completed`
3. Add implementation summary as comment
4. Link to merged PR if available
5. Check if all tasks under the parent epic are done — if yes, prompt to close the epic too

---

### `update TASK-XXX [field] [value]` — Update a field

Update priority, effort, status, parent epic, or description.

---

## Priority Guide

| Priority | Meaning | Examples |
|----------|---------|---------|
| **P0** | Critical blocker — production broken | Bug causing data loss, security vulnerability |
| **P1** | This sprint — high value | Core feature, key UX improvement |
| **P2** | Next sprint — important but not urgent | Nice-to-have features, performance improvements |
| **P3** | Backlog — someday/maybe | Experiments, research, low-priority polish |

## Status Lifecycle

```
Not Started → In Progress → Completed
                    ↓
               (blocked by dependency)
```

## Notion Access — Use MCP Connector

**Notion is connected via MCP connector — do NOT use the browse skill to access Notion.**

Use Notion MCP tools (e.g. `mcp__claude_ai_Notion__*`) to read/write directly:
- Query the Sprint Tracker: database ID `8a82f4d7c75f49699c8984d0074e89fb`
- Data source ID: `847f3552-71bb-430b-9f52-f6b6938670ab`
- Parent Epic field is a self-relation — pass as JSON array of page URLs
- When setting Parent Epic: `"Parent Epic": "[\"https://www.notion.so/<epic-page-id>\"]"`

**Never use `/browse https://www.notion.so/...` — it will hit a login wall.**

## NOSE Context

- Notion Sprint Tracker: https://www.notion.so/8a82f4d7c75f49699c8984d0074e89fb
- Database ID: `8a82f4d7c75f49699c8984d0074e89fb`
- Full guide: `docs/TICKET_MANAGEMENT.md`
- Branch naming: `feature/task-XXX-short-slug`
- Never commit directly to `main` — always use feature branches
- Current highest IDs: TASK-041, FEAT-017, EPIC-009 (as of 2026-04-05)
- **Always assign a Parent Epic.** If no existing epic fits, create one first.
