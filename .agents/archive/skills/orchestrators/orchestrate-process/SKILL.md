> **DEPRECATED** — Merged into `orchestrate-plan` or `orchestrate-test` or downgraded to utility skill.
>
# /orchestrate-process — Process Optimization Orchestrator

## Purpose
Analyze task flow, identify bottlenecks, measure completion times, audit documentation compliance, and recommend workflow improvements.

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

### Request Type → Agent Mapping

| Request | Spawn |
|---------|-------|
| "Analyze sprint" / "Task flow" | `agent-sprint-analyst` |
| "Identify bottlenecks" / "What's slowing us down?" | `agent-bottleneck-investigator` |
| "Audit docs" / "Are docs up to date?" | `agent-compliance-auditor` |
| "Metrics" / "How fast are we shipping?" | `agent-metrics-analyst` |

### Step 1: Spawn Relevant Agent(s)
For full process audit, spawn all 4 in parallel.

### Step 2: Synthesize Recommendations
Merge outputs into prioritized improvement plan:
```
🔴 Immediate (fix this week): [actions]
🟡 Short-term (next sprint): [actions]
🟢 Long-term (this quarter): [actions]
```

## Post-flight
```
Process Analysis Complete

Bottlenecks: [count]
Avg Cycle Time: [X days]
Docs Compliance: [X%]

Top Recommendation:
[action with highest impact]
```

---


---

## Responsibilities

See `.agents/rules/orchestrator-responsibilities.md` for Task Distribution, State Update handling, Rule Update handling, Agent Memory verification, Output Styles, and Project State update protocols.
