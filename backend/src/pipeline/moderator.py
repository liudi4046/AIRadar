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
