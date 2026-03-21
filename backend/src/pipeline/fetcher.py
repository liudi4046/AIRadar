import feedparser
import httpx

RSSHUB_ROUTE_MAP = {
    "twitter": "/twitter/user/{handle}",
    "github_releases": "/github/release/{handle}",
}


async def fetch_entity_feed(
    rsshub_base_url: str,
    source: dict,
) -> list[dict]:
    """Fetch RSS feed for a single scrape source and return parsed items."""
    if source["type"] == "rss":
        if "url" in source:
            url = source["url"]
        else:
            url = f"{rsshub_base_url}{source['path']}"
    else:
        route_template = RSSHUB_ROUTE_MAP.get(source["type"])
        if not route_template:
            return []
        url = rsshub_base_url + route_template.format(**source)

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
