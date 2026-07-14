-- ==========================================
-- LGNM Database Schema - Sprint 1 Foundation
-- ==========================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS citext;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'source_url_type') THEN
    CREATE TYPE source_url_type AS ENUM ('website', 'rss', 'api');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'article_status') THEN
    CREATE TYPE article_status AS ENUM ('new', 'collected', 'duplicate', 'archived', 'error');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'run_status') THEN
    CREATE TYPE run_status AS ENUM ('started', 'success', 'partial', 'failed');
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS source_categories (
  id SMALLSERIAL PRIMARY KEY,
  name CITEXT NOT NULL UNIQUE,
  description TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS government_entities (
  id BIGSERIAL PRIMARY KEY,
  name_en TEXT NOT NULL UNIQUE,
  name_ar TEXT,
  slug CITEXT NOT NULL UNIQUE,
  category_id SMALLINT NOT NULL REFERENCES source_categories(id),
  parent_entity_id BIGINT REFERENCES government_entities(id) ON DELETE SET NULL,
  jurisdiction TEXT NOT NULL DEFAULT 'Libya',
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS sources (
  id BIGSERIAL PRIMARY KEY,
  entity_id BIGINT NOT NULL REFERENCES government_entities(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  slug CITEXT NOT NULL UNIQUE,
  language_code VARCHAR(10),
  priority SMALLINT NOT NULL DEFAULT 3 CHECK (priority BETWEEN 1 AND 5),
  check_interval_minutes INTEGER NOT NULL DEFAULT 120 CHECK (check_interval_minutes >= 15),
  enabled BOOLEAN NOT NULL DEFAULT TRUE,
  last_checked_at TIMESTAMPTZ,
  last_success_at TIMESTAMPTZ,
  last_error TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS source_urls (
  id BIGSERIAL PRIMARY KEY,
  source_id BIGINT NOT NULL REFERENCES sources(id) ON DELETE CASCADE,
  url_type source_url_type NOT NULL,
  url TEXT NOT NULL,
  is_primary BOOLEAN NOT NULL DEFAULT FALSE,
  enabled BOOLEAN NOT NULL DEFAULT TRUE,
  http_status INTEGER,
  etag TEXT,
  last_modified TEXT,
  last_checked_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (source_id, url_type, url)
);

CREATE TABLE IF NOT EXISTS articles (
  id BIGSERIAL PRIMARY KEY,
  source_id BIGINT NOT NULL REFERENCES sources(id) ON DELETE RESTRICT,
  source_url_id BIGINT REFERENCES source_urls(id) ON DELETE SET NULL,
  title TEXT NOT NULL,
  summary TEXT,
  body TEXT,
  canonical_url TEXT,
  language_code VARCHAR(10),
  published_at TIMESTAMPTZ,
  collected_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  content_hash TEXT NOT NULL,
  status article_status NOT NULL DEFAULT 'new',
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  UNIQUE (content_hash),
  UNIQUE (canonical_url)
);

CREATE TABLE IF NOT EXISTS collection_runs (
  id BIGSERIAL PRIMARY KEY,
  source_id BIGINT REFERENCES sources(id) ON DELETE SET NULL,
  started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  finished_at TIMESTAMPTZ,
  status run_status NOT NULL DEFAULT 'started',
  items_found INTEGER NOT NULL DEFAULT 0,
  items_inserted INTEGER NOT NULL DEFAULT 0,
  error_message TEXT,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE TABLE IF NOT EXISTS reports (
  id BIGSERIAL PRIMARY KEY,
  report_date DATE NOT NULL UNIQUE,
  title TEXT NOT NULL,
  markdown_body TEXT NOT NULL,
  html_body TEXT,
  generated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  sent_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS app_settings (
  key CITEXT PRIMARY KEY,
  value TEXT NOT NULL,
  description TEXT,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_government_entities_updated_at ON government_entities;
CREATE TRIGGER trg_government_entities_updated_at
BEFORE UPDATE ON government_entities
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS trg_sources_updated_at ON sources;
CREATE TRIGGER trg_sources_updated_at
BEFORE UPDATE ON sources
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE INDEX IF NOT EXISTS idx_government_entities_category ON government_entities(category_id);
CREATE INDEX IF NOT EXISTS idx_government_entities_parent ON government_entities(parent_entity_id);
CREATE INDEX IF NOT EXISTS idx_government_entities_active ON government_entities(is_active) WHERE is_active;
CREATE INDEX IF NOT EXISTS idx_sources_entity ON sources(entity_id);
CREATE INDEX IF NOT EXISTS idx_sources_enabled_priority ON sources(enabled, priority, check_interval_minutes) WHERE enabled;
CREATE INDEX IF NOT EXISTS idx_source_urls_source_type ON source_urls(source_id, url_type);
CREATE INDEX IF NOT EXISTS idx_source_urls_enabled ON source_urls(enabled) WHERE enabled;
CREATE INDEX IF NOT EXISTS idx_articles_source_published ON articles(source_id, published_at DESC NULLS LAST);
CREATE INDEX IF NOT EXISTS idx_articles_collected_at ON articles(collected_at DESC);
CREATE INDEX IF NOT EXISTS idx_articles_status ON articles(status);
CREATE INDEX IF NOT EXISTS idx_articles_metadata_gin ON articles USING GIN (metadata);
CREATE INDEX IF NOT EXISTS idx_collection_runs_source_started ON collection_runs(source_id, started_at DESC);
CREATE INDEX IF NOT EXISTS idx_collection_runs_status ON collection_runs(status);
