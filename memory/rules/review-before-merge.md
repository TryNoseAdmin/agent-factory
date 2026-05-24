# Rule: Always Run Review Before Merge

**Established:** 2026-05-03
**Severity:** CRITICAL

"Ship it" / "merge it" / "let's go" from the user does NOT skip review — it means "after review passes."

## Workflow
1. Open PR
2. Run review pass → spawn the right reviewer subset based on diff classification
3. Fold convergent findings into the same branch
4. Then merge

## Rationale
Two retro-reviews surfaced 2+ CRITICAL findings each that would have shipped to main without the gate.
