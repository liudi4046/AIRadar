import asyncio
import json
import logging
from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .api.entities import router as entities_router
from .api.posts import router as posts_router
from .config import get_settings
from .db import get_supabase

logger = logging.getLogger(__name__)


def _auto_seed_entities() -> None:
    """Seed entities table on first run if it is empty."""
    client = get_supabase()
    result = client.table("entities").select("id").limit(1).execute()
    if result.data:
        return
    data_path = Path(__file__).resolve().parent.parent / "data" / "entities.json"
    if not data_path.exists():
        logger.warning("entities.json not found at %s, skipping auto-seed", data_path)
        return
    with open(data_path) as f:
        entities = json.load(f)
    for entity in entities:
        client.table("entities").upsert(entity).execute()
    logger.info("Auto-seeded %d entities on first startup", len(entities))


async def _pipeline_loop() -> None:
    """Run the content pipeline on a recurring schedule."""
    from .pipeline.orchestrator import run_pipeline

    settings = get_settings()
    interval = settings.scrape_interval_hours * 3600

    # Run once immediately on startup, then repeat on schedule.
    while True:
        try:
            logger.info("Pipeline run starting…")
            stats = await run_pipeline()
            logger.info("Pipeline run complete: %s", stats)
        except Exception:
            logger.exception("Pipeline run failed")
        await asyncio.sleep(interval)


@asynccontextmanager
async def lifespan(app: FastAPI):
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s %(levelname)s %(name)s: %(message)s",
    )
    _auto_seed_entities()
    pipeline_task = asyncio.create_task(_pipeline_loop())
    yield
    pipeline_task.cancel()


app = FastAPI(title="AI Radar API", version="0.1.0", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(entities_router)
app.include_router(posts_router)


@app.get("/health")
async def health_check():
    return {"status": "ok", "version": "0.1.0"}
