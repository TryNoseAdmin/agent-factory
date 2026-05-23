> **DEPRECATED** — Merged into `orchestrate-plan` or `orchestrate-test` or downgraded to utility skill.
>
# /orchestrate-design — Design Orchestrator

## Purpose
Run the full design loop: research → design → audit. Spawn UX researcher, UI designer, and design auditor in sequence (not parallel — each depends on the previous).

## Spawn Protocol

For EACH agent you spawn, construct the prompt as:

```
{ReadFile('.agents/rules/universal.md')}

---

{ReadFile('.agents/agents/agent-<name>.md')}

---

## Task Context
[specific task, ticket, diff, etc.]
```

Spawn agents in parallel when possible. Wait for all results before proceeding.


## Execution Flow

### Step 1: Spawn UX Researcher
```
agent-ux-researcher: "Research [feature] user needs and friction points"
```
Wait for research brief.

### Step 2: Spawn UI Designer
Pass the research brief:
```
agent-ui-designer: "Design [feature] based on this research brief: [brief]"
```
Wait for design specs.

### Step 3: Spawn Design Auditor
Pass the design specs:
```
agent-design-auditor: "Audit these design specs: [specs]"
```

### Step 4: Gate Decision
- Score ≥ 75% → Design approved, hand to /orchestrate-build
- Score < 75% → Trigger /orchestrate-brainstorm for redesign

## Post-flight
```
Design complete: [Feature]
- Research: [key findings]
- UI Specs: [components, states]
- Audit Score: [X/8]

Ready for /orchestrate-build
```

---


---

## Responsibilities

See `.agents/rules/orchestrator-responsibilities.md` for Task Distribution, State Update handling, Rule Update handling, Agent Memory verification, Output Styles, and Project State update protocols.
