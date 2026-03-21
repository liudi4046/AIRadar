from fastapi import APIRouter, HTTPException, Query

from ..db import get_supabase

router = APIRouter(prefix="/api/posts", tags=["posts"])

POST_SELECT = "*, entities(id, name, avatar, identity_tag)"


@router.get("/timeline")
async def get_timeline(
    entity_ids: str = Query(..., description="Comma-separated entity IDs"),
    page: int = Query(0, ge=0),
    page_size: int = Query(20, ge=1, le=50),
):
    """Get timeline posts for subscribed entities, ordered by published_at desc."""
    client = get_supabase()
    ids = [eid.strip() for eid in entity_ids.split(",") if eid.strip()]
    start = page * page_size
    end = start + page_size - 1

    result = (
        client.table("posts")
        .select(POST_SELECT)
        .in_("entity_id", ids)
        .order("published_at", desc=True)
        .range(start, end)
        .execute()
    )
    return result.data


@router.get("/trending")
async def get_trending(
    page: int = Query(0, ge=0),
    page_size: int = Query(10, ge=1, le=50),
):
    """Get trending/hot posts for recommendation."""
    client = get_supabase()
    start = page * page_size
    end = start + page_size - 1

    result = (
        client.table("posts")
        .select(POST_SELECT)
        .eq("is_trending", True)
        .order("published_at", desc=True)
        .range(start, end)
        .execute()
    )
    return result.data


@router.get("/entity/{entity_id}")
async def get_entity_posts(
    entity_id: str,
    page: int = Query(0, ge=0),
    page_size: int = Query(20, ge=1, le=50),
):
    """Get all posts for a specific entity."""
    client = get_supabase()
    start = page * page_size
    end = start + page_size - 1

    result = (
        client.table("posts")
        .select(POST_SELECT)
        .eq("entity_id", entity_id)
        .order("published_at", desc=True)
        .range(start, end)
        .execute()
    )
    return result.data


@router.get("/{post_id}")
async def get_post_detail(post_id: str):
    """Get full detail of a single post."""
    client = get_supabase()
    result = client.table("posts").select(POST_SELECT).eq("id", post_id).execute()
    if not result.data:
        raise HTTPException(status_code=404, detail="Post not found")
    return result.data[0]
