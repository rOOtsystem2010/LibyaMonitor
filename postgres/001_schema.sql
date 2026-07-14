-- ==========================================
-- Libya Monitor Database Schema v0.1.0
-- ==========================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ==========================================
-- Sources
-- ==========================================

CREATE TABLE IF NOT EXISTS sources (

    id SERIAL PRIMARY KEY,

    name VARCHAR(255) NOT NULL,

    slug VARCHAR(255) UNIQUE NOT NULL,

    source_category VARCHAR(100),

    country VARCHAR(100) DEFAULT 'Libya',

    website_url TEXT,

    rss_url TEXT,

    facebook_url TEXT,

    x_url TEXT,

    enabled BOOLEAN DEFAULT TRUE,

    priority INTEGER DEFAULT 1,

    check_interval_minutes INTEGER DEFAULT 60,

    last_checked TIMESTAMP,

    last_success TIMESTAMP,

    last_error TEXT,

    http_status INTEGER,

    etag TEXT,

    created_at TIMESTAMP DEFAULT NOW(),

    updated_at TIMESTAMP DEFAULT NOW()

);

CREATE INDEX idx_sources_enabled
ON sources(enabled);

CREATE INDEX idx_sources_priority
ON sources(priority);

-- ==========================================
-- News
-- ==========================================

CREATE TABLE IF NOT EXISTS news (

    id BIGSERIAL PRIMARY KEY,

    source_id INTEGER NOT NULL REFERENCES sources(id),

    title TEXT NOT NULL,

    summary TEXT,

    content TEXT,

    article_url TEXT UNIQUE,

    language VARCHAR(20),

    published_at TIMESTAMP,

    collected_at TIMESTAMP DEFAULT NOW(),

    content_hash TEXT UNIQUE,

    status VARCHAR(30) DEFAULT 'NEW'

);

CREATE INDEX idx_news_source
ON news(source_id);

CREATE INDEX idx_news_date
ON news(published_at);

CREATE INDEX idx_news_hash
ON news(content_hash);

-- ==========================================
-- AI Analysis
-- ==========================================

CREATE TABLE IF NOT EXISTS news_analysis (

    id BIGSERIAL PRIMARY KEY,

    news_id BIGINT REFERENCES news(id) ON DELETE CASCADE,

    category VARCHAR(100),

    importance INTEGER,

    sentiment VARCHAR(50),

    keywords JSONB,

    entities JSONB,

    numbers JSONB,

    summary TEXT,

    created_at TIMESTAMP DEFAULT NOW()

);

-- ==========================================
-- Daily Reports
-- ==========================================

CREATE TABLE IF NOT EXISTS reports (

    id BIGSERIAL PRIMARY KEY,

    report_date DATE UNIQUE,

    html_report TEXT,

    markdown_report TEXT,

    sent BOOLEAN DEFAULT FALSE,

    created_at TIMESTAMP DEFAULT NOW()

);

-- ==========================================
-- Workflow Logs
-- ==========================================

CREATE TABLE IF NOT EXISTS workflow_logs (

    id BIGSERIAL PRIMARY KEY,

    workflow_name VARCHAR(255),

    status VARCHAR(50),

    message TEXT,

    created_at TIMESTAMP DEFAULT NOW()

);

-- ==========================================
-- Settings
-- ==========================================

CREATE TABLE IF NOT EXISTS settings (

    id SERIAL PRIMARY KEY,

    setting_key VARCHAR(255) UNIQUE,

    setting_value TEXT,

    updated_at TIMESTAMP DEFAULT NOW()

);