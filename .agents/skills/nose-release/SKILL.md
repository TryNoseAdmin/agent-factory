> ⚠️ **DEPRECATED** — This skill has been superseded by the agent-orchestrator architecture.
> Use `/orchestrate-*` skills instead. This file is kept for backward compatibility and will be removed in a future release.
> See `~/.agents/skills/orchestrate-*/SKILL.md` for the new thin orchestrators and `~/.agents/agents/agent-*.md` for domain agents.

---
name: nose-release
version: 1.1.0
description: |
  NOSE + Cureyt post-merge release workflow. Auto-detects which repo (nose vs cureyt) and runs the right flow. Updates docs, bumps versions in lock-step (cureyt: VERSION + 3 subpackage.json files + extension dist rebuild), closes the Notion ticket (nose only — cureyt has no Notion), polishes the CHANGELOG, creates a git tag. Use after a PR merges to main: "release", "close ticket", "update docs", "post-merge", "wrap up TASK-XXX".
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Grep
  - Glob
  - AskUserQuestion
---

# /release — NOSE + Cureyt Post-Merge Release Workflow

You are the post-merge release workflow. Run after a PR has been merged to main.

## Step 0: Detect repo (NOSE vs CUREYT)

The skill handles two repos:
  - **nose** (perfume platform) — has Notion tickets, three sub-repos (nose-fe / nose-be / nose), single repo-root `VERSION` file
  - **cureyt** (podcast mention extractor Chrome extension) — no Notion, monorepo with three subpackages (`extension/`, `worker/`, `website/`), each with its own `package.json` whose `version` field flows to user-visible places (Chrome extension manifest, package metadata)

Detect via the git remote URL:

```bash
REMOTE=$(git config --get remote.origin.url 2>/dev/null || echo "")
if echo "$REMOTE" | grep -q "/cureyt"; then
  REPO_MODE="cureyt"
elif echo "$REMOTE" | grep -q "/nose"; then
  REPO_MODE="nose"
else
  REPO_MODE="unknown"
fi
echo "Detected repo mode: $REPO_MODE"
```

If `REPO_MODE=cureyt` → **jump to the "## Cureyt release workflow" section at the bottom of this file**. Skip Steps 1–7 below.

If `REPO_MODE=nose` → continue with Step 1.

If `REPO_MODE=unknown` → ask the user which repo this is before proceeding.

## Step 1: Identify What Merged

```bash
# Get to main
git checkout main
git pull origin main

# See what was just merged
git log --oneline -5
git diff HEAD~1...HEAD --stat
```

Identify: ticket number, feature name, version number from CHANGELOG.

## Step 2: Update Affected Documentation

Read the diff and identify which docs need updating:

| If this changed... | Update this doc... |
|--------------------|--------------------|
| API endpoints | `PROJECT:backend-repo/backend/app/api/routes/` (live code) or `docs/NOSE_PRODUCTION_ARCHITECTURE.md` |
| Database schema | `PROJECT:backend-repo/backend/app/models/__init__.py` (ORM source of truth) + `docs/schema/perfume-schema-v2.md` |
| Tech stack | `docs/TECH_STACK.md` |
| Deployment | `docs/REPOS.md` §Deploy Status (Vercel/Render/Neon targets + env contract) |
| Brand/design | `docs/brand_guidelines.md` |
| Cost implications | `docs/TECH_STACK.md` §Complete Cost Breakdown (COST_CONTROL_STRATEGY.md archived 2026-04-22 — its pre-v2 Ollama/11-agent polling scope no longer applies) |

For each affected doc:
1. Read the current version
2. Add/update the relevant section
3. Keep the existing voice and format

Don't rewrite entire docs — make surgical updates only.

## Step 3: Cross-Doc Consistency Check

Quick scan for stale references:
```bash
# Find any references to old version numbers
grep -r "v0\.[0-9]\." docs/ --include="*.md" | grep -v "CHANGELOG"

# Find TODO/FIXME that were resolved by this change
grep -r "TODO\|FIXME" docs/ --include="*.md"
```

Fix any stale references found.

## Step 4: Close the Notion Ticket

Mark the ticket as Completed and add implementation summary.

Implementation summary template:
```
✅ Completed in v[X.Y.Z]
PR: [GitHub PR URL]
Branch: feature/task-[XXX]-[slug]
Merged: [date]

What was implemented:
- [Key change 1]
- [Key change 2]
- [Key change 3]

Tests added:
- [Test file]: [what it tests]

Files changed: [N files, +X/-Y lines]
```

## Step 5: Polish CHANGELOG Entry

Read the CHANGELOG entry added during `/ship` and apply brand voice polish:

**Brand voice for CHANGELOG:**
- Use active voice: "Added" not "The system now has"
- Be specific: "Perfume detail page now shows ScentRadar" not "Improved perfume page"
- Focus on user value: what does the user experience differently?
- Technical details go in "Technical Details" section, not the summary

**Before (technical):**
> Fixed N+1 query in search endpoint by adding eager loading

**After (brand voice):**
> **Search performance** — Results load up to 4x faster; eliminated redundant database queries

## Step 6: Create Git Tag

```bash
VERSION=$(cat VERSION)
git tag -a "v$VERSION" -m "Release v$VERSION — $(date +%Y-%m-%d)"
git push origin "v$VERSION"
echo "Tagged: v$VERSION"
```

## Step 7: Done

Output:
```
✅ Release complete!

Version: v[X.Y.Z]
Ticket: TASK-XXX → Completed
Docs updated: [list of files]
Tag: v[X.Y.Z]

The scent has been bottled. 🫧
```

## NOSE Context

- Sprint tracker: https://www.notion.so/8a82f4d7c75f49699c8984d0074e89fb
- Docs directory: `docs/`
- Key architecture doc: `docs/NOSE_PRODUCTION_ARCHITECTURE.md`
- Brand voice: see CLAUDE.md for copy guidelines

---

## Cureyt release workflow

Use this section ONLY when Step 0 detected `REPO_MODE=cureyt`. The flow mirrors NOSE's spirit but adapts to cureyt's structure (no Notion, monorepo with three subpackages, Chrome extension that needs a dist rebuild).

### C1: Identify what merged

```bash
git checkout main
git pull --ff-only origin main
git log --oneline -5
git diff HEAD~1...HEAD --stat
```

Identify: feature/fix name, current `VERSION` value, the merged PR number.

### C2: Decide the version bump

Cureyt follows SemVer:
- **Patch** (1.4.0 → 1.4.1) — bug fix, internal cleanup, transparent to users
- **Minor** (1.4.0 → 1.5.0) — new feature OR meaningful behavior change OR cost change OR new dependency. Backward-compatible API.
- **Major** (1.x.x → 2.0.0) — breaking API change, schema change requiring user action, removed feature.

Examples from prior cureyt history:
- v1.2.0 (cleaner + corrected pricing) — minor (cost change material)
- v1.2.1 (bundled error PNG) — patch
- v1.3.0 (abuse defense) — minor (new feature, schema migration, new dep)
- v1.3.1 (transcript chip-bar fix) — patch
- v1.4.0 (default model swap to k2-turbo) — minor (cost + quality + behavior change)

When in doubt, ask the user.

### C3: Bump VERSION + all three subpackage.json files in lock-step

**Critical** — the repo-root `VERSION` file is decorative; the three subpackage `package.json` `version` fields are the ones that matter:

| File | Why it matters |
|---|---|
| `extension/package.json` | `manifest.config.ts` reads `pkg.version` → ends up in `dist/manifest.json` → **what Chrome shows in `chrome://extensions`** |
| `worker/package.json` | Cosmetic in Workers (no user-visible surface today), but kept aligned for sanity |
| `website/package.json` | Cosmetic for Astro, but same |

A pre-2026-05-02 release-process bug (fixed in PR #57) left these three pinned at scaffolding versions for months while only `VERSION` got bumped. **Do not regress that fix.**

```bash
NEW_VERSION="X.Y.Z"  # set this from C2
python3 - <<PYEOF
import re
NEW = "$NEW_VERSION"
open("VERSION", "w").write(NEW + "\n")
for sub in ("extension", "worker", "website"):
    p = f"{sub}/package.json"
    txt = open(p).read()
    new = re.sub(r'"version":\s*"[^"]+"', f'"version": "{NEW}"', txt, count=1)
    open(p, "w").write(new)
print("Bumped VERSION + 3 subpackage.json files to", NEW)
PYEOF
```

### C4: Sync the three lockfiles

```bash
for d in extension worker website; do
  (cd "$d" && npm install --package-lock-only --no-audit --no-fund 2>&1 | tail -1)
done
# Verify all three lockfiles now show the new version
for f in extension worker website; do
  head -5 "$f/package-lock.json" | grep '"version"' && echo "  ↑ $f"
done
```

### C5: Rebuild the extension dist (so the user can immediately reload Chrome)

The `dist/` folder is gitignored, so this build is local-only — but it's what the user reloads in `chrome://extensions`. Without this step the user reloads the previous version and asks why it's stale.

```bash
(cd extension && npm run build) 2>&1 | tail -3
echo "--- built manifest version ---"
grep '"version"' extension/dist/manifest.json | head -1
```

The grep should show the version you just bumped to. If it doesn't, the build failed or didn't pick up the package.json change.

### C6: Update CHANGELOG.md

Cureyt's `CHANGELOG.md` follows Keep a Changelog format (existing entries are the template). Open it, replace the `## [Unreleased]` placeholder with the new version + date, and write the entry directly above the previous version's entry.

Required sections per entry (use the ones that apply):
- **Lead paragraph** — one sentence on what changed + one sentence on why
- **Added / Changed / Fixed** — bullet list per category
- **Technical Details** — PR link, test counts, anything that doesn't fit the categories above

Style:
- Active voice. "Bumped default model to k2-turbo" not "Default model was bumped".
- Be specific. "Cost projection ~$0.020/call (was ~$0.011)" not "Cost may change".
- Cite measurements + sources for any external claim — anti-fabrication gate applies.

After editing CHANGELOG.md, restore the `## [Unreleased]\n\nNothing yet — see [BACKLOG.md](./BACKLOG.md) for what's next.\n` placeholder above your new entry.

### C7: Commit on chore/release-vX.Y.Z branch

```bash
git checkout -b "chore/release-v$NEW_VERSION"
git add VERSION CHANGELOG.md \
  extension/package.json extension/package-lock.json \
  worker/package.json worker/package-lock.json \
  website/package.json website/package-lock.json
git commit -m "release: $NEW_VERSION — <one-line summary>"
```

### C8: Push, open PR, merge

```bash
git push -u origin "chore/release-v$NEW_VERSION"
gh pr create --base main --head "chore/release-v$NEW_VERSION" \
  --title "release: $NEW_VERSION — <one-line summary>" \
  --body "<expanded summary + test plan>"
gh pr merge --squash --delete-branch
```

### C9: Pull main + tag + push the tag

```bash
git checkout main
git pull --ff-only origin main
git tag -a "v$NEW_VERSION" -m "Release v$NEW_VERSION — <summary>

PR #<release-pr-number>"
git push origin "v$NEW_VERSION"
```

### C10: Done — output checklist for the user

```
✅ Cureyt release v[X.Y.Z] complete

  - VERSION bumped: 1.X.X → X.Y.Z (4 files in lock-step)
  - CHANGELOG entry added
  - Tag v[X.Y.Z] pushed
  - extension/dist/manifest.json shows X.Y.Z

Next steps for you (deploy):
  1. Reload extension in chrome://extensions → click ↻ on Cureyt card
     → version badge should flip from old → X.Y.Z
  2. cd worker && wrangler deploy → push worker changes live
  3. Website auto-deploys via Cloudflare Pages on push to main

The mentions have been bottled. 🫧
```

### Cureyt-specific things this skill does NOT do (intentionally)

- **No Notion ticket close** — cureyt is a Tier 2 SaaS per the project's doc-tiering memo. Releases are tracked in CHANGELOG.md, not Notion.
- **No /docs cross-doc consistency check** — cureyt's docs are minimal (PRIVACY.md + a few READMEs). Surgical edits go in the relevant PR, not the release commit.
- **No Chrome Web Store upload** — manual step, intentionally not automated. When you're ready to push to the Web Store, zip `extension/dist/` and upload via the developer dashboard.
