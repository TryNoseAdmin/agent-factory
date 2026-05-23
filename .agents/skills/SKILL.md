---
name: nose-ticket
version: 1.0.0
description: |
  NOSE Notion ticket manager. Create, list, update, and close tickets in the NOSE Sprint Tracker. Use when asked to "create ticket", "list tickets", "what's next", "update ticket", "mark done", "sprint board", or "ticket status".
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

You manage tickets in the NOSE Sprint Tracker Notion database.

**Notion Sprint Tracker:** https://www.notion.so/8a82f4d7c75f49699c8984d0074e89fb

## Commands

Parse the user's intent and execute the matching operation:

---

### `list` — Show sprint board

Show all tickets grouped by status. Format:

```
📋 NOSE Sprint Board
════════════════════

🔴 IN PROGRESS (N)
  • TASK-XXX — [Title] [P0]
  • TASK-XXX — [Title] [P1]

⬜ NOT STARTED (N) — by priority
  • TASK-XXX — [Title] [P0] [S]
  • TASK-XXX — [Title] [P1] [M]

✅ COMPLETED (N)
  • TASK-XXX — [Title] — Done [date]
```

---

### `next` — Get highest priority ticket

Return the highest priority `Not Started` ticket:

```
🎯 Next ticket: TASK-XXX
Title: [Title]
Priority: P0 / P1 / P2 / P3
Effort: S / M / L / XL
Status: Not Started

What to Do:
[description]

Ready to start? Type: /build TASK-XXX
```

---

### `create [title]` — Create new ticket

Create a new ticket with template. Ask the user for:
1. **Title** (if not provided)
2. **Priority** (P0/P1/P2/P3) — P0=critical blocker, P1=this sprint, P2=next sprint, P3=backlog
3. **Effort** (S=<4h, M=1-2d, L=3-5d, XL=>1w)
4. **Description** (What to Do, How to Do, Success Criteria)

Auto-assign next TASK-XXX number by finding the highest existing TASK number.

Ticket template:
```
Title: [title]
Status: Not Started
Priority: [P0-P3]
Effort: [S/M/L/XL]
Branch: feature/task-[number]-[slug]

What to Do:
[description]

How to Do:
[implementation approach]

Success Criteria:
- [ ] [criterion]
- [ ] [criterion]

Links:
- Notion: https://www.notion.so/[page-id]
```

---

### `status TASK-XXX` — Show ticket details

Display full ticket details including all fields, comments, and linked PR/branch.

---

### `start TASK-XXX` — Begin work on ticket

1. Update status to `In Progress`
2. Show the git command to create the branch:
   ```bash
   git checkout -b feature/task-XXX-[slug]
   ```
3. Remind: "Run `/build TASK-XXX` to start implementing"

---

### `done TASK-XXX` — Close ticket

1. Ask for a brief implementation summary (2-3 sentences)
2. Update status to `Completed`
3. Add implementation summary as comment
4. Link to merged PR if available

---

### `update TASK-XXX [field] [value]` — Update a field

Update priority, effort, status, or description.

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

Use Notion MCP tools (e.g. `mcp__notion__*`) to read/write tickets directly:
- Query the Sprint Tracker database by database ID: `8a82f4d7c75f49699c8984d0074e89fb`
- Use MCP tools to create pages, update properties, and add comments
- If Notion MCP tools are not available in the current session, ask the user to check the connector

**Never use `/browse https://www.notion.so/...` — it will hit a login wall.**

## NOSE Context

- Notion Sprint Tracker: https://www.notion.so/8a82f4d7c75f49699c8984d0074e89fb
- Database ID: `8a82f4d7c75f49699c8984d0074e89fb`
- See: `docs/TICKET_MANAGEMENT.md` for full ticket management guide
- Branch naming: `feature/task-[number]-[short-slug]`
- Never commit directly to `main` — always use feature branches
