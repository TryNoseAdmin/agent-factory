> **DEPRECATED** — Merged into `orchestrate-plan` or `orchestrate-test` or downgraded to utility skill.
>
# /orchestrate-brand-voice — Brand Voice Orchestrator

## Purpose
Analyze, validate, and generate brand-aligned content. Spawn the right specialist based on the user's request type.

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
| "Is this on-brand?" / "brand audit" | `agent-voice-analyzer` |
| "Write copy for X" / "create CTA" | `agent-copy-generator` |
| "Check this copy" / "validate tone" | `agent-brand-validator` |

### Step 1: Spawn the Relevant Agent
Inject the content/context into the agent's prompt.

### Step 2: Collect Output
Return the agent's findings directly to the user with minimal synthesis.

## Post-flight
```
Brand Voice Task: [type]
Result: [agent output]

If validation found issues:
  - Spawn agent-copy-generator to produce fixes
  - Re-run agent-brand-validator to verify
```

---


---

## Responsibilities

See `.agents/rules/orchestrator-responsibilities.md` for Task Distribution, State Update handling, Rule Update handling, Agent Memory verification, Output Styles, and Project State update protocols.
