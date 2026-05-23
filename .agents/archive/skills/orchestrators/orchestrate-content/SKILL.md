> **DEPRECATED** — Merged into `orchestrate-plan` or `orchestrate-test` or downgraded to utility skill.
>
# /orchestrate-content — Content Orchestrator

## Purpose
Activate the autonomous Content Strategist agent. The agent reads state, diagnoses situation, decides priorities, executes, and reports back. No task description required — the agent is self-directed.

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

### Step 1: Spawn Content Strategist
```
agent-content-strategist: "Run your autonomy loop"
```

The agent will:
1. Read `.agents/agent-memory/agent-content-strategist/state.json`
2. Assess the current situation
3. Diagnose what needs to happen
4. Execute the highest-priority work
5. Report back with a weekly standup
6. Update state for next session

### Step 2: Collect Standup Report
Return the agent's standup directly to the user.

### Alternative Modes
- `/orchestrate-content status` → Read state summary without running the full agent
- `/orchestrate-content report` → Trigger report phase only

## Post-flight
```
Content Strategist Standup:
[agent's full report]

State updated: .agents/agent-memory/agent-content-strategist/state.json
```

---


---

## Responsibilities

See `.agents/rules/orchestrator-responsibilities.md` for Task Distribution, State Update handling, Rule Update handling, Agent Memory verification, Output Styles, and Project State update protocols.
