# Ticket Utility

## Purpose
Notion ticket management. Called by other orchestrators (plan, build, release) — not a standalone lifecycle stage.

## Config Check

Before any operation, read `.agents/project-data/state/<project>/config.json`:
- If `notion_connected: false` → return immediately with "skipped — notion not connected"
- If `notion_database_id` is null → return immediately

## Operations

### Create Ticket (called by plan)
```
Input: ticket title, description, acceptance criteria, design specs, content plan, SEO plan
Action: Create Notion page in sprint tracker
Output: ticket_id, notion_url
```

### Update Progress (called by build)
```
Input: ticket_id, status update, blockers
Action: Update Notion page status
```

### Mark Complete (called by release)
```
Input: ticket_id, ship summary, version
Action: Update Notion page to "Completed" with release notes
```

## Notion API
Use Notion MCP write/read endpoints directly. Never browse to notion.so.

**Database ID:** Read from config (`notion_database_id`)
**Source of Truth:** [NOSE Sprint Tracker](https://www.notion.so/8a82f4d7c75f49699c8984d0074e89fb)

## Status Lifecycle
```
Not Started → In Progress → Ready for Review → Completed
```

## Output Format
```
Ticket Op: [create | update | complete]
Ticket ID: [id]
Status: [success | skipped]
URL: [notion_url or n/a]
```
