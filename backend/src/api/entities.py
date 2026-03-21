from fastapi import APIRouter, HTTPException

from ..db import get_supabase

router = APIRouter(prefix="/api/entities", tags=["entities"])


@router.get("")
async def list_entities(category: str | None = None):
    client = get_supabase()
    query = client.table("entities").select("*")
    if category:
        query = query.eq("category", category)
    result = query.execute()
    return result.data


@router.get("/{entity_id}")
async def get_entity(entity_id: str):
    client = get_supabase()
    result = client.table("entities").select("*").eq("id", entity_id).execute()
    if not result.data:
        raise HTTPException(status_code=404, detail="Entity not found")
    return result.data[0]
