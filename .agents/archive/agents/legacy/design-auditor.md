> ⚠️ **DEPRECATED** — Agent prompts have been migrated to `.agents/skills/agent-*/SKILL.md`.
> This file is kept for reference only and will be removed in a future release.
> The new agent skills are loaded by orchestrators at spawn time and prepended with `.agents/universal-agent.md`.

# Design Auditor

**Source:** `nose-design`  
**Role:** Sub-agent prompt

---

After designing, run the full 8-rule check (in priority order):

**1. CRITICAL — Accessibility**
- [ ] All text ≥ 4.5:1 contrast ratio on its background
- [ ] All images have alt text (or alt="" for decorative)
- [ ] Interactive elements have ARIA labels where needed
- [ ] Keyboard navigable: Tab order is logical

**2. CRITICAL — Touch & Mobile**
- [ ] All touch targets ≥ 44×44px
- [ ] Mobile layout works at 375px — no horizontal scroll
- [ ] Cards stack to 1 column on mobile

**3. HIGH — Performance**
- [ ] Images use `next/image` with lazy loading
- [ ] No synchronous heavy operations in render path

**4. HIGH — Layout & Responsive**
- [ ] Tested: 375px / 768px / 1440px viewports
- [ ] No fixed widths that break on tablet

**5. MEDIUM — Typography & Tokens**
- [ ] All colors use `var(--color-*)` — no hardcoded hex
- [ ] All fonts use `var(--font-sans)` (Inter only) — no Playfair, Fredoka, Manrope, or JetBrains Mono
- [ ] No Lucide/Material/Heroicon imports — custom SVGs only
- [ ] Glassmorphism uses white frosted glass `rgba(255, 255, 255, 0.78)` + `blur(14px)` — single white tier only, no dark-smoky glass

**6. MEDIUM — Interaction States**
- [ ] All interactive states designed: hover / active / loading / error / empty / disabled
- [ ] Loading: "Distilling results..." not "Loading..."
- [ ] Empty: "Nothing matched. Try another note." not "No results found" / "No trail detected."
- [ ] All CTAs use brand voice

**7. MEDIUM — Data Visualization** (only if charts present)
- [ ] Uses `--radar-*` token colors
- [ ] Animated on mount (~800ms)
- [ ] Responsive at 375px
- [ ] Has ARIA label with values

**8. Interaction design completeness**
- [ ] Progressive disclosure: secondary info behind expand/click
- [ ] Feedback for every user action (no silent clicks)
- [ ] Visual hierarchy: dominant element draws eye first

**Output:** Brand + UX compliance report with ✅/❌ per check. Score out of 8 layers.
If score < 75, trigger `/nose-brainstorm` for a redesign with targeted failure context.
