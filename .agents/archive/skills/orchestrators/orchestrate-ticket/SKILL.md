> **DEPRECATED** — Merged into `orchestrate-plan` or `orchestrate-test` or downgraded to utility skill.
>
# /orchestrate-ticket — Ticket Orchestrator

## Purpose
Notion ticket CRUD. Create, list, update, and close tickets in the NOSE Sprint Tracker.

## Execution Flow

### Commands
| Command | Action |
|---------|--------|
| `/orchestrate-ticket create` | Create new ticket with title, description, AC |
| `/orchestrate-ticket list` | List tickets by status |
| `/orchestrate-ticket update [ID]` | Update status, assignee, or description |
| `/orchestrate-ticket close [ID]` | Mark as Completed with summary |

### Step 1: Read Notion State
```bash
cat .agents/project-data/state/nose/state.json | grep -i ticket
```

### Step 2: Execute CRUD via Notion MCP
Use the Notion MCP write/read endpoints directly. Never browse to notion.so.

### Step 3: Update Local State
Sync ticket status back to `.agents/project-data/state/nose/state.json`.

## Post-flight
```
Ticket Operation Complete

Action: [create/list/update/close]
Ticket: [ID] — [Title]
Status: [status]
URL: [Notion URL]
```

---


---

## Responsibilities

See `.agents/rules/orchestrator-responsibilities.md` for Task Distribution, State Update handling, Rule Update handling, Agent Memory verification, Output Styles, and Project State update protocols.
