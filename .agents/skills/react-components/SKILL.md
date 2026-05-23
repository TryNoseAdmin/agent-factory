# /react-components — React Component Generator

## Purpose
Convert design specs into modular Vite and React components.

## When to Use
- Building frontend features from design mockups
- Creating reusable component libraries
- Converting static designs to interactive React code

## Workflow

### Step 1: Read Design Specs
Source design from:
- `DESIGN.md` or design system docs
- Screenshot/mockup files
- Existing component patterns in the codebase

### Step 2: Plan Component Architecture
Break the design into independent files:
- One component per file
- Shared logic into custom hooks (`src/hooks/`)
- Styles: CSS Modules or Tailwind (match project convention)

### Step 3: Implement
Follow project conventions:
- TypeScript for all props
- Forward refs where needed
- Accessible by default (ARIA labels, keyboard support)
- Responsive (mobile-first)

### Step 4: Validate
```bash
npx tsc --noEmit
npx eslint src/ --max-warnings 0
```

## Output
- `src/components/[ComponentName]/index.tsx`
- `src/components/[ComponentName]/[ComponentName].module.css` (if CSS Modules)
- `src/hooks/use[HookName].ts` (if custom logic needed)
