# /orchestrate-plan — Plan Orchestrator

## Purpose
Comprehensive planning phase. Spawns discovery agents in parallel, synthesizes into a single coherent plan, and creates ONE Notion ticket with all artifacts attached.

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
Merge all outputs into unified plan document:
- **Executive Summary** (strategy)
- **Architecture** (data model + API)
- **Design Specs** (UI + audit)
- **Brand Voice** (copy strategy)
- **Content Plan** (content + growth)
- **SEO Strategy** (routes + keywords + schema)
- **Implementation Phases** (ordered by dependency)
- **Complexity Estimate** (S/M/L/XL)

### Phase 5: Utility Skills (On Demand)
Available during planning if needed:
- `skills/design-md` — design system synthesis
- `skills/enhance-prompt` — UI idea → polished prompt

### Phase 6: Create/Update Ticket
Call `skills/ticket` to create or update ONE ticket with:
- Title, description, acceptance criteria
- All plan artifacts (design specs, content plan, SEO plan)
- Effort estimate, assigned epic

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
