import json

import pytest
import httpx


MOCK_TWITTER_RESPONSE = {
    "status": "success",
    "tweets": [
        {
            "id": "123456",
            "text": "LLMs don't need complex prompts anymore. The future is about better models, not better prompts.",
            "url": "https://x.com/karpathy/status/123456",
            "createdAt": "Thu, 20 Mar 2026 10:00:00 +0000",
            "likeCount": 500,
            "retweetCount": 120,
        }
    ],
    "has_next_page": False,
    "next_cursor": "",
    "message": "",
}

MOCK_RSS_XML = """<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
  <channel>
    <title>Test Feed</title>
    <item>
      <title>Test Post Title</title>
      <link>https://openai.com/blog/test-post</link>
      <description>A new breakthrough in AI reasoning capabilities.</description>
      <pubDate>Thu, 20 Mar 2026 10:00:00 GMT</pubDate>
    </item>
  </channel>
</rss>"""


def _make_settings(**overrides):
    """Create a minimal settings-like object for testing."""
    from unittest.mock import MagicMock

    defaults = {
        "twitter_api_key": "test-api-key",
        "twitter_api_base_url": "https://api.twitterapi.io",
    }
    defaults.update(overrides)
    settings = MagicMock()
    for k, v in defaults.items():
        setattr(settings, k, v)
    return settings


@pytest.mark.asyncio
async def test_fetch_twitter(httpx_mock):
    httpx_mock.add_response(
        url="https://api.twitterapi.io/twitter/user/last_tweets?userName=karpathy",
        json=MOCK_TWITTER_RESPONSE,
    )

    from src.pipeline.fetcher import fetch_entity_feed

    settings = _make_settings()
    items = await fetch_entity_feed(
        settings=settings,
        source={"type": "twitter", "handle": "karpathy"},
    )
    assert len(items) == 1
    assert "LLMs" in items[0]["content"]
    assert items[0]["link"] == "https://x.com/karpathy/status/123456"
    assert items[0]["published"] == "Thu, 20 Mar 2026 10:00:00 +0000"
    assert len(items[0]["title"]) <= 80


@pytest.mark.asyncio
async def test_fetch_twitter_error_status(httpx_mock):
    httpx_mock.add_response(
        url="https://api.twitterapi.io/twitter/user/last_tweets?userName=nobody",
        json={"status": "error", "tweets": [], "has_next_page": False, "next_cursor": "", "message": "User not found"},
    )

    from src.pipeline.fetcher import fetch_entity_feed

    settings = _make_settings()
    items = await fetch_entity_feed(
        settings=settings,
        source={"type": "twitter", "handle": "nobody"},
    )
    assert items == []


@pytest.mark.asyncio
async def test_fetch_rss_direct_url(httpx_mock):
    httpx_mock.add_response(url="https://openai.com/blog/rss.xml", text=MOCK_RSS_XML)

    from src.pipeline.fetcher import fetch_entity_feed

    settings = _make_settings()
    items = await fetch_entity_feed(
        settings=settings,
        source={"type": "rss", "url": "https://openai.com/blog/rss.xml"},
    )
    assert len(items) == 1
    assert items[0]["title"] == "Test Post Title"
    assert "breakthrough" in items[0]["content"]


@pytest.mark.asyncio
async def test_fetch_unknown_type():
    from src.pipeline.fetcher import fetch_entity_feed

    settings = _make_settings()
    items = await fetch_entity_feed(
        settings=settings,
        source={"type": "unknown_source"},
    )
    assert items == []
