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
