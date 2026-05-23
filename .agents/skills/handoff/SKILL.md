---
name: handoff
description: Generate a structured end-of-session handoff so the next agent (or session) re-grounds in 30 seconds, not 30 minutes. Auto-fills mechanical sections (STATE, SHIPPED) from git + gh; agent fills strategic sections (FRAME, NEXT, BLOCKED, FRICTION) from session memory. Saves the block to ~/.claude/projects/<project>/memory/latest_session_handoff.md so the next session auto-loads it. Skip if no PRs shipped AND no strategic decisions made.
---

# /handoff — Session Handoff Generator

## When to use

- User signals end-of-session: "wrap up", "see you tomorrow", "done for today", "end session", "next session", "I'm out"
- After `/nose-release` if the day's arc is closing
- Long build/ship sessions (≥1 PR shipped OR ≥30 min) that haven't already produced a handoff this calendar day

## When to skip

- Pure-chat session — no PRs shipped today AND no strategic decisions made
- User said "quick question" at start
- Already produced a handoff in this same session (don't double-generate)

If skipping, ask the user once: *"Pure-chat session — skip handoff? (Y/n)"*. Don't silently skip.

## The format (target ≤30s read for next agent)

```
# <Repo> — Session Handoff (YYYY-MM-DD)

## STATE
- branch: <name> [clean | uncommitted: <N> files]
- open PRs:
  - #N · <title> · <status>
- version: <X.Y.Z>
- memories added: <list> | none

## FRAME
- bottleneck: <distribution | monetization | infra | code-quality>
- rule: <durable rule that should govern the next session>
- avoid: <1–2 known traps from this session>

## SHIPPED
- PR #N · <one line> · <sha> · merged | open
- ...

## NEXT (in order)
1. [<branch-name>] <action> — <one-line why>
2. ...

## BLOCKED ON YOU
- <decision pending> | <waiting on cred / vendor / external>
- (or "nothing")

## FRICTION
- <process bug hit this session> · <one-line workaround>
- (or "nothing")
```

Every section is mandatory. If a section is empty, write `nothing` or `none` — explicit is better than omitted (tells the next agent it was considered, not forgotten).

## Steps

### 1. Skip-detection

```bash
shipped=$(git log main..HEAD --oneline 2>/dev/null | wc -l | tr -d ' ')
merged_today=$(gh pr list --state merged --search "merged:$(date +%Y-%m-%d)" --json number --jq 'length' 2>/dev/null || echo 0)
echo "shipped=$shipped merged_today=$merged_today"
```

If both are 0 AND no strategic memory was written this session → ask user before generating.

### 2. Auto-fill STATE

```bash
echo "branch: $(git branch --show-current)"
git status --porcelain | wc -l            # uncommitted file count
gh pr list --state open --json number,title,headRefName,isDraft \
  --jq '.[] | "  - #\(.number) · \(.title) · \(if .isDraft then "draft" else "open" end)"'
cat VERSION 2>/dev/null
```

For `memories added`, list the `.md` files added to the project's memory dir this session (the agent tracks this).

### 3. Auto-fill SHIPPED

```bash
git log main..HEAD --oneline 2>/dev/null
gh pr list --state merged --search "merged:$(date +%Y-%m-%d)" \
  --json number,title,mergeCommit \
  --jq '.[] | "  - #\(.number) · \(.title) · \(.mergeCommit.oid[0:7])"'
```

### 4. Manual sections (judgment, not mechanical)

Fill from session memory. Each item one line. Examples:

- **FRAME → bottleneck**: pick the one thing this project most needs more of right now. Code-quality, distribution, monetization, infra. From the strategic memo if one exists.
- **FRAME → rule**: one durable rule the next session should not break. E.g. "no new features after PR-E", "ship via PR not direct push", "no cureyt design system on nose code".
- **FRAME → avoid**: traps hit *this* session that the next session should sidestep. E.g. "don't bundle cross-domain changes into one PR; review-cost spikes."
- **NEXT**: ordered concrete actions. Each prefixed with the branch name the next session should create. If unclear, name a candidate branch.
- **BLOCKED ON YOU**: things that genuinely need user input before any progress. List the decision + cost of waiting (e.g. "Polar.sh signup — blocks Pro tier launch which is monetization gate").
- **FRICTION**: process bugs the next session should know about. Anything that wasted time here. Wrong paths, broken deps, vendor restrictions, agent behaviors.

### 5. Save to memory

Project memory dir: `~/.claude/projects/<project-slug>/memory/`. The slug for this user's nose project is `-Users-musheerk-Documents-GitHub-Trynose-nose` (literal; matches Claude Code's path-encoding convention).

Use the Write tool to OVERWRITE `latest_session_handoff.md` in that dir with the rendered block plus minimal frontmatter:

```markdown
---
name: Latest session handoff (YYYY-MM-DD)
description: Auto-generated at end-of-session by /handoff. Always overwritten — only the latest matters. Read this FIRST at session start to re-ground.
type: project
---

<the full handoff block>
```

### 6. Output to chat

Echo the same block back to the user as a fenced markdown code block. They scroll-back to find it. Don't re-render with extra prose; the block is the deliverable.

### 7. MEMORY.md pointer (one-time setup)

Make sure `MEMORY.md` has an entry pointing to `latest_session_handoff.md` near the TOP (load order matters — gets read before specific feedback memories drift it). One line:

```
- [Latest session handoff](latest_session_handoff.md) — read this FIRST. State + frame + frictions from the previous session.
```

Only add this entry once. Subsequent runs just overwrite the file content.

## Why each section earns its spot

- **STATE** — eliminates cross-repo confusion; the first thing every new session checks anyway
- **FRAME** — stops drift into wrong work (e.g. "build more features when distribution is the bottleneck")
- **SHIPPED** — receipts for what changed; prevents re-asking
- **NEXT** — concrete, branch-named so it's a commitment, not a wish list
- **BLOCKED ON YOU** — explicit so a decision doesn't sit silent waiting forever
- **FRICTION** — the highest-leverage section. Process bugs tax every future session until written down

## What this skill is NOT

- A retrospective. No "what went well / went poorly" theater. FRICTION is for actionable process bugs, not feelings.
- A changelog. SHIPPED links to PRs which already have changelogs.
- A todo list for the user. NEXT is for the next *agent* to pick up. User-facing roadmap lives elsewhere (BACKLOG.md, GitHub issues, Notion).
- An every-session ceremony. Skip cleanly when nothing was shipped.
