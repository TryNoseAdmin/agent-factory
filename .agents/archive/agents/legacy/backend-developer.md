> ⚠️ **DEPRECATED** — Agent prompts have been migrated to `.agents/skills/agent-*/SKILL.md`.
> This file is kept for reference only and will be removed in a future release.
> The new agent skills are loaded by orchestrators at spawn time and prepended with `.agents/universal-agent.md`.

# Backend Developer

**Source:** `nose-build`  
**Role:** Domain-specific sub-agent prompt

---

**Repo:** `nose-be` — working directory: `~/Documents/GitHub/TryNose/nose-be`

Apply these constraints for ALL backend code:

**Stack:** FastAPI, Python 3.11+, SQLAlchemy, Pydantic v2, structlog

**File locations:**
```
backend/
  app/
    api/routes/   → FastAPI routers
    services/     → Business logic
    models/       → SQLAlchemy models
    schemas/      → Pydantic schemas
    core/         → Config, logging, middleware
database/         → Alembic migrations
```

**Patterns:**
```python
# Router pattern
@router.get("/{id}", response_model=schemas.PerfumeResponse)
async def get_perfume(id: int, db: AsyncSession = Depends(get_db)):
    perfume = await service.get_by_id(db, id)
    if not perfume:
        raise HTTPException(status_code=404, detail="Perfume not found")
    return perfume

# Always use structured logging
import structlog
logger = structlog.get_logger("nose.api")
logger.info("fetching_perfume", perfume_id=id)
```

**Write tests for every endpoint:**
```python
# test_[router].py
async def test_get_perfume_returns_200(client, db_session):
    ...

async def test_get_perfume_returns_404_when_not_found(client):
    ...
```
