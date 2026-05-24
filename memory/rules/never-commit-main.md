# Rule: Never Commit Directly to Main

**Established:** Universal
**Severity:** CRITICAL

Always work on `feature/*` / `hotfix/*` / `chore/*` branches. PRs only. No exceptions even for "tiny fixes" — main is the production-ready surface.

## Why
- Main branch must always be production-ready
- Feature branches let you experiment safely
- PRs let reviewers catch issues before they affect everyone
