# ExpIn

**Status**: Bootstrapped  
**Type**: Product — Expense tracking via SMS/MMS  
**Stack**: Next.js 15, Supabase, Twilio, Claude 3.5 Sonnet, Tailwind + shadcn/ui  

## Repositories
| Repo | Path | Purpose |
|------|------|---------|
| Brain | `~/Documents/GitHub/Trynose/expin` | Docs, state, memory, plans |
| Frontend | `~/Documents/GitHub/Trynose/expin-fe` | Next.js app — webhooks, dashboard, API routes |

## Key Files
- `expin/PROJECT.md` — Brand voice, design tokens, epics
- `expin/docs/TECH_STACK.md` — Full stack + data flow
- `expin/docs/PROJECT_BRIEFING.md` — Vision, target market, MVP scope
- `expin-fe/app/api/webhook/twilio/route.ts` — Twilio MMS webhook (future)

## Integrations
- QuickBooks Online (planned)
- Xero (planned)

## Notes
- Single workspace MVP first
- Auth via Supabase magic link
- Edge Runtime for webhooks where possible
