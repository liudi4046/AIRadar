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
        patch("src.pipeline.orchestrator.post_exists", return_value=False),
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
        patch("src.pipeline.orchestrator.post_exists", return_value=False),
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
