from enum import StrEnum
from typing import Any

from pydantic import BaseModel, Field


class EntityType(StrEnum):
    PERSON = "person"
    ORG = "org"
    OPENSOURCE = "opensource"
    MEDIA = "media"


CATEGORY_LABELS = {
    "core_leaders": "🧠 核心领袖",
    "top_brands": "🏢 顶级厂牌",
    "opensource_geeks": "🛠️ 开源与极客",
    "industry_intel": "📰 行业内参",
}


class Entity(BaseModel):
    id: str
    name: str
    avatar: str = ""
    identity_tag: str = ""
    type: EntityType
    bio: str = ""
    activity_tags: list[str] = Field(default_factory=list)
    influence: dict[str, str] = Field(default_factory=dict)
    recent_highlights: list[str] = Field(default_factory=list)
    scrape_sources: list[dict[str, Any]] = Field(default_factory=list)
    category: str = "core_leaders"


class Post(BaseModel):
    id: str
    entity_id: str
    source_type: str = ""
    source_url: str = ""
    original_text: str = ""
    summary_zh: str = ""
    insight_zh: str = ""
    interpretation_zh: str = ""
    translation_zh: str = ""
    published_at: str = ""
    created_at: str = ""
    is_trending: bool = False
    trending_source: str = ""
