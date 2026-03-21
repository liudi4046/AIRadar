-- Run this in Supabase SQL Editor to create the tables

CREATE TABLE IF NOT EXISTS entities (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    avatar TEXT DEFAULT '',
    identity_tag TEXT DEFAULT '',
    type TEXT NOT NULL CHECK (type IN ('person', 'org', 'opensource', 'media')),
    bio TEXT DEFAULT '',
    activity_tags JSONB DEFAULT '[]'::jsonb,
    influence JSONB DEFAULT '{}'::jsonb,
    recent_highlights JSONB DEFAULT '[]'::jsonb,
    scrape_sources JSONB DEFAULT '[]'::jsonb,
    category TEXT DEFAULT 'core_leaders',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS posts (
    id TEXT PRIMARY KEY,
    entity_id TEXT NOT NULL REFERENCES entities(id),
    source_type TEXT DEFAULT '',
    source_url TEXT DEFAULT '',
    original_text TEXT DEFAULT '',
    summary_zh TEXT DEFAULT '',
    insight_zh TEXT DEFAULT '',
    interpretation_zh TEXT DEFAULT '',
    translation_zh TEXT DEFAULT '',
    published_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    is_trending BOOLEAN DEFAULT FALSE,
    trending_source TEXT DEFAULT ''
);

CREATE INDEX IF NOT EXISTS idx_posts_entity_id ON posts(entity_id);
CREATE INDEX IF NOT EXISTS idx_posts_published_at ON posts(published_at DESC);
CREATE INDEX IF NOT EXISTS idx_posts_is_trending ON posts(is_trending) WHERE is_trending = TRUE;
