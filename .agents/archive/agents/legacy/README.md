# NOSE Agent Definitions

Centralized agent prompts extracted from `.agents/skills/*/SKILL.md`.

**Why this exists:** The skill files were monolithic — each orchestrator skill embedded its sub-agent prompts inline. This directory separates concerns so agents can be reused, tested, and maintained independently.

---

## Agent Inventory

### `/nose-plan` Analysts (4)
| Agent | File | Purpose |
|-------|------|---------|
| Analyst A — Strategy | `analyst-a-strategy.md` | CEO/founder lens on feature value |
| Analyst B — Architecture | `analyst-b-architecture.md` | Engineering/data model/API design |
| Analyst C — Design | `analyst-c-design.md` | UX flow, components, micro-copy |
| Analyst D — SEO | `analyst-d-seo.md` | URL structure, keywords, schema |

### `/nose-build` Domain Agents (3)
| Agent | File | Purpose |
|-------|------|---------|
| Frontend Developer | `frontend-developer.md` | Next.js 15, TypeScript, CSS Modules, Tailwind |
| Backend Developer | `backend-developer.md` | FastAPI, Python, SQLAlchemy, Pydantic |
| Database Developer | `database-developer.md` | Neon PostgreSQL, Alembic migrations |

### `/nose-review` Reviewers (7)
| Agent | File | Purpose |
|-------|------|---------|
| Reviewer 1 — Engineering | `reviewer-1-engineering.md` | Architecture, code quality, performance, concurrency |
| Reviewer 2 — Security | `reviewer-2-security.md` | OWASP Top 10, auth, secrets, input validation |
| Reviewer 3 — Design & Accessibility | `reviewer-3-design-accessibility.md` | Brand tokens, icon imports, a11y, responsive |
| Reviewer 4 — Adversarial | `reviewer-4-adversarial.md` | Edge cases, race conditions, failure modes |
| Reviewer 5 — Design Consistency | `reviewer-5-design-consistency.md` | Interaction states, cognitive load, UX patterns |
| Reviewer 6 — Coding Standards | `reviewer-6-coding-standards.md` | SOLID, clean code, logging, testing, anti-patterns |
| Reviewer 7 — Acceptance Criteria | `reviewer-7-acceptance-criteria.md` | Gates the verdict — any unmet criterion = blocker |

### `/nose-qa` Testers (4)
| Agent | File | Purpose |
|-------|------|---------|
| QA Tester 1 — Functional | `qa-tester-1-functional.md` | User flows, forms, navigation, error states |
| QA Tester 2 — Visual | `qa-tester-2-visual.md` | Brand consistency, responsive, dark mode |
| QA Tester 3 — Performance | `qa-tester-3-performance.md` | Core Web Vitals, bundle size, API latency |
| QA Tester 4 — Accessibility | `qa-tester-4-accessibility.md` | WCAG 2.1 AA, keyboard nav, screen reader |

### `/nose-design` Agents (3)
| Agent | File | Purpose |
|-------|------|---------|
| UX Researcher | `ux-researcher.md` | User goals, friction points, edge cases |
| UI Designer | `ui-designer.md` | Component spec, layout, states, mobile |
| Design Auditor | `design-auditor.md` | 8-layer brand + UX compliance check |

### `/nose-brand-voice` Agents (3)
| Agent | File | Purpose |
|-------|------|---------|
| Voice Analyzer | `sub-agent-1-voice-analyzer.md` | Analyze copy against brand voice |
| Copy Generator | `sub-agent-2-copy-generator.md` | Generate brand-aligned micro-copy |
| Brand Validator | `sub-agent-3-brand-validator.md` | Validate content against guidelines |

### `/nose-content` Agents (1)
| Agent | File | Purpose |
|-------|------|---------|
| Content Strategist | `content-strategist.md` | **Autonomous employee.** Self-directed growth owner. Reads state, diagnoses situation, executes highest-priority work, reports weekly. Full authority on content/channel/calendar decisions. Escalates only for budget, partnerships, legal risk. |

### `/nose-seo` Agents (4)
| Agent | File | Purpose |
|-------|------|---------|
| SEO Researcher | `sub-agent-1-seo-researcher.md` | Keyword research, gap analysis |
| Page Optimizer | `sub-agent-2-page-optimizer.md` | On-page SEO, meta tags, schema |
| Technical Auditor | `sub-agent-3-technical-auditor.md` | Crawlability, performance, indexation |
| Competitor Analyst | `sub-agent-4-competitor-analyst.md` | Competitor gap analysis |

### `/nose-process` Agents (4)
| Agent | File | Purpose |
|-------|------|---------|
| Sprint Analyst | `sub-agent-1-sprint-analyst.md` | Task flow analysis, completion times |
| Bottleneck Investigator | `sub-agent-2-bottleneck-investigator.md` | Workflow bottleneck detection |
| Compliance Auditor | `sub-agent-3-compliance-auditor.md` | Documentation compliance audit |
| Metrics Analyst | `sub-agent-4-metrics-analyst.md` | Completion metrics, velocity analysis |

---

## Usage

Skills should reference these agents instead of embedding prompts inline:

```markdown
## Step 2: Spawn Reviewers

Use the Agent tool with the prompt from the agent file:

```python
engineering_prompt = Read(".agents/agents/reviewer-1-engineering.md") + "\n\n[PASTE DIFF HERE]"
Agent(prompt=engineering_prompt)
```
```

---

## Maintenance

- **Update an agent?** Edit only the `.md` file here. All skills using it get the update.
- **Add a new agent?** Create a new `.md` file in this directory and reference it from the skill.
- **Agent prompts are plain markdown** — no frontmatter required. The first `# H1` is the agent name.
