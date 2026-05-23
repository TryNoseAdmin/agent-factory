> ⚠️ **DEPRECATED** — This skill has been superseded by the agent-orchestrator architecture.
> Use `/orchestrate-*` skills instead. This file is kept for backward compatibility and will be removed in a future release.
> See `.agents/skills/orchestrate-*/SKILL.md` for the new thin orchestrators and `.agents/agents/agent-*.md` for domain agents.

---
name: nose-qa
version: 2.0.0
description: |
  NOSE QA orchestrator. Spawns 4 parallel testers (functional, visual, performance, accessibility) against the live app and produces a health score report. Use when asked to "qa", "test the app", "check production", "test live", or "user flows".
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
---

# /qa — NOSE QA Orchestrator (v2)

You are the NOSE QA orchestrator. Test the live app from 4 angles in parallel and produce a health score — writing the score and failures to shared state so the orchestrator can decide to proceed or trigger a debug+fix loop.

**State file:** `.agents/nose-state.json`

## Lazy-Load Gate (required before any visual / accessibility run)

Before spawning the visual or accessibility testers, `Read docs/design/DESIGN_CHECKLIST.md` — that is the canonical source for per-change design rules (contrast, touch targets, state coverage, glass tier, brand voice, responsive). The checklist items become the pass/fail criteria for the testers below. Do not QA from memory; the checklist evolves.

## Step 0: Read State

```bash
if [ -f .agents/nose-state.json ]; then
  cat .agents/nose-state.json
fi
```

Check:
- `current_phase` — should be `ready_to_qa` (or `qa_failed` for re-test after fix)
- `qa_results.iteration` — if > 0, this is a re-test after a fix pass
- `branch` and `ticket_id` — for context

If `iteration > 0`, note this is a re-test and check if previously failing tests now pass.

## Step 1: Get the URL

Determine what to test:
```bash
# Check if app is running locally
curl -s http://localhost:3000 > /dev/null && echo "LOCAL: http://localhost:3000"

# Check production URL from Vercel config (nose-fe repo)
cat ~/Documents/GitHub/TryNose/nose-fe/.vercel/project.json 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(d)" 2>/dev/null
```

If no URL found, ask: "What URL should I test? (e.g. http://localhost:3000 or your Vercel URL)"

## Step 2: Spawn 4 Parallel QA Testers

Use the Agent tool to spawn all 4 simultaneously. Each uses the browse skill for navigation.

---

### QA Tester 1 — Functional

Test all user flows:

**Homepage flows:**
- [ ] Page loads without JS errors
- [ ] Search bar accepts input and submits
- [ ] "Distilling results..." appears during search (not "Loading...")
- [ ] Search results display perfume cards
- [ ] Filter chips work (each filter category)
- [ ] Pagination or infinite scroll works

**Perfume detail flows:**
- [ ] Clicking a perfume card opens detail page
- [ ] ScentRadar chart renders (all 5 axes: Longevity, Sillage, Versatility, Value, Projection)
- [ ] Note pills display with correct color families
- [ ] "See the notes" expands notes accordion
- [ ] "Save to Collection" button works (or prompts sign-in)
- [ ] "You might also like" section shows related perfumes

**Navigation flows:**
- [ ] NOSE logo returns to homepage
- [ ] Back navigation works ("Return to the Collection")
- [ ] 404 shows "The scent has evaporated." (not generic 404)
- [ ] Health endpoint responds: GET /health → 200

**Error flows:**
- [ ] Empty search shows "Nothing matched. Try another note." (not "No results found")
- [ ] Network error shows ErrorBoundary ("This trail goes cold.")

Rate each: PASS / FAIL / PARTIAL
Note: exact error messages and file:line if FAIL

---

### QA Tester 2 — Visual

Check brand consistency at multiple viewport sizes:

**Desktop (1440px):**
- [ ] Background is near-black (#0a0a0c / #131315) — NOT navy-violet, NOT pure black
- [ ] Glass card effect uses amber tint (subtle warm glow, not violet/grey)
- [ ] Primary buttons show amber gradient (`#F5A623` → `#b87311`), not flat color
- [ ] No pure white (#FFFFFF) or pure black (#000000) elements
- [ ] Primary accent color is amber/orange — NOT lavender or violet

**Tablet (768px):**
- [ ] Layout reflows correctly — no horizontal scroll
- [ ] Touch targets are large enough (≥ 44px)
- [ ] Cards show correct grid columns

**Mobile (375px):**
- [ ] Navigation works on mobile
- [ ] Cards stack to 1 column
- [ ] ScentRadar chart is legible and not clipped
- [ ] No text overflow or cut-off

**Typography check (v6.0):**
- [ ] Headings use rounded sans (Fredoka appearance — bubbly, not serif)
- [ ] Body text uses geometric sans (Manrope appearance)
- [ ] No serif headings (Playfair Display is deprecated)

**Icon check:**
- [ ] No Lucide/Material/emoji icons visible in UI
- [ ] All icons look custom/consistent

**Design consistency check:**
- [ ] Brand voice correct: "Distilling results..." not "Loading..."
- [ ] Empty states: "Nothing matched. Try another note." not "No results found"
- [ ] All interactive elements have visible hover feedback (amber glow)
- [ ] No orphaned pages without back navigation

Rate each viewport: PASS / FAIL / PARTIAL with screenshot description

---

### QA Tester 3 — Performance

Check load times and Core Web Vitals:

**Load times (target):**
- [ ] Homepage: < 3s first load
- [ ] Search results: < 1s after query
- [ ] Perfume detail: < 2s
- [ ] API /health: < 200ms

**Core Web Vitals (target):**
- [ ] LCP (Largest Contentful Paint): < 2.5s (GOOD) / < 4s (OK)
- [ ] CLS (Cumulative Layout Shift): < 0.1 (GOOD)
- [ ] No render-blocking resources visible

**API performance:**
```bash
# Test API response times
time curl -s [URL]/health
time curl -s [URL]/api/perfumes?limit=20
time curl -s "[URL]/api/search?q=rose"
```

**Image optimization:**
- [ ] Images load from Cloudflare R2 CDN (`images.trynose.in`, not raw retailer paths)
- [ ] No images blocking render above fold

Rate each: PASS / SLOW / FAIL with measured ms

---

### QA Tester 4 — Accessibility

Check WCAG 2.1 AA compliance:

**Keyboard navigation:**
- [ ] Tab order is logical (header → main → footer)
- [ ] All interactive elements are keyboard-focusable
- [ ] Focus indicators are visible (not hidden)
- [ ] Enter/Space activates buttons and links
- [ ] Escape closes modals/dropdowns

**Screen reader compatibility:**
- [ ] All images have alt text (or alt="" for decorative)
- [ ] Form inputs have labels (not just placeholder text)
- [ ] Buttons have descriptive text (not just icons)
- [ ] Page has logical heading hierarchy (h1 → h2 → h3)

**Color contrast (WCAG AA):**
- [ ] Body text on dark bg: ≥ 4.5:1
- [ ] Large text: ≥ 3:1
- [ ] UI components: ≥ 3:1
- [ ] Note pill text readable on pill background

**Language and structure:**
- [ ] `<html lang="en">` is set
- [ ] Main landmark exists (`<main>`)
- [ ] Navigation landmarks exist (`<nav>`)

Rate each: PASS / FAIL with specific element/location

---

## Step 3: Synthesize QA Report

```
╔══════════════════════════════════════════════════════════════╗
║              NOSE QA REPORT — [URL]                         ║
║              Tested: [date] | Viewport: 375/768/1440px      ║
╠══════════════════════════════════════════════════════════════╣
║  HEALTH SCORE: [0-100]/100  [EXCELLENT/GOOD/NEEDS WORK]     ║
╚══════════════════════════════════════════════════════════════╝

FUNCTIONAL (N/N checks passed):
  ✅ PASS — Homepage loads correctly
  ❌ FAIL — "Loading..." shows instead of "Distilling results..."
  ...

VISUAL (N/N checks passed):
  ✅ PASS — Desktop layout correct
  ⚠️ PARTIAL — Mobile: ScentRadar chart clips at 375px
  ...

PERFORMANCE:
  LCP: Xms [GOOD/OK/POOR]
  API /health: Xms
  API /search: Xms
  ⚠️ SLOW — Perfume detail loads in 4.2s (target: < 2s)
  ...

ACCESSIBILITY (N/N checks passed):
  ✅ PASS — Keyboard navigation works
  ❌ FAIL — Search input missing label (only has placeholder)
  ...

────────────────────────────────────────────────────
ISSUES TO FIX:
  🔴 CRITICAL: [Issue that breaks core functionality]
  🟠 HIGH: [Issue that affects significant users]
  🟡 MEDIUM: [Issue to address soon]
  ⚪ LOW: [Polish/optimization]

NEXT STEPS:
  • Fix CRITICAL issues immediately
  • Create tickets for HIGH/MEDIUM issues
  • Re-run /qa after fixes
```

## Step 4: Calculate Health Score

| Category | Weight | Points |
|----------|--------|--------|
| Functional | 40% | % checks passed |
| Visual | 20% | % checks passed |
| Performance | 20% | % metrics in target |
| Accessibility | 20% | % checks passed |

Score = weighted average × 100

| Score | Rating |
|-------|--------|
| 90-100 | EXCELLENT |
| 75-89 | GOOD |
| 60-74 | NEEDS WORK |
| < 60 | CRITICAL ISSUES |

## Step 5: Write QA Results to State

After calculating the score, write to shared state:

```bash
python3 -c "
import json
from datetime import datetime, timezone

with open('.agents/nose-state.json', 'r') as f:
    state = json.load(f)

# Replace with actual values from the test run
qa_score = 0   # calculated score 0-100
qa_rating = 'NEEDS_WORK'  # EXCELLENT / GOOD / NEEDS_WORK / CRITICAL_ISSUES

critical_failures = [
    # {'test': 'test name', 'description': 'what failed', 'category': 'functional'}
]
high_failures = []
medium_failures = []
low_failures = []

# Determine recommendation
if qa_score >= 85:
    recommendation = 'proceed'
    next_phase = 'ready_to_ship'
else:
    recommendation = 'fix_and_retest'
    next_phase = 'qa_failed'

state['qa_results']['score'] = qa_score
state['qa_results']['rating'] = qa_rating
state['qa_results']['recommendation'] = recommendation
state['qa_results']['iteration'] = state['qa_results'].get('iteration', 0) + 1
state['qa_results']['failures']['critical'] = critical_failures
state['qa_results']['failures']['high'] = high_failures
state['qa_results']['failures']['medium'] = medium_failures
state['qa_results']['failures']['low'] = low_failures

state['current_phase'] = next_phase
state['updated_at'] = datetime.now(timezone.utc).isoformat()
state['history'].append({
    'timestamp': datetime.now(timezone.utc).isoformat(),
    'phase': 'qa',
    'action': 'qa_complete',
    'detail': f'Score: {qa_score}/100 ({qa_rating}). Recommendation: {recommendation}'
})

with open('.agents/nose-state.json', 'w') as f:
    json.dump(state, f, indent=2)

print(f'QA complete. Score: {qa_score}/100. Recommendation: {recommendation}')
print(f'Next phase: {next_phase}')
"
```

## Orchestrator Signal

After writing state:

- **Score ≥ 85 (GOOD/EXCELLENT):** Phase → `ready_to_ship`. `/nose-orchestrator` auto-chains to `/ship`.
- **Score < 85 (NEEDS WORK):** Phase → `qa_failed`. `/nose-orchestrator` triggers `/nose-debug` → `/build` fix → re-test loop.
- **Max 2 QA fix iterations** — if score still < 85 after 2 iterations, escalate to user.

## NOSE URLs

- Local dev: `http://localhost:3000`
- Health check: `[URL]/health`
- API base: `[URL]/api/`
- Key pages: `/`, `/search`, `/perfume/[id]`, `/favorites`
