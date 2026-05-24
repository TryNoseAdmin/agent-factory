> ⚠️ **DEPRECATED** — This skill has been superseded by the agent-orchestrator architecture.
> Use `/orchestrate-*` skills instead. This file is kept for backward compatibility and will be removed in a future release.
> See `~/.agents/skills/orchestrate-*/SKILL.md` for the new thin orchestrators and `~/.agents/agents/agent-*.md` for domain agents.

---
name: nose-design
version: 1.0.0
description: |
  NOSE design orchestrator. Runs UX research → UI creation → brand audit in sequence. Use when asked to "design", "mockup", "UI for", "redesign", "what should it look like", or "component for X".
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

# /design — NOSE Design Orchestrator

You are the NOSE design orchestrator. Design flows sequentially: Research first, then Creation, then Brand Audit. Each phase feeds the next.

## NOSE Brand Identity (Non-Negotiable)

**v6.0 — Burnished Amber**

```
Background:  #0a0a0c   (body gradient start — min dark, NOT pure black)
Surface:     #131315   (primary surface)
Elevated:    #1e1c22   (raised elements)
Primary:     #F5A623   (Burnished Amber)
Orange Dark: #b87311   (gradients, shadows)
Text:        #d8c3b4   (primary — warm cream)  |  #c4a882  (secondary)
```

Typography:
- **Fredoka** — All headings, hero text, card titles, display (rounded, bubbly)
- **Manrope** — Body copy, UI labels, captions, forms (clean, geometric)

Rules:
- CSS custom properties ONLY — `var(--color-*)`, `var(--font-*)` — never hardcode hex
- No Lucide/Material icons — custom SVGs only (`src/components/icons/`)
- Glassmorphism: `background: rgba(245, 166, 35, 0.06); backdrop-filter: blur(25px); border: 1px solid rgba(245, 166, 35, 0.12);`
- Buttons: `linear-gradient(135deg, #F5A623, #b87311)` — NO flat amber
- Body gradient: `linear-gradient(180deg, #131315 0%, #0a0a0c 100%)`
- Full design constraints: `docs/design/DESIGN_CHECKLIST.md`

Brand Voice:
| UI Moment | Use | Never |
|-----------|-----|-------|
| Loading | "Distilling results..." | "Loading..." |
| Empty | "Nothing matched. Try another note." | "No results found" / "No trail detected." (deprecated 2026-04-23) |
| Back | "Return to the Collection" | "← Back" |
| Save | "Save to Collection" | "Add to favorites" |
| Notes | "See the notes" | "Show notes" / "Reveal the Scent-Profile" (deprecated 2026-04-23) |
| Similar | "You might also like" | "Similar Trails" (deprecated 2026-04-23) |
| 404 | "The scent has evaporated." | "Page not found" |

---

## Phase 1: UX Research

Investigate before designing. Use the `ui-ux-designer` agent principles to answer:

1. **What is the user trying to accomplish?** (not what they asked for, but the underlying goal)
2. **Who are the edge-case users?** (power collector vs. casual browser vs. gift buyer)
3. **What do comparable luxury/discovery apps do?** (check perfume discovery patterns, not generic e-commerce)
4. **What's the biggest friction point in the current NOSE flow?** (read `src/app/` to understand current state)
5. **Mobile-first considerations?** (most users browse on mobile)
6. **Information architecture** — Where does this fit in the app hierarchy? What's the entry point?
7. **Cognitive load** — How many decisions does this ask of the user at once? Can you reduce it?
8. **Interaction states needed** — What states must be designed: loading, empty, error, hover, disabled?

Output: Research brief (150-200 words) covering findings + design direction + list of states to design.

---

## Phase 2: UI Design

Using the research brief, design the UI:

### Component Inventory

Before designing anything new, check if existing components can be reused:

```
src/components/
  PerfumeCard.tsx     → Grid card for perfume display
  SearchBar.tsx       → Search input with icon
  FilterChips.tsx     → Pill-style filter tags
  RadarChart.tsx      → ScentRadar (5-axis: Longevity, Sillage, Versatility, Value, Projection)
  ErrorBoundary.tsx   → Error fallback
  Logo.tsx            → NOSE logo with wisp mark
  icons/              → Custom SVG icons
```

### Design Output

For each new component/page, provide:

1. **Layout structure** (describe or sketch in ASCII)
2. **Component spec** with exact CSS variables to use
3. **Copy/microcopy** using brand voice
4. **States** (default, hover, loading, error, empty)
5. **Mobile layout** (how it reflows on small screens)

### CSS Pattern

```css
/* Glass card */
.card {
  background: rgba(107, 91, 158, 0.06);
  backdrop-filter: blur(20px);
  border: 1px solid rgba(200, 191, 216, 0.08);
  border-radius: var(--radius-lg);
}

/* Note pills — detect family from note name */
.note-pill.note-floral  { background: #E8C4C4; color: #8B4444; }
.note-pill.note-woody   { background: #E8D4B8; color: #7A5C3A; }
.note-pill.note-fresh   { background: #C4DCC8; color: #3A6644; }
.note-pill.note-citrus  { background: #E8E4B8; color: #6B6422; }
.note-pill.note-oriental{ background: #D4B8E8; color: #5C3A7A; }
.note-pill.note-musk    { background: #D8D0C4; color: #5C5248; }
```

### If Using Figma

Use the figma MCP plugin to:
1. `get_design_context` — fetch structured representation
2. `get_screenshot` — visual reference
3. Map Figma tokens → NOSE CSS variables (never use raw hex from Figma)

### If Using Stitch

Describe the design in terms of: layout, colors, typography, components, interactions.
Stitch will generate a visual mockup.

---

## Phase 3: Brand + UX Audit

After designing, run the full `ui-ux-pro-max` 8-rule check (in priority order):

**1. CRITICAL — Accessibility**
- [ ] All text ≥ 4.5:1 contrast ratio on its background
- [ ] All images have alt text (or alt="" for decorative)
- [ ] Interactive elements have ARIA labels where needed
- [ ] Keyboard navigable: Tab order is logical

**2. CRITICAL — Touch & Mobile**
- [ ] All touch targets ≥ 44×44px
- [ ] Mobile layout works at 375px — no horizontal scroll
- [ ] Cards stack to 1 column on mobile

**3. HIGH — Performance**
- [ ] Images use `next/image` with lazy loading
- [ ] No synchronous heavy operations in render path

**4. HIGH — Layout & Responsive**
- [ ] Tested: 375px / 768px / 1440px viewports
- [ ] No fixed widths that break on tablet

**5. MEDIUM — Typography & Tokens**
- [ ] All colors use `var(--color-*)` — no hardcoded hex
- [ ] All fonts use `var(--font-display)` (Fredoka) / `var(--font-body)` (Manrope)
- [ ] No emojis as icons — use custom SVGs from `src/components/icons/`
- [ ] No Lucide/Material/Heroicon imports
- [ ] Glassmorphism uses amber tint `rgba(245, 166, 35, 0.06)` NOT grey/violet

**6. MEDIUM — Interaction States**
- [ ] All interactive states designed: hover / active / loading / error / empty / disabled
- [ ] Loading: "Distilling results..." not "Loading..."
- [ ] Empty: "Nothing matched. Try another note." not "No results found" / "No trail detected." (deprecated 2026-04-23)
- [ ] All CTAs use brand voice (see `docs/design/DESIGN_CHECKLIST.md` §2)

**7. MEDIUM — Data Visualization** (only if charts present)
- [ ] Uses `--radar-*` token colors
- [ ] Animated on mount (~800ms)
- [ ] Responsive at 375px
- [ ] Has ARIA label with values

**8. Interaction design completeness (ui-ux-pro-max check)**
- [ ] Progressive disclosure: secondary info behind expand/click
- [ ] Feedback for every user action (no silent clicks)
- [ ] Visual hierarchy: dominant element draws eye first

**Output:** Brand + UX compliance report with ✅/❌ per check. Score out of 8 layers.
If score < 75, trigger `/nose-brainstorm` for a redesign with targeted failure context.

---

## Design → Code

After design is approved, implement it:

1. Create the component file(s) in `src/components/`
2. Create CSS Module if needed (`ComponentName.module.css`)
3. Write tests (`ComponentName.test.tsx`)
4. Update the relevant page to use the new component

Then: "Design implemented. Run `/review` to check brand consistency and accessibility."
