"""Seed the entities table with initial whitelist data."""
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from dotenv import load_dotenv

load_dotenv()

from src.db import get_supabase


def seed():
    data_path = Path(__file__).resolve().parent.parent / "data" / "entities.json"
    with open(data_path) as f:
        entities = json.load(f)

    client = get_supabase()
    for entity in entities:
        client.table("entities").upsert(entity).execute()
        print(f"  Seeded: {entity['name']}")

    print(f"\nDone. {len(entities)} entities seeded.")


if __name__ == "__main__":
    seed()
