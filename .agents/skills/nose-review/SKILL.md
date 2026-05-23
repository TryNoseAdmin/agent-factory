> ⚠️ **DEPRECATED** — This skill has been superseded by the agent-orchestrator architecture.
> Use `/orchestrate-*` skills instead. This file is kept for backward compatibility and will be removed in a future release.
> See `.agents/skills/orchestrate-*/SKILL.md` for the new thin orchestrators and `.agents/agents/agent-*.md` for domain agents.

---
name: nose-review
version: 2.3.0
description: |
  NOSE pre-merge review orchestrator. Classifies the diff, then spawns ONLY the reviewers that apply (e.g. skips UI/design reviewers on backend-only PRs, skips engineering/security on docs-only PRs). Always runs Acceptance Criteria + Adversarial. Synthesizes findings into a severity-ranked report. Any unmet acceptance criterion is an automatic blocker. Use when asked to "review", "check this", "ready for review", "pre-merge", or "PR review".
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Grep
  - Glob
  - Agent
  - AskUserQuestion
  - WebSearch
---

# /review — NOSE Pre-Merge Review Orchestrator (v2.4 — anti-fabrication gate added)

---

## 🚧 NON-NEGOTIABLE: Fabrication-Detection Gate (read FIRST)

**This gate exists because of a real failure on 2026-05-02 — see `memory:feedback_no_fabricated_external_claims`. The review step is the LAST line of defense against doc-only features and unverified external claims reaching main.**

### Reviewers MUST flag these patterns

When ANY spawned reviewer (Engineering, Security, Coding Standards, AC) sees these in the diff, they MUST raise a CRITICAL or HIGH finding:

1. **Doc-only features** — a docstring/comment/PR-description claims a behavior, but no code produces it. Examples:
   - Docstring says "uses prompt caching" — no `cache_control` field, no header, no API change in the diff
   - Function name implies a behavior (`enableX()`) — body is `return` or `noop`
   - Test name implies coverage (`test_x_feature_works`) — assertion only checks a constant
   - **Specific case to watch for:** "cache-friendly" / "cache-aware" / "auto-cached" claims with no observable cache integration

2. **Unverified external API claims** — code or comment asserts that a third-party service does X without a citation. Examples:
   - "Moonshot supports Y" with no link to Moonshot's docs
   - Pricing constants (`$0.60/1M`) hardcoded without a comment citing the source page
   - Provider-confusion: implementation copy-pasted from a different provider's example

3. **Plan/brainstorm claims that didn't survive verification** — if the PR description references `[UNVERIFIED]` claims from upstream, the review must check whether those got verified during build OR deferred. Silent inheritance = HIGH finding.

### How the AC reviewer enforces this

Reviewer 7 (Acceptance Criteria) gets an extra question for every claimed feature: **"Does the code actually do this, or only document the intent?"**

If a criterion says "uses caching" / "saves N tokens" / "supports feature X" and the diff has only a docstring or comment supporting it, mark as **❌ NOT MET (doc-only)** — even if the docstring is well-written. Documentation is not implementation.

### How to spawn the verification

When in doubt, the review skill should `WebFetch` the relevant provider docs in real time and quote the answer back. The AC reviewer agent has WebFetch access — use it.

### Severity rules

- Doc-only feature claim where the user could believe it works → **CRITICAL**
- Unverified external API/pricing claim → **HIGH** (block merge until verified or downgraded)
- "Cache-friendly" / "performance-optimised" prose with no measurement → **MEDIUM** (flag for clarification)

---

# /review — NOSE Pre-Merge Review Orchestrator (v2.3 — concurrency checklist + nose-be precommit health)

You are the NOSE review orchestrator. First **classify the diff** to decide which reviewers actually apply. Then spawn *only* those reviewers in parallel, synthesize into a unified severity-ranked report, and write findings to shared state so the orchestrator can decide to approve or trigger a fix loop.

**Why scoped spawn:** firing all 7 reviewers on a backend-only PR wastes tokens on the Design + Design Consistency reviewers (they have nothing to review). Firing the Engineering + Security reviewers on a docs-only PR has the same problem. The skill picks the right subset based on what actually changed.

**State file:** `.agents/nose-state.json`

## Step 0: Read State

```bash
if [ -f .agents/nose-state.json ]; then
  cat .agents/nose-state.json
fi
```

Check:
- `current_phase` — should be `ready_to_review`
- `review_feedback.iteration` — if > 0, this is a re-review after a fix pass
- `ticket_id` and `branch` — for context

If `iteration > 0`, note this is a re-review and check if previously flagged issues were resolved.

## Step 1: Get the Diff

**Multi-repo:** Collect diffs from all repos that have changes on the feature branch.

```bash
BRANCH=$(python3 -c "import json; d=open('$HOME/Documents/GitHub/TryNose/nose/.agents/nose-state.json').read(); print(json.loads(d).get('branch',''))")

echo "=== nose-fe diff ==="
cd ~/Documents/GitHub/TryNose/nose-fe
git fetch origin main 2>/dev/null
if git show-ref --verify --quiet "refs/heads/$BRANCH" 2>/dev/null; then
  git diff main...$BRANCH --stat
  git diff main...$BRANCH
fi

echo "=== nose-be diff ==="
cd ~/Documents/GitHub/TryNose/nose-be
git fetch origin main 2>/dev/null
if git show-ref --verify --quiet "refs/heads/$BRANCH" 2>/dev/null; then
  git diff main...$BRANCH --stat
  git diff main...$BRANCH
fi

cd ~/Documents/GitHub/TryNose/nose
```

If no changes found in any repo, ask: "What should I review? Share the branch name or describe the changes."

## Step 1.25: Load Acceptance Criteria from the Ticket

**Every review MUST verify acceptance criteria.** No exceptions.

Read the ticket's spec from Notion via MCP — never `/browse` to notion.so (login wall). The ticket ID is in state:

```bash
python3 -c "import json; s=json.load(open('.agents/nose-state.json')); print(s.get('ticket_id',''))"
```

Then fetch the ticket page using `mcp__claude_ai_Notion__notion-fetch` (Sprint Tracker data source `847f3552-71bb-430b-9f52-f6b6938670ab`) and extract:
- **Acceptance Criteria** (or "Success Criteria" / "Definition of Done")
- **What to Do** — functional requirements
- **Design Spec** (if present) — required tokens/classes/copy

Write each criterion to a numbered list. If the ticket has no explicit acceptance criteria, ask the user: "This ticket has no acceptance criteria — what's the definition of done so I can review against it?" Do not proceed without a list.

If no `ticket_id` in state, ask: "Which ticket does this PR close? I need its acceptance criteria to review."

## Step 1.5: Run Automated Static Analysis

Run linters first — violations here are automatic CRITICAL findings:

```bash
# nose-fe
cd ~/Documents/GitHub/TryNose/nose-fe
npx eslint src/ --max-warnings 0 2>&1 | head -50
npx tsc --noEmit 2>&1 | head -30

# nose-be
cd ~/Documents/GitHub/TryNose/nose-be
python -m ruff check backend/app/ 2>&1 | head -50
python -m mypy backend/app/ --ignore-missing-imports 2>&1 | head -30
```

Any violations from the above = CRITICAL findings that block approval.

## Step 1.75: Classify the Diff → Pick the Reviewer Set

Collect the changed paths from the multi-repo diff in Step 1, then classify:

```bash
# Collect changed paths across all three repos
BRANCH=$(python3 -c "import json; print(json.load(open('.agents/nose-state.json')).get('branch',''))")
PATHS=$(
  for repo in nose nose-fe nose-be; do
    REPO_PATH="$HOME/Documents/GitHub/TryNose/$repo"
    if [ -d "$REPO_PATH/.git" ] && git -C "$REPO_PATH" show-ref --verify --quiet "refs/heads/$BRANCH" 2>/dev/null; then
      git -C "$REPO_PATH" diff --name-only "main...$BRANCH" 2>/dev/null | sed "s|^|$repo/|"
    fi
  done
)
echo "$PATHS"
```

Classify each path into one or more buckets:

| Bucket | Path pattern |
|---|---|
| **fe_code** | `nose-fe/src/app/**`, `nose-fe/src/components/**`, `nose-fe/src/hooks/**`, `nose-fe/src/lib/**`, `nose-fe/src/styles/**`, `nose-fe/src/**/*.tsx`, `nose-fe/src/**/*.ts`, `nose-fe/src/**/*.css` |
| **be_code** | `nose-be/backend/**/*.py`, `nose-be/scripts/**/*.py`, `nose-be/alembic/**` |
| **tests** | `**/tests/**`, `**/__tests__/**`, `**/*test*.py`, `**/*.test.ts`, `**/*.test.tsx`, `**/*.spec.ts` |
| **config** | `*.yml`, `*.yaml`, `*.toml`, `*.json` (package.json, tsconfig, vercel.json, pyproject, .pre-commit), `.github/**`, `next.config.*`, `Dockerfile*` |
| **docs** | `docs/**/*.md`, `CHANGELOG.md`, `README.md`, `*.md` under root, `CLAUDE.md` |
| **skills** | `.agents/skills/**` |

One path can hit multiple buckets (a test file under `nose-be/backend/tests/` hits both `be_code` and `tests`).

### Reviewer selection rules

Apply these rules in order; a reviewer runs if ANY rule adds it.

| # | Reviewer | Runs when |
|---|---|---|
| 1 | Engineering | `fe_code` OR `be_code` OR `config` |
| 2 | Security | `fe_code` OR `be_code` OR `config` |
| 3 | Design | `fe_code` (any file under `nose-fe/src/`) |
| 4 | Adversarial | **ALWAYS** (catches edge cases even in docs/config) |
| 5 | Design Consistency | `fe_code` (any file under `nose-fe/src/`) |
| 6 | Coding Standards | `fe_code` OR `be_code` (NOT config-only, NOT docs-only, NOT skills-only) |
| 7 | Acceptance Criteria | **ALWAYS** — load-bearing, gates the verdict |

### Common PR shapes → reviewer set

| PR shape | Spawned reviewers |
|---|---|
| Full-stack FE + BE feature | 1, 2, 3, 4, 5, 6, 7 (all seven) |
| Backend-only (API / service / migration) | 1, 2, 4, 6, 7 — **skip 3 + 5** |
| Frontend-only UI | 1, 2, 3, 4, 5, 6, 7 |
| Config / CI / infra only | 1, 2, 4, 7 — **skip 3, 5, 6** |
| Docs-only (`/docs`, `CHANGELOG`, `README`) | 4, 7 — **skip 1, 2, 3, 5, 6** |
| Skill / process change only (`.agents/skills/**`) | 4, 7 — **skip 1, 2, 3, 5, 6** |
| Tests-only change | 1, 4, 6, 7 — **skip 2, 3, 5** |

State which reviewers you're spawning and why in one line before Step 2. Example:

> Classified as **backend-only** (nose-be/backend/** only touched). Spawning reviewers 1, 2, 4, 6, 7. Skipping 3 (Design) and 5 (Design Consistency) — no FE files changed.

If the classification is ambiguous (e.g. diff touches `.md` AND `.tsx`), err on the side of including the reviewer, not skipping it. When in doubt, spawn. This skill optimises away the *obvious* waste, not every edge case.

## Step 1.8: nose-be Pre-Commit Health Check (runs only when nose-be backend code is touched)

If the diff touches `nose-be` backend code, verify the pre-commit chain on `nose-be` is sane before reviewing the diff. A broken pre-commit means the commits on this branch may have skipped local enforcement and arrived less-than-clean.

Background: per memory entry `memory/nose/project_nose_be_precommit_broken.md`, nose-be's pre-commit has known issues (`.secrets.baseline` missing, EOF-fixer churns 50+ files, 180+ pre-existing mypy errors). Tracked for repair in **TASK-183** (Notion). Until TASK-183 ships, this Step 1.8 surfaces the risk on every backend PR so reviewers know the merge gate is not as strict as it should be.

**Removal trigger:** `/nose-release` will refuse to ship a release that closes TASK-183 unless this Step 1.8 has been deleted from this skill (acceptance criterion (e) on TASK-183). When you ship TASK-183, delete this entire step in the same PR — the release skill enforces the cleanup.

**Self-contained execution** — re-derive `BRANCH` and `BE_TOUCHED` here, since each Bash tool call is a fresh shell and previous variable scope does not persist:

```bash
BRANCH=$(python3 -c "import json; print(json.load(open('$HOME/Documents/GitHub/TryNose/nose/.agents/nose-state.json')).get('branch',''))")
NOSE_BE=~/Documents/GitHub/TryNose/nose-be

# Re-derive whether this branch touches backend code in nose-be
BE_TOUCHED=0
if [ -n "$BRANCH" ] && [ -d "$NOSE_BE/.git" ] && git -C "$NOSE_BE" show-ref --verify --quiet "refs/heads/$BRANCH" 2>/dev/null; then
  BE_TOUCHED=$(git -C "$NOSE_BE" diff --name-only "main...$BRANCH" 2>/dev/null | grep -E '^(backend/|alembic/)' | wc -l | tr -d ' ')
fi

if [ "$BE_TOUCHED" -gt 0 ]; then
  echo "=== nose-be pre-commit health ($BE_TOUCHED backend files touched on $BRANCH) ==="

  # 1. .secrets.baseline must exist for detect-secrets hook
  if [ ! -f "$NOSE_BE/.secrets.baseline" ]; then
    echo "[HIGH] nose-be/.secrets.baseline missing — detect-secrets hook will fail on every commit"
  fi

  # 2. Pre-commit config must exist
  if [ ! -f "$NOSE_BE/.pre-commit-config.yaml" ]; then
    echo "[MEDIUM] nose-be/.pre-commit-config.yaml missing — no local hook enforcement at all"
  fi

  # 3. Branch commits should not have used --no-verify or skipped hooks
  if git -C "$NOSE_BE" log --format="%h %s" "main..$BRANCH" 2>/dev/null | grep -i -q "no-verify\|skip.*hook\|bypass.*hook"; then
    echo "[HIGH] --no-verify / hook-skip evidence in commit messages on this branch"
  fi
else
  echo "(nose-be Step 1.8 skipped — branch does not touch nose-be backend)"
fi
```

**How to surface findings:** include any output from this step under the **Engineering** reviewer's report under a `Pre-Commit Health` heading. These are HIGH / MEDIUM warnings about repo-state hygiene, NOT diff-content issues — they do not by themselves block merge, but they signal the merge gate is weaker than expected. Mention them in the final synthesis so reviewers don't assume hooks ran.

**Why this step lives after classification:** Step 1.75 collects the changed paths; this step needs that information (or re-derives it). Running it before Step 1.75 leaves `$PATHS` empty and the entire check silently no-ops. The check used to live as Step 1.6 above; that ordering was a bug.

**Why no `pre_commit --version` check:** the working pre-commit env on developer machines lives in a project-specific venv (per memory: `/tmp/precommit-venv312` or similar). A bare `python -m pre_commit` against the ambient interpreter reports MEDIUM on every reviewer machine, which is noise. Skip that check until TASK-183 standardises the venv.

## Step 2: Spawn the Selected Reviewers in Parallel

Spawn only the reviewers from the Step 1.75 set, simultaneously, using the Agent tool. Reviewer 7 (Acceptance Criteria) is load-bearing — its output gates the verdict. Reviewers that were skipped produce no output; the synthesis in Step 3 omits their sections.

---

### Reviewer 1 — Engineering

Read `.agents/agents/reviewer-1-engineering.md`, then replace `[PASTE DIFF HERE]` with the actual diff before spawning the Agent.


---

### Reviewer 2 — Security

Read `.agents/agents/reviewer-2-security.md`, then replace `[PASTE DIFF HERE]` with the actual diff before spawning the Agent.


---

### Reviewer 3 — Design & Accessibility

```
You are a design and accessibility reviewer for NOSE perfume platform.

NOSE brand: v6.0 Burnished Amber. Design tokens in src/app/globals.css.
Typography: Fredoka (headings) + Manrope (body). Dark surface: #0a0a0c / #131315.
Primary: #F5A623 (Burnished Amber). Glassmorphism uses amber tint rgba(245,166,35,0.12).

[PASTE DIFF HERE]

Review for:
1. **Brand tokens** — Any hardcoded hex colors? Should use var(--color-*). Any hardcoded font-family strings (especially "Playfair Display" or "Inter" — these are deprecated)?
2. **Icon imports** — Any imports from lucide-react, @heroicons, @material-ui/icons, react-icons? (forbidden — use custom SVGs in src/components/icons/)
3. **Brand voice** — Any "Loading...", "No results found", "Add to favorites", "Back to catalog"? (wrong — use brand copy from docs/design/DESIGN_CHECKLIST.md §2)
4. **CSS modules** — Component styles in CSS module files? Or inline styles for colors/spacing?
5. **Glassmorphism** — Uses amber tint rgba(245,166,35,0.06–0.12)? Or wrong grey/violet tint?
6. **Accessibility** — Missing alt text, poor color contrast (< 4.5:1), missing ARIA labels, non-semantic HTML?
7. **Responsive** — Fixed widths that break mobile? Touch targets < 44px?
8. **Performance** — Large images without next/image? Missing lazy loading on non-critical assets?

Rate each finding: CRITICAL / HIGH / MEDIUM / LOW
Format: [SEVERITY] Issue — file:line — Fix: [CSS variable or component to use instead]
```

---

### Reviewer 5 — Design Consistency

```
You are a design consistency reviewer for NOSE perfume platform. Your job is to catch design system violations and UX quality issues that code-focused reviewers miss.

Reference: docs/design/DESIGN_CHECKLIST.md — all per-change checks apply.

Apply the ui-ux-pro-max 8-rule priority framework (in priority order):
1. CRITICAL: Accessibility — WCAG AA contrast, alt text, ARIA labels, keyboard nav
2. CRITICAL: Touch — all interactive elements ≥ 44×44px touch target
3. HIGH: Performance — images via next/image, no render-blocking, lazy loading
4. HIGH: Layout — no horizontal scroll, correct reflow at 375/768/1440px
5. MEDIUM: Typography — Fredoka headings, Manrope body, correct scale
6. MEDIUM: Animation — transitions 400–600ms, not jarring, no motion sickness risk
7. MEDIUM: Style — amber gradient, surface hierarchy, no-line rule
8. LOW: Charts/data viz — radar-* tokens, animated, responsive, accessible

[PASTE DIFF HERE]

Check:
1. **Interaction states** — Does every interactive element have: hover, active, loading, error, empty, disabled states?
2. **Cognitive load** — Is any new view showing too much at once? (> 7 visible groups is a smell)
3. **Progressive disclosure** — Is secondary info always visible, or revealed on demand?
4. **Data visualization** — Any new chart/stat? Uses --radar-* tokens? Animated? Has ARIA label?
5. **Note pills** — getNoteFamily() applied? All 8 families handled?
6. **Brand voice** — Every new string of UI copy compliant with DESIGN_CHECKLIST §2?
7. **Information architecture** — New feature has clear entry point? No orphaned pages?
8. **Gradient consistency** — Buttons use linear-gradient(135deg, #F5A623, #b87311)? Cards use correct card gradient?

Rate each finding: CRITICAL / HIGH / MEDIUM / LOW
Format: [SEVERITY] Layer (Accessibility/Touch/Layout/etc.) — Issue — file:line — Fix: [what to change]
```

---

### Reviewer 4 — Adversarial

Read `.agents/agents/reviewer-4-adversarial.md`, then replace `[PASTE DIFF HERE]` with the actual diff before spawning the Agent.


---

### Reviewer 6 — Coding Standards

```
You are a coding standards reviewer for NOSE perfume platform.
Reference: docs/CODING_STANDARDS.md — every rule applies.

[PASTE DIFF HERE]

Review against the full NOSE Coding Standards. Check every category:

1. **SOLID / Architecture**
   - Single Responsibility: does any function/class do more than one thing?
   - Separation of concerns: business logic in routes/components? DB logic in services?
   - Dependency Injection: tight coupling between modules?

2. **Clean Code**
   - Functions > 30 lines? (flag each one)
   - Nesting depth > 3 levels? (flag each one)
   - Magic numbers? (any literal number that isn't 0, 1, -1)
   - Abbreviations or meaningless names? (data, temp, val, x, cb)
   - Duplicate logic that should be extracted?

3. **Error Handling**
   - Empty catch blocks? Silent failures?
   - Missing error context in messages? (what failed, what input/ID)
   - Errors swallowed instead of propagated?

4. **Logging**
   - Any `print()` statements in Python?
   - Any `console.log()` in React components?
   - Missing INFO logs on key actions (fetches, writes, searches)?
   - Missing ERROR logs on failure paths?

5. **Testing**
   - New functions without tests?
   - Tests checking implementation (mocking internals) instead of behavior?
   - Shared state between tests?
   - Missing fixtures for setup/teardown?

6. **Documentation**
   - Exported functions without JSDoc / docstrings?
   - Missing param/return documentation on public APIs?

7. **Anti-patterns**
   - God classes/functions doing too much?
   - Copy-paste code blocks?
   - Hardcoded config that belongs in env?
   - Global mutable state?
   - YAGNI violations — code built for hypothetical future use?

8. **Dependencies**
   - New package added? Is it justified? Could it be 10 lines instead?
   - Known vulnerable or unmaintained package?

Rate each finding: CRITICAL / HIGH / MEDIUM / LOW
CRITICAL = silent failure, no error handling, hardcoded secret
HIGH = SOLID violation, function > 60 lines, no tests on critical path
MEDIUM = magic numbers, missing docs, print statements
LOW = naming, minor DRY violations

Format: [SEVERITY] Category — Issue — file:line — Fix: [specific action]
```

---

### Reviewer 7 — Acceptance Criteria (LOAD-BEARING)

This reviewer gates the verdict. Any unmet criterion = automatic NEEDS FIXES regardless of what the others say.

```
You are the acceptance criteria verifier for the NOSE review system.

Your job: for each acceptance criterion on the ticket, decide whether the diff actually satisfies it. You are the last line of defense against "looks good, ships broken spec."

TICKET: [ticket_id — e.g. TASK-165]
ACCEPTANCE CRITERIA (numbered list from Step 1.25):
1. [criterion 1]
2. [criterion 2]
...

DIFF:
[PASTE DIFF HERE]

ADDITIONAL CONTEXT YOU MAY USE:
- Read any file in ~/Documents/GitHub/TryNose/nose-fe or nose-be to verify claims
- Run `grep -r "..." src/` to confirm a string/token is actually present
- Check docs/design/DESIGN_CHECKLIST.md for brand/copy rules when a criterion references them

For EACH criterion, produce one line with a verdict:
  ✅ MET       — Evidence: file:line or commit ref showing the criterion is satisfied
  ⚠️ PARTIAL  — What's done + what's missing (specific)
  ❌ NOT MET  — Why it's missing + exactly what code/change would satisfy it
  ❓ UNCLEAR  — The criterion itself is ambiguous; state the ambiguity and ask the orchestrator to clarify with the user

Rules:
- Never mark MET without concrete evidence (file:line, function name, or visible behavior).
- Never mark MET because "the component exists" — check the criterion's actual requirement (e.g. if criterion says "shows error state", verify an error state is rendered, not just that a component file was created).
- If a criterion references a design spec (e.g. "uses --elysian-glass-light tokens"), grep the diff to confirm the token is actually used, not just imported.
- If a criterion references copy (e.g. "empty state says 'Nothing matched. Try another note.'"), grep the diff for the exact string.
- If a criterion references a route, visit it (via chrome-devtools-mcp or /browse) when practical.

End with a summary:
  MET: X / TOTAL
  PARTIAL: Y
  NOT MET: Z
  UNCLEAR: W
  VERDICT: PASS (all MET) | BLOCK (any NOT MET or PARTIAL) | NEEDS CLARIFICATION (any UNCLEAR)

Format each finding as:
  [✅/⚠️/❌/❓] AC#N: [criterion text] — [evidence or gap] — file:line
```

---

## Step 3: Synthesize Results

After all 7 reviewers complete, produce the unified report:

```
╔══════════════════════════════════════════════════════════════╗
║            NOSE REVIEW REPORT — [branch-name]               ║
║            Ticket: [TASK-XXX] | Iteration: [N]              ║
║            Reviewed: [date] | Files: N | Lines: +X/-Y       ║
╠══════════════════════════════════════════════════════════════╣
║  VERDICT: [APPROVED / APPROVED WITH NOTES / NEEDS FIXES]    ║
║  ACCEPTANCE CRITERIA: [X / TOTAL met]                       ║
╚══════════════════════════════════════════════════════════════╝

ACCEPTANCE CRITERIA (load-bearing — any ❌ blocks merge):
  ✅ AC#1: [criterion text] — Evidence: file:line
  ❌ AC#2: [criterion text] — Missing: [what's not done] — Fix: [what to add]
  ⚠️ AC#3: [criterion text] — Partial: [what's done + what's left]
  ❓ AC#4: [criterion text] — Unclear: [ambiguity — needs user clarification]

HIGH CONFIDENCE (2+ reviewers flagged):
  🔴 [CRITICAL] SQL injection in search endpoint — backend/routes/search.py:45

ENGINEERING:
  🔴 [CRITICAL] ...
  🟠 [HIGH] ...
  🟡 [MEDIUM] ...
  ⚪ [LOW] ...

SECURITY:
  🔴 [CRITICAL] API key exposed in client-side code — src/lib/api.ts:12
  ...

DESIGN:
  🟠 [HIGH] Hardcoded #1A1825 (deprecated Lavender bg — use var(--color-bg)) — src/components/Card.tsx:23
  ...

DESIGN CONSISTENCY:
  🔴 [CRITICAL] Missing hover/error states on new SaveButton component — src/components/SaveButton.tsx
  🟡 [MEDIUM] "Loading..." copy on line 45 — should be "Distilling results..." — src/components/Grid.tsx:45
  ...

CODING STANDARDS:
  🔴 [CRITICAL] Empty catch block — silent failure — src/hooks/usePerfume.ts:34
  🟠 [HIGH] Business logic in route handler, should be in service — backend/app/api/routes/search.py:67
  🟡 [MEDIUM] Magic number 85 — extract as QA_PASSING_THRESHOLD constant — backend/app/services/qa.py:12
  ...

ADVERSARIAL:
  [FIXABLE] Double-submit race condition on save button — src/components/FavButton.tsx:67
  ...

─────────────────────────────────────────────────────
SUMMARY:
  Critical: N (MUST FIX before merge)
  High:     N (SHOULD FIX before merge)
  Medium:   N (FIX in follow-up ticket)
  Low:      N (Optional improvements)

NEXT STEPS:
  [ ] Fix all CRITICAL issues
  [ ] Fix all HIGH issues
  [ ] Re-run /review after fixes
  [ ] Run /ship when clean
```

## Step 4: Write Findings to State

After synthesizing, write the review results to shared state:

```bash
python3 -c "
import json
from datetime import datetime, timezone

with open('.agents/nose-state.json', 'r') as f:
    state = json.load(f)

# Determine verdict
critical_count = 0        # replace with actual count
high_count = 0            # replace with actual count
ac_not_met_count = 0      # acceptance criteria marked ❌ NOT MET
ac_partial_count = 0      # acceptance criteria marked ⚠️ PARTIAL
ac_unclear_count = 0      # acceptance criteria marked ❓ UNCLEAR

# Acceptance criteria gate FIRST — any NOT MET or PARTIAL blocks merge,
# UNCLEAR requires user clarification before verdict can be finalized.
if ac_unclear_count > 0:
    verdict = 'NEEDS_CLARIFICATION'
    next_phase = 'awaiting_clarification'
elif ac_not_met_count > 0 or ac_partial_count > 0:
    verdict = 'NEEDS_FIXES'
    next_phase = 'fix_required'
elif critical_count > 0:
    verdict = 'NEEDS_FIXES'
    next_phase = 'fix_required'
elif high_count > 3:
    verdict = 'NEEDS_FIXES'
    next_phase = 'fix_required'
elif high_count > 0:
    verdict = 'APPROVED_WITH_NOTES'
    next_phase = 'ready_to_ship'
else:
    verdict = 'APPROVED'
    next_phase = 'ready_to_ship'

state['review_feedback']['verdict'] = verdict
state['review_feedback']['iteration'] = state['review_feedback'].get('iteration', 0) + 1
state['review_feedback']['acceptance_criteria'] = [
    # {'id': 'AC#1', 'status': 'MET'|'PARTIAL'|'NOT_MET'|'UNCLEAR',
    #  'criterion': '...', 'evidence_or_gap': '...', 'file': '...', 'line': N}
]
state['review_feedback']['critical'] = [
    # Add actual critical findings here
    # {'description': 'SQL injection in search', 'file': 'backend/routes/search.py', 'line': 45}
]
state['review_feedback']['high'] = [
    # Add actual high findings here
]
state['review_feedback']['medium'] = [
    # Add actual medium findings here
]
state['review_feedback']['low'] = [
    # Add actual low findings here
]

state['current_phase'] = next_phase
state['updated_at'] = datetime.now(timezone.utc).isoformat()
state['history'].append({
    'timestamp': datetime.now(timezone.utc).isoformat(),
    'phase': 'review',
    'action': 'review_complete',
    'detail': (
        f'Verdict: {verdict}. AC met: {len([])}, AC not met: {ac_not_met_count}, '
        f'AC partial: {ac_partial_count}, AC unclear: {ac_unclear_count}, '
        f'Critical: {critical_count}, High: {high_count}'
    )
})

with open('.agents/nose-state.json', 'w') as f:
    json.dump(state, f, indent=2)

print(f'State updated: review complete. Verdict: {verdict}')
print(f'Next phase: {next_phase}')
"
```

## Verdict Rules

Acceptance Criteria gate everything — the code-quality signals only matter if the feature actually does what the ticket asked for.

| Findings | Verdict | State Phase |
|----------|---------|-------------|
| Any ❓ UNCLEAR acceptance criterion | NEEDS CLARIFICATION | `awaiting_clarification` → ask user, do not proceed |
| Any ❌ NOT MET or ⚠️ PARTIAL acceptance criterion | NEEDS FIXES | `fix_required` → `/nose-orchestrator` triggers `/build` fix mode with AC gap list |
| All AC met, any Critical code finding | NEEDS FIXES | `fix_required` → `/nose-orchestrator` triggers `/build` fix mode |
| All AC met, 0 Critical, 4+ High | NEEDS FIXES | `fix_required` |
| All AC met, 0 Critical, 1–3 High | APPROVED WITH NOTES | `ready_to_ship` → fix highs or document |
| All AC met, 0 Critical, 0 High | APPROVED | `ready_to_ship` → run `/ship` |

**Fix mode precedence:** when triggering `/build` fix mode, the acceptance-criteria gap list takes priority over code-quality findings. Fix the missing behavior first, then address code-quality issues.

## Auto-Fix Option

For LOW findings only, offer: "Want me to auto-fix the LOW severity issues now?"
If yes, fix them and re-commit before proceeding.

## Orchestrator Signal

After writing state, if `NEEDS_FIXES`:
- State phase is `fix_required`
- `/nose-orchestrator` will auto-trigger `/build` in fix mode
- Fix pass will read `state.review_feedback.critical` and `state.review_feedback.high`
- After fix, `/review` runs again (iteration count increments)
- Max 2 fix iterations — if still failing after 2, escalate to user
