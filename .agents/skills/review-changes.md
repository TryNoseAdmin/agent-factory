---
name: Review Changes
description: Perform a structured code review using change detection and impact
---

## Review Changes

Perform a thorough, risk-aware code review using the knowledge graph. Every review must verify the change actually satisfies the ticket's acceptance criteria — not just that the code is clean.

### Steps

1. **Load acceptance criteria.** Read the linked ticket's acceptance criteria / success criteria / definition of done before touching the diff. For NOSE work, the ticket ID is in `.agents/nose-state.json` (fetch the Notion page via `mcp__claude_ai_Notion__notion-fetch` — never `/browse` to notion.so). If no ticket is linked, ask the user for the definition of done before proceeding.
2. Run `detect_changes` to get risk-scored change analysis.
3. Run `get_affected_flows` to find impacted execution paths.
4. For each high-risk function, run `query_graph` with pattern="tests_for" to check test coverage.
5. Run `get_impact_radius` to understand the blast radius.
6. For any untested changes, suggest specific test cases.
7. **Verify each acceptance criterion against the diff.** Mark ✅ MET / ⚠️ PARTIAL / ❌ NOT MET / ❓ UNCLEAR with concrete evidence (file:line, function, or observed behavior). Never mark MET because "the component exists" — check the actual behavior the criterion requires (copy strings, tokens, state handling, routes).

### Output Format

Start with an **Acceptance Criteria** section (load-bearing — it gates the recommendation):
- ✅ AC#1: [criterion] — Evidence: file:line
- ❌ AC#2: [criterion] — Gap: [what's missing] — Fix: [what to add]

Then provide code-quality findings grouped by risk level (high/medium/low):
- What changed and why it matters
- Test coverage status
- Suggested improvements

End with an overall merge recommendation:
- **BLOCK** if any criterion is ❌ NOT MET or ⚠️ PARTIAL, or any ❓ UNCLEAR needs user clarification
- **APPROVE WITH NOTES** if all AC met but there are high-risk code findings
- **APPROVE** if all AC met and no high-risk findings
