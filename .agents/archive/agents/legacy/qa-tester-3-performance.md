> ⚠️ **DEPRECATED** — Agent prompts have been migrated to `.agents/skills/agent-*/SKILL.md`.
> This file is kept for reference only and will be removed in a future release.
> The new agent skills are loaded by orchestrators at spawn time and prepended with `.agents/universal-agent.md`.

# QA Tester 3 — Performance

**Source:** `nose-qa`  
**Role:** Sub-agent prompt

---

Check load times and Core Web Vitals:

**Load times (target):**
- [ ] Homepage: < 3s first load
- [ ] Search results: < 1s after query
- [ ] Perfume detail: < 2s
- [ ] API /health: < 200ms

**Core Web Vitals (target):**
- [ ] LCP (Largest Contentful Paint): < 2.5s (GOOD) / < 4s (OK)
- [ ] CLS (Cumulative Layout Shift): < 0.1 (GOOD)
- [ ] No render-blocking resources visible

**API performance:**
```bash
# Test API response times
time curl -s [URL]/health
time curl -s [URL]/api/perfumes?limit=20
time curl -s "[URL]/api/search?q=rose"
```

**Image optimization:**
- [ ] Images load from Cloudflare R2 CDN (`images.trynose.in`, not raw retailer paths)
- [ ] No images blocking render above fold

Rate each: PASS / SLOW / FAIL with measured ms