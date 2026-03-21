"""Run the content scraping and processing pipeline once."""
import asyncio
import logging
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from dotenv import load_dotenv

load_dotenv()

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s: %(message)s")


async def main():
    from src.pipeline.orchestrator import run_pipeline

    logging.info("Starting pipeline run...")
    stats = await run_pipeline()
    logging.info("Pipeline complete: %s", stats)


if __name__ == "__main__":
    asyncio.run(main())
