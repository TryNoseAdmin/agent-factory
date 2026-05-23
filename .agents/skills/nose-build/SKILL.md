> ⚠️ **DEPRECATED** — This skill has been superseded by the agent-orchestrator architecture.
> Use `/orchestrate-*` skills instead. This file is kept for backward compatibility and will be removed in a future release.
> See `.agents/skills/orchestrate-*/SKILL.md` for the new thin orchestrators and `.agents/agents/agent-*.md` for domain agents.

---
name: nose-build
version: 2.0.0
description: |
  NOSE build orchestrator. Reads a Notion ticket, routes to domain-specific agents (frontend, backend, database), and implements with TDD throughout. Use when asked to "build TASK-XXX", "implement", "start coding", "develop this feature", or "let's code".
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

# /build — NOSE Build Orchestrator (v2.1 — anti-fabrication gate added)

You are the NOSE build orchestrator. Your job is to read a ticket, understand the scope, and implement it using domain-specific agents with TDD throughout — writing all progress to shared state so the orchestrator can track and auto-chain.

**State file:** `~/Documents/GitHub/TryNose/nose/.agents/nose-state.json`
**Coding Standards:** `~/Documents/GitHub/TryNose/nose/docs/CODING_STANDARDS.md` — read and internalize before writing any code.

---

## 🚧 NON-NEGOTIABLE: Anti-Fabrication Gate (read FIRST)

**This gate exists because of a real failure on 2026-05-02 — see `memory:feedback_no_fabricated_external_claims`. The build step is where the costliest version of fabrication happens: code gets shipped that claims to do something it doesn't.**

### Rule 1 — Documentation MUST match implementation

If a docstring, comment, or PR description claims a behavior, the diff MUST contain code that produces that behavior. **No "intent" comments without backing code.**

Examples of what's banned:
- A docstring saying "uses prompt caching via cache_control" with NO `cache_control` field in the diff
- A PR title "cache-friendly prompt" when the only "cache" reference is a comment
- A function named `enableXFeature()` whose body is a single `return null`
- Tests that "cover" a feature by asserting a constant, not the behavior

**If the gate catches you mid-build:** either implement the behavior properly, OR delete the claim and mark the work as scoped-down. Never ship doc-only features.

### Rule 2 — External API claims need citations BEFORE you write the integration

Before writing code that depends on a third-party API feature (caching, batch, tools, streaming, file upload, model-specific params), you MUST:

1. **WebFetch the provider's actual docs** (not Anthropic's, not OpenAI's — the specific provider you are targeting)
2. **Paste the relevant docs quote** as a code comment or commit-message paragraph next to the integration
3. **Or mark the integration as `[UNVERIFIED — TODO confirm with provider docs]`** — and the PR description must list this as a known caveat

**Forbidden inferences:**
- "Provider X is OpenAI-compatible, so it must support feature Y" — verify Y specifically
- "Provider X has model Y similar to Anthropic's Sonnet, so pricing must be similar" — fetch the pricing page
- "I remember from the brainstorm that the savings are N%" — re-verify; brainstorm output is hypothesis, not fact

### Rule 3 — Build cannot proceed on fabricated brainstorm/plan claims

If the upstream `/nose-brainstorm` or `/nose-plan` output contains claims marked `[UNVERIFIED]`, the build step MUST do ONE of:

- **Verify the claim now** (WebFetch + paste quote in commit message)
- **Scope the claim out of this PR** (move to a follow-up ticket)
- **STOP and ask the user** which of the above to do

Do NOT silently implement an unverified claim and hope it works.

### Rule 4 — When the user asks "is this real?", answer with evidence

If the user questions a claim during/after build, the response MUST be evidence-first:
- ✅ "Per Moonshot docs at <URL> as of <date>: <quote>"
- ✅ "Measured locally: <command> returned <output>"
- ❌ "I think it works because <plausible-sounding inference>"

If you can't produce evidence in 60 seconds, say "I can't verify that — let me WebFetch the docs" and actually fetch them.

---

## Coding Standards Gate (NON-NEGOTIABLE)

Before writing any code, verify every item below. These are not suggestions — they are enforced rules.

### Architecture
- [ ] UI / API / DB logic isolated — no mixing layers
- [ ] Business logic in services layer, NOT in route handlers or components
- [ ] Components use hooks — no direct API/DB calls in React components
- [ ] Route handlers only: validate → call service → return response

### Code Quality (per function/class written)
- [ ] Single responsibility — one function = one purpose
- [ ] Max 30 lines per function — split if longer
- [ ] Max nesting depth 3 — use early returns to flatten
- [ ] No magic numbers — use named constants
- [ ] No hardcoded values — use env vars or config constants
- [ ] Descriptive names — no `data`, `temp`, `thing`, `handle`
- [ ] No duplicate logic — DRY, extract shared logic

### Error Handling (every function that can fail)
- [ ] Structured try/catch — never empty catch blocks
- [ ] Meaningful error messages with context (what failed, what ID/input)
- [ ] Fail fast on critical errors — don't swallow and continue
- [ ] Errors propagate properly — caller knows something failed

### Logging (every service/route function)
- [ ] nose-be: use `structlog` — `logger.info/warning/error/debug`
- [ ] nose-fe: no `console.log` in components — use error boundaries
- [ ] Log key actions at INFO: "Perfume fetched", "Search executed"
- [ ] Log failures at ERROR with context: id, user, error message
- [ ] No `print()` statements in Python — ruff will catch this

### Testing (every new function/component)
- [ ] Unit tests for all service functions
- [ ] Integration tests for all API routes
- [ ] Component tests for all new React components
- [ ] Tests are independent — no shared state between tests
- [ ] Tests verify behavior, not implementation details

### Security
- [ ] All user inputs validated (Pydantic schemas in BE, types in FE)
- [ ] No secrets, tokens, or passwords in code
- [ ] SQL queries use ORM/parameterized — no string concatenation
- [ ] No sensitive data logged

### Documentation
- [ ] JSDoc on every exported FE function/hook/component
- [ ] Docstring on every BE service function and route
- [ ] Purpose + params + return documented

### YAGNI / KISS
- [ ] No speculative abstractions — build exactly what the ticket requires
- [ ] No "just in case" parameters or config flags
- [ ] Simplest solution that passes the acceptance criteria

---

## Step 0: Read State

Always read state first before doing anything:

```bash
if [ -f .agents/nose-state.json ]; then
  cat .agents/nose-state.json
else
  echo "No state file found. Initialize with /nose-plan first."
fi
```

Check:
- `current_phase` — should be `ready_to_build` or `build` or `fix` (for review feedback loop)
- `ticket_id` — if set, use it; otherwise use what user provided
- `ticket_notion_page_id` / `ticket_notion_url` — Notion pointers set by `/nose-plan` or `/nose-ticket`
- `review_feedback` — if `current_phase == "fix"`, this contains issues to fix

## Step 1: Read the Ticket from Notion

**The plan lives in the Notion ticket body. Never read `docs/plans/`** — that directory is retired.

If the ticket ID or Notion page ID is known:
1. Check state for `ticket_notion_page_id` first (set by `/nose-plan`).
2. If missing, search Notion via `mcp__claude_ai_Notion__notion-search` inside the Sprint Tracker data source `collection://847f3552-71bb-430b-9f52-f6b6938670ab` with `query: "TASK-XXX"`.
3. Fetch the ticket with `mcp__claude_ai_Notion__notion-fetch` using the page ID.
4. Read:
   - **Properties** — `What to Do`, `How to Do`, `Success Criteria`, `Files Affected`, `Dependencies`, `Parent Epic`, `Priority`, `Feature Area`, `Effort (hours)`, `Week`.
   - **Content body** — the `## §Full Plan` section (if present) contains the synthesized architecture / design / SEO / acceptance-criteria detail.
5. Treat acceptance criteria (from `Success Criteria` property + any `Acceptance Criteria` checklist in the body) as the build target. Every criterion must be satisfied before `/nose-ship`.

If called in **fix mode** (orchestrator sent you after review failures):
- Read `state.review_feedback.critical` and `state.review_feedback.high`
- Focus ONLY on fixing those specific issues
- Do not add new features during a fix pass

If no ticket ID, ask: "What are we building? Share the TASK number or describe the feature."

## Step 1.5: Design System Contract Gate (NON-NEGOTIABLE for FE work)

If this ticket touches frontend UI (new page, new component, restyling, any change under `src/app/` or `src/components/` in `nose-fe`), the **Notion ticket body** MUST contain a **Design System Contract** table — element → utility class + CSS variable tokens (see `/nose-plan` and `/nose-ticket` for the exact schema). Plans no longer live in `docs/plans/` — the ticket body IS the plan.

**Before writing any code, verify ALL of the following:**

1. **Contract exists in Notion.** Fetch the ticket via `mcp__claude_ai_Notion__notion-fetch`. Find the "Design System Contract" section in the body (or under `## §Full Plan` → `### Design Direction`).
2. **Contract uses token names, not raw hex.** Every cell must reference a `var(--...)` token or a utility class name — never an inline hex or `rgba(...)`.
3. **Every referenced token exists in tokens.css.** Read `~/Documents/GitHub/TryNose/nose-fe/src/styles/tokens.css` (and `tokens.brand-extension.css`) and grep for each token the contract cites. If any are missing, they must be added to tokens.css FIRST (or the contract must be corrected).

**If the contract is missing:**
```
STOP. Do not write any FE code. Output:

"This ticket has frontend work but no Design System Contract. I will not improvise tokens — that's what broke the profile page on 2026-04-17.

Please run one of:
  /nose-plan                                        (re-synthesize into the Notion ticket body)
  /nose-ticket update TASK-XXX design-spec          (add contract to the Notion ticket directly)

The contract must map every element (cards, CTAs, headings, pills, icons) to a utility class + CSS variable token from nose-fe/src/styles/tokens.css. No raw hex. No rgba literals."

Then exit the skill.
```

**If the contract cites tokens not in globals.css:**
```
STOP. Output:

"Design contract references tokens not in globals.css: [list]. 
Two options:
  1. Add these tokens to src/app/globals.css first, then re-run /nose-build
  2. Update the contract to use existing tokens from globals.css

Pick one."

Then exit the skill.
```

**Only after the contract is present and valid** may you proceed to Step 2. Do not silently fall back to raw hex, inline styles, solid-white glass, or Lucide icons. The purpose of this gate is to eliminate the waste cycle of plan → build wrong → review → fix.

**Backend-only / non-UI tickets:** skip this gate. Note in state: `design_contract_gate: "n/a — no UI changes"`.

## Step 1.6: Backend External-Data & Queue Gate (NON-NEGOTIABLE)

**This gate fires whenever the ticket touches ANY of:**
- External feed ingestion (XML/JSON/CSV from third parties — Cuelinks, OBF, Amazon, retailer APIs, webhooks)
- Remote content download or re-host (images, PDFs, files from URLs we don't control)
- Background workers / job queues / cron tasks
- Any `httpx` / `requests` / `boto3` call whose target host is not fully controlled by us

**If ANY of those apply, every item below MUST be true before writing code. Add a TodoWrite task for each unchecked item.** Hard-learned from TASK-050 review — don't repeat.

### Parsing untrusted input
- [ ] XML: use `defusedxml.ElementTree.fromstring` — NEVER stdlib `xml.etree.ElementTree` on external bytes. `defusedxml` is in `requirements.txt`; if not, add it
- [ ] Wrap `fromstring` in `try/except ET.ParseError` with structured log including feed URL + byte length + first 200 bytes snippet (sanitized)
- [ ] JSON: use Pydantic `.model_validate(dict)` — never `json.loads(...)` + bare `.get()` chains on untrusted payloads

### URL handling (SSRF + open-redirect prevention)
- [ ] Any URL from an external source is passed through a shared validator BEFORE fetching. The validator MUST reject: non-`https` schemes, RFC1918 private ranges, loopback, link-local (`169.254/16`), metadata endpoints, and hosts not on an explicit retailer/feed allowlist
- [ ] `httpx.AsyncClient(..., follow_redirects=False)` — or if redirects are needed, re-validate each target. Never trust `Location` headers from untrusted hosts
- [ ] Affiliate links / retailer URLs are re-validated before writing to DB — the field flows to end users, so `javascript:`/`data:` schemes must be rejected at the boundary

### Downloading remote content
- [ ] Stream responses with a `max_bytes` cap (e.g. 10 MB for images, 50 MB for feeds). Read via `httpx.stream(...)` and accumulate until cap; abort past it
- [ ] Content-type determined by **magic-byte sniff** on the first 8–12 bytes — NEVER trust the `Content-Type` response header. JPEG=`\xff\xd8\xff`, PNG=`\x89PNG`, WebP=`RIFF…WEBP`, GIF=`GIF8`. Reject anything else for image pipelines
- [ ] Before uploading to our CDN (R2): re-check key does not contain `..` segments, slashes must only appear as path separators at positions we generated

### External field values written to DB
- [ ] Enum-validate any string field whose values are consumed by our code (`retailer`, `currency`, `status`) — reject or coerce to a sentinel
- [ ] Length-cap any free-text field at a sane bound (e.g. `name ≤ 200 chars`) at the boundary, not in the UI
- [ ] Never persist raw feed values to a user-facing column without going through a validator

### Async correctness
- [ ] If any function in the module is `async def`, ALL HTTP calls in its transitive call graph must be `await client.get(...)` on `httpx.AsyncClient` — **never** blocking `httpx.get()`. Blocking I/O in an async event loop stalls every other request
- [ ] If mixing sync + async (e.g. sync SQLAlchemy `Session` + async httpx), document WHY inline and keep the boundary at function granularity, not line granularity
- [ ] DB: if the repo uses `AsyncSession` elsewhere, use it here too — don't silently introduce a sync `Session` in a new worker

### Queue / worker completeness (if building a job system)
If the ticket creates or extends a queue (`enrichment_jobs`, `tasks`, etc.), ALL of the following must ship in the same PR:
- [ ] **Run-loop** that claims → dispatches → marks complete/failed in a bounded loop
- [ ] **Dispatch table** — explicit `{"job_type_a": handler_a, "job_type_b": handler_b}` mapping. No `eval`, no dynamic imports
- [ ] **SKIP LOCKED** claim using `UPDATE … WHERE id = (SELECT … FOR UPDATE SKIP LOCKED LIMIT 1) RETURNING *` — single atomic statement, hydrate ORM from the `RETURNING` row. No commit-then-re-SELECT (race window)
- [ ] **Exponential backoff** on failure + **max_attempts** → permanent `failed` state
- [ ] **Stale-lock reaper** for crashed workers (single UPDATE on `locked_at < NOW() - interval`)
- [ ] **Handler idempotency** — re-running the same job must not duplicate effects. Dedup by a natural key on every append (e.g. `(retailer, sku_id)` in a JSONB list)
- [ ] **Per-run summary log** — after a batch, emit one structlog event with `Counter` rollups per dimension the AC names (e.g. `per_merchant`, `matched`, `missed`, `errors`)

Required tests in the same PR:
- [ ] Two-worker concurrency — assert only one wins the same row (SKIP LOCKED contract)
- [ ] Retry exhaustion — handler fails N times → job transitions to `failed` and stops being picked up
- [ ] Stale-lock reaper — lock older than threshold → row resets to `pending`
- [ ] Each handler — happy path + validation-error path + missing-row path
- [ ] Idempotency — run same job twice → DB state is identical to running once

### JSONB payloads
- [ ] Every distinct `job_type` / `event_type` / `payload` shape has a Pydantic model. Validate with `Model.model_validate(payload)` as the first line of the handler
- [ ] Validation errors → `mark_failed` with a permanent-fail sentinel (do not retry — the payload will never become valid)

### No global mutable state
- [ ] No module-level `_cache = ...` dict/list that handlers mutate. Use a class with DI, `functools.lru_cache` on a pure-input function, or pass the cache through an explicit parameter
- [ ] If a feed must be cached process-wide, own the lifecycle in a `FeedLoader` class whose instance is passed into the worker — testable + swappable

### Parser / transformer behavior tests
- [ ] Tests assert user-facing behavior, not implementation side effects. `_parse_price("₹2,399.00")` → `2399` (rupees), NOT `239900`. If the test comment says "caller decides scale," find the caller and test end-to-end — or fix the parser
- [ ] Round-trip where applicable: `parse(render(x)) == x`

### Pilot / acceptance gate tests
- [ ] Fixtures must NOT be index-aligned with expected outputs. If `perfumes[i]` is paired only with `candidates[i]` via `zip()`, the test doesn't measure discrimination. Shuffle + assert that each perfume finds its correct match from the full candidate pool
- [ ] Gates must penalize false positives. A matcher that matches everything to everything must fail the test, not pass it

### Dependencies
- [ ] New packages in `requirements.txt` with `>=` are OK only if the repo has a lockfile (`uv.lock`, `requirements.lock`) checked in. If not, add version upper bounds (`pkg>=1.2,<2`) at minimum
- [ ] Bump floors past known-CVE versions for packages you're adding (check with `pip-audit` or PyPI advisories)
- [ ] Justify every new dep against the "10 lines in stdlib?" rule

### Shared hardening module
If this is the first backend ticket to need SSRF validation, magic-byte sniffing, or capped downloads, create `backend/app/services/security.py` (or similar) and put the validators there. Subsequent tickets REUSE it — don't re-invent per-service.

**If any checkbox is unchecked, STOP and fix before writing application code.** The entire TASK-050 review (5 criticals, 16 highs) traced back to skipping items in this list.

## Step 2: Update State — Build Started

```bash
TICKET_ID="[ticket-id]"
BRANCH=$(git branch --show-current)

python3 -c "
import json, sys
from datetime import datetime, timezone

with open('.agents/nose-state.json', 'r') as f:
    state = json.load(f)

state['ticket_id'] = '$TICKET_ID'
state['branch'] = '$BRANCH'
state['current_phase'] = 'build'
state['updated_at'] = datetime.now(timezone.utc).isoformat()
state['history'].append({
    'timestamp': datetime.now(timezone.utc).isoformat(),
    'phase': 'build',
    'action': 'build_started',
    'detail': 'Building ticket: $TICKET_ID on branch: $BRANCH'
})

with open('.agents/nose-state.json', 'w') as f:
    json.dump(state, f, indent=2)

print('State: build started')
"
```

## Step 3: Determine Scope

Classify the work into one or more domains:

- **Frontend** — React components, pages, layouts, CSS, TypeScript UI code
- **Backend** — FastAPI endpoints, services, middleware, Python code
- **Database** — Schema changes, migrations, new queries

A single ticket may span multiple domains. Identify ALL that apply.

**MULTI-REPO ROUTING — critical:**

Each domain lives in a separate repo. Sub-agents must `cd` to the correct directory before doing any work:

| Domain | Repo | Working directory |
|--------|------|-------------------|
| Frontend | `nose-fe` | `~/Documents/GitHub/TryNose/nose-fe` |
| Backend | `nose-be` | `~/Documents/GitHub/TryNose/nose-be` |
| Database | `nose-be` | `~/Documents/GitHub/TryNose/nose-be/database` |
| State / docs | `nose` | `~/Documents/GitHub/TryNose/nose` |

**State file** stays in `nose` repo. Always read/write it from: `~/Documents/GitHub/TryNose/nose/.agents/nose-state.json`

**Feature branches** must be created in each repo that has changes:
```bash
# In nose-fe (if frontend work):
cd ~/Documents/GitHub/TryNose/nose-fe
git checkout -b feature/task-[NUMBER]-[slug]

# In nose-be (if backend work):
cd ~/Documents/GitHub/TryNose/nose-be
git checkout -b feature/task-[NUMBER]-[slug]
```

Generate a task list and write it to state:

```bash
python3 -c "
import json
from datetime import datetime, timezone

with open('.agents/nose-state.json', 'r') as f:
    state = json.load(f)

# Add the task list (replace with actual tasks derived from the ticket)
tasks = [
    'task-1: [description]',
    'task-2: [description]',
    'task-3: [description]'
]

state['progress']['tasks'] = tasks
state['progress']['completed'] = []
state['progress']['percent'] = 0
state['updated_at'] = datetime.now(timezone.utc).isoformat()

with open('.agents/nose-state.json', 'w') as f:
    json.dump(state, f, indent=2)

print('Task list written to state')
"
```

## Step 4: Setup Branch

```bash
# Create feature branch if not on one
CURRENT=$(git branch --show-current)
if [[ "$CURRENT" == "main" ]]; then
  SLUG=$(echo "[ticket-title]" | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g' | cut -c1-30)
  git checkout -b feature/task-[NUMBER]-$SLUG
  echo "Created branch: feature/task-[NUMBER]-$SLUG"
fi
```

## Step 5: Implement by Domain

As you complete each task, update state progress:

```bash
# After completing a task, mark it done
python3 -c "
import json
from datetime import datetime, timezone

with open('.agents/nose-state.json', 'r') as f:
    state = json.load(f)

completed_task = '[task-description]'
state['progress']['completed'].append(completed_task)
total = len(state['progress']['tasks'])
done = len(state['progress']['completed'])
state['progress']['percent'] = int((done / total) * 100) if total > 0 else 0
state['progress']['current_task'] = '[next-task-description]'
state['updated_at'] = datetime.now(timezone.utc).isoformat()
state['history'].append({
    'timestamp': datetime.now(timezone.utc).isoformat(),
    'phase': 'build',
    'action': 'task_completed',
    'detail': completed_task
})

with open('.agents/nose-state.json', 'w') as f:
    json.dump(state, f, indent=2)

print(f'Progress: {done}/{total} tasks ({state[\"progress\"][\"percent\"]}%)')
"
```

### Frontend Work

**Repo:** `nose-fe` — working directory: `~/Documents/GitHub/TryNose/nose-fe`

Read `.agents/agents/frontend-developer.md` for the full constraints, then implement.


### Backend Work

**Repo:** `nose-be` — working directory: `~/Documents/GitHub/TryNose/nose-be`

Read `.agents/agents/backend-developer.md` for the full constraints, then implement.


### Database Work

Read `.agents/agents/database-developer.md` for the full constraints, then implement.


## Step 6: TDD Throughout

For EACH piece of implementation:
1. **Write failing test first** (RED)
2. **Write minimal code to pass** (GREEN)
3. **Refactor if needed** (REFACTOR)

Run tests continuously:
```bash
# Frontend
npm test -- --watchAll=false

# Backend
cd backend && python -m pytest tests/ -v
```

Never commit code with failing tests.

## Step 7: Run Automated Standards Check

Before declaring build complete, run the linters. Fix all violations — do not bypass.

```bash
# nose-fe: lint + type check
cd ~/Documents/GitHub/TryNose/nose-fe
npx eslint src/ --max-warnings 0
npx tsc --noEmit
npx prettier --check src/

# nose-be: ruff + type check
cd ~/Documents/GitHub/TryNose/nose-be
python -m ruff check backend/app/
python -m ruff format --check backend/app/
python -m mypy backend/app/ --ignore-missing-imports
```

If any violations remain, fix them before proceeding. ESLint `max-warnings 0` means zero tolerance.

## Step 8: Verify Acceptance Criteria

Check each acceptance criterion from the plan/ticket:
```
✅ [Criterion 1] — [how verified]
✅ [Criterion 2] — [how verified]
⬜ [Criterion 3] — [what's missing]
```

## Step 8: Commit

Use conventional commit format:
```bash
git add [specific files — never git add -A]
git commit -m "feat(TASK-XXX): [description of what was implemented]"
```

## Step 9: Update State — Build Complete

```bash
python3 -c "
import json
from datetime import datetime, timezone

with open('.agents/nose-state.json', 'r') as f:
    state = json.load(f)

state['current_phase'] = 'ready_to_review'
state['progress']['percent'] = 100
state['progress']['current_task'] = ''
state['updated_at'] = datetime.now(timezone.utc).isoformat()
state['history'].append({
    'timestamp': datetime.now(timezone.utc).isoformat(),
    'phase': 'build',
    'action': 'build_complete',
    'detail': 'All tasks complete, ready for review'
})

with open('.agents/nose-state.json', 'w') as f:
    json.dump(state, f, indent=2)

print('State: build complete, ready for /review')
"
```

Then: "Ready for `/review` — run it to check for issues before merging."

Or if using autonomous mode: "State updated. `/nose-orchestrator` will now auto-chain to `/review`."

## NOSE Tech Stack Quick Reference

| Layer | Tech | Key Files |
|-------|------|-----------|
| Frontend | Next.js 15 + TypeScript | `src/app/`, `src/components/` |
| Styling | CSS Modules + Tailwind | `src/app/globals.css`, `*.module.css` |
| Backend | FastAPI + Python | `backend/app/` |
| Database | Neon PostgreSQL | `backend/alembic/` |
| CDN | Cloudflare R2 (`images.trynose.in`) | `src/lib/images.ts` (FE URL builder), `backend/app/services/r2_client.py` (BE uploads) |
| Deploy | Vercel | `.vercel/` |
| Logging | structlog | `backend/app/core/logging.py` |
