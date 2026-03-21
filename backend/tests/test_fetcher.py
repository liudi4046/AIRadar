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
