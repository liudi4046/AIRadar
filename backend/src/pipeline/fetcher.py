from __future__ import annotations

import asyncio
import logging
from typing import TYPE_CHECKING

import feedparser
import httpx

if TYPE_CHECKING:
    from ..config import Settings

logger = logging.getLogger(__name__)

_TWITTER_MAX_RETRIES = 3
_TWITTER_RETRY_BASE_DELAY = 2.0


async def _fetch_twitter(settings: Settings, handle: str) -> list[dict]:
    """Fetch latest tweets for a handle via TwitterAPI.io with retry on 429."""
    url = f"{settings.twitter_api_base_url}/twitter/user/last_tweets"
    headers = {"X-API-Key": settings.twitter_api_key}
    params = {"userName": handle}

    for attempt in range(_TWITTER_MAX_RETRIES):
        async with httpx.AsyncClient(timeout=30) as client:
            resp = await client.get(url, headers=headers, params=params)

        if resp.status_code == 429:
            delay = _TWITTER_RETRY_BASE_DELAY * (2 ** attempt)
            logger.warning("Rate limited fetching @%s, retrying in %.1fs (attempt %d/%d)",
                           handle, delay, attempt + 1, _TWITTER_MAX_RETRIES)
            await asyncio.sleep(delay)
            continue

        resp.raise_for_status()
        break
    else:
        resp.raise_for_status()

    data = resp.json()
    if data.get("status") != "success":
        logger.warning(
            "Twitter API non-success for @%s: status=%s message=%s",
            handle,
            data.get("status"),
            (data.get("message") or "")[:300],
        )
        return []

    # API may return "tweets": null; dict.get("tweets", []) still yields None if key exists.
    tweets = data.get("tweets") or []
    if not tweets:
        logger.warning(
            "Twitter API returned no tweets for @%s (message=%s)",
            handle,
            (data.get("message") or "")[:300],
        )
        return []

    items = []
    for tweet in tweets:
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
    async with httpx.AsyncClient(timeout=30, follow_redirects=True) as client:
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
