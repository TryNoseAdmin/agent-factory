# Orchestrator Responsibilities

Shared reference for all orchestrators. Load this section into your workflow instead of duplicating it.

---

## Task Distribution (Do Not Overload Agents)

**Core principle:** If a task is too large for one agent, split it into parallel instances of the same agent type with distinct scopes. Never give a single agent >3 major responsibilities.

### How to Split Any Agent

When an agent's task list exceeds 3 major items, spawn multiple instances with narrowed scopes:

| Agent Type | Large Task Split | Small Task |
|-----------|------------------|------------|
| `agent-frontend-dev` | Agent A: UI structure + data flow<br>Agent B: Styling + responsive behavior<br>Agent C: Accessibility + keyboard nav + axe-core | Single agent |
| `agent-backend-dev` | Agent A: API design + implementation<br>Agent B: Schema + migrations<br>Agent C: Testing + validation | Single agent |
| `agent-reviewer-engineering` | Agent A: Architecture + data flow<br>Agent B: Code quality + standards<br>Agent C: Performance + security patterns | Single agent |
| `agent-qa-functional` | Agent A: User flows + navigation<br>Agent B: Forms + validation<br>Agent C: Error states + edge cases | Single agent |
| `agent-analyst-strategy` | Agent A: User value + market fit<br>Agent B: Engineering cost + feasibility | Single agent |

**Spawn context format for parallel agents:**
```
Agent A prompt: {universal} + {agent-file} + "Your scope: [narrowed scope]. Do NOT work on [other scopes]."
Agent B prompt: {universal} + {agent-file} + "Your scope: [narrowed scope]. Do NOT work on [other scopes]."
```

### Review Work Distribution
| PR Size | Spawn |
|---------|-------|
| Large (>20 files, cross-domain) | All applicable reviewers in parallel |
| Small (<10 files, single domain) | Only relevant reviewers |

### Parallelization Rule
Always spawn agents in parallel when they have no dependencies. Analysts, QA testers, reviewers, and large task sub-agents are all parallelizable.

**Split heuristic:** If you find yourself writing "and also..." or "additionally..." more than twice in a single agent's task description, split the agent.

---

## Post-Execution Responsibilities

After all agents report back:

### 1. Handle State Update Requests
Check each agent's output for `## State Update Request` sections.
- If valid and safe → apply to `.project-state.json`
- If unclear or risky → ask the user before applying
- Log all applied updates with timestamp

### 2. Handle Rule Update Requests
Check each agent's output for `## Rule Update Request` sections.
- If confidence = high and no obvious conflicts → spawn `agent-rule-keeper` to validate and apply
- If confidence = medium or complex → spawn `agent-rule-keeper` to review, then ask user before applying
- If confidence = low → log for future reference, do not apply
- Never apply rule updates that contradict `rules/universal.md`

agent-rule-keeper workflow:
```
ReadFile('.agents/rules/universal.md')
ReadFile('.agents/agents/agent-rule-keeper.md')
[Rule Update Requests from this session]
→ validate, deduplicate, apply to target rule or pattern file
```

### 3. Verify Agent Memory
Spot-check that agents wrote to their memory files:
```bash
# Quick check — last 20 lines of each agent's memory
for f in .agents/agent-memory/*.md; do
  echo "=== $(basename $f) ==="
  tail -n 20 "$f"
done
```
If an agent's memory is stale or empty, note it in your report.

### 4. Use Output Styles
Format your final synthesis using the appropriate template from `.agents/output-styles/`:
- Build/ship reports → `standup-report.md`
- Review findings → `review-report.md`
- QA results → `qa-report.md`
- Design briefs → `design-brief.md`

Inject actual findings into the template sections. Don't just dump raw agent outputs.

### 5. Update Project State (if applicable)
If your workflow changes the project phase (e.g., build → review → qa → ship), update:
```python
import json
from datetime import datetime, timezone

with open('.project-state.json', 'r') as f:
    state = json.load(f)

state['current_phase'] = '[new_phase]'
state['updated_at'] = datetime.now(timezone.utc).isoformat()
state['history'].append({
    'timestamp': datetime.now(timezone.utc).isoformat(),
    'phase': '[current_skill]',
    'action': '[what_happened]',
    'detail': '[summary]'
})

with open('.project-state.json', 'w') as f:
    json.dump(state, f, indent=2)
```
