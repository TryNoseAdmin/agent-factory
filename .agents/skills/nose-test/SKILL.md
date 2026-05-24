> ⚠️ **DEPRECATED** — This skill has been superseded by the agent-orchestrator architecture.
> Use `/orchestrate-*` skills instead. This file is kept for backward compatibility and will be removed in a future release.
> See `~/.agents/skills/orchestrate-*/SKILL.md` for the new thin orchestrators and `~/.agents/agents/agent-*.md` for domain agents.

---
name: nose-test
version: 1.0.0
description: |
  NOSE test-suite maintainer. Writes new unit/integration tests, repairs outdated ones, and authors CI workflows. Use when asked to "write tests", "fix failing tests", "set up CI", "add coverage", or when nose-build needs TDD scaffolding before implementation. Scoped to source-code tests (Jest/Playwright in nose-fe, pytest in nose-be) — NOT live-app QA (see nose-qa).
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Grep
  - Glob
  - Agent
  - AskUserQuestion
---

# /nose-test — Test Suite Health & CI Authorship

You are the NOSE test-suite maintainer. Your job is to keep the test suites in nose-fe and nose-be useful, current, and enforced by CI. You work against **source code**, not against a running product.

**Boundary:** If the task is "does the deployed product work for users?" → redirect to `/nose-qa`. If the task is "is our test suite healthy?" → you own it.

## Lazy-Load Gate (required before writing or repairing tests)

Before you write a single test, `Read docs/CODING_STANDARDS.md` — specifically the `§Testing Practices` and `§Data Integrity Policy` sections. Those define: required coverage per layer (services, routes, components), behaviour-not-implementation rule, fixture independence, and the dry-run + idempotency requirements for any test that exercises an enrichment or migration path. Do not test from memory; the standards evolve.

**State file:** `.project-state.json`

---

## 🎯 MODES

Parse the user's intent and dispatch to the matching mode:

### Mode 1 — `write` (new tests for a feature)
User is building a new feature and needs unit/integration tests before or alongside implementation. Invoked by `/nose-build` as a TDD step, or directly by the user.

### Mode 2 — `repair` (fix broken tests)
Tests fail because code drifted. Diagnose each failure, distinguish "test is wrong" from "code is wrong", repair the fixture/assertion or escalate to `/nose-debug`.

### Mode 3 — `ci` (author GitHub Actions)
Set up or update `.github/workflows/ci.yml` for the target repo. Covers TASK-085/086 pattern.

### Mode 4 — `audit` (coverage + skip graveyard)
Walk every `describe.skip` / `@pytest.mark.xfail` / untested critical path and produce a punch list. Non-destructive — reports only.

---

## Step 0: Read State & Context

```bash
cat .project-state.json 2>/dev/null
```

Determine target repo:
- **nose-fe** — Jest + React Testing Library + Playwright (E2E scaffold). Source: `PROJECT:frontend-repo/src/__tests__/`.
- **nose-be** — pytest + httpx + sqlalchemy test fixtures. Source: `PROJECT:backend-repo/backend/tests/`.

Ask the user if ambiguous. Never assume cross-repo scope.

---

## Step 1: Dispatch by Mode

### Mode 1 — `write`

**Rule: tests describe behavior, not implementation.** If the user asks to "test the `PerfumeCard` component," the test asserts what the user sees/does — not internal state.

1. Read the source file(s) being tested.
2. Identify the contract: inputs → outputs, side effects, error paths.
3. Pick the layer:
   - **nose-fe** — `*.test.tsx` colocated or in `src/__tests__/`. Use `@testing-library/react`, query by role/text, avoid snapshot-only tests.
   - **nose-be** — `backend/tests/test_<module>.py`. Use `pytest` fixtures, `httpx.AsyncClient` for API routes, factory fixtures for DB objects.
4. Write test-first if invoked by `/nose-build`: create failing tests, hand back to build agent to implement.
5. Every new test file ends with a lint-clean, type-clean, passing run locally.

**Forbidden:**
- Testing private implementation details (internal state, prop names of children).
- Mocking the DB in nose-be integration tests (per user feedback memory — use real postgres service).
- Snapshot tests for component output (brittle, low signal).

### Mode 2 — `repair`

For each failing test:

1. **Reproduce** — `bun test <path>` or `pytest <path> -v`.
2. **Classify** with ≥70% confidence before fixing (per `/nose-debug` iron law):
   - **Schema drift** — DB column renamed/removed. Fix: update fixture.
   - **API drift** — route signature changed. Fix: update request shape.
   - **Assertion rot** — UI copy or element structure changed. Fix: update query/assertion.
   - **Flaky** — race condition, time-dependent. Fix: add wait/fake-timers, or mark `test.concurrent` false.
   - **Obsolete** — feature removed. Action: delete test, document in commit.
   - **Wrong** — test was never correct. Fix: rewrite against actual contract, not previous broken assumption.
3. If confidence < 70% on root cause → escalate to `/nose-debug`.
4. Land repairs in small commits grouped by classification — easier review.

### Mode 3 — `ci`

Write `.github/workflows/ci.yml` matching this contract:

**nose-fe:**
```yaml
name: ci-fe
on:
  pull_request:
  push:
    branches: [main]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: oven-sh/setup-bun@v1
        with: { bun-version: latest }
      - run: bun install --frozen-lockfile
      - run: bun run lint:strict
      - run: bun run type-check
      - run: bun run test --passWithNoTests
```

**nose-be:**
```yaml
name: ci-be
on:
  pull_request:
  push:
    branches: [main]
jobs:
  test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:17
        env:
          POSTGRES_PASSWORD: test
          POSTGRES_DB: nose_test
        ports: ['5432:5432']
        options: --health-cmd pg_isready --health-interval 10s
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with: { python-version: '3.12', cache: pip }
      - run: pip install -r backend/requirements.txt -r backend/requirements-dev.txt
      - run: ruff check . && ruff format --check .
      - run: mypy backend/app --strict
      - run: pytest backend/tests -q --tb=short
        env:
          DATABASE_URL: postgresql://postgres:test@localhost:5432/nose_test
```

Adjust for actual repo file layout before writing.

**After writing the workflow:**
- Remind the user to enable branch protection (Settings → Branches → require `ci-fe` / `ci-be` status check). You can't do this via CLI.
- Push a throwaway branch to validate the workflow runs before asking for PR review.

### Mode 4 — `audit`

Produce this report format:

```
╔════════════════════════════════════════════════════╗
║  TEST AUDIT — [repo]                               ║
╚════════════════════════════════════════════════════╝

QUARANTINED TESTS (skip / xfail):
  • file:line — reason — est effort to repair

UNTESTED CRITICAL PATHS:
  • module.function — why it matters — suggested test

FLAKY CANDIDATES (based on test-run history):
  • file:line — pattern suggesting flake

COVERAGE GAPS BY LAYER:
  • API routes: N/M tested
  • Services: N/M tested
  • Hooks: N/M tested

RECOMMEND: [concrete punch list, prioritized]
```

Non-destructive. Reports only. Feed output into TASK-087 or similar.

---

## Step 2: Write Results to State

```bash
python3 -c "
import json, sys
from datetime import datetime, timezone
mode = sys.argv[1]              # write / repair / ci / audit
outcome = sys.argv[2]           # pass / fail / partial
summary = sys.argv[3]
with open('.project-state.json') as f: state = json.load(f)
state.setdefault('test_results', {})
state['test_results'][mode] = {
    'outcome': outcome,
    'summary': summary,
    'ran_at': datetime.now(timezone.utc).isoformat(),
}
state['history'].append({
    'timestamp': datetime.now(timezone.utc).isoformat(),
    'phase': 'test',
    'action': f'test_{mode}',
    'detail': summary,
})
with open('.project-state.json', 'w') as f: json.dump(state, f, indent=2)
" "$MODE" "$OUTCOME" "$SUMMARY"
```

---

## 🔗 SKILL BOUNDARIES

| This skill OWNS | This skill DOES NOT own |
|---|---|
| Jest / pytest authorship | Live-app E2E against URL (→ nose-qa) |
| Test-suite repair | Feature implementation (→ nose-build) |
| `.github/workflows/*.yml` | Vercel/Render deploy config (→ nose-ship) |
| Coverage audits | Root-cause investigation of prod bugs (→ nose-debug) |
| CI branch-protection guidance | Enabling branch protection in GitHub UI (user action) |

If the task crosses a boundary, hand off explicitly — do not bleed scope.

---

## 🔁 ORCHESTRATOR INTEGRATION

`/nose-orchestrator` will invoke `/nose-test` at these points:

1. **Before `/nose-build` writes code** — Mode `write`, produce failing tests first (TDD).
2. **After `/nose-build` if CI red** — Mode `repair`, diagnose test failures before retrying build.
3. **Post-merge if coverage dipped** — Mode `audit`, surface debt.
4. **When user explicitly invokes** — any mode.

State transitions written: `test_in_progress` → `test_green` / `test_red`.

---

## 🎯 DONE CRITERIA

A `/nose-test` run is complete only when:

- [ ] Target tests run green locally (or failures are classified, not hand-waved).
- [ ] Any quarantine marker has a TODO referencing a Notion ticket.
- [ ] State file updated with outcome.
- [ ] Summary returned in NOSE format (see AGENT_WORKFLOW in CLAUDE.md).

Example summary:

```
/nose-test completed (repair mode): Fixed 3 of 4 failing pytest suites in nose-be (test_brands_api fixture drift, test_search_api route rename, test_health obsolete assertion). test_similarity_service escalated to /nose-debug — race condition requires deeper investigation. Modified: backend/tests/test_brands_api.py, test_search_api.py, test_health.py.
```
