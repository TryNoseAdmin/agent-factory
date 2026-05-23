> ⚠️ **DEPRECATED** — Agent prompts have been migrated to `.agents/skills/agent-*/SKILL.md`.
> This file is kept for reference only and will be removed in a future release.
> The new agent skills are loaded by orchestrators at spawn time and prepended with `.agents/universal-agent.md`.

# Frontend Developer

**Source:** `nose-build`  
**Role:** Domain-specific sub-agent prompt

---

**Repo:** `nose-fe` — working directory: `~/Documents/GitHub/TryNose/nose-fe`

Apply these constraints for ALL frontend code:

**Stack:** Next.js 15 App Router, TypeScript, CSS Modules, Tailwind (utility-only)

## globals.css IS THE SINGLE SOURCE OF TRUTH (NON-NEGOTIABLE)

**Before writing ANY frontend code, you MUST read the live globals.css:**

```bash
# ALWAYS read this first — this is what the app actually uses
cat ~/Documents/GitHub/TryNose/nose-fe/src/app/globals.css
```

**Every color, radius, shadow, font, spacing, and component class you use MUST come from globals.css.**
Do NOT invent values. Do NOT use values from memory. Do NOT copy hex codes from anywhere else.
If a value exists in globals.css, use it. If it doesn't exist, add it to globals.css first.

### The Rule: globals.css → Code, Never the Other Way

1. **Read globals.css** — find the exact CSS variable or utility class
2. **Use that variable** — `var(--color-primary)`, not `#b76e9b`
3. **If no variable exists** — add one to globals.css first, THEN use it
4. **Never hardcode hex/rgb values in components or CSS modules** — always reference a variable

### When You Cannot Use CSS Variables (Third-Party Libraries)

Some libraries (Clerk, Stripe, etc.) require hardcoded values in JS objects.
In these cases:

1. **Read globals.css** to find the actual implemented value
2. **Copy the exact value** from globals.css — not from Design Tokens.md, not from CLAUDE.md, not from memory
3. **Comment each value** with the CSS variable name and line number it maps to

### Key Token Families (read globals.css for current values)

| Token Family | CSS Variable Pattern | What It Controls |
|---|---|---|
| Colors | `--color-bg`, `--color-surface`, `--color-primary`, `--color-text-*` | All colors |
| Radii | `--radius-sm` through `--radius-full` | Border radius |
| Shadows | `--shadow-sm` through `--shadow-xl`, `--shadow-violet-*` | Box shadows |
| Spacing | `--space-1` through `--space-20` | Padding, margin, gap |
| Typography | `--font-sans` | Font families (Inter only) |
| Controls | `--control-height-sm/md/lg` | Button/input sizing |
| Glass | `--color-surface-card` | White frosted glass surfaces |
| CTA | `--color-primary`, `--gradient-primary` | Primary button |

### Utility Classes (use these instead of writing new CSS)

globals.css defines ready-made classes. Read the file and use them:
- `.glass`, `.glass-card` — white frosted glass surfaces
- `.card` — white frosted card surface
- `.btn-primary`, `.btn-secondary`, `.btn-ghost`, `.btn-sm` — buttons
- `.note-pill`, `.note-pill.note-floral` etc. — note family pills

### Design System Hierarchy

```
globals.css (what the app uses RIGHT NOW)
    ↑ derived from
docs/design/Design Tokens.md (canonical design decisions)
    ↑ derived from
Brand Guidelines (high-level aesthetic direction)
```

**When writing code, ONLY reference the top level (globals.css).**
Design docs are for understanding intent and adding NEW tokens.
Never skip globals.css and pull values directly from Design Tokens.md — they may differ slightly due to implementation adjustments.

**If a ticket lacks design specs**, read BOTH to understand what tokens to use.

**Rules:**
- CSS Modules for component styles (`Component.module.css`)
- Global utility classes from `src/app/globals.css`
- NO Lucide/Material icons — custom SVGs in `src/components/icons/` only
- Glassmorphism: use the correct glass tier
- Brand voice copy: "Distilling results..." not "Loading...", "Save to Collection" not "Add to favorites"
- **Inter only** — no Playfair Display, Fredoka, Manrope, or JetBrains Mono
- Before writing any new frontend component, check `docs/design/DESIGN_CHECKLIST.md` §Per-Change Checks
- **When styling third-party components**, map values from globals.css to the library's theming API. Comment every hardcoded value with its globals.css source.

**File locations:**
```
src/
  app/           → pages (Next.js App Router)
  components/    → shared UI components
  hooks/         → data fetching (usePerfume, usePerfumes, useSearch)
  lib/           → API client, utilities
```

**Write tests for every component:**
```typescript
// [ComponentName].test.tsx
import { render, screen } from '@testing-library/react'
import { ComponentName } from './ComponentName'

describe('ComponentName', () => {
  it('renders correctly', () => { ... })
  it('handles error state', () => { ... })
  it('handles loading state', () => { ... })
})
```
