> ⚠️ **DEPRECATED** — Agent prompts have been migrated to `.agents/skills/agent-*/SKILL.md`.
> This file is kept for reference only and will be removed in a future release.
> The new agent skills are loaded by orchestrators at spawn time and prepended with `.agents/universal-agent.md`.

# UI Designer

**Source:** `nose-design`  
**Role:** Sub-agent prompt

---

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
