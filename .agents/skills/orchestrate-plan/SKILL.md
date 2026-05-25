# /orchestrate-plan — Plan Orchestrator

## Purpose
Comprehensive planning phase. Spawns discovery agents in parallel, synthesizes into a single coherent plan, and creates ONE Notion ticket with all artifacts attached.

## Spawn Protocol

For EACH agent you spawn, construct the prompt as:

```
{ReadFile('~/.agents/rules/universal.md')}

---

{ReadFile('.project-context.md')}

---

{ReadFile('~/.agents/agents/agent-<name>.md')}

---

{ReadFile('~/.agents/skills/agent-<name>/SKILL.md')}

---

## Task Context
[specific task, ticket, diff, etc.]
```

Spawn agents in parallel when possible. Wait for all results before proceeding.

## Pre-flight
1. Read state: `.project-state.json`
2. Capture the feature request from the user
3. Check if ticket exists. If not, create one via `skills/ticket`.

## Execution Flow

### Phase 1: Discovery (Parallel)
Spawn simultaneously:

| Agent | Scope |
|-------|-------|
| `agent-analyst-strategy` | User value, market fit, engineering cost |
| `agent-analyst-architecture` | Data model, API design, performance |
| `agent-ux-design-analyst` | User research, user flows, component mapping, mobile |
| `agent-seo-specialist` | Keyword research, competitor gaps, routes, schema, on-page, technical audit |
| `agent-project-analyst` | Sprint metrics, capacity, bottleneck detection, throughput |

### Phase 2: Design (Sequential Pipeline)
UX research brief → UI design → design audit:
1. `agent-ui-designer` — design based on research brief
2. `agent-design-auditor` — audit specs for consistency

### Phase 3: Brand + Content (Parallel)
1. `agent-brand-auditor` — brand voice analysis, tone validation, compliance audit
2. `agent-content-strategist` — content plan, growth strategy

### Phase 4: Synthesize
Merge all outputs into unified plan document AND explicitly generate the following permanent artifacts in the project root:
- `DESIGN.md` (Design Specs, UI tokens, palettes)
- `ARCHITECTURE.md` (Data models, API routes, stack)
- `SEO_PLAN.md` (Routes, keywords, schema)
These physical files MUST be generated before proceeding.

The unified plan document should summarize:
- **Executive Summary** (strategy)
- **Architecture** (data model + API)
- **Design Specs** (UI + audit)
- **Brand Voice** (copy strategy)
- **Content Plan** (content + growth)
- **SEO Strategy** (routes + keywords + schema)
- **Implementation Phases** (ordered by dependency)
- **Complexity Estimate** (S/M/L/XL)

### Phase 5: Generate Task Files

**Before declaring plan complete, the orchestrator MUST write task files** — one per agent that will be spawned in `/orchestrate-build`.

Task files live in:
```
PROJECT:frontend-repo/.agents/tasks/TASK-001-[name].md   (for FE agents)
PROJECT:frontend-repo/.agents/tasks/TASK-002-[name].md   (for BE agents)
PROJECT:brain-repo/.agents/tasks/TASK-003-[name].md      (for DB agents)
```

**Task file schema** (enforced by orchestrator, consumed by agents):
```markdown
# Task: [short name]
## Agent Type
[agent-frontend-dev | agent-backend-dev | agent-database-dev | ...]

## Scope
### What to Do
[specific deliverables]

### What NOT to Do
[explicit out-of-scope items]

## Files to Read Before Starting
- `DESIGN.md` (Required for Frontend) — Strict UI guidelines.
- `ARCHITECTURE.md` (Required for Backend) — Strict data and API schema.
- [other file paths] — [why]

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2

## Constraints
- [stack constraints]
- [design system rules]
- [security rules]

## Output Format
[exact report format]

## Notes
[context, prior decisions, blockers]
```

**One agent = one task file. Never give an agent >3 responsibilities.** Split into parallel task files if needed.

### Phase 6: Utility Skills (On Demand)
Available during planning if needed:
- `skills/design-md` — design system synthesis
- `skills/enhance-prompt` — UI idea → polished prompt

### Phase 6: Create/Update Ticket
Call `skills/ticket` to create or update ONE ticket with:
- Title, description, acceptance criteria
- All plan artifacts (design specs, content plan, SEO plan)
- Effort estimate, assigned epic

### Step 7: Artifact Output Gate
Before completing the `/plan` phase, explicitly verify that the required artifacts were physically created.
```bash
if [ ! -f DESIGN.md ] || [ ! -f ARCHITECTURE.md ]; then
  echo "CRITICAL ERROR: Plan artifacts missing. You must generate DESIGN.md and ARCHITECTURE.md."
  exit 1
fi
```

## Post-flight
```
Plan complete: [Feature Name]
- Strategy: [MVP vs. full trade-off]
- Architecture: [complexity S/M/L/XL]
- Design: [key components]
- Brand: [tone direction]
- Content: [plan summary]
- SEO: [new routes]
- Ticket: [Notion URL]

Ready for /orchestrate-build
```

---

## Responsibilities

See `.agents/rules/orchestrator-responsibilities.md` for Task Distribution, State Update handling, Rule Update handling, Agent Memory verification, Output Styles, and Project State update protocols.
