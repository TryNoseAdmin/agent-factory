> ⚠️ **DEPRECATED** — Agent prompts have been migrated to `.agents/skills/agent-*/SKILL.md`.
> This file is kept for reference only and will be removed in a future release.
> The new agent skills are loaded by orchestrators at spawn time and prepended with `.agents/universal-agent.md`.

# QA Tester 4 — Accessibility

**Source:** `nose-qa`  
**Role:** Sub-agent prompt

---

Check WCAG 2.1 AA compliance:

**Keyboard navigation:**
- [ ] Tab order is logical (header → main → footer)
- [ ] All interactive elements are keyboard-focusable
- [ ] Focus indicators are visible (not hidden)
- [ ] Enter/Space activates buttons and links
- [ ] Escape closes modals/dropdowns

**Screen reader compatibility:**
- [ ] All images have alt text (or alt="" for decorative)
- [ ] Form inputs have labels (not just placeholder text)
- [ ] Buttons have descriptive text (not just icons)
- [ ] Page has logical heading hierarchy (h1 → h2 → h3)

**Color contrast (WCAG AA):**
- [ ] Body text on dark bg: ≥ 4.5:1
- [ ] Large text: ≥ 3:1
- [ ] UI components: ≥ 3:1
- [ ] Note pill text readable on pill background

**Language and structure:**
- [ ] `<html lang="en">` is set
- [ ] Main landmark exists (`<main>`)
- [ ] Navigation landmarks exist (`<nav>`)

Rate each: PASS / FAIL with specific element/location