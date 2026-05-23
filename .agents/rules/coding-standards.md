# Coding Standards — Universal Rules

Extracted from `AGENTS.md`. These apply to all code changes across `nose`, `nose-fe`, and `nose-be`.

---

## Surgical Changes — The One-Line Rule

**Every changed line should trace directly to the user's request.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it — don't delete it.
- Remove imports/variables/functions only if YOUR changes made them unused.

**The test:** if you can't explain why a changed line is needed to satisfy the request, revert it.

---

## Goal-Driven Execution

Transform vague imperatives into verifiable goals before implementing:

| Instead of… | Transform to… |
|---|---|
| "Add validation" | "Write tests for invalid inputs, then make them pass" |
| "Fix the bug" | "Write a test that reproduces it, then make it pass" |
| "Refactor X" | "Ensure tests pass before and after" |
| "Improve performance" | "Measure baseline, define target (e.g. p95 < 200ms), verify after" |
| "Make this accessible" | "Run axe-core + keyboard nav audit, define pass criteria, verify" |

For multi-step tasks, state the plan as: `[Step] → verify: [check]`.

---

## Frontend (Next.js 15 / React)

### Stack
- Next.js 15 App Router only. No `pages/` directory.
- TypeScript with strict mode.
- CSS Modules + Tailwind. No inline styles for colors or spacing.
- Custom SVGs only. No Lucide, Heroicons, FontAwesome, or emoji as UI icons.
- Inter font only. No Playfair Display, JetBrains Mono, Fredoka, or Manrope.

### Design Token Source of Truth
Three sheets loaded in `src/app/layout.tsx` in this order:
1. `src/styles/tokens.css` — primitive + semantic palette
2. `src/styles/components.css` — `.btn`, `.card`, `.chip`, `.badge`, `.input`, `.modal`, `.alert`, etc.
3. `src/styles/tokens.brand-extension.css` — note family pastels + ScentRadar axes
4. `src/app/globals.css` — compat shim for legacy token names

**Never hardcode colors, spacing, or font values outside these files.**

### Styling Rules
- **CSS custom properties only** — `var(--color-*)`, `var(--space-*)`, `var(--radius-*)`, `var(--control-*)`, `var(--violet-*)`, `var(--font-sans)`
- **Never hardcode hex colors** — always use CSS tokens
- **Glass — single tier:** use `.card` class (white frosted) or `.surface-solid` (opaque over photography). Never reintroduce dark-smoky glass (`rgba(30, 25, 35, X)`).
- **Dark backdrop exception:** when a dark background is genuinely needed, set `color: var(--color-text-inverse, #ffffff)` explicitly.
- **No inline styles** for colors or spacing — use CSS classes or tokens.
- **CSS Modules** for component-specific styles.

### Typography — Inter only
```css
--font-sans: "Inter", "SF Pro Display", system-ui, -apple-system, sans-serif;
--font-mono: ui-monospace, "SF Mono", Menlo, Consolas, monospace;
```
Brand-moment emphasis comes from weight (800) + scale, not a serif family.

### Interactive Element Sizing (3-Tier System)

| Size | Token | Height | Padding | Font | Use Cases |
|------|-------|--------|---------|------|-----------|
| **sm** | `--control-height-sm` | 32px | `0 12px` | 0.75rem | Chips, icon buttons |
| **md** | `--control-height-md` | 40px | `0 20px` | 0.875rem | Secondary buttons, ghost |
| **lg** | `--control-height-lg` | 48px | `0 24px` | 0.875rem | Primary CTAs, form inputs |

**Never hardcode** button/input heights. Always use `var(--control-height-*)`.
The hero search pill (58px) is the **only exception**.

### Note Pill Color System
Detect scent family from note name and apply class:

```tsx
function getNoteFamily(note: string): string {
  const n = note.toLowerCase();
  if (/rose|jasmine|lily|iris|violet|peony|tuberose/.test(n)) return 'floral';
  if (/wood|cedar|sandalwood|oud|oak|pine|vetiver/.test(n)) return 'woody';
  if (/lemon|orange|bergamot|grapefruit|lime|citrus/.test(n)) return 'citrus';
  if (/fresh|green|grass|mint|aqua|marine|sea/.test(n)) return 'aquatic';
  if (/amber|vanilla|musk|incense|resin/.test(n)) return 'musk';
  if (/spice|pepper|cardamom|cinnamon|clove/.test(n)) return 'oriental';
  if (/caramel|honey|chocolate|almond|praline/.test(n)) return 'gourmand';
  return 'fresh';
}
// Apply as: <span className={`note-pill note-${getNoteFamily(note)}`}>{note}</span>
```

### What NOT To Do (Frontend)
- ❌ Never use `#7A1A23` (Crimson Fig), `#C5A059` (Aura Gold), `#b76e9b` (v4.0 pink-mauve), `#1A1825` / `#1c1a20` (v4.0 dark navy-violet) — all deprecated.
- ❌ Never use pure black `#000000` or `#0D0D0D` as backgrounds.
- ❌ Never use Playfair Display, JetBrains Mono, Fredoka, or Manrope. **Inter only.**
- ❌ Never reintroduce a dark glass tier. Single white glass.
- ❌ Never add Lucide, Heroicons, or FontAwesome.
- ❌ Never hardcode font families — use `var(--font-sans)`.
- ❌ Never let `--color-text` resolve onto a dark surface. Set `color: var(--color-text-inverse, #ffffff)` explicitly on every intentionally-dark button / pill / dismiss chip.
- ❌ Never use the warm display gradient (`--gradient-display`, pink → orange → gold) on headings, CTAs, body text, or brand surfaces. It's reserved for at most ONE data moment per page (price callout, hero stat).

---

## Backend (FastAPI / Python)

- Pydantic v2 for all schemas.
- SQLAlchemy 2.0 style with async sessions.
- Alembic for migrations. Every model change needs a migration.
- Fail loud — no silent catch-all exceptions.

---

## Multi-Repo Routing

| Work Type | Repo | Local Path |
|-----------|------|------------|
| UI / React / TypeScript | `nose-fe` | `~/Documents/GitHub/Trynose/nose-fe` |
| API / Python / DB | `nose-be` | `~/Documents/GitHub/Trynose/nose-be` |
| Skills / docs / state | `nose` | `~/Documents/GitHub/Trynose/nose` |

---

## Frontend Verification — Browser + DevTools (Mandatory)

Every frontend code change MUST be visually verified in a real browser. Code review without browser inspection is incomplete.

### Required Checks

1. **Visual Inspection**
   - Navigate to the affected page/route
   - Verify layout, spacing, colors, typography match design tokens
   - Test hover, focus, active states
   - Test responsive breakpoints (mobile, tablet, desktop)
   - Check dark mode if applicable

2. **Chrome DevTools — Network Tab**
   - Verify API calls fire correctly
   - Check request payloads are well-formed
   - Verify response status codes (200, 400, 401, 500)
   - Check response payload structure
   - Verify no duplicate or unnecessary requests

3. **Chrome DevTools — Console**
   - Zero console errors (red)
   - Zero unhandled promise rejections
   - Zero React warnings (yellow acceptable if legacy)
   - No 404s for assets, fonts, or images

4. **Chrome DevTools — Performance**
   - First Contentful Paint < 1.5s
   - Largest Contentful Paint < 2.5s
   - No layout shifts (CLS < 0.1)
   - No long tasks (>50ms) on main thread

5. **Chrome DevTools — Elements**
   - Verify computed styles match tokens (no hardcoded values)
   - Check accessibility tree (labels, roles, states)
   - Verify DOM structure is semantic

### Tools
- `/browse` skill — headless browser navigation and interaction
- Chrome DevTools MCP — network, console, performance, elements inspection
- Playwright — E2E verification (automated)

### Anti-Pattern
❌ "The code looks correct, shipping it."
✅ "Code passes lint, browser renders correctly, network calls succeed, console is clean, performance is within budget."
