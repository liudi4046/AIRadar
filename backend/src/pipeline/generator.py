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
