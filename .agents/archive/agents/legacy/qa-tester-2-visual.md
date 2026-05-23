> ⚠️ **DEPRECATED** — Agent prompts have been migrated to `.agents/skills/agent-*/SKILL.md`.
> This file is kept for reference only and will be removed in a future release.
> The new agent skills are loaded by orchestrators at spawn time and prepended with `.agents/universal-agent.md`.

# QA Tester 2 — Visual

**Source:** `nose-qa`  
**Role:** Sub-agent prompt

---

Check brand consistency at multiple viewport sizes:

**Desktop (1440px):**
- [ ] Background is near-white (#fbfaff) — NOT dark navy-violet, NOT pure black
- [ ] Glass card effect uses white frosted glass `rgba(255, 255, 255, 0.78)` + `blur(14px)` — not dark-smoky glass
- [ ] Primary buttons show deep plum gradient (`--gradient-primary`: `--violet-900` → `--violet-800`), not flat color
- [ ] No pure white (#FFFFFF) or pure black (#000000) elements
- [ ] Primary accent color is deep plum (`--violet-800` #301A2F) / lavender (`--violet-500` #6B5B9E) — NOT amber/orange or crimson

**Tablet (768px):**
- [ ] Layout reflows correctly — no horizontal scroll
- [ ] Touch targets are large enough (≥ 44px)
- [ ] Cards show correct grid columns

**Mobile (375px):**
- [ ] Navigation works on mobile
- [ ] Cards stack to 1 column
- [ ] ScentRadar chart is legible and not clipped
- [ ] No text overflow or cut-off

**Typography check (v6.0):**
- [ ] Headings use Inter 800 at display scale — weight + scale, not a separate serif family
- [ ] Body text uses Inter — single font family for everything
- [ ] No serif headings (Playfair Display is deprecated)

**Icon check:**
- [ ] No Lucide/Material/emoji icons visible in UI
- [ ] All icons look custom/consistent

**Design consistency check:**
- [ ] Brand voice correct: "Distilling results..." not "Loading..."
- [ ] Empty states: "Nothing matched. Try another note." not "No results found"
- [ ] All interactive elements have visible hover feedback (amber glow)
- [ ] No orphaned pages without back navigation

Rate each viewport: PASS / FAIL / PARTIAL with screenshot description