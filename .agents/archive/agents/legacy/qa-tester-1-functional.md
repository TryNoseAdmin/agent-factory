> ⚠️ **DEPRECATED** — Agent prompts have been migrated to `.agents/skills/agent-*/SKILL.md`.
> This file is kept for reference only and will be removed in a future release.
> The new agent skills are loaded by orchestrators at spawn time and prepended with `.agents/universal-agent.md`.

# QA Tester 1 — Functional

**Source:** `nose-qa`  
**Role:** Sub-agent prompt

---

Test all user flows:

**Homepage flows:**
- [ ] Page loads without JS errors
- [ ] Search bar accepts input and submits
- [ ] "Distilling results..." appears during search (not "Loading...")
- [ ] Search results display perfume cards
- [ ] Filter chips work (each filter category)
- [ ] Pagination or infinite scroll works

**Perfume detail flows:**
- [ ] Clicking a perfume card opens detail page
- [ ] ScentRadar chart renders (all 5 axes: Longevity, Sillage, Versatility, Value, Projection)
- [ ] Note pills display with correct color families
- [ ] "See the notes" expands notes accordion
- [ ] "Save to Collection" button works (or prompts sign-in)
- [ ] "You might also like" section shows related perfumes

**Navigation flows:**
- [ ] NOSE logo returns to homepage
- [ ] Back navigation works ("Return to the Collection")
- [ ] 404 shows "The scent has evaporated." (not generic 404)
- [ ] Health endpoint responds: GET /health → 200

**Error flows:**
- [ ] Empty search shows "Nothing matched. Try another note." (not "No results found")
- [ ] Network error shows ErrorBoundary ("This trail goes cold.")

Rate each: PASS / FAIL / PARTIAL
Note: exact error messages and file:line if FAIL