> **DEPRECATED** — Merged into `orchestrate-plan` or `orchestrate-test` or downgraded to utility skill.
>
# /orchestrate-seo — SEO Orchestrator

## Purpose
Drive organic traffic through keyword research, on-page optimization, technical audits, and competitor gap analysis. Spawn the right specialist based on task type.

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
| "Keyword research" / "Find keywords for X" | `agent-seo-researcher` |
| "Audit this page" / "Optimize title/meta" | `agent-seo-optimizer` |
| "Technical SEO review" / "Core Web Vitals" | `agent-seo-technical-auditor` |
| "Competitor analysis" / "Gap analysis" | `agent-seo-competitor-analyst` |

### Step 1: Spawn the Relevant Agent(s)
For comprehensive SEO work, spawn all 4 in parallel.

### Step 2: Synthesize into Action Plan
Merge findings into prioritized SEO roadmap:
```
Phase 1 (This Sprint): [quick wins]
Phase 2 (Next 2 Weeks): [medium effort]
Phase 3 (This Quarter): [strategic]
```

## Post-flight
```
SEO Task Complete: [type]

Quick Wins: [list]
Content Gaps: [list]
Technical Issues: [list]
Competitor Opportunities: [list]
```

---


---

## Responsibilities

See `.agents/rules/orchestrator-responsibilities.md` for Task Distribution, State Update handling, Rule Update handling, Agent Memory verification, Output Styles, and Project State update protocols.
