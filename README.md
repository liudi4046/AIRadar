# AI Radar (AI 追更)

**AI Radar** (Chinese product name: **AI 追更**) is an AI news aggregation app for Chinese-speaking users. It collects updates from overseas AI thought leaders via RSS feeds (RSSHub), processes content with Alibaba Cloud Bailian (Qwen3.5) for moderation and Chinese summaries, stores structured data in Supabase (PostgreSQL), and serves a FastAPI backend to a Flutter client—so readers get timely, curated AI industry signal in their language.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         Overseas content sources                             │
│                    (Twitter/X, blogs, etc. via RSSHub)                       │
└───────────────────────────────────┬─────────────────────────────────────────┘
                                    │ HTTP / RSS
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         RSSHub (Docker) — scraper tier                       │
│                    Normalizes feeds; exposes routes on :1200                 │
└───────────────────────────────────┬─────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                    AI processing tier (Python pipeline)                      │
│         Fetch → moderate (Qwen3.5-Flash) → generate (Qwen3.5-Plus)           │
└───────────────────────────────────┬─────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         Supabase (PostgreSQL)                                │
│                         entities, posts, metadata                            │
└───────────────────────────────────┬─────────────────────────────────────────┘
                                    │ supabase-py
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                    FastAPI — REST API (:8000)                                │
└───────────────────────────────────┬─────────────────────────────────────────┘
                                    │ JSON / HTTPS (dev: HTTP)
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                    Flutter app (iOS primary; multi-platform)                 │
│                    Riverpod · GoRouter · Dio                                 │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Prerequisites

| Requirement | Notes |
|-------------|--------|
| **Python 3.12** | Matches backend Docker image and tooling |
| **Flutter 3.x** | Dart SDK as specified in `client/pubspec.yaml` |
| **Docker** | For RSSHub (and optional Compose stack for API + RSSHub) |
| **Supabase account** | Project URL and API keys for Postgres + REST |
| **Alibaba Cloud Bailian API key** | DashScope-compatible endpoint for Qwen3.5 (moderation + generation) |

## Quick start

### 1. Supabase

Create a Supabase project. Apply the database schema from `backend/scripts/init_schema.sql`. Copy URL and keys—you will use them in the backend `.env`.

### 2. Backend

```bash
cd backend
python3.12 -m venv .venv
source .venv/bin/activate   # Windows: .venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env
# Edit .env: Supabase URLs/keys, QWEN_* and RSSHUB_BASE_URL as needed
```

Run the API locally:

```bash
cd backend
source .venv/bin/activate
uvicorn src.main:app --reload --host 0.0.0.0 --port 8000
```

Optional: seed entities (requires valid Supabase credentials):

```bash
cd backend
python scripts/seed_entities.py
```

Optional: run the ingestion pipeline once (RSSHub + Qwen must be reachable):

```bash
cd backend
python scripts/run_pipeline.py
```

### 3. RSSHub (Docker)

From the repository root, start RSSHub so `RSSHUB_BASE_URL` (default `http://localhost:1200`) resolves:

```bash
cd infra
# Optionally create infra/rsshub/.env from infra/rsshub/.env.example for Twitter routes
docker compose up -d rsshub
```

Point `RSSHUB_BASE_URL` in `backend/.env` at the running instance (e.g. `http://localhost:1200` or your host).

### 4. Flutter client

```bash
cd client
flutter pub get
flutter run
```

The app defaults to `http://localhost:8000` (see `client/lib/services/api_config.dart`). For a physical device, use your machine’s LAN IP and ensure the device can reach the API.

## Environment variables

### Backend (`backend/.env.example` → `backend/.env`)

| Variable | Description |
|----------|-------------|
| `SUPABASE_URL` | Supabase project URL |
| `SUPABASE_KEY` | Supabase anon (public) key |
| `SUPABASE_SERVICE_KEY` | Supabase service role key (server-side; keep secret) |
| `QWEN_API_KEY` | Alibaba Cloud Bailian / DashScope API key |
| `QWEN_BASE_URL` | OpenAI-compatible base URL (default: DashScope compatible mode) |
| `QWEN_MODERATION_MODEL` | Model for content moderation (e.g. `qwen3.5-flash`) |
| `QWEN_GENERATION_MODEL` | Model for summaries/insights (e.g. `qwen3.5-plus`) |
| `RSSHUB_BASE_URL` | Base URL of the RSSHub instance used by the pipeline |

### RSSHub Compose (`infra/rsshub/.env.example`)

Used when running `docker compose` from `infra/` so RSSHub can access Twitter-dependent routes:

| Variable | Description |
|----------|-------------|
| `TWITTER_AUTH_TOKEN` | Twitter/X auth token for RSSHub Twitter routes (optional if unused) |

The root `infra/docker-compose.yml` passes `TWITTER_AUTH_TOKEN` into the `rsshub` service from the host environment.

## Project structure

```
AIRadar/
├── backend/                 # Python FastAPI backend
│   ├── src/
│   │   ├── main.py         # FastAPI app with health check
│   │   ├── config.py       # Settings (pydantic-settings)
│   │   ├── db.py           # Supabase client
│   │   ├── models/         # Pydantic models (Entity, Post)
│   │   ├── api/            # REST API endpoints
│   │   │   ├── entities.py # GET /api/entities, GET /api/entities/{id}
│   │   │   └── posts.py    # GET /api/posts/timeline, trending, entity/{id}, {id}
│   │   └── pipeline/       # Content processing pipeline
│   │       ├── fetcher.py  # RSSHub feed fetcher
│   │       ├── moderator.py # AI content moderation (Qwen3.5-Flash)
│   │       ├── generator.py # AI content generation (Qwen3.5-Plus)
│   │       └── orchestrator.py # Pipeline orchestrator
│   ├── tests/              # pytest test suite
│   ├── scripts/            # CLI scripts (seed, pipeline runner, cron)
│   ├── data/               # Seed data (entities.json)
│   ├── requirements.txt
│   ├── Dockerfile
│   └── .env.example
├── client/                  # Flutter iOS app
│   ├── lib/
│   │   ├── main.dart
│   │   ├── app.dart        # MaterialApp with Material 3
│   │   ├── router.dart     # GoRouter with 3 tabs + 2 detail routes
│   │   ├── providers.dart  # Riverpod providers
│   │   ├── models/         # Dart data models
│   │   ├── services/       # API client (Dio)
│   │   ├── screens/        # 6 screens (timeline, discover, profile, post detail, entity, shell)
│   │   └── widgets/        # Reusable widgets (post_card, trending_card, entity_card, etc.)
│   └── test/               # Flutter tests
├── infra/                   # Infrastructure
│   ├── docker-compose.yml  # RSSHub + API services
│   ├── crontab            # Pipeline cron job (every 2 hours)
│   └── rsshub/            # RSSHub config
└── docs/plans/             # Design docs and implementation plan
```

## API endpoints

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/health` | Liveness check; returns status and API version |
| `GET` | `/api/entities` | List entities; optional query `category` |
| `GET` | `/api/entities/{entity_id}` | Single entity by ID |
| `GET` | `/api/posts/timeline` | Timeline for comma-separated `entity_ids` (required); `page`, `page_size` |
| `GET` | `/api/posts/trending` | Trending posts; `page`, `page_size` |
| `GET` | `/api/posts/entity/{entity_id}` | Posts for one entity; `page`, `page_size` |
| `GET` | `/api/posts/{post_id}` | Single post with related entity fields |

Interactive docs: `http://localhost:8000/docs` (Swagger UI) when the server is running.

## Testing

**Backend (pytest):**

```bash
cd backend
pytest
```

**Flutter:**

```bash
cd client
flutter test
```

## Deployment

**Docker Compose (API + RSSHub)** from `infra/`:

1. Ensure `backend/.env` exists with production values (Supabase, Qwen, `RSSHUB_BASE_URL` pointing at the RSSHub service name or public URL).
2. Optionally export `TWITTER_AUTH_TOKEN` for RSSHub Twitter routes.
3. Build and start:

```bash
cd infra
docker compose up -d --build
```

- API is exposed on port **8000**, RSSHub on **1200** (see `infra/docker-compose.yml`).
- Schedule the pipeline using your orchestrator (e.g. adapt `infra/crontab` to run `backend/scripts/cron_runner.sh` or `run_pipeline.py` on your host or in a sidecar).

For production, place the API behind HTTPS, restrict CORS in `backend/src/main.py`, and rotate Supabase service keys regularly.
