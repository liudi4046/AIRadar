"""Remove posts inserted by seed_demo_posts.py from Supabase.

Run when you want the timeline to show only pipeline-ingested content.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from dotenv import load_dotenv

load_dotenv()

from src.db import get_supabase

# Keep in sync with seed_demo_posts.DEMO_POSTS ids
DEMO_POST_IDS = [
    "demo-post-karpathy-01",
    "demo-post-openai-01",
    "demo-post-sama-01",
    "demo-post-anthropic-01",
    "demo-post-hf-01",
]


def main() -> None:
    client = get_supabase()
    for post_id in DEMO_POST_IDS:
        client.table("posts").delete().eq("id", post_id).execute()
        print(f"  Deleted: {post_id}")
    print(f"\nDone. Removed {len(DEMO_POST_IDS)} demo posts.")


if __name__ == "__main__":
    main()
