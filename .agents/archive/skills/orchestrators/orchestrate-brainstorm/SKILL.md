> **DEPRECATED** — Merged into `orchestrate-plan` or `orchestrate-test` or downgraded to utility skill.
>
# /orchestrate-brainstorm — Brainstorm Orchestrator

## Purpose
Explore 3-5 distinct design directions for a feature or UI problem before committing to any single approach. Prevents premature convergence.

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

### Step 1: Define the Problem
Clarify the feature request or design problem with the user.

### Step 2: Spawn Parallel Brainstorm Agents
Spawn 3-5 generic coder agents simultaneously, each with a different creative constraint:

| Agent | Constraint |
|-------|-----------|
| Direction A | "Minimalist — remove everything non-essential" |
| Direction B | "Data-rich — show maximum information density" |
| Direction C | "Social — emphasize community and sharing" |
| Direction D | "AI-first — lean heavily into smart recommendations" |
| Direction E | "Luxury — premium, editorial, high-touch" |

(Only spawn 3-5. Skip directions that clearly don't fit the problem.)

### Step 3: Compare and Contrast
Synthesize the directions into a comparison matrix:
```
| Direction | Pros | Cons | Complexity | User Value |
|-----------|------|------|------------|------------|
```

### Step 4: Recommend
Pick the best direction or a hybrid. Explain why.

## Post-flight
```
Brainstorm Complete: [Problem]

Directions Explored: [count]

Recommendation: [Direction X]
Rationale: [why]

Next: /orchestrate-design or /orchestrate-plan
```

---


---

## Responsibilities

See `.agents/rules/orchestrator-responsibilities.md` for Task Distribution, State Update handling, Rule Update handling, Agent Memory verification, Output Styles, and Project State update protocols.
