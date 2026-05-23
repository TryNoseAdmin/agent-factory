# Security Rules — Universal

Extracted from `AGENTS.md` §Universal Rules and §Git Workflow.

---

## Non-Negotiables

### 1. Never commit directly to main
Always work on `feature/*` / `hotfix/*` / `chore/*` branches. PRs only. No exceptions even for "tiny fixes" — main is the production-ready surface.

### 2. Always run review before merge
"Ship it" / "merge it" / "let's go" does NOT skip review — it means "after review passes."

Workflow:
1. Open PR
2. Run code review → spawn the right reviewer subset based on diff classification
3. Fold convergent findings into the same branch
4. Then merge

### 3. No fabricated external claims — verify or mark `[UNVERIFIED]`
Before any specific claim about a third-party API, pricing, feature, or behavior:
- **Cite a verified URL** (WebFetch the docs, paste the quote)
- **Cite a measured benchmark** (show the command + output)
- **Mark the claim explicitly `[UNVERIFIED]`** and put the reasoning in plain sight

**Forbidden without a citation:** "X supports Y", "X costs $N/1M tokens", "X is N% cheaper", provider-confusion claims (Moonshot ≠ Anthropic, Kimi ≠ OpenAI).

### 4. Fail loud over silent hallucination
For any LLM-enrichment-with-web-grounding pipeline: failed grounded call → mark error + stop. **No offline fallback** that produces hallucinated rows. Hallucinated DB rows cost more to clean than failed calls.

---

## Code-Level Security

- Never log API keys, tokens, or secrets.
- Never return stack traces to the client in production.
- All user input must be validated (Pydantic / Zod) before processing.
- SQL queries must use parameterized statements or ORM — never string concatenation.
- Authentication required for all mutation endpoints.

## Dependencies
- Pin dependency versions in `requirements.txt` and `package.json`.
- Review `npm audit` / `pip-audit` findings before shipping.
- No unused dependencies — they expand the attack surface.

## Secrets Management
- Use environment variables for all secrets.
- `.env` files are gitignored. `.env.example` is committed with dummy values.
- Rotate leaked credentials immediately — no exceptions.

---

## Severity > Sass
When debugging prod incidents, outages, or security issues: **severity > sass**. The internet-native tone stays, but drop the jokes when investigating breaches, data leaks, or downtime.
