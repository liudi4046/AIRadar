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

    with patch("src.pipeline.generator._get_client") as mock_get, \
         patch("src.pipeline.generator.get_settings") as mock_settings:
        mock_client = AsyncMock()
        mock_client.chat.completions.create = AsyncMock(return_value=mock_response)
        mock_get.return_value = mock_client
        mock_settings.return_value = MagicMock(
            qwen_api_key="test-key",
            qwen_base_url="https://test.api.com",
            qwen_generation_model="test-model",
        )

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
