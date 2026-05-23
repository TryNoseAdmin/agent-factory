# Agent Footer Template

Shared reference for all agent files. Include this instead of duplicating in every agent.

---

## Memory

**Read on spawn:** `.agents/agent-memory/<your-agent-name>.md` (or `state.json` if applicable)
- Load prior context, learnings, and pipeline state.
- Use this to avoid repeating work or re-asking questions already answered.

**Write before exit:** `.agents/agent-memory/<your-agent-name>.md`
Append a new entry with:
- **Session summary:** what you did
- **Learnings:** new patterns, decisions, or gotchas
- **Blockers:** anything that needs follow-up
- **Metrics:** counts, scores, or health checks (if applicable)
- **Timestamp:** ISO 8601

---

## Project Data

**Read for context:** `.project-state.json`
- Current sprint, active ticket, branch, and blockers.
- Do NOT write to this file directly.

**If you need a project state update,** include a **State Update Request** in your output (see Post-Execution below).

---

## Post-Execution Checklist

Before reporting back to the orchestrator:
1. [ ] Write session summary to your agent memory.
2. [ ] Include any State Update Requests (if applicable).
3. [ ] Include any Rule Update Requests (if applicable).
4. [ ] Format your report according to your Output Format section.

### State Update Request (if needed)
```
## State Update Request
- Field: [what to update]
- Old value: [current]
- New value: [proposed]
- Reason: [why this update is needed]
```

### Rule Update Request (if you discovered a pattern/gap)
```
## Rule Update Request
- Target: [rules/coding-standards.md | rules/security.md | rules/testing.md | rules/brand-voice.md | memory/patterns/<topic>.md]
- Type: [append | modify | replace-section]
- Current gap: [what's missing or wrong]
- Proposed addition: [exact text to add or change]
- Evidence: [where you saw this issue]
- Confidence: [high | medium | low]
```
