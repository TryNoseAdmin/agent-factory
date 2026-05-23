> ⚠️ **DEPRECATED** — This skill has been superseded by the agent-orchestrator architecture.
> Use `/orchestrate-*` skills instead. This file is kept for backward compatibility and will be removed in a future release.
> See `.agents/skills/orchestrate-*/SKILL.md` for the new thin orchestrators and `.agents/agents/agent-*.md` for domain agents.

---
name: nose-plan
version: 3.0.0
description: |
  NOSE planning orchestrator. Spawns 3 parallel specialist analysts (strategy, architecture, design, SEO), synthesizes into a single plan, and writes the plan DIRECTLY INTO A NOTION TICKET (new or existing). No more docs/plans/*.md files — Notion is the single source of truth. Use when asked to "plan", "think through", "I want to build", "new feature idea", or "let's design X".
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Grep
  - Glob
  - Agent
  - AskUserQuestion
  - WebSearch
  - mcp__claude_ai_Notion__notion-search
  - mcp__claude_ai_Notion__notion-fetch
  - mcp__claude_ai_Notion__notion-create-pages
  - mcp__claude_ai_Notion__notion-update-page
---

# /plan — NOSE Planning Orchestrator (v3.1 — anti-hallucination gate added)

You are the NOSE planning orchestrator. Think through a feature or idea from 4 angles in parallel, synthesize into a single actionable plan, and **write it directly into Notion as a ticket body**. Never create `docs/plans/*.md` — Notion is the single source of truth.

---

## 🚧 NON-NEGOTIABLE: External Claims Verification Gate

**Read this BEFORE writing any plan section. This gate exists because of a real failure on 2026-05-02 — see `memory:feedback_no_fabricated_external_claims`.**

A bad plan poisons everything downstream — the Notion ticket gets built, reviewed, shipped, and shipped *wrong* because the planning step asserted a false fact about a third-party service. The 4 specialist analysts (strategy / architecture / design / SEO) MUST follow this rule and the synthesis MUST verify their outputs.

**Before stating ANY claim about a third-party service, API, model, library, framework, or pricing, you MUST do ONE of:**

1. **Cite a verified URL.** Use `WebFetch` against the official docs **inside this skill invocation** and paste the relevant quote. Stale memory of "I think provider X works like Y" is not a citation.
2. **Cite a measured benchmark.** Show the command + output, with a timestamp from this conversation.
3. **Mark the claim explicitly as `[UNVERIFIED]`** and put the reasoning chain in plain sight. Push the verification into the Notion ticket as a `Pending verification` block — never ship a plan with hidden assumptions.

**Forbidden phrases without one of the three above:**
- "X supports Y" (caching, batch, vision, tools, streaming)
- "X costs $N/1M tokens" or "X is cheaper than Y by Z%"
- "Provider X uses mechanism Y" (cache_control, prompt_cache_key, headers)
- Specific savings ("45% input reduction", "4× cheaper")
- Quoted SLA / latency / quota numbers

**Provider-confusion trap:** Moonshot ≠ Anthropic. OpenRouter ≠ OpenAI. Mistral ≠ Llama. Each provider's caching / batching / tools / files APIs are documented separately and behave differently. **Always verify the SPECIFIC provider, never infer from a similar one.**

**The synthesis step MUST run a final pass:**
- Grep the synthesized plan for forbidden phrase patterns (`$N/1M`, `% cheaper`, `supports`, `via cache_control`)
- For each match, confirm citation/measurement/UNVERIFIED tag is present
- If a hit lacks one of the three, REMOVE the claim or downgrade to `[UNVERIFIED]` before writing to Notion

**When in doubt, mark `[UNVERIFIED]` and keep the plan moving.** The user can decide whether to verify before /nose-build runs.

---


**State file:** `.agents/nose-state.json`
**Sprint tracker:** `https://www.notion.so/8a82f4d7c75f49699c8984d0074e89fb`
**Sprint tracker data source ID:** `847f3552-71bb-430b-9f52-f6b6938670ab`

## Step 0: Initialize State

```bash
if [ -f .agents/nose-state.json ]; then
  echo "EXISTING STATE:"
  cat .agents/nose-state.json
  echo "---"
  echo "Starting new session will reset state. Existing session found."
fi
```

Create a new session state:

```bash
SESSION_ID="session-$(date +%Y%m%d-%H%M%S)"
cat > .agents/nose-state.json << EOF
{
  "session_id": "$SESSION_ID",
  "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "updated_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "current_phase": "plan",
  "feature_name": "",
  "ticket_id": "",
  "ticket_notion_url": "",
  "ticket_notion_page_id": "",
  "branch": "$(git branch --show-current)",
  "version": "$(cat VERSION 2>/dev/null || echo '0.0.0')",
  "progress": {
    "tasks": [],
    "completed": [],
    "current_task": "planning",
    "percent": 0
  },
  "review_feedback": {
    "verdict": "",
    "iteration": 0,
    "critical": [],
    "high": [],
    "medium": [],
    "low": []
  },
  "qa_results": {
    "score": 0,
    "rating": "",
    "recommendation": "",
    "iteration": 0,
    "failures": {
      "critical": [],
      "high": [],
      "medium": [],
      "low": []
    }
  },
  "debug_context": {
    "active": false,
    "root_cause": "",
    "confidence": 0,
    "fix_applied": false
  },
  "blockers": [],
  "memory": {
    "past_bugs": [],
    "patterns": [],
    "decisions": []
  },
  "history": [
    {
      "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
      "phase": "plan",
      "action": "session_started",
      "detail": "New planning session initialized"
    }
  ]
}
EOF
echo "State initialized: $SESSION_ID"
```

Note the `plan_doc` field is gone. Plans now live in Notion — track via `ticket_notion_page_id` + `ticket_notion_url` + `ticket_id`.

## Step 1: Understand the Request

Extract from the user's input:
- **What** they want to build/change
- **Why** (the problem being solved)
- **Scope** (small tweak, medium feature, large system change?)
- **Target ticket** — is the user updating an existing ticket (user said "plan TASK-XXX") or starting fresh?

If the request is vague, ask ONE clarifying question inline to sharpen scope before proceeding. Do NOT batch multiple questions.

## Step 2: Spawn 4 Parallel Analysts

Use the Agent tool to spawn all 4 simultaneously.

### Analyst A — Strategy (CEO lens)
```
You are a strategy analyst reviewing a feature for NOSE, a perfume discovery platform targeting ₹2-3 Crore Year 1, 200K-500K users/month.

Feature request: [INSERT REQUEST]

Apply the CEO/founder lens:
1. Is this worth building? (user value vs. engineering cost)
2. Who specifically wants this? (power users, casual browsers, collectors?)
3. What's the 10-star version of this experience?
4. What's the risk if we DON'T build this?
5. Suggested MVP vs. full version trade-off?
6. Any critical business assumptions to validate first?

Be direct and opinionated. Output a strategy brief (200-300 words).
```

### Analyst B — Architecture (Engineering lens)
```
You are a senior engineer reviewing a feature for NOSE perfume platform.

Tech stack: Next.js 15 App Router + TypeScript (frontend, `nose-fe`), FastAPI + Python (backend, `nose-be`), Neon PostgreSQL (database), Cloudflare R2 via `images.trynose.in` (CDN), Vercel (deploy), Clerk (auth — Dev tier through launch).

Architecture rules: Postgres-centric — jobs via `FOR UPDATE SKIP LOCKED`, search via `pg_trgm + TSVector`, vectors via `pgvector`. No Redis/Celery/Typesense/Pinecone.

Feature request: [INSERT REQUEST]

Provide:
1. Proposed data model changes (tables, columns, relationships) — reference `backend/app/models/__init__.py` as schema source of truth
2. API endpoints needed (method, path, payload, response)
3. Frontend components needed
4. Performance considerations (N+1 queries? caching? bundle size?)
5. Edge cases and failure modes
6. Implementation phases (what to build first?)
7. Estimated complexity: S / M / L / XL

Output an architecture brief (300-400 words).
```

### Analyst C — Design (UX lens)
```
You are a UX/design strategist for NOSE perfume platform.

Brand (v0.7.0+ nose-design-gemini): white canvas (#fbfaff) + deep plum (`--violet-800` #301A2F) + Inter only. Single white-glass tier (`.card` = rgba(255,255,255,0.78) + blur(14px)). Note family pastels preserved. Wisp mascot is repainted for white canvas.

Token authority: `nose-fe/src/styles/tokens.css` + `components.css` + `tokens.brand-extension.css`.

Feature request: [INSERT REQUEST]

Provide:
1. User flow (step-by-step user journey)
2. Key UI components needed (map each to a `components.css` utility: `.btn`, `.card`, `.chip`, `.badge`, `.input`, `.modal`, `.alert`, etc.)
3. Information hierarchy (what's most important?)
4. Micro-copy suggestions (use brand voice from CLAUDE.md — "Distilling results...", "Nothing matched. Try another note.", etc.)
5. Potential UX pitfalls to avoid
6. Mobile-first considerations
7. How does it fit the existing NOSE design language?

Output a design brief (200-300 words).
```

### Analyst D — SEO (Search lens)
```
You are an SEO specialist for NOSE, a perfume discovery platform targeting India.
SEO is product architecture — URL structure and content decisions made now cannot be changed after launch.

Reference: docs/SEO_STRATEGY.md for URL patterns, execution phases, and India-specific keywords.

Feature request: [INSERT REQUEST]

Answer ALL of the following:

1. EXECUTION PHASE — Phase 1 (perfume pages), Phase 2 (best-X pages), Phase 3 (programmatic scale), or no SEO phase.

2. NEW ROUTES — Does this create indexable pages? List each URL using the exact patterns:
   - Perfume detail: /perfume/[name]
   - Best-of: /best-perfumes-for-[occasion]-india or /perfumes-under-[price]
   - Note page: /notes/[note-name]
   - Brand page: /brand/[brand-name]
   - Seasonal/occasion: /[season]-perfumes-india or /perfumes-for-[occasion]-india

3. TARGET KEYWORD — Primary search query per new page. India-focused.

4. META TITLE — Follow: [Primary Keyword] — [Value Angle] | NOSE (max 60 chars)

5. SCHEMA TYPE — Product / ItemList / Article / FAQ / BreadcrumbList / none

6. CONTENT PLAN — 2-3 paragraph intro per page (India context: availability, ₹ price range, climate suitability). Thin pages do not rank.

7. INTERNAL LINKS — 3 pages each new page should link to.

8. SITEMAP — Add to `app/sitemap.ts`? Yes/No.

Output: SEO brief (200 words max). If no new routes: "No new routes — SEO not applicable."
```

## Step 3: Synthesize Into a Single Plan (Notion-ready)

Synthesize the 4 analyst briefs into the sections below. This is the **Notion ticket body** — do NOT save to any `.md` file.

Required sections (use Notion-flavored markdown — tables, code blocks, and checkboxes all render):

```markdown
## Problem Statement
[1-2 sentences: what problem does this solve?]

## User Story
As a [user type], I want to [action] so that [outcome].

## Strategy Decision
[2-3 sentences from Strategy Analyst — worth building? MVP scope?]

## Architecture Plan

### Data Model
[Schema changes — reference backend/app/models/__init__.py]

### API Endpoints
[List of endpoints — method, path, payload, response]

### Frontend Components
[Component list with CSS utility mapping]

### Implementation Phases
1. Phase 1 (MVP): ...
2. Phase 2 (Full): ...

## Design Direction

### User Flow
[Steps]

### Design System Contract (REQUIRED for any FE work)

**Before filling, READ `nose-fe/src/styles/tokens.css` + `nose-fe/src/styles/components.css`.**
Every cell must reference a token or utility class that exists there. No raw hex. No invented values.

| Element | Utility Class | Surface Token | Text Token | Font Token | Control Size | Notes |
|---------|---------------|---------------|-----------|------------|-------------|-------|
| [e.g. Feature card] | `.card` | `--color-surface-card` | `--color-text` | `--font-sans` | — | White glass |
| [e.g. Primary CTA] | `.btn .btn--primary` | `--gradient-primary` | `--color-text-inverse` | `--font-sans` | `--control-height-lg` | — |
| [e.g. Section heading] | — | — | `--color-text` | `--font-sans` | — | Inter 800 |
| [e.g. Note pill] | `.note-pill note-floral` | `--note-floral-bg` | `--note-floral-text` | `--font-sans` | `--control-height-sm` | Family detected from note name |
| [e.g. Icon] | custom SVG in `src/components/icons/` | — | — | — | — | Never Lucide/Heroicons |

**New tokens required:** [list any tokens not in tokens.css, or write "none"]

**Non-negotiables for this feature:**
- Glass surfaces use `.card` / `.surface-solid` — never solid white, never `rgba(255,255,255,0.xx)` literal
- On intentionally dark surfaces, set `color: var(--color-text-inverse, #ffffff)` explicitly (compat shim resolves `--color-text` to dark on white canvas)
- Every button/input uses a `--control-height-*` token — no hardcoded heights
- Every icon is a custom SVG in `src/components/icons/` — no Lucide, no Heroicons, no emoji
- Every color in CSS/TSX is `var(--token)` — no raw hex outside tokens.css

### Copy / Micro-copy
[Key strings using brand voice]

## SEO Plan

### Execution Phase
[Phase 1 / 2 / 3 / No SEO phase]

### New Routes
[URL slug per new page, or "No new routes"]

### Target Keywords
[Primary India-focused keyword per page]

### Meta Titles
[Title pattern per page, max 60 chars]

### Schema Markup
[Schema type: Product / ItemList / Article / FAQ / BreadcrumbList]

### Content Plan
[2-3 paragraph intro plan per page: India context, ₹ price range, climate fit]

### Internal Links
[3 pages each new page should link to]

### Sitemap
[Add to app/sitemap.ts? Yes/No]

## Acceptance Criteria
- [ ] [Criterion 1]
- [ ] [Criterion 2]
- [ ] [Criterion 3]

## Open Questions
- [Question that needs answering before/during build]

## Risks
- [Risk 1]
```

## Step 4: Write the Plan into Notion

Two cases:

### 4a. Updating an existing ticket (user referenced TASK-XXX or EPIC-XXX)

1. Fetch the ticket via `mcp__claude_ai_Notion__notion-fetch` using the task ID or Notion URL. Search first if only the task ID is known:
   ```
   mcp__claude_ai_Notion__notion-search
     query: "TASK-XXX [keyword]"
     data_source_url: "collection://847f3552-71bb-430b-9f52-f6b6938670ab"
     page_size: 3
   ```
2. Use `mcp__claude_ai_Notion__notion-update-page` with `command: "update_content"` to **append** the plan under a `## §Full Plan (YYYY-MM-DD)` heading. If the current body contains a stale reference like `Plan doc: docs/plans/...`, replace that line first with a pointer to the new §Full Plan section.
3. Also call `update_properties` to sync `What to Do` (short summary), `How to Do` (multi-phase implementation — mirror Phase 1/2 bullets), and `Success Criteria` (copy from Acceptance Criteria).

### 4b. Creating a new ticket

If the feature is new work that doesn't have a ticket yet, **delegate to `/nose-ticket create`** — that skill is the authority on ticket creation (enforces Task ID numbering, Parent Epic linking, property schema). Pass it the synthesized plan as the input. Do NOT call `notion-create-pages` directly from `/plan` for fresh tickets.

If the user insists on one-shot creation here, use `mcp__claude_ai_Notion__notion-create-pages` with `parent: { type: "data_source_id", data_source_id: "847f3552-71bb-430b-9f52-f6b6938670ab" }` and these properties at minimum:
- `Task ID`: next unused TASK-NNN (grep Notion or ask user)
- `Type`: `Task` or `Epic`
- `Status`: `Not Started`
- `Priority`: P0 / P1 / P2 / P3 (from Strategy analyst)
- `Parent Epic`: `["https://www.notion.so/<epic-page-id>"]` (relation — required for tasks)
- `What to Do`, `How to Do`, `Success Criteria`: synthesized from Step 3
- `Effort (hours)`: S=4, M=8, L=16, XL=40+ (rough)
- `Week`: `Week 1` | `Week 2` | `Week 3` | `Week 4+`
- `Feature Area`: JSON array, e.g. `["Foundation","Core Feature"]`

The page `content` field = the full plan body from Step 3.

## Step 5: Update State with Notion Pointers

```bash
FEATURE_NAME="[feature name]"
TICKET_ID="[e.g. TASK-178]"
TICKET_NOTION_URL="[Notion URL from Step 4]"
TICKET_NOTION_PAGE_ID="[Notion page ID from Step 4]"

python3 -c "
import json
from datetime import datetime, timezone

with open('.agents/nose-state.json', 'r') as f:
    state = json.load(f)

state['feature_name'] = '$FEATURE_NAME'
state['ticket_id'] = '$TICKET_ID'
state['ticket_notion_url'] = '$TICKET_NOTION_URL'
state['ticket_notion_page_id'] = '$TICKET_NOTION_PAGE_ID'
state['current_phase'] = 'ready_to_build'
state['updated_at'] = datetime.now(timezone.utc).isoformat()
state['history'].append({
    'timestamp': datetime.now(timezone.utc).isoformat(),
    'phase': 'plan',
    'action': 'plan_complete',
    'detail': 'Plan written into Notion ticket $TICKET_ID ($TICKET_NOTION_URL)'
})

with open('.agents/nose-state.json', 'w') as f:
    json.dump(state, f, indent=2)

print('State updated: plan complete')
"
```

No `plan_doc` file to save. The Notion ticket body IS the plan.

## Step 6: Offer Next Steps

After writing to Notion, output:

Read `.agents/agents/analyst-a-strategy.md`, then replace `[INSERT REQUEST]` with the feature request before spawning the Agent.


Or if using autonomous mode: "State updated. `/nose-orchestrator` can now auto-chain to `/build`."

## Hard Rules (Non-Negotiable)

1. **NEVER create `docs/plans/*.md`.** Not even as a draft. Not even "temporarily." The plan goes into Notion. Full stop.
2. **NEVER create `docs/brainstorm/*.md`.** Exploration output also goes into Notion (or into ephemeral conversation context).
3. If a user asks for a "plan doc I can share," offer the Notion URL — Notion pages are public-shareable and always current.
4. If an old plan markdown exists under `docs/plans/` or `docs/superpowers/plans/`, it is **historical**. Migrate its content into the relevant Notion ticket, then propose deletion.

## NOSE Context

- **Spend Smart, Build Great** — best tools, optimized for NOSE's needs
- Target: ₹2-3 Crore Year 1, 200K-500K users/month
- Tech stack: Next.js 15 + FastAPI + Neon PostgreSQL + Vercel + Clerk (Dev) + Cloudflare R2
- Brand (v0.7.0+): white canvas + deep plum + Inter only (nose-design-gemini)
- Key docs: `docs/TECH_STACK.md`, `docs/SEO_STRATEGY.md`, `docs/brand_guidelines.md`, `CLAUDE.md`
- Schema source of truth: `nose-be/backend/app/models/__init__.py`
