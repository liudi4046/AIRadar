# AI 追更 (AI Radar) MVP Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a minimal but complete AI news aggregation app that scrapes whitelisted overseas AI thought leaders, generates Chinese AI summaries/insights, and presents them in a Flutter iOS app — validating the core value proposition of "3 minutes a day, never miss an AI event."

**Architecture:** A three-tier system: (1) An overseas Python scraper fetches content from whitelisted entities via RSSHub, pipes it through Qwen3.5 (Alibaba Cloud Bailian) for moderation and AI content generation, then pushes structured data to Supabase. (2) A FastAPI backend on a domestic server exposes REST APIs for the Flutter client. (3) A Flutter iOS app with three tabs (Timeline, Discover, Profile) consumes the API.

**Tech Stack:**
- **Backend API**: Python 3.12, FastAPI, uvicorn, Supabase (PostgreSQL + Auth)
- **Scraper/Pipeline**: Python 3.12, httpx, feedparser, RSSHub (Docker)
- **AI Processing**: Qwen3.5 dual-model via Alibaba Cloud Bailian (OpenAI-compatible SDK)
  - **Qwen3.5-Flash**: Content moderation — ¥0.2/M input tokens, 98 tok/s, fast & cheap
  - **Qwen3.5-Plus**: Content generation (summary, insight, interpretation) — ¥1.52/¥3.8 per M tokens, high quality
  - Both support native `response_format: {"type": "json_object"}` for structured output (99.7% accuracy)
- **Client**: Flutter 3.x (Dart), iOS-first
- **Infrastructure**: Docker, Docker Compose

---

## Phase 0: Project Scaffolding

### Task 1: Initialize Python Backend Project

**Files:**
- Create: `backend/pyproject.toml`
- Create: `backend/requirements.txt`
- Create: `backend/.env.example`
- Create: `backend/src/__init__.py`
- Create: `backend/src/main.py`
- Create: `backend/tests/__init__.py`
- Create: `.gitignore`
- Create: `README.md`

**Step 1: Create project structure**

```
AIRadar/
├── backend/
│   ├── src/
│   │   ├── __init__.py
│   │   ├── main.py
│   │   ├── config.py
│   │   ├── models/
│   │   ├── api/
│   │   ├── services/
│   │   └── pipeline/
│   ├── tests/
│   │   └── __init__.py
│   ├── scripts/
│   ├── pyproject.toml
│   ├── requirements.txt
│   └── .env.example
├── client/          # Flutter app (Task 11+)
├── infra/           # Docker configs
└── docs/plans/
```

**Step 2: Create `backend/requirements.txt`**

```
fastapi>=0.115.0
uvicorn[standard]>=0.34.0
httpx>=0.28.0
feedparser>=6.0.0
openai>=1.60.0
supabase>=2.12.0
python-dotenv>=1.0.0
pydantic>=2.10.0
pydantic-settings>=2.7.0
pytest>=8.3.0
pytest-asyncio>=0.25.0
pytest-httpx>=0.35.0
```

**Step 3: Create `backend/.env.example`**

```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_KEY=your-anon-key
SUPABASE_SERVICE_KEY=your-service-key
QWEN_API_KEY=your-dashscope-api-key
QWEN_BASE_URL=https://dashscope.aliyuncs.com/compatible-mode/v1
QWEN_MODERATION_MODEL=qwen3.5-flash
QWEN_GENERATION_MODEL=qwen3.5-plus
RSSHUB_BASE_URL=http://localhost:1200
```

**Step 4: Create `backend/src/main.py` with health check**

```python
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="AI Radar API", version="0.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
async def health_check():
    return {"status": "ok", "version": "0.1.0"}
```

**Step 5: Create `.gitignore`**

```
__pycache__/
*.py[cod]
.env
.venv/
venv/
*.egg-info/
dist/
build/
.pytest_cache/
.coverage
node_modules/
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies
build/
*.iml
.idea/
.DS_Store
```

**Step 6: Install dependencies and verify**

Run: `cd backend && python -m venv .venv && source .venv/bin/activate && pip install -r requirements.txt`

**Step 7: Run health check test**

Run: `cd backend && python -m pytest tests/ -v`
(No tests yet, but verify pytest works)

**Step 8: Start server and test manually**

Run: `cd backend && uvicorn src.main:app --reload --port 8000`
Verify: `curl http://localhost:8000/health` → `{"status":"ok","version":"0.1.0"}`

**Step 9: Commit**

```bash
git add -A
git commit -m "chore: scaffold Python backend with FastAPI"
```

---

### Task 2: Create Configuration Module

**Files:**
- Create: `backend/src/config.py`
- Create: `backend/tests/test_config.py`

**Step 1: Write the failing test**

```python
# backend/tests/test_config.py
import os
import pytest


def test_settings_loads_from_env(monkeypatch):
    monkeypatch.setenv("SUPABASE_URL", "https://test.supabase.co")
    monkeypatch.setenv("SUPABASE_KEY", "test-key")
    monkeypatch.setenv("SUPABASE_SERVICE_KEY", "test-service-key")
    monkeypatch.setenv("QWEN_API_KEY", "test-qwen-key")

    from src.config import get_settings

    settings = get_settings()
    assert settings.supabase_url == "https://test.supabase.co"
    assert settings.supabase_key == "test-key"
    assert settings.qwen_api_key == "test-qwen-key"


def test_settings_has_defaults(monkeypatch):
    monkeypatch.setenv("SUPABASE_URL", "https://test.supabase.co")
    monkeypatch.setenv("SUPABASE_KEY", "test-key")
    monkeypatch.setenv("SUPABASE_SERVICE_KEY", "test-service-key")
    monkeypatch.setenv("QWEN_API_KEY", "test-qwen-key")

    from src.config import get_settings

    settings = get_settings()
    assert settings.rsshub_base_url == "http://localhost:1200"
    assert settings.qwen_base_url == "https://dashscope.aliyuncs.com/compatible-mode/v1"
    assert settings.qwen_moderation_model == "qwen3.5-flash"
    assert settings.qwen_generation_model == "qwen3.5-plus"
```

**Step 2: Run test to verify it fails**

Run: `cd backend && python -m pytest tests/test_config.py -v`
Expected: FAIL with `ModuleNotFoundError` or `ImportError`

**Step 3: Write implementation**

```python
# backend/src/config.py
from functools import lru_cache
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    supabase_url: str
    supabase_key: str
    supabase_service_key: str
    qwen_api_key: str
    qwen_base_url: str = "https://dashscope.aliyuncs.com/compatible-mode/v1"
    qwen_moderation_model: str = "qwen3.5-flash"
    qwen_generation_model: str = "qwen3.5-plus"
    rsshub_base_url: str = "http://localhost:1200"
    scrape_interval_hours: int = 2

    model_config = {"env_file": ".env", "extra": "ignore"}


@lru_cache
def get_settings() -> Settings:
    return Settings()
```

**Step 4: Run tests to verify they pass**

Run: `cd backend && python -m pytest tests/test_config.py -v`
Expected: 2 PASSED

**Step 5: Commit**

```bash
git add backend/src/config.py backend/tests/test_config.py
git commit -m "feat: add configuration module with Qwen3.5 dual-model settings"
```

---

## Phase 1: Database Schema & Models

### Task 3: Define Pydantic Models for Entities

**Files:**
- Create: `backend/src/models/__init__.py`
- Create: `backend/src/models/entity.py`
- Create: `backend/tests/test_models.py`

**Step 1: Write the failing test**

```python
# backend/tests/test_models.py
from datetime import datetime


def test_entity_model_creation():
    from src.models.entity import Entity, EntityType

    entity = Entity(
        id="karpathy",
        name="Andrej Karpathy",
        avatar="https://example.com/avatar.jpg",
        identity_tag="前特斯拉AI总监",
        type=EntityType.PERSON,
        bio="计算机视觉传奇人物，曾任特斯拉 AI 总监，OpenAI 联合创始人。",
        activity_tags=["🔥 高频更新 周更5+", "🧠 硬核技术"],
        influence={"twitter_followers": "1.2M", "github_stars": "48k"},
        recent_highlights=["Karpathy 发布新视频讲解 LLM 训练"],
        scrape_sources=[{"type": "twitter", "handle": "karpathy"}],
        category="core_leaders",
    )
    assert entity.name == "Andrej Karpathy"
    assert entity.type == EntityType.PERSON
    assert len(entity.activity_tags) == 2


def test_post_model_creation():
    from src.models.entity import Post

    post = Post(
        id="post-001",
        entity_id="karpathy",
        source_type="twitter",
        source_url="https://x.com/karpathy/status/123",
        original_text="LLMs don't need complex prompts anymore...",
        summary_zh="Karpathy 认为未来的大模型将不再需要复杂的 Prompt 技巧。",
        insight_zh="这是对近期 AI Agent 框架过度依赖 Prompt Engineering 的一次公开质疑。",
        interpretation_zh="Karpathy 在今天的推文中分享了他对大模型交互方式的思考...",
        published_at="2026-03-20T10:00:00Z",
        is_trending=False,
    )
    assert post.entity_id == "karpathy"
    assert post.is_trending is False
```

**Step 2: Run test to verify it fails**

Run: `cd backend && python -m pytest tests/test_models.py -v`
Expected: FAIL with `ModuleNotFoundError`

**Step 3: Write implementation**

```python
# backend/src/models/__init__.py
from .entity import Entity, EntityType, Post

__all__ = ["Entity", "EntityType", "Post"]
```

```python
# backend/src/models/entity.py
from datetime import datetime
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
```

**Step 4: Run tests to verify they pass**

Run: `cd backend && python -m pytest tests/test_models.py -v`
Expected: 2 PASSED

**Step 5: Commit**

```bash
git add backend/src/models/ backend/tests/test_models.py
git commit -m "feat: add Entity and Post pydantic models"
```

---

### Task 4: Set Up Supabase Schema & Database Client

**Files:**
- Create: `backend/src/db.py`
- Create: `backend/scripts/init_schema.sql`
- Create: `backend/tests/test_db.py`

**Step 1: Create the SQL schema**

```sql
-- backend/scripts/init_schema.sql
-- Run this in Supabase SQL Editor to create the tables

CREATE TABLE IF NOT EXISTS entities (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    avatar TEXT DEFAULT '',
    identity_tag TEXT DEFAULT '',
    type TEXT NOT NULL CHECK (type IN ('person', 'org', 'opensource', 'media')),
    bio TEXT DEFAULT '',
    activity_tags JSONB DEFAULT '[]'::jsonb,
    influence JSONB DEFAULT '{}'::jsonb,
    recent_highlights JSONB DEFAULT '[]'::jsonb,
    scrape_sources JSONB DEFAULT '[]'::jsonb,
    category TEXT DEFAULT 'core_leaders',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS posts (
    id TEXT PRIMARY KEY,
    entity_id TEXT NOT NULL REFERENCES entities(id),
    source_type TEXT DEFAULT '',
    source_url TEXT DEFAULT '',
    original_text TEXT DEFAULT '',
    summary_zh TEXT DEFAULT '',
    insight_zh TEXT DEFAULT '',
    interpretation_zh TEXT DEFAULT '',
    translation_zh TEXT DEFAULT '',
    published_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    is_trending BOOLEAN DEFAULT FALSE,
    trending_source TEXT DEFAULT ''
);

CREATE INDEX IF NOT EXISTS idx_posts_entity_id ON posts(entity_id);
CREATE INDEX IF NOT EXISTS idx_posts_published_at ON posts(published_at DESC);
CREATE INDEX IF NOT EXISTS idx_posts_is_trending ON posts(is_trending) WHERE is_trending = TRUE;
```

**Step 2: Write the failing test for DB client**

```python
# backend/tests/test_db.py
from unittest.mock import MagicMock, patch


def test_get_supabase_client():
    with patch("src.db.create_client") as mock_create:
        mock_create.return_value = MagicMock()
        from src.db import get_supabase

        client = get_supabase()
        assert client is not None
```

**Step 3: Run test to verify it fails**

Run: `cd backend && python -m pytest tests/test_db.py -v`
Expected: FAIL

**Step 4: Write implementation**

```python
# backend/src/db.py
from functools import lru_cache

from supabase import Client, create_client

from .config import get_settings


@lru_cache
def get_supabase() -> Client:
    settings = get_settings()
    return create_client(settings.supabase_url, settings.supabase_service_key)
```

**Step 5: Run tests to verify they pass**

Run: `cd backend && python -m pytest tests/test_db.py -v`
Expected: 1 PASSED

**Step 6: Commit**

```bash
git add backend/src/db.py backend/scripts/init_schema.sql backend/tests/test_db.py
git commit -m "feat: add Supabase schema and database client"
```

---

### Task 5: Seed Entity Data

**Files:**
- Create: `backend/scripts/seed_entities.py`
- Create: `backend/data/entities.json`

**Step 1: Create seed data JSON with 15 core entities**

Create `backend/data/entities.json` containing an array of 15 entities across 4 categories. Each entity must have all fields from the Entity model. Include:

**Core Leaders (5):** Sam Altman, Andrej Karpathy, Yann LeCun, Demis Hassabis, Jim Fan
**Top Brands (4):** OpenAI, Anthropic, Google DeepMind, Meta AI
**Open Source & Geeks (3):** HuggingFace, LangChain, Ollama
**Industry Intel (3):** Hacker News AI, The Rundown AI, AI News (by Ben's Bites)

Each entity needs:
- `id`: lowercase slug (e.g., `"sam-altman"`)
- `name`: display name
- `avatar`: placeholder URL (e.g., `"https://unavatar.io/twitter/{handle}"`)
- `identity_tag`: Chinese role description
- `type`: person/org/opensource/media
- `bio`: 2-3 sentence Chinese bio
- `activity_tags`: array of activity descriptors
- `influence`: dict of platform metrics
- `recent_highlights`: 2 recent highlights in Chinese
- `scrape_sources`: array of `{"type": "twitter"|"rss", "handle"|"url": "..."}` dicts
- `category`: one of `core_leaders`, `top_brands`, `opensource_geeks`, `industry_intel`

**Step 2: Create seed script**

```python
# backend/scripts/seed_entities.py
"""Seed the entities table with initial whitelist data."""
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from dotenv import load_dotenv

load_dotenv()

from src.db import get_supabase


def seed():
    data_path = Path(__file__).resolve().parent.parent / "data" / "entities.json"
    with open(data_path) as f:
        entities = json.load(f)

    client = get_supabase()
    for entity in entities:
        client.table("entities").upsert(entity).execute()
        print(f"  Seeded: {entity['name']}")

    print(f"\nDone. {len(entities)} entities seeded.")


if __name__ == "__main__":
    seed()
```

**Step 3: Run seed script (requires live Supabase)**

Run: `cd backend && python scripts/seed_entities.py`
Expected: "Done. 15 entities seeded."

**Step 4: Commit**

```bash
git add backend/data/entities.json backend/scripts/seed_entities.py
git commit -m "feat: add seed data for 15 core entities"
```

---

## Phase 2: Content Scraping Pipeline

### Task 6: RSSHub Fetcher Module

**Files:**
- Create: `backend/src/pipeline/__init__.py`
- Create: `backend/src/pipeline/fetcher.py`
- Create: `backend/tests/test_fetcher.py`

**Step 1: Write the failing test**

```python
# backend/tests/test_fetcher.py
import pytest
import httpx


MOCK_RSS_XML = """<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
  <channel>
    <title>Test Feed</title>
    <item>
      <title>Test Post Title</title>
      <link>https://x.com/karpathy/status/123</link>
      <description>LLMs don't need complex prompts anymore. The future is about better models, not better prompts.</description>
      <pubDate>Thu, 20 Mar 2026 10:00:00 GMT</pubDate>
    </item>
  </channel>
</rss>"""


@pytest.mark.asyncio
async def test_fetch_entity_feed(httpx_mock):
    httpx_mock.add_response(url="http://localhost:1200/twitter/user/karpathy", text=MOCK_RSS_XML)

    from src.pipeline.fetcher import fetch_entity_feed

    items = await fetch_entity_feed(
        rsshub_base_url="http://localhost:1200",
        source={"type": "twitter", "handle": "karpathy"},
    )
    assert len(items) == 1
    assert items[0]["title"] == "Test Post Title"
    assert "LLMs" in items[0]["content"]


@pytest.mark.asyncio
async def test_fetch_entity_feed_rss_source(httpx_mock):
    httpx_mock.add_response(url="http://localhost:1200/custom/feed", text=MOCK_RSS_XML)

    from src.pipeline.fetcher import fetch_entity_feed

    items = await fetch_entity_feed(
        rsshub_base_url="http://localhost:1200",
        source={"type": "rss", "path": "/custom/feed"},
    )
    assert len(items) == 1
```

**Step 2: Run test to verify it fails**

Run: `cd backend && python -m pytest tests/test_fetcher.py -v`
Expected: FAIL with `ModuleNotFoundError`

**Step 3: Write implementation**

```python
# backend/src/pipeline/__init__.py
```

```python
# backend/src/pipeline/fetcher.py
import feedparser
import httpx

RSSHUB_ROUTE_MAP = {
    "twitter": "/twitter/user/{handle}",
    "github_releases": "/github/release/{handle}",
}


async def fetch_entity_feed(
    rsshub_base_url: str,
    source: dict,
) -> list[dict]:
    """Fetch RSS feed for a single scrape source and return parsed items."""
    if source["type"] == "rss":
        url = f"{rsshub_base_url}{source['path']}"
    else:
        route_template = RSSHUB_ROUTE_MAP.get(source["type"])
        if not route_template:
            return []
        url = rsshub_base_url + route_template.format(**source)

    async with httpx.AsyncClient(timeout=30) as client:
        resp = await client.get(url)
        resp.raise_for_status()

    feed = feedparser.parse(resp.text)
    items = []
    for entry in feed.entries:
        items.append({
            "title": entry.get("title", ""),
            "content": entry.get("description", entry.get("summary", "")),
            "link": entry.get("link", ""),
            "published": entry.get("published", ""),
        })
    return items
```

**Step 4: Run tests to verify they pass**

Run: `cd backend && python -m pytest tests/test_fetcher.py -v`
Expected: 2 PASSED

**Step 5: Commit**

```bash
git add backend/src/pipeline/ backend/tests/test_fetcher.py
git commit -m "feat: add RSSHub fetcher module"
```

---

### Task 7: AI Content Moderation Module

**Files:**
- Create: `backend/src/pipeline/moderator.py`
- Create: `backend/tests/test_moderator.py`

**Step 1: Write the failing test**

```python
# backend/tests/test_moderator.py
import pytest
from unittest.mock import AsyncMock, patch, MagicMock


@pytest.mark.asyncio
async def test_moderate_safe_content():
    mock_response = MagicMock()
    mock_response.choices = [MagicMock(message=MagicMock(content='{"safe": true, "reason": ""}'))]

    with patch("src.pipeline.moderator._get_client") as mock_get:
        mock_client = AsyncMock()
        mock_client.chat.completions.create = AsyncMock(return_value=mock_response)
        mock_get.return_value = mock_client

        from src.pipeline.moderator import moderate_content

        result = await moderate_content("Karpathy talks about LLM training techniques")
        assert result["safe"] is True


@pytest.mark.asyncio
async def test_moderate_unsafe_content():
    mock_response = MagicMock()
    mock_response.choices = [MagicMock(message=MagicMock(content='{"safe": false, "reason": "政治敏感内容"}'))]

    with patch("src.pipeline.moderator._get_client") as mock_get:
        mock_client = AsyncMock()
        mock_client.chat.completions.create = AsyncMock(return_value=mock_response)
        mock_get.return_value = mock_client

        from src.pipeline.moderator import moderate_content

        result = await moderate_content("Some political content...")
        assert result["safe"] is False
        assert "政治" in result["reason"]
```

**Step 2: Run test to verify it fails**

Run: `cd backend && python -m pytest tests/test_moderator.py -v`
Expected: FAIL

**Step 3: Write implementation**

```python
# backend/src/pipeline/moderator.py
import json

from openai import AsyncOpenAI

from ..config import get_settings

MODERATION_PROMPT = """你是一个内容合规审查员。判断以下内容是否包含政治敏感、色情、暴力、仇恨言论等不适合发布的内容。
这些内容来自 AI/科技领域，大部分应该是安全的。只有明显违规的才标记为不安全。

请返回 JSON 格式：{"safe": true/false, "reason": "如果不安全，简要说明原因"}

待审查内容：
"""


def _get_client() -> AsyncOpenAI:
    settings = get_settings()
    return AsyncOpenAI(api_key=settings.qwen_api_key, base_url=settings.qwen_base_url)


async def moderate_content(text: str) -> dict:
    """Return {"safe": bool, "reason": str}. Uses Qwen3.5-Flash for fast, cheap moderation."""
    client = _get_client()
    settings = get_settings()
    response = await client.chat.completions.create(
        model=settings.qwen_moderation_model,
        messages=[{"role": "user", "content": MODERATION_PROMPT + text}],
        response_format={"type": "json_object"},
        temperature=0,
        max_tokens=200,
    )
    raw = response.choices[0].message.content.strip()
    try:
        return json.loads(raw)
    except json.JSONDecodeError:
        return {"safe": False, "reason": f"Failed to parse moderation response: {raw}"}
```

**Step 4: Run tests to verify they pass**

Run: `cd backend && python -m pytest tests/test_moderator.py -v`
Expected: 2 PASSED

**Step 5: Commit**

```bash
git add backend/src/pipeline/moderator.py backend/tests/test_moderator.py
git commit -m "feat: add AI content moderation module"
```

---

### Task 8: AI Content Generator Module

**Files:**
- Create: `backend/src/pipeline/generator.py`
- Create: `backend/tests/test_generator.py`

**Step 1: Write the failing test**

```python
# backend/tests/test_generator.py
import pytest
from unittest.mock import AsyncMock, patch, MagicMock
import json


MOCK_AI_OUTPUT = json.dumps({
    "summary_zh": "Karpathy 认为未来的大模型将不再需要复杂的 Prompt 技巧。",
    "insight_zh": "这是对近期 AI Agent 框架过度依赖 Prompt Engineering 的一次公开质疑，可能影响下一代开发工具的设计方向。",
    "interpretation_zh": "Karpathy 在今天的推文中分享了他对大模型交互方式的思考。他认为随着模型能力的提升，用户不再需要精心设计 Prompt 来获得好的结果。这一观点挑战了目前 Prompt Engineering 作为一项核心技能的地位..."
}, ensure_ascii=False)


@pytest.mark.asyncio
async def test_generate_content():
    mock_response = MagicMock()
    mock_response.choices = [MagicMock(message=MagicMock(content=MOCK_AI_OUTPUT))]

    with patch("src.pipeline.generator._get_client") as mock_get:
        mock_client = AsyncMock()
        mock_client.chat.completions.create = AsyncMock(return_value=mock_response)
        mock_get.return_value = mock_client

        from src.pipeline.generator import generate_content

        result = await generate_content(
            original_text="LLMs don't need complex prompts anymore...",
            entity_name="Andrej Karpathy",
            entity_bio="前特斯拉AI总监",
        )
        assert "summary_zh" in result
        assert "insight_zh" in result
        assert "interpretation_zh" in result
        assert len(result["summary_zh"]) > 0
```

**Step 2: Run test to verify it fails**

Run: `cd backend && python -m pytest tests/test_generator.py -v`
Expected: FAIL

**Step 3: Write implementation**

```python
# backend/src/pipeline/generator.py
import json

from openai import AsyncOpenAI

from ..config import get_settings

GENERATION_PROMPT = """你是一个 AI 领域资讯编辑。根据以下英文原文，生成三样中文产物。

作者信息：{entity_name}（{entity_bio}）

要求：
1. summary_zh（一句话核心摘要）：20-40字，直击核心结论，用于信息流卡片展示。
2. insight_zh（核心洞察）：1-2句，说明为什么这条消息重要，对行业有什么影响。
3. interpretation_zh（详细解读）：一篇流畅的中文深度解读，不是大纲要点罗列。要做到：
   - 用平实语言把原文核心信息讲清楚
   - 补充必要的背景知识
   - 解释潜在影响和意义
   - 如有必要用类比帮助理解
   - 篇幅：短内容100-200字，长内容300-500字

请返回 JSON 格式，包含 summary_zh、insight_zh、interpretation_zh 三个字段。

英文原文：
{text}"""


def _get_client() -> AsyncOpenAI:
    settings = get_settings()
    return AsyncOpenAI(api_key=settings.qwen_api_key, base_url=settings.qwen_base_url)


async def generate_content(
    original_text: str,
    entity_name: str,
    entity_bio: str,
) -> dict:
    """Generate summary, insight, and interpretation. Uses Qwen3.5-Plus for high-quality generation."""
    client = _get_client()
    settings = get_settings()
    prompt = GENERATION_PROMPT.format(
        entity_name=entity_name,
        entity_bio=entity_bio,
        text=original_text,
    )
    response = await client.chat.completions.create(
        model=settings.qwen_generation_model,
        messages=[{"role": "user", "content": prompt}],
        response_format={"type": "json_object"},
        temperature=0.3,
        max_tokens=2000,
    )
    raw = response.choices[0].message.content.strip()
    try:
        return json.loads(raw)
    except json.JSONDecodeError:
        return {
            "summary_zh": "",
            "insight_zh": "",
            "interpretation_zh": "",
            "_error": f"Failed to parse: {raw[:200]}",
        }
```

**Step 4: Run tests to verify they pass**

Run: `cd backend && python -m pytest tests/test_generator.py -v`
Expected: 1 PASSED

**Step 5: Commit**

```bash
git add backend/src/pipeline/generator.py backend/tests/test_generator.py
git commit -m "feat: add AI content generator (summary, insight, interpretation)"
```

---

### Task 9: Pipeline Orchestrator

**Files:**
- Create: `backend/src/pipeline/orchestrator.py`
- Create: `backend/tests/test_orchestrator.py`

**Step 1: Write the failing test**

```python
# backend/tests/test_orchestrator.py
import pytest
from unittest.mock import AsyncMock, patch, MagicMock


@pytest.mark.asyncio
async def test_process_single_entity():
    mock_items = [
        {
            "title": "Test Post",
            "content": "LLMs are amazing",
            "link": "https://x.com/test/1",
            "published": "Thu, 20 Mar 2026 10:00:00 GMT",
        }
    ]
    mock_moderation = {"safe": True, "reason": ""}
    mock_generation = {
        "summary_zh": "测试摘要",
        "insight_zh": "测试洞察",
        "interpretation_zh": "测试解读",
    }

    with (
        patch("src.pipeline.orchestrator.fetch_entity_feed", new_callable=AsyncMock, return_value=mock_items),
        patch("src.pipeline.orchestrator.moderate_content", new_callable=AsyncMock, return_value=mock_moderation),
        patch("src.pipeline.orchestrator.generate_content", new_callable=AsyncMock, return_value=mock_generation),
        patch("src.pipeline.orchestrator.save_post") as mock_save,
    ):
        from src.pipeline.orchestrator import process_entity

        entity = {
            "id": "test-entity",
            "name": "Test Entity",
            "bio": "A test entity",
            "scrape_sources": [{"type": "twitter", "handle": "test"}],
        }
        count = await process_entity(entity, rsshub_base_url="http://localhost:1200")
        assert count == 1
        mock_save.assert_called_once()


@pytest.mark.asyncio
async def test_process_entity_filters_unsafe():
    mock_items = [
        {"title": "Bad Post", "content": "Unsafe content", "link": "https://x.com/test/2", "published": ""},
    ]
    mock_moderation = {"safe": False, "reason": "政治敏感"}

    with (
        patch("src.pipeline.orchestrator.fetch_entity_feed", new_callable=AsyncMock, return_value=mock_items),
        patch("src.pipeline.orchestrator.moderate_content", new_callable=AsyncMock, return_value=mock_moderation),
        patch("src.pipeline.orchestrator.generate_content", new_callable=AsyncMock) as mock_gen,
        patch("src.pipeline.orchestrator.save_post") as mock_save,
    ):
        from src.pipeline.orchestrator import process_entity

        entity = {
            "id": "test-entity",
            "name": "Test",
            "bio": "",
            "scrape_sources": [{"type": "twitter", "handle": "test"}],
        }
        count = await process_entity(entity, rsshub_base_url="http://localhost:1200")
        assert count == 0
        mock_gen.assert_not_called()
        mock_save.assert_not_called()
```

**Step 2: Run test to verify it fails**

Run: `cd backend && python -m pytest tests/test_orchestrator.py -v`
Expected: FAIL

**Step 3: Write implementation**

```python
# backend/src/pipeline/orchestrator.py
import hashlib
import logging
from datetime import datetime

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
```

**Step 4: Run tests to verify they pass**

Run: `cd backend && python -m pytest tests/test_orchestrator.py -v`
Expected: 2 PASSED

**Step 5: Commit**

```bash
git add backend/src/pipeline/orchestrator.py backend/tests/test_orchestrator.py
git commit -m "feat: add pipeline orchestrator for entity processing"
```

---

### Task 10: Pipeline CLI Runner

**Files:**
- Create: `backend/scripts/run_pipeline.py`

**Step 1: Create the CLI runner script**

```python
# backend/scripts/run_pipeline.py
"""Run the content scraping and processing pipeline once."""
import asyncio
import logging
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from dotenv import load_dotenv

load_dotenv()

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s: %(message)s")


async def main():
    from src.pipeline.orchestrator import run_pipeline

    logging.info("Starting pipeline run...")
    stats = await run_pipeline()
    logging.info("Pipeline complete: %s", stats)


if __name__ == "__main__":
    asyncio.run(main())
```

**Step 2: Verify it runs (requires live services)**

Run: `cd backend && python scripts/run_pipeline.py`
Expected: Logs showing pipeline execution (may fail without live RSSHub/Supabase — that's ok, structure is verified)

**Step 3: Commit**

```bash
git add backend/scripts/run_pipeline.py
git commit -m "feat: add pipeline CLI runner script"
```

---

## Phase 3: REST API Layer

### Task 11: Entity API Endpoints

**Files:**
- Create: `backend/src/api/__init__.py`
- Create: `backend/src/api/entities.py`
- Create: `backend/tests/test_api_entities.py`
- Modify: `backend/src/main.py`

**Step 1: Write the failing test**

```python
# backend/tests/test_api_entities.py
import pytest
from unittest.mock import patch, MagicMock
from fastapi.testclient import TestClient


@pytest.fixture
def client():
    from src.main import app
    return TestClient(app)


def _mock_supabase_entities():
    mock = MagicMock()
    mock.table.return_value.select.return_value.execute.return_value = MagicMock(
        data=[
            {"id": "karpathy", "name": "Andrej Karpathy", "category": "core_leaders", "type": "person"},
            {"id": "openai", "name": "OpenAI", "category": "top_brands", "type": "org"},
        ]
    )
    mock.table.return_value.select.return_value.eq.return_value.execute.return_value = MagicMock(
        data=[{"id": "karpathy", "name": "Andrej Karpathy", "category": "core_leaders", "type": "person"}]
    )
    return mock


def test_list_entities(client):
    with patch("src.api.entities.get_supabase", return_value=_mock_supabase_entities()):
        resp = client.get("/api/entities")
        assert resp.status_code == 200
        data = resp.json()
        assert len(data) == 2


def test_list_entities_by_category(client):
    with patch("src.api.entities.get_supabase", return_value=_mock_supabase_entities()):
        resp = client.get("/api/entities?category=core_leaders")
        assert resp.status_code == 200


def test_get_entity_by_id(client):
    with patch("src.api.entities.get_supabase", return_value=_mock_supabase_entities()):
        resp = client.get("/api/entities/karpathy")
        assert resp.status_code == 200
        data = resp.json()
        assert data["id"] == "karpathy"
```

**Step 2: Run test to verify it fails**

Run: `cd backend && python -m pytest tests/test_api_entities.py -v`
Expected: FAIL

**Step 3: Write implementation**

```python
# backend/src/api/__init__.py
```

```python
# backend/src/api/entities.py
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
```

**Step 4: Register router in main.py**

```python
# backend/src/main.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .api.entities import router as entities_router

app = FastAPI(title="AI Radar API", version="0.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(entities_router)


@app.get("/health")
async def health_check():
    return {"status": "ok", "version": "0.1.0"}
```

**Step 5: Run tests to verify they pass**

Run: `cd backend && python -m pytest tests/test_api_entities.py -v`
Expected: 3 PASSED

**Step 6: Commit**

```bash
git add backend/src/api/ backend/src/main.py backend/tests/test_api_entities.py
git commit -m "feat: add entity API endpoints (list, filter, detail)"
```

---

### Task 12: Timeline (Posts) API Endpoints

**Files:**
- Create: `backend/src/api/posts.py`
- Create: `backend/tests/test_api_posts.py`
- Modify: `backend/src/main.py`

**Step 1: Write the failing test**

```python
# backend/tests/test_api_posts.py
import pytest
from unittest.mock import patch, MagicMock
from fastapi.testclient import TestClient


@pytest.fixture
def client():
    from src.main import app
    return TestClient(app)


MOCK_POSTS = [
    {
        "id": "post-001",
        "entity_id": "karpathy",
        "summary_zh": "测试摘要",
        "insight_zh": "测试洞察",
        "interpretation_zh": "测试解读",
        "source_url": "https://x.com/karpathy/1",
        "original_text": "Test content",
        "published_at": "2026-03-20T10:00:00Z",
        "is_trending": False,
        "entities": {"id": "karpathy", "name": "Andrej Karpathy", "avatar": "", "identity_tag": "前特斯拉AI总监"},
    },
]


def _mock_supabase_posts():
    mock = MagicMock()
    # Chain: select -> eq -> order -> range -> execute
    chain = mock.table.return_value.select.return_value
    chain.in_.return_value.order.return_value.range.return_value.execute.return_value = MagicMock(data=MOCK_POSTS)
    chain.eq.return_value.order.return_value.range.return_value.execute.return_value = MagicMock(data=MOCK_POSTS)
    chain.order.return_value.range.return_value.execute.return_value = MagicMock(data=MOCK_POSTS)
    chain.eq.return_value.execute.return_value = MagicMock(data=MOCK_POSTS[:1])
    return mock


def test_get_timeline(client):
    with patch("src.api.posts.get_supabase", return_value=_mock_supabase_posts()):
        resp = client.get("/api/posts/timeline?entity_ids=karpathy,openai")
        assert resp.status_code == 200


def test_get_entity_posts(client):
    with patch("src.api.posts.get_supabase", return_value=_mock_supabase_posts()):
        resp = client.get("/api/posts/entity/karpathy")
        assert resp.status_code == 200


def test_get_post_detail(client):
    with patch("src.api.posts.get_supabase", return_value=_mock_supabase_posts()):
        resp = client.get("/api/posts/post-001")
        assert resp.status_code == 200
```

**Step 2: Run test to verify it fails**

Run: `cd backend && python -m pytest tests/test_api_posts.py -v`
Expected: FAIL

**Step 3: Write implementation**

```python
# backend/src/api/posts.py
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
```

**Step 4: Register the posts router in main.py**

Add to `backend/src/main.py`:

```python
from .api.posts import router as posts_router
# ... after entities_router
app.include_router(posts_router)
```

**Step 5: Run tests to verify they pass**

Run: `cd backend && python -m pytest tests/test_api_posts.py -v`
Expected: 3 PASSED

**Step 6: Commit**

```bash
git add backend/src/api/posts.py backend/src/main.py backend/tests/test_api_posts.py
git commit -m "feat: add posts API endpoints (timeline, trending, entity posts, detail)"
```

---

## Phase 4: Flutter Client

### Task 13: Initialize Flutter Project

**Files:**
- Create: `client/` (Flutter project)

**Step 1: Create Flutter project**

Run: `cd /path/to/AIRadar && flutter create --org com.airadar --project-name ai_radar client`

**Step 2: Add dependencies to `client/pubspec.yaml`**

Add under `dependencies:`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  dio: ^5.7.0
  riverpod: ^2.6.0
  flutter_riverpod: ^2.6.0
  go_router: ^14.8.0
  cached_network_image: ^3.4.0
  intl: ^0.19.0
  shared_preferences: ^2.3.0
  shimmer: ^3.0.0
  url_launcher: ^6.3.0
```

**Step 3: Install dependencies**

Run: `cd client && flutter pub get`

**Step 4: Verify project builds**

Run: `cd client && flutter build ios --no-codesign --debug`
Expected: Build succeeds

**Step 5: Commit**

```bash
git add client/
git commit -m "chore: initialize Flutter project with core dependencies"
```

---

### Task 14: Flutter Data Layer (Models + API Client)

**Files:**
- Create: `client/lib/models/entity.dart`
- Create: `client/lib/models/post.dart`
- Create: `client/lib/services/api_client.dart`
- Create: `client/lib/services/api_config.dart`
- Create: `client/test/models/entity_test.dart`
- Create: `client/test/models/post_test.dart`

**Step 1: Write failing test for Entity model**

```dart
// client/test/models/entity_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_radar/models/entity.dart';

void main() {
  test('Entity.fromJson parses correctly', () {
    final json = {
      'id': 'karpathy',
      'name': 'Andrej Karpathy',
      'avatar': 'https://example.com/avatar.jpg',
      'identity_tag': '前特斯拉AI总监',
      'type': 'person',
      'bio': '计算机视觉传奇人物',
      'activity_tags': ['🔥 高频更新'],
      'influence': {'twitter_followers': '1.2M'},
      'recent_highlights': ['发布新视频'],
      'category': 'core_leaders',
    };

    final entity = Entity.fromJson(json);
    expect(entity.id, 'karpathy');
    expect(entity.name, 'Andrej Karpathy');
    expect(entity.type, EntityType.person);
    expect(entity.activityTags.length, 1);
  });
}
```

**Step 2: Run test to verify it fails**

Run: `cd client && flutter test test/models/entity_test.dart`
Expected: FAIL

**Step 3: Implement Entity model**

```dart
// client/lib/models/entity.dart
enum EntityType { person, org, opensource, media }

class Entity {
  final String id;
  final String name;
  final String avatar;
  final String identityTag;
  final EntityType type;
  final String bio;
  final List<String> activityTags;
  final Map<String, String> influence;
  final List<String> recentHighlights;
  final String category;

  Entity({
    required this.id,
    required this.name,
    this.avatar = '',
    this.identityTag = '',
    required this.type,
    this.bio = '',
    this.activityTags = const [],
    this.influence = const {},
    this.recentHighlights = const [],
    this.category = 'core_leaders',
  });

  factory Entity.fromJson(Map<String, dynamic> json) {
    return Entity(
      id: json['id'] as String,
      name: json['name'] as String,
      avatar: json['avatar'] as String? ?? '',
      identityTag: json['identity_tag'] as String? ?? '',
      type: EntityType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => EntityType.person,
      ),
      bio: json['bio'] as String? ?? '',
      activityTags: (json['activity_tags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      influence: (json['influence'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v.toString())) ??
          {},
      recentHighlights: (json['recent_highlights'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      category: json['category'] as String? ?? 'core_leaders',
    );
  }
}
```

**Step 4: Run test and verify it passes**

Run: `cd client && flutter test test/models/entity_test.dart`
Expected: PASS

**Step 5: Write failing test for Post model**

```dart
// client/test/models/post_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_radar/models/post.dart';

void main() {
  test('Post.fromJson parses correctly', () {
    final json = {
      'id': 'post-001',
      'entity_id': 'karpathy',
      'source_type': 'twitter',
      'source_url': 'https://x.com/karpathy/1',
      'original_text': 'LLMs are amazing',
      'summary_zh': '测试摘要',
      'insight_zh': '测试洞察',
      'interpretation_zh': '测试解读',
      'published_at': '2026-03-20T10:00:00Z',
      'is_trending': false,
      'entities': {
        'id': 'karpathy',
        'name': 'Andrej Karpathy',
        'avatar': '',
        'identity_tag': '前特斯拉AI总监',
      },
    };

    final post = Post.fromJson(json);
    expect(post.id, 'post-001');
    expect(post.entityId, 'karpathy');
    expect(post.summaryZh, '测试摘要');
    expect(post.entity?.name, 'Andrej Karpathy');
  });
}
```

**Step 6: Implement Post model**

```dart
// client/lib/models/post.dart

class PostEntity {
  final String id;
  final String name;
  final String avatar;
  final String identityTag;

  PostEntity({
    required this.id,
    required this.name,
    this.avatar = '',
    this.identityTag = '',
  });

  factory PostEntity.fromJson(Map<String, dynamic> json) {
    return PostEntity(
      id: json['id'] as String,
      name: json['name'] as String,
      avatar: json['avatar'] as String? ?? '',
      identityTag: json['identity_tag'] as String? ?? '',
    );
  }
}

class Post {
  final String id;
  final String entityId;
  final String sourceType;
  final String sourceUrl;
  final String originalText;
  final String summaryZh;
  final String insightZh;
  final String interpretationZh;
  final String publishedAt;
  final bool isTrending;
  final String trendingSource;
  final PostEntity? entity;

  Post({
    required this.id,
    required this.entityId,
    this.sourceType = '',
    this.sourceUrl = '',
    this.originalText = '',
    this.summaryZh = '',
    this.insightZh = '',
    this.interpretationZh = '',
    this.publishedAt = '',
    this.isTrending = false,
    this.trendingSource = '',
    this.entity,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as String,
      entityId: json['entity_id'] as String,
      sourceType: json['source_type'] as String? ?? '',
      sourceUrl: json['source_url'] as String? ?? '',
      originalText: json['original_text'] as String? ?? '',
      summaryZh: json['summary_zh'] as String? ?? '',
      insightZh: json['insight_zh'] as String? ?? '',
      interpretationZh: json['interpretation_zh'] as String? ?? '',
      publishedAt: json['published_at'] as String? ?? '',
      isTrending: json['is_trending'] as bool? ?? false,
      trendingSource: json['trending_source'] as String? ?? '',
      entity: json['entities'] != null
          ? PostEntity.fromJson(json['entities'] as Map<String, dynamic>)
          : null,
    );
  }
}
```

**Step 7: Run test and verify it passes**

Run: `cd client && flutter test test/models/post_test.dart`
Expected: PASS

**Step 8: Implement API client**

```dart
// client/lib/services/api_config.dart
class ApiConfig {
  static const String baseUrl = 'http://localhost:8000';
}
```

```dart
// client/lib/services/api_client.dart
import 'package:dio/dio.dart';
import '../models/entity.dart';
import '../models/post.dart';
import 'api_config.dart';

class ApiClient {
  final Dio _dio;

  ApiClient({Dio? dio})
      : _dio = dio ?? Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));

  Future<List<Entity>> getEntities({String? category}) async {
    final params = <String, dynamic>{};
    if (category != null) params['category'] = category;
    final resp = await _dio.get('/api/entities', queryParameters: params);
    return (resp.data as List).map((e) => Entity.fromJson(e)).toList();
  }

  Future<Entity> getEntity(String entityId) async {
    final resp = await _dio.get('/api/entities/$entityId');
    return Entity.fromJson(resp.data);
  }

  Future<List<Post>> getTimeline(List<String> entityIds,
      {int page = 0}) async {
    final resp = await _dio.get('/api/posts/timeline', queryParameters: {
      'entity_ids': entityIds.join(','),
      'page': page,
    });
    return (resp.data as List).map((e) => Post.fromJson(e)).toList();
  }

  Future<List<Post>> getTrending({int page = 0}) async {
    final resp = await _dio.get('/api/posts/trending',
        queryParameters: {'page': page});
    return (resp.data as List).map((e) => Post.fromJson(e)).toList();
  }

  Future<List<Post>> getEntityPosts(String entityId, {int page = 0}) async {
    final resp = await _dio.get('/api/posts/entity/$entityId',
        queryParameters: {'page': page});
    return (resp.data as List).map((e) => Post.fromJson(e)).toList();
  }

  Future<Post> getPostDetail(String postId) async {
    final resp = await _dio.get('/api/posts/$postId');
    return Post.fromJson(resp.data);
  }
}
```

**Step 9: Run all tests**

Run: `cd client && flutter test`
Expected: All PASS

**Step 10: Commit**

```bash
git add client/lib/models/ client/lib/services/ client/test/
git commit -m "feat: add Flutter data models and API client"
```

---

### Task 15: Flutter App Shell (Router + Tab Navigation)

**Files:**
- Rewrite: `client/lib/main.dart`
- Create: `client/lib/app.dart`
- Create: `client/lib/router.dart`
- Create: `client/lib/providers.dart`
- Create: `client/lib/screens/timeline_screen.dart`
- Create: `client/lib/screens/discover_screen.dart`
- Create: `client/lib/screens/profile_screen.dart`
- Create: `client/lib/screens/shell_screen.dart`

**Step 1: Create providers**

```dart
// client/lib/providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/api_client.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final subscribedEntityIdsProvider = StateProvider<List<String>>((ref) {
  // MVP default subscriptions
  return [
    'sam-altman', 'karpathy', 'openai', 'anthropic', 'huggingface',
  ];
});
```

**Step 2: Create router with go_router**

```dart
// client/lib/router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'screens/shell_screen.dart';
import 'screens/timeline_screen.dart';
import 'screens/discover_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/post_detail_screen.dart';
import 'screens/entity_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/timeline',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => ShellScreen(navigationShell: shell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(path: '/timeline', builder: (_, __) => const TimelineScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/discover', builder: (_, __) => const DiscoverScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        ]),
      ],
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/post/:id',
      builder: (_, state) => PostDetailScreen(postId: state.pathParameters['id']!),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/entity/:id',
      builder: (_, state) => EntityScreen(entityId: state.pathParameters['id']!),
    ),
  ],
);
```

**Step 3: Create shell screen with bottom nav**

```dart
// client/lib/screens/shell_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ShellScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ShellScreen({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (i) => navigationShell.goBranch(i, initialLocation: i == navigationShell.currentIndex),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dynamic_feed), label: '动态'),
          NavigationDestination(icon: Icon(Icons.explore), label: '发现'),
          NavigationDestination(icon: Icon(Icons.person), label: '我的'),
        ],
      ),
    );
  }
}
```

**Step 4: Create placeholder screens**

```dart
// client/lib/screens/timeline_screen.dart
import 'package:flutter/material.dart';

class TimelineScreen extends StatelessWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Timeline - Coming soon')),
    );
  }
}
```

```dart
// client/lib/screens/discover_screen.dart
import 'package:flutter/material.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Discover - Coming soon')),
    );
  }
}
```

```dart
// client/lib/screens/profile_screen.dart
import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Profile - Coming soon')),
    );
  }
}
```

```dart
// client/lib/screens/post_detail_screen.dart
import 'package:flutter/material.dart';

class PostDetailScreen extends StatelessWidget {
  final String postId;
  const PostDetailScreen({super.key, required this.postId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(child: Text('Post Detail: $postId')),
    );
  }
}
```

```dart
// client/lib/screens/entity_screen.dart
import 'package:flutter/material.dart';

class EntityScreen extends StatelessWidget {
  final String entityId;
  const EntityScreen({super.key, required this.entityId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(child: Text('Entity: $entityId')),
    );
  }
}
```

**Step 5: Update main.dart and create app.dart**

```dart
// client/lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

void main() {
  runApp(const ProviderScope(child: AIRadarApp()));
}
```

```dart
// client/lib/app.dart
import 'package:flutter/material.dart';
import 'router.dart';

class AIRadarApp extends StatelessWidget {
  const AIRadarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'AI 追更',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF6750A4),
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: const Color(0xFF6750A4),
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      routerConfig: router,
    );
  }
}
```

**Step 6: Run the app**

Run: `cd client && flutter run`
Expected: App launches with three tabs (动态, 发现, 我的) and navigation works

**Step 7: Commit**

```bash
git add client/
git commit -m "feat: add Flutter app shell with tab navigation and routing"
```

---

### Task 16: Flutter Timeline Screen (Tab 1)

**Files:**
- Rewrite: `client/lib/screens/timeline_screen.dart`
- Create: `client/lib/widgets/post_card.dart`
- Create: `client/lib/widgets/trending_card.dart`

**Step 1: Create PostCard widget**

Build a card widget matching the design spec:
- Entity avatar + name (tappable → navigate to entity page) + identity tag
- Source icon (X logo for Twitter) + time
- **AI one-line summary in Chinese** (large, bold — visual center)
- First two lines of English original (light gray, small)

Key implementation points:
- Use `GestureDetector` for tap → `context.push('/post/${post.id}')`
- Avatar tap → `context.push('/entity/${post.entityId}')`
- Use `cached_network_image` for avatar
- Use `timeago` formatting for relative time

**Step 2: Create TrendingCard widget**

Similar to PostCard but:
- Shows `🔥` icon + `AI 热点` label + source attribution
- No avatar row, replaced by trending header

**Step 3: Build TimelineScreen with Riverpod**

Create providers:
- `timelineProvider`: fetches posts from API using subscribed entity IDs
- `trendingProvider`: fetches trending posts

The screen uses a `ListView.builder` that interleaves subscribed posts with trending posts (insert 1 trending post every 5 subscribed posts).

Pull-to-refresh with `RefreshIndicator`. Pagination with scroll listener.

Show `"你已看完所有最新动态 ✓"` + `"去发现更多值得关注的 AI 大牛 →"` at the bottom.

**Step 4: Run and verify**

Run: `cd client && flutter run`
Expected: Timeline tab shows post cards (or empty state if no backend data)

**Step 5: Commit**

```bash
git add client/lib/screens/timeline_screen.dart client/lib/widgets/
git commit -m "feat: implement Timeline screen with post cards and trending"
```

---

### Task 17: Flutter Discover Screen (Tab 2)

**Files:**
- Rewrite: `client/lib/screens/discover_screen.dart`
- Create: `client/lib/widgets/entity_card.dart`
- Create: `client/lib/widgets/entity_detail_sheet.dart`

**Step 1: Build entity card for list display**

Compact card showing:
- Avatar + Name + Identity tag
- 1-line bio preview
- Subscribe button (`[+ 订阅更新]` / `[已订阅 ✓]`)

**Step 2: Build entity detail bottom sheet**

Half-screen modal (`showModalBottomSheet`) showing full entity info per design spec:
1. Avatar + Name + Identity tag
2. AI bio (2-3 lines)
3. Activity tags
4. Influence metrics
5. Recent highlights (2 items)
6. `[+ 订阅更新]` button + `[查看全部动态 →]` link

**Step 3: Build DiscoverScreen**

- Fetch all entities from API, grouped by category
- Section headers: 🧠 核心领袖, 🏢 顶级厂牌, 🛠️ 开源与极客, 📰 行业内参
- Each section shows entity cards in a `ListView`
- Tap card → open entity detail sheet

**Step 4: Run and verify**

Run: `cd client && flutter run`
Expected: Discover tab shows categorized entities with subscription functionality

**Step 5: Commit**

```bash
git add client/lib/screens/discover_screen.dart client/lib/widgets/
git commit -m "feat: implement Discover screen with entity cards and detail sheet"
```

---

### Task 18: Flutter Post Detail Screen

**Files:**
- Rewrite: `client/lib/screens/post_detail_screen.dart`

**Step 1: Build the detail screen layout**

From top to bottom per design spec:
1. **Entity info bar**: avatar + name (tappable) + identity tag + time
2. **AI Core Insight card** (`insight_zh`): styled card with accent background
3. **AI Detailed Interpretation** (`interpretation_zh`): main content area, rich text
4. **Original link**: `🔗 查看原文链接` button at bottom, opens with `url_launcher`

Note: Full translation (`translation_zh`) is omitted for MVP.

**Step 2: Connect to API with Riverpod**

Create `postDetailProvider(postId)` that fetches the full post.

**Step 3: Run and verify**

Run: `cd client && flutter run`
Expected: Tapping a post card navigates to detail page with full AI analysis

**Step 4: Commit**

```bash
git add client/lib/screens/post_detail_screen.dart
git commit -m "feat: implement post detail screen with AI insight and interpretation"
```

---

### Task 19: Flutter Entity Page

**Files:**
- Rewrite: `client/lib/screens/entity_screen.dart`

**Step 1: Build entity page layout**

Per design spec:
1. **Top: Entity info area** (reuse entity detail sheet content — extract shared widget)
2. **Bottom: Entity timeline** — all posts for this entity, time-descending. Reuse PostCard but omit avatar/name row.

**Step 2: Connect to API**

Create providers for entity detail + entity posts.

**Step 3: Run and verify**

Run: `cd client && flutter run`
Expected: Tapping an entity name navigates to their dedicated page with full timeline

**Step 4: Commit**

```bash
git add client/lib/screens/entity_screen.dart client/lib/widgets/
git commit -m "feat: implement entity page with profile and dedicated timeline"
```

---

### Task 20: Flutter Profile Screen (Tab 3, Simplified)

**Files:**
- Rewrite: `client/lib/screens/profile_screen.dart`

**Step 1: Build simple profile screen**

MVP profile with:
- **订阅管理**: List of subscribed entities with unsubscribe button
- **设置**: Toggle for hot topic recommendations (stored in SharedPreferences)
- App version info

No payment, no auth, no favorites for MVP.

**Step 2: Wire subscription state**

Use the `subscribedEntityIdsProvider` from providers.dart. Persist to SharedPreferences.

**Step 3: Run and verify**

Run: `cd client && flutter run`
Expected: Profile tab shows subscriptions and settings

**Step 4: Commit**

```bash
git add client/lib/screens/profile_screen.dart
git commit -m "feat: implement simplified profile screen with subscription management"
```

---

## Phase 5: Infrastructure & Deployment

### Task 21: Docker Setup for RSSHub

**Files:**
- Create: `infra/docker-compose.yml`
- Create: `infra/rsshub/.env.example`

**Step 1: Create Docker Compose for overseas scraper node**

```yaml
# infra/docker-compose.yml
services:
  rsshub:
    image: diygod/rsshub:latest
    restart: always
    ports:
      - "1200:1200"
    environment:
      - NODE_ENV=production
      - CACHE_TYPE=memory
      - CACHE_EXPIRE=600
      - TWITTER_AUTH_TOKEN=${TWITTER_AUTH_TOKEN:-}
```

**Step 2: Verify RSSHub starts**

Run: `cd infra && docker-compose up -d rsshub`
Verify: `curl http://localhost:1200` → RSSHub welcome page

**Step 3: Commit**

```bash
git add infra/
git commit -m "chore: add Docker Compose for RSSHub deployment"
```

---

### Task 22: Backend Dockerfile & Deployment Config

**Files:**
- Create: `backend/Dockerfile`
- Modify: `infra/docker-compose.yml`

**Step 1: Create backend Dockerfile**

```dockerfile
# backend/Dockerfile
FROM python:3.12-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .

CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

**Step 2: Add backend to docker-compose.yml**

```yaml
  api:
    build: ../backend
    restart: always
    ports:
      - "8000:8000"
    env_file:
      - ../backend/.env
```

**Step 3: Verify it builds and runs**

Run: `cd infra && docker-compose build api && docker-compose up -d api`
Verify: `curl http://localhost:8000/health`

**Step 4: Commit**

```bash
git add backend/Dockerfile infra/docker-compose.yml
git commit -m "chore: add backend Dockerfile and deployment config"
```

---

### Task 23: Cron Job for Pipeline Execution

**Files:**
- Create: `infra/crontab`
- Create: `backend/scripts/cron_runner.sh`

**Step 1: Create cron runner script**

```bash
#!/bin/bash
# backend/scripts/cron_runner.sh
cd /app
python scripts/run_pipeline.py >> /var/log/pipeline.log 2>&1
```

**Step 2: Create crontab configuration**

```
# infra/crontab
# Run pipeline every 2 hours
0 */2 * * * /app/scripts/cron_runner.sh
```

**Step 3: Commit**

```bash
git add infra/crontab backend/scripts/cron_runner.sh
git commit -m "chore: add cron job for pipeline execution every 2 hours"
```

---

## Phase 6: Integration Testing & Polish

### Task 24: End-to-End Smoke Test

**Step 1: Start all services**

```bash
cd infra && docker-compose up -d
```

**Step 2: Seed the database**

```bash
cd backend && python scripts/seed_entities.py
```

**Step 3: Run pipeline manually**

```bash
cd backend && python scripts/run_pipeline.py
```

**Step 4: Verify API responses**

```bash
curl http://localhost:8000/api/entities | python -m json.tool
curl http://localhost:8000/api/posts/timeline?entity_ids=karpathy,openai | python -m json.tool
```

**Step 5: Launch Flutter app and verify full flow**

```bash
cd client && flutter run
```

Verify:
- [ ] Tab 1 (动态) shows posts from subscribed entities
- [ ] Post cards display entity info + Chinese summary + English preview
- [ ] Tapping a card opens detail page with AI insight + interpretation
- [ ] Tab 2 (发现) shows entities grouped by category
- [ ] Entity card tap opens bottom sheet with full info
- [ ] Subscribe/unsubscribe works
- [ ] Tab 3 (我的) shows subscription management
- [ ] Entity page shows profile + dedicated timeline

**Step 6: Commit any fixes**

```bash
git add -A
git commit -m "fix: integration testing fixes"
```

---

### Task 25: README & Documentation

**Files:**
- Create: `README.md`

**Step 1: Write README**

Cover:
- Project overview (1 paragraph)
- Architecture diagram (ASCII)
- Prerequisites (Python 3.12, Flutter, Docker)
- Quick start steps (backend, RSSHub, Flutter)
- Environment variables reference
- Project structure

**Step 2: Commit**

```bash
git add README.md
git commit -m "docs: add README with setup instructions and architecture overview"
```

---

## Summary

| Phase | Tasks | Description |
|-------|-------|-------------|
| 0 | 1-2 | Project scaffolding, config |
| 1 | 3-5 | Database schema, models, seed data |
| 2 | 6-10 | Content scraping & AI pipeline |
| 3 | 11-12 | REST API endpoints |
| 4 | 13-20 | Flutter client (all screens) |
| 5 | 21-23 | Docker, deployment, cron |
| 6 | 24-25 | Integration testing, docs |

**Estimated total: ~25 tasks, ~120 steps**

Critical path: Phase 0 → Phase 1 → Phase 2 → Phase 3 → Phase 4. Phases 4 and 2-3 can partially overlap (Flutter data layer can be built while API is in progress using mock data).
