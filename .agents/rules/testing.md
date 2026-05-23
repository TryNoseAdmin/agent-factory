# Testing Standards — Universal

Extracted from `AGENTS.md` §Task Execution Discipline and §AI Agent Workflow Requirements.

---

## Philosophy

- Tests are production code. Treat them with the same care.
- A test that never fails is useless. A test that flakes is worse.
- Coverage is a compass, not a target. 100% coverage with bad tests is a lie.

---

## TDD Discipline

**Write failing test first.** No exceptions.

Transform vague testing requests into verifiable goals:

| Instead of… | Transform to… |
|---|---|
| "Add validation" | "Write tests for invalid inputs, then make them pass" |
| "Fix the bug" | "Write a test that reproduces it, then make it pass" |
| "Refactor X" | "Ensure tests pass before and after" |
| "Improve performance" | "Measure baseline, define target (e.g. p95 < 200ms), verify after" |
| "Make this accessible" | "Run axe-core + keyboard nav audit, define pass criteria, verify" |

For multi-step tasks, state the plan as: `[Step] → verify: [check]`.

---

## Frontend Testing

- Jest for unit tests, Playwright for E2E.
- Every component that receives props needs at least one render test.
- Every user flow (search, save, purchase) needs an E2E test.
- Test accessibility with axe-core in CI.

## Backend Testing

- pytest with `pytest-asyncio` for async code.
- Every API endpoint needs at least: success case, 400 case, 401/403 case.
- Database tests use a fresh test DB per session, rolled back per test.
- Mock external APIs — never hit real services in tests.

---

## Regression Discipline

- Found a bug? Write a test that reproduces it FIRST, then fix.
- No bug fix PR without a regression test.

---

## Validation Gates

Every fix MUST be validated:
1. Tests required
2. Confidence scored
3. No fix without root cause confidence > 70%

**Iron Law:** No fix is attempted until root cause confidence > 70%.
