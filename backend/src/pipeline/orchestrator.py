import hashlib
import logging

from .fetcher import fetch_entity_feed
from .moderator import moderate_content
from .generator import generate_content
from ..db import get_supabase

logger = logging.getLogger(__name__)


def _make_post_id(entity_id: str, link: str) -> str:
    return hashlib.sha256(f"{entity_id}:{link}".encode()).hexdigest()[:16]


def save_post(post_data: dict) -> None:
    client = get_supabase()
    client.table("posts").upsert(post_data).execute()


def post_exists(post_id: str) -> bool:
    client = get_supabase()
    result = client.table("posts").select("id").eq("id", post_id).execute()
    return len(result.data) > 0


async def process_entity(entity: dict, rsshub_base_url: str) -> int:
    """Process all scrape sources for one entity. Returns count of new posts saved."""
    saved = 0
    for source in entity.get("scrape_sources", []):
        try:
            items = await fetch_entity_feed(rsshub_base_url, source)
        except Exception:
            logger.exception("Failed to fetch feed for %s source %s", entity["id"], source)
            continue

        for item in items:
            post_id = _make_post_id(entity["id"], item["link"])
            if post_exists(post_id):
                continue

            moderation = await moderate_content(item["content"])
            if not moderation.get("safe", False):
                logger.info("Content filtered for %s: %s", entity["id"], moderation.get("reason"))
                continue

            generated = await generate_content(
                original_text=item["content"],
                entity_name=entity["name"],
                entity_bio=entity.get("bio", ""),
            )

            post_data = {
                "id": post_id,
                "entity_id": entity["id"],
                "source_type": source.get("type", ""),
                "source_url": item["link"],
                "original_text": item["content"],
                "summary_zh": generated.get("summary_zh", ""),
                "insight_zh": generated.get("insight_zh", ""),
                "interpretation_zh": generated.get("interpretation_zh", ""),
                "published_at": item.get("published", ""),
                "is_trending": False,
            }
            save_post(post_data)
            saved += 1

    return saved


async def run_pipeline() -> dict:
    """Run the full pipeline for all entities. Returns stats."""
    from ..config import get_settings

    settings = get_settings()
    client = get_supabase()
    entities = client.table("entities").select("*").execute().data

    stats = {"total_entities": len(entities), "new_posts": 0, "errors": 0}
    for entity in entities:
        try:
            count = await process_entity(entity, settings.rsshub_base_url)
            stats["new_posts"] += count
        except Exception:
            logger.exception("Failed to process entity %s", entity["id"])
            stats["errors"] += 1

    return stats
