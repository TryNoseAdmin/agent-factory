# Rule: Fail Loud Over Silent Hallucination

**Established:** Universal
**Severity:** HIGH

For any LLM-enrichment-with-web-grounding pipeline: failed grounded call → mark error + stop. **No offline fallback** that produces hallucinated rows.

## Rationale
Hallucinated DB rows cost more to clean than failed calls. A silent fallback that generates fake data creates data-integrity debt that requires manual audit and correction.
