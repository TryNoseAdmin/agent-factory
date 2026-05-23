> ⚠️ **DEPRECATED** — This skill has been superseded by the agent-orchestrator architecture.
> Use `/orchestrate-*` skills instead. This file is kept for backward compatibility and will be removed in a future release.
> See `.agents/skills/orchestrate-*/SKILL.md` for the new thin orchestrators and `.agents/agents/agent-*.md` for domain agents.

---
name: nose-setup
version: 1.2.0
description: |
  Cold-start context loader for NOSE. Hybrid model — eager-loads the 5 small orienting docs (rules, registry, repos, skill catalogue, ticket lifecycle) plus current state (version, changelog, session, Notion, git, PRs, memory). Specialist docs (standards, brand, SEO, design gate, tech stack) are lazy-loaded by the skills that need them at point of use. Use when starting fresh: "setup", "load context", "catch me up", "new session", "where are we".
allowed-tools:
  - Bash
  - Read
  - Grep
  - mcp__claude_ai_Notion__notion-search
  - mcp__claude_ai_Notion__notion-fetch
---

# /nose-setup — Cold-Start Context Loader (v1.2 — Hybrid)

**Job:** for a new session, load just enough to orient the agent — the rules, the registry, the project map, the skill catalogue, the ticket lifecycle — then a snapshot of current state. Specialist docs (coding standards, brand tokens, SEO rules, design checklist, tech stack) are NOT read here. They're lazy-loaded by the skill that needs them, at point of use, gated by that skill's own checks.

**Why hybrid:** small docs = cheap eager load (always needed). Large specialist docs = pay-per-use (only relevant to certain work, stay fresh on read). Point-of-use gates in each skill already enforce the reads — that's the right enforcement layer, not session start.

---

## Step 1 — Read the 5 orienting docs

Read each silently. Confirm with one line. Do NOT echo doc contents to the user.

```
Read CLAUDE.md                          # working rules, git workflow, meta
Read docs/PROJECT_BRIEFING.md           # vision + registry of all canonical owners
Read docs/REPOS.md                      # multi-repo map (nose / nose-fe / nose-be)
Read docs/SKILL_ARCHITECTURE.md         # what each /nose-* skill does
Read docs/TICKET_MANAGEMENT.md          # Notion lifecycle, Task ID numbering
```

After this, the agent knows: how to work with the user, where to find everything, what lives in which repo, which skill to reach for, and how tickets flow.

For specialist questions (stack, brand, SEO, design gate, standards), the registry in PROJECT_BRIEFING.md tells the agent which file to fetch — and the skill that actually uses that knowledge will read the file at point of use.

If any file is missing, note "missing: X" and continue. Don't fail.

## Step 2 — Version + shipped history

```bash
echo "VERSION: $(cat VERSION 2>/dev/null || echo 'unknown')"
echo ""
awk '/^## \[/{n++; if (n>3) exit} n>0' CHANGELOG.md 2>/dev/null | head -80
```

## Step 3 — Current session state

```bash
if [ -f .agents/nose-state.json ]; then
  python3 -c "
import json
with open('.agents/nose-state.json') as f:
    s = json.load(f)
print(f\"Session:        {s.get('session_id', '-')}\")
print(f\"Current phase:  {s.get('current_phase', '-')}\")
print(f\"Feature:        {s.get('feature_name', '-')}\")
print(f\"Ticket:         {s.get('ticket_id', '-')}\")
print(f\"Notion URL:     {s.get('ticket_notion_url', '-')}\")
print(f\"Branch:         {s.get('branch', '-')}\")
progress = s.get('progress', {})
done = len(progress.get('completed', []))
total = len(progress.get('tasks', []))
if total:
    print(f\"Progress:       {done}/{total} tasks ({progress.get('percent', 0)}%)\")
    print(f\"Current task:   {progress.get('current_task', '-')}\")
review = s.get('review_feedback', {})
if review.get('verdict'):
    print(f\"Last review:    {review['verdict']} (iteration {review.get('iteration', 0)})\")
qa = s.get('qa_results', {})
if qa.get('score'):
    print(f\"Last QA score:  {qa['score']}/100 ({qa.get('rating', '-')})\")
blockers = s.get('blockers', [])
if blockers:
    print(f\"Blockers:       {len(blockers)} active\")
"
else
  echo "No active session state."
fi
```

## Step 4 — In-flight + recently-closed tickets (Notion)

Use `mcp__claude_ai_Notion__notion-search` against data source `collection://847f3552-71bb-430b-9f52-f6b6938670ab`:
- Query `"In Progress"` (page_size 5) — currently active
- Query `"Completed"` with `created_date_range` start_date = 14 days ago (page_size 5) — last sprint's output

Print as:
```
[STATUS] TASK-XXX — <title> — P<N>
```

If MCP is unavailable: `Notion unavailable — open https://www.notion.so/8a82f4d7c75f49699c8984d0074e89fb manually.`

## Step 5 — Recent commits across three repos

```bash
for repo in nose nose-fe nose-be; do
  REPO_PATH="$HOME/Documents/GitHub/TryNose/$repo"
  if [ -d "$REPO_PATH/.git" ]; then
    echo "=== $repo ==="
    git -C "$REPO_PATH" log --oneline -5 2>/dev/null || echo "  (log unavailable)"
    echo ""
  fi
done
```

## Step 6 — Open PRs across three repos

```bash
for repo in nose nose-fe nose-be; do
  OPEN=$(gh pr list --repo TryNoseAdmin/$repo --state open --limit 5 --json number,title,headRefName 2>/dev/null)
  if [ -n "$OPEN" ] && [ "$OPEN" != "[]" ]; then
    echo "=== $repo PRs ==="
    echo "$OPEN" | python3 -c "
import json, sys
for pr in json.load(sys.stdin):
    print(f\"  #{pr['number']} {pr['title']} ({pr['headRefName']})\")
"
  fi
done
```

## Step 7 — Cross-session memory

```bash
MEMORY_DIR="$HOME/.claude/projects/-Users-musheerk-Documents-GitHub-Trynose-nose/memory"
if [ -f "$MEMORY_DIR/MEMORY.md" ]; then
  cat "$MEMORY_DIR/MEMORY.md"
else
  echo "No memory index yet."
fi
```

## Step 8 — Show the user a compact dashboard

After all reads succeed, print one dashboard (max ~50 lines). No raw doc dumps — those sat in agent context. The user sees only this:

```
╔══════════════════════════════════════════════════════════════╗
║   NOSE — Session Context                                     ║
║   [YYYY-MM-DD]                                               ║
╚══════════════════════════════════════════════════════════════╝

Loaded: 5 orienting docs (CLAUDE, briefing+registry, repos,
skill catalogue, ticket lifecycle). Specialist docs (standards,
brand, SEO, design gate, stack) load per-skill at point of use.

Version:       vX.Y.Z  (last shipped: [date])
Branch:        [current branch]
Session phase: [current_phase or "fresh"]

▸ In flight (Notion)
  - TASK-XXX  [title]  P1
  - TASK-YYY  [title]  P0

▸ Recently shipped (last 3)
  - v0.7.0  EPIC-014 PR1 — nose-design-gemini adoption
  - v0.6.0  wisp mascot Phase 1
  - v0.5.2  enrichment job queue

▸ Open PRs
  - nose#35  phase-2 archive
  - nose#36  plans to Notion + skill rewires
  - nose#37  briefing = registry + /nose-setup

▸ Active session
  Ticket:     TASK-XXX
  Progress:   N/M tasks
  Last review: APPROVED_WITH_NOTES

▸ Memory highlights
  - [top 5-8 entries by relevance to current work]

Ready. What would you like to do?
```

---

## Rules for this skill

1. **Read-only.** Never writes state, never modifies files.
2. **Eager, upfront.** All 10 identity/rules docs are read before Step 2. The agent is fully oriented before the dashboard prints.
3. **Degrade gracefully.** Missing doc → note it, skip, continue. Never fail the whole skill.
4. **User-facing output stays compact.** Raw doc contents belong in agent context, not the user's screen.
5. **Run on every fresh session.** That is the whole point.
6. **Do not decide next steps.** That's `/nose-orchestrator`. This skill loads; orchestrator decides.
