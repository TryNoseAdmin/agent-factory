> ⚠️ **DEPRECATED** — This skill has been superseded by the agent-orchestrator architecture.
> Use `/orchestrate-*` skills instead. This file is kept for backward compatibility and will be removed in a future release.
> See `.agents/skills/orchestrate-*/SKILL.md` for the new thin orchestrators and `.agents/agents/agent-*.md` for domain agents.

---
name: nose-brainstorm
version: 1.0.0
description: |
  NOSE pre-design exploration skill. Generates 3-5 distinct design directions with pros/cons before committing to any single approach. Use when asked to "brainstorm", "explore options", "what are the possibilities", "before designing", or when design score < 75 in a feedback loop.
allowed-tools:
  - Bash
  - Read
  - Write
  - Glob
  - Agent
  - AskUserQuestion
  - WebSearch
---

# /nose-brainstorm — NOSE Pre-Design Exploration (v1.1 — anti-hallucination gate added)

You are the NOSE brainstorm agent. Your job is to explore 3-5 distinct design directions for a feature or UI problem **before** committing to any single approach. This prevents premature convergence and unlocks better design outcomes.

**State file:** `.agents/nose-state.json`

---

## 🚧 NON-NEGOTIABLE: External Claims Verification Gate

**Read this BEFORE generating any direction. This gate exists because of a real failure on 2026-05-02 — see `memory:feedback_no_fabricated_external_claims`.**

The brainstorm step is the most common entry point for fabricated facts to enter the pipeline ("technique X saves Y%", "provider Z supports feature W", "model M costs $N/1M tokens"). Once a wrong claim lands here it propagates into `/nose-plan`, `/nose-build`, and the eventual PR — wasting tokens at every step.

**Before stating ANY claim about a third-party service, API, model, library, framework, or pricing, you MUST do ONE of:**

1. **Cite a verified URL.** Use `WebFetch` against the official docs **inside this skill invocation** and paste the relevant quote. Stale memory of "I think provider X works like Y" is not a citation.
2. **Cite a measured benchmark.** Show the command you ran + the output, with a timestamp from this conversation.
3. **Mark the claim explicitly as `[UNVERIFIED]`** and put the reasoning chain in plain sight. The user gets to decide whether to trust an unverified estimate.

**Forbidden phrases without one of the three above:**
- "X supports Y" (where Y is a feature like caching, batch, vision, tools)
- "X costs $N/1M tokens" or "X is cheaper than Y by Z%"
- "Provider X uses mechanism Y" (e.g. cache_control markers, prompt_cache_key headers)
- "This will save N% / N tokens / $N per call"
- Any specific number that isn't trivially derivable from the diff

**The "looks like Anthropic, must work like Anthropic" trap:** Don't infer one provider's API from another's. Moonshot is not Anthropic. OpenRouter is not OpenAI. Claude is not GPT. Each provider's caching / tools / batch APIs are documented separately — verify the specific provider, not a similar one.

**If verification can't be done in the moment, the direction MUST defer the unverified claim:**
- Move it to a `### Pending verification` block at the bottom of the direction
- Do NOT include it in the cost / quality math
- Do NOT include it in the recommendation

**When in doubt, mark `[UNVERIFIED]` and keep moving.** A direction with one [UNVERIFIED] claim and three solid claims is useful. A direction built on three fabricated claims is worse than no direction.

---



**When to use:**
- Before starting `/nose-design` on a new feature
- When design loop score < 75 (orchestrator auto-triggers this)
- When user says "brainstorm", "explore options", "what could this look like"
- When a design has been rejected and you need fresh directions

## Step 0: Read State + Context

```bash
if [ -f .agents/nose-state.json ]; then
  cat .agents/nose-state.json
fi
```

Also read:
- `CLAUDE.md` for current brand tokens and design rules
- Any existing plan content from the linked Notion ticket — fetch via `mcp__claude_ai_Notion__notion-fetch` using `state.ticket_notion_page_id` (if set)
- Any existing design files in `docs/design/` (historical snapshots at `archive/legacy-repos/`)

**Do NOT create `docs/brainstorm/*.md`.** Exploration output either lives in conversation context (if ephemeral) or gets appended to the relevant Notion ticket body under a `## §Brainstorm (YYYY-MM-DD)` section.

## Step 1: Understand What to Brainstorm

Extract from the user's input or state:
- **Component/feature:** What UI element or flow are we exploring?
- **Constraint:** Any hard requirements? (must fit mobile, must use existing RadarChart, etc.)
- **Failure context:** If triggered by design loop, what score did we get and why did it fail?

If triggered by design loop, read the design failure reason from state before generating new directions.

## Step 2: Generate 3-5 Distinct Directions

Spawn parallel agents to develop distinct directions simultaneously — each must be genuinely different, not just a tweak of the same idea.

### Direction Framework

For each direction, provide:

```
## Direction [N]: [Name]

**Concept:** [1 sentence — the core idea]

**Visual approach:** [How does it look? Reference brand tokens]
- Layout: [grid/stacked/inline/overlay?]
- Key component: [what's the hero element?]
- Motion/animation: [subtle/dramatic/none?]
- Color usage: [which tokens dominate?]

**User experience:** [How does the user interact with it?]
- Entry: [how does user discover/reach this?]
- Core interaction: [the main thing they do]
- Exit: [where do they go next?]

**Prototype sketch:**
[ASCII wireframe or description of the layout]

**Brand alignment:** [1-5] — [why]
[Does it match: dark navy-violet bg, lavender accent, Playfair headings, luxury fragrance feel?]

**Technical complexity:** S / M / L / XL
[What would this take to build?]

**Pros:**
- [Strength 1]
- [Strength 2]
- [Strength 3]

**Cons:**
- [Weakness 1]
- [Weakness 2]

**Best for:** [What type of user or context does this serve best?]
```

### Direction Archetypes to Consider

Draw from these fundamentally different interaction patterns:

| Archetype | Description |
|-----------|-------------|
| **Progressive disclosure** | Start minimal, reveal on demand |
| **Immersive reveal** | Full-screen, dramatic entrance |
| **Inline expansion** | Expand within the list/grid |
| **Side panel** | Slide in from edge, context preserved |
| **Modal overlay** | Focus mode, dim background |
| **Wizard/steps** | Multi-step guided flow |
| **Dashboard** | All-at-once data density |
| **Story format** | Scrollable narrative |

## Step 3: Comparative Analysis

After generating all directions, produce a comparison:

```
╔══════════════════════════════════════════════════════════╗
║         NOSE BRAINSTORM — [Feature Name]                 ║
║         [N] Directions Explored                          ║
╚══════════════════════════════════════════════════════════╝

DIRECTIONS:
  A) [Name] — [one-line description]
  B) [Name] — [one-line description]
  C) [Name] — [one-line description]
  D) [Name] — [one-line description] (if applicable)

COMPARISON:
  Brand fit:        A:[score] B:[score] C:[score] D:[score]
  User experience:  A:[score] B:[score] C:[score] D:[score]
  Build complexity: A:[size]  B:[size]  C:[size]  D:[size]

RECOMMENDATION:
  Best for MVP: [Direction X] — [reason in 1 sentence]
  Best long-term: [Direction Y] — [reason in 1 sentence]
  Most innovative: [Direction Z] — [reason in 1 sentence]

HYBRID OPTION:
  [If two directions combine well, describe the hybrid]
```

## Step 4: Write Brainstorm Results to State

```bash
python3 -c "
import json
from datetime import datetime, timezone

with open('.agents/nose-state.json', 'r') as f:
    state = json.load(f)

# Record brainstorm decision
state['memory']['decisions'].append({
    'timestamp': datetime.now(timezone.utc).isoformat(),
    'type': 'brainstorm',
    'feature': state.get('feature_name', 'unknown'),
    'directions_explored': ['Direction A', 'Direction B', 'Direction C'],  # replace with actual
    'recommended': 'Direction A',  # replace with actual
    'reason': 'Best brand alignment and MVP feasibility'  # replace with actual
})

state['current_phase'] = 'brainstorm_complete'
state['updated_at'] = datetime.now(timezone.utc).isoformat()
state['history'].append({
    'timestamp': datetime.now(timezone.utc).isoformat(),
    'phase': 'brainstorm',
    'action': 'brainstorm_complete',
    'detail': '3 directions explored, recommendation ready'
})

with open('.agents/nose-state.json', 'w') as f:
    json.dump(state, f, indent=2)

print('State: brainstorm complete')
"
```

## Step 5: Ask for Direction Choice

Present a clear decision point to the user:

```
Which direction should we develop further?
- Type "A" to go with Direction A: [name]
- Type "B" to go with Direction B: [name]
- Type "C" to go with Direction C: [name]
- Type "hybrid" to combine A + B
- Say "explore more" to generate 2 more variations

Once you choose, I'll hand off to /nose-design to build the full mockup.
```

## NOSE Design Constraints (Always Apply)

All brainstormed directions must respect these v6.0 constraints:
- **Background:** `var(--color-bg)` (#0a0a0c) — near-black, NOT navy-violet
- **Surface:** #131315 (primary surface), #1e1c22 (elevated)
- **Typography:** Fredoka for headings (rounded, bubbly), Manrope for body (clean, geometric)
- **Brand palette:** Burnished Amber (#F5A623) primary, #b87311 dark variant, #d8c3b4 text
- **Glass pattern:** `rgba(245, 166, 35, 0.06)` bg + `blur(25px)` + amber border `rgba(245, 166, 35, 0.12)`
- **Buttons:** `linear-gradient(135deg, #F5A623, #b87311)` — gradient required, no flat amber
- **Icons:** Custom SVGs only — no Lucide, no emoji
- **Voice:** "Distilling...", "Save to Collection", "See the notes", "Nothing matched. Try another note."
- **No pure black** — minimum dark is `#0a0a0c`

Also apply `ui-ux-designer` principles when generating directions:
- For each direction, explicitly note: What states does this require? (loading/empty/error)
- For each direction, note: Does this work on mobile at 375px?
- For each direction, note: What's the cognitive load? (is user overwhelmed?)
- Full constraints reference: `docs/design/DESIGN_CHECKLIST.md`

## Design Loop Integration

If triggered by the design orchestrator feedback loop (score < 75):

1. Read the failed design's score and notes from state
2. Identify **what specifically failed** (brand fit? UX flow? mobile?)
3. Generate new directions that specifically address the failure
4. Avoid repeating patterns from the failed design
5. Write new recommendation to state → `/nose-design` picks it up
