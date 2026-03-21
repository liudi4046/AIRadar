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
