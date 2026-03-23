from __future__ import annotations

from typing import TYPE_CHECKING

import feedparser
import httpx

if TYPE_CHECKING:
    from ..config import Settings


async def _fetch_twitter(settings: Settings, handle: str) -> list[dict]:
    """Fetch latest tweets for a handle via TwitterAPI.io."""
    url = f"{settings.twitter_api_base_url}/twitter/user/last_tweets"
    headers = {"X-API-Key": settings.twitter_api_key}
    params = {"userName": handle}

    async with httpx.AsyncClient(timeout=30) as client:
        resp = await client.get(url, headers=headers, params=params)
        resp.raise_for_status()

    data = resp.json()
    if data.get("status") != "success":
        return []

    items = []
    for tweet in data.get("tweets", []):
        text = tweet.get("text", "")
        items.append({
            "title": text[:80] if text else "",
            "content": text,
            "link": tweet.get("url", ""),
            "published": tweet.get("createdAt", ""),
        })
    return items


async def _fetch_rss(url: str) -> list[dict]:
    """Fetch and parse an RSS/Atom feed by direct URL."""
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


async def fetch_entity_feed(settings: Settings, source: dict) -> list[dict]:
    """Fetch feed items for a single scrape source.

    Returns a list of dicts with keys: title, content, link, published.
    """
    if source["type"] == "twitter":
        return await _fetch_twitter(settings, source["handle"])

    if source["type"] == "rss":
        return await _fetch_rss(source["url"])

    return []
