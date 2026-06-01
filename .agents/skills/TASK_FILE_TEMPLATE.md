# Task File Template

**Copy this template for every agent task. One file = one agent.**

---

```markdown
# Task: [short descriptive name]

## Agent Type
[agent-frontend-dev | agent-backend-dev | agent-database-dev | agent-reviewer-engineering | agent-qa-functional | ...]

## Scope

### What to Do
[Numbered list of specific deliverables. Be exact.]
1. Implement the dashboard page at `/dashboard` with expense stats cards
2. Add mobile bottom navigation to `DashboardShell.tsx`
3. Wire up Supabase query for recent receipts

### What NOT to Do
[Explicit exclusions. Prevents scope creep.]
- Do NOT build the receipts detail page (that's TASK-002)
- Do NOT add real-time subscriptions
- Do NOT modify the auth flow

## Files to Read Before Starting
- `app/dashboard/page.tsx` — existing placeholder
- `components/layout/DashboardShell.tsx` — layout shell
- `lib/supabase.ts` — client config
- `docs/DESIGN.md` — design system tokens

## Acceptance Criteria
- [ ] Dashboard shows 3 metric cards (total, pending, failed)
- [ ] Recent receipts list shows last 10 items
- [ ] Mobile bottom nav visible at <640px
- [ ] All colors use design tokens — zero hardcoded hex
- [ ] Build passes (`npm run build`)
- [ ] ESLint passes (`npx eslint app/ components/ lib/ --max-warnings 0`)

## Constraints
- Next.js 15 App Router, TypeScript strict
- Tailwind CSS only — no inline styles
- shadcn/ui components where applicable
- Mobile-first responsive
- All amounts use `font-variant-numeric: tabular-nums`

## Output Format
```
Status: [COMPLETE | PARTIAL | BLOCKED]
Files modified: [list]
Tests: [passing / failing — counts]
Build: [PASS / FAIL]
Lint: [PASS / FAIL]
Notes: [blockers, design decisions, follow-ups]
```

## Notes
- The `MetricCard` component already exists at `components/receipts/MetricCard.tsx` — reuse it
- Empty state copy: "Your team hasn't texted any receipts yet."
- Receipt data shape: `{ id, vendor_name, amount, category, created_at, integration_status }`
```

---

## Rules for the Orchestrator

1. **One agent = one task file.** Never give an agent >3 major responsibilities.
2. **File name:** `TASK-001-[domain]-[short-name].md` or `REVIEW-001-[domain].md` or `QA-001-[type].md`
3. **Location:** `PROJECT:repo/.agents/tasks/`
4. **Spawn prompt:** One-liner pointing to the file. Nothing else.
5. **If task file is missing:** Agent reports `BLOCKED` and stops.
