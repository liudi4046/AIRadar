import pytest
from unittest.mock import AsyncMock, patch, MagicMock


@pytest.mark.asyncio
async def test_moderate_safe_content():
    mock_response = MagicMock()
    mock_response.choices = [MagicMock(message=MagicMock(content='{"safe": true, "reason": ""}'))]

    with patch("src.pipeline.moderator._get_client") as mock_get, \
         patch("src.pipeline.moderator.get_settings") as mock_settings:
        mock_client = AsyncMock()
        mock_client.chat.completions.create = AsyncMock(return_value=mock_response)
        mock_get.return_value = mock_client
        mock_settings.return_value = MagicMock(
            qwen_api_key="test-key",
            qwen_base_url="https://test.api.com",
            qwen_moderation_model="test-model",
        )

        from src.pipeline.moderator import moderate_content

        result = await moderate_content("Karpathy talks about LLM training techniques")
        assert result["safe"] is True


@pytest.mark.asyncio
async def test_moderate_unsafe_content():
    mock_response = MagicMock()
    mock_response.choices = [MagicMock(message=MagicMock(content='{"safe": false, "reason": "政治敏感内容"}'))]

    with patch("src.pipeline.moderator._get_client") as mock_get, \
         patch("src.pipeline.moderator.get_settings") as mock_settings:
        mock_client = AsyncMock()
        mock_client.chat.completions.create = AsyncMock(return_value=mock_response)
        mock_get.return_value = mock_client
        mock_settings.return_value = MagicMock(
            qwen_api_key="test-key",
            qwen_base_url="https://test.api.com",
            qwen_moderation_model="test-model",
        )

        from src.pipeline.moderator import moderate_content

        result = await moderate_content("Some political content...")
        assert result["safe"] is False
        assert "政治" in result["reason"]
