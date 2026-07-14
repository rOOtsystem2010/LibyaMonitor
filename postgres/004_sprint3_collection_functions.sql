-- ==========================================
-- LGNM Sprint 3 Website Collection Helpers
-- ==========================================

-- Article author support is required before collection functions are compiled.
ALTER TABLE articles
ADD COLUMN IF NOT EXISTS author TEXT;

CREATE INDEX IF NOT EXISTS idx_articles_author
ON articles(author)
WHERE author IS NOT NULL;

CREATE OR REPLACE VIEW vw_website_collection_queue AS
SELECT
  s.id AS source_id,
  s.name AS source_name,
  s.slug AS source_slug,
  su.id AS source_url_id,
  su.url AS website_url,
  s.priority,
  s.check_interval_minutes,
  s.last_checked_at,
  s.last_success_at
FROM sources s
JOIN source_urls su ON su.source_id = s.id
WHERE s.enabled = TRUE
  AND su.enabled = TRUE
  AND su.url_type = 'website'
ORDER BY s.priority ASC, s.last_checked_at NULLS FIRST, s.id ASC;

CREATE OR REPLACE FUNCTION start_website_collection_run(
  p_source_id BIGINT,
  p_source_url_id BIGINT,
  p_website_url TEXT
)
RETURNS BIGINT AS $$
DECLARE
  v_run_id BIGINT;
BEGIN
  INSERT INTO collection_runs (source_id, status, metadata)
  VALUES (
    p_source_id,
    'started',
    jsonb_build_object(
      'source_url_id', p_source_url_id,
      'website_url', p_website_url,
      'pipeline', 'website_collection'
    )
  )
  RETURNING id INTO v_run_id;

  RETURN v_run_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION record_collected_article(
  p_run_id BIGINT,
  p_source_id BIGINT,
  p_source_url_id BIGINT,
  p_title TEXT,
  p_published_at TIMESTAMPTZ,
  p_content TEXT,
  p_canonical_url TEXT,
  p_author TEXT DEFAULT NULL,
  p_metadata JSONB DEFAULT '{}'::jsonb
)
RETURNS TABLE(article_id BIGINT, inserted BOOLEAN) AS $$
DECLARE
  v_article_id BIGINT;
  v_inserted BOOLEAN := FALSE;
BEGIN
  IF p_canonical_url IS NULL OR btrim(p_canonical_url) = '' THEN
    RETURN QUERY SELECT NULL::BIGINT, FALSE;
    RETURN;
  END IF;

  INSERT INTO articles (
    source_id,
    source_url_id,
    title,
    body,
    canonical_url,
    author,
    language_code,
    published_at,
    content_hash,
    status,
    metadata
  )
  VALUES (
    p_source_id,
    p_source_url_id,
    NULLIF(btrim(COALESCE(p_title, '')), ''),
    NULLIF(btrim(COALESCE(p_content, '')), ''),
    p_canonical_url,
    NULLIF(btrim(COALESCE(p_author, '')), ''),
    'und',
    p_published_at,
    encode(digest(COALESCE(p_canonical_url, '') || '|' || COALESCE(p_title, '') || '|' || COALESCE(p_content, ''), 'sha256'), 'hex'),
    'collected',
    COALESCE(p_metadata, '{}'::jsonb)
  )
  ON CONFLICT (canonical_url) DO UPDATE SET
    title = COALESCE(EXCLUDED.title, articles.title),
    body = COALESCE(EXCLUDED.body, articles.body),
    author = COALESCE(EXCLUDED.author, articles.author),
    published_at = COALESCE(EXCLUDED.published_at, articles.published_at),
    metadata = articles.metadata || EXCLUDED.metadata
  RETURNING id, (xmax = 0) INTO v_article_id, v_inserted;

  UPDATE collection_runs
  SET items_inserted = items_inserted + CASE WHEN v_inserted THEN 1 ELSE 0 END,
      finished_at = now(),
      status = 'success'
  WHERE id = p_run_id;

  UPDATE sources
  SET last_checked_at = now(),
      last_success_at = now(),
      last_error = NULL
  WHERE id = p_source_id;

  RETURN QUERY SELECT v_article_id, v_inserted;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION finish_website_collection_run(
  p_run_id BIGINT,
  p_source_id BIGINT,
  p_items_found INTEGER,
  p_status run_status DEFAULT 'success',
  p_error_message TEXT DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
  UPDATE collection_runs
  SET finished_at = now(),
      status = p_status,
      items_found = COALESCE(p_items_found, 0),
      error_message = p_error_message
  WHERE id = p_run_id;

  UPDATE sources
  SET last_checked_at = now(),
      last_success_at = CASE WHEN p_status IN ('success', 'partial') THEN now() ELSE last_success_at END,
      last_error = p_error_message
  WHERE id = p_source_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE VIEW vw_recent_collected_articles AS
SELECT
  a.id,
  a.source_id,
  s.name AS source_name,
  a.title,
  a.canonical_url,
  a.author,
  a.published_at,
  a.collected_at,
  a.status
FROM articles a
JOIN sources s ON s.id = a.source_id
ORDER BY a.collected_at DESC;

CREATE OR REPLACE FUNCTION record_collected_articles_bulk(
  p_run_id BIGINT,
  p_source_id BIGINT,
  p_source_url_id BIGINT,
  p_items_found INTEGER,
  p_articles JSONB
)
RETURNS INTEGER AS $$
DECLARE
  v_article JSONB;
  v_result RECORD;
  v_inserted_count INTEGER := 0;
BEGIN
  FOR v_article IN SELECT value FROM jsonb_array_elements(COALESCE(p_articles, '[]'::jsonb)) LOOP
    SELECT * INTO v_result
    FROM record_collected_article(
      p_run_id,
      p_source_id,
      p_source_url_id,
      v_article ->> 'title',
      NULLIF(v_article ->> 'published_at', '')::timestamptz,
      v_article ->> 'content',
      v_article ->> 'url',
      v_article ->> 'author',
      COALESCE(v_article -> 'metadata', '{}'::jsonb)
    );

    IF COALESCE(v_result.inserted, FALSE) THEN
      v_inserted_count := v_inserted_count + 1;
    END IF;
  END LOOP;

  PERFORM finish_website_collection_run(p_run_id, p_source_id, COALESCE(p_items_found, 0), 'success', NULL);
  RETURN v_inserted_count;
END;
$$ LANGUAGE plpgsql;
