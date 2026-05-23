# /enhance-prompt — UI Prompt Enhancement

## Purpose
Transform vague UI ideas into polished, design-optimized prompts for better generation results.

## When to Use
- User gives a rough idea ("make it look better")
- Before sending a prompt to a design or code generation tool
- When prompts are returning generic or off-brand results

## Workflow

### Step 1: Analyze the Raw Prompt
Identify what's missing:
- No atmosphere or mood keywords
- Missing UI/UX context (mobile vs desktop, accessibility)
- No design system references
- Vague action verbs

### Step 2: Inject Keywords
Add specificity:
- **Atmosphere**: minimal, bold, playful, professional, dark mode
- **Layout**: grid, bento, card-based, list, hero-centered
- **Interaction**: hover states, micro-animations, scroll-triggered
- **Accessibility**: WCAG AA, keyboard-navigable, screen-reader friendly
- **Brand**: reference existing tokens from `DESIGN.md`

### Step 3: Structure the Output
```
[Context] — What this is and who it's for
[Visual Direction] — Style, mood, key aesthetics
[Layout] — Structure, responsive behavior
[Interaction] — States, animations, feedback
[Constraints] — Accessibility, performance, brand compliance
[Deliverable] — Expected output format
```

## Example

**Before:**
> "A settings page"

**After:**
> "A settings page for a perfume discovery app. Clean, minimal layout with a near-white canvas (`--color-bg-page: #fbfaff`). Left sidebar navigation with deep plum active states (`--violet-800`). Main content area uses card-based grouping with frosted glass surfaces (`--color-surface-card: rgba(255,255,255,0.78)`). Each setting has a toggle switch with smooth transition. Keyboard-navigable. Mobile-responsive: sidebar becomes bottom sheet on <768px."
