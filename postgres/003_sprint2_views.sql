-- ==========================================
-- LGNM Sprint 2 Helper Views
-- ==========================================

CREATE OR REPLACE VIEW vw_enabled_website_sources AS
SELECT
  s.id AS source_id,
  s.name AS source_name,
  s.slug AS source_slug,
  ge.id AS entity_id,
  ge.name_en AS entity_name,
  sc.name AS category_name,
  su.id AS source_url_id,
  su.url AS website_url,
  s.priority,
  s.check_interval_minutes,
  s.last_checked_at,
  s.last_success_at
FROM sources s
JOIN government_entities ge ON ge.id = s.entity_id
JOIN source_categories sc ON sc.id = ge.category_id
JOIN source_urls su ON su.source_id = s.id
WHERE s.enabled = TRUE
  AND su.enabled = TRUE
  AND su.url_type = 'website';

CREATE OR REPLACE VIEW vw_collection_run_summary AS
SELECT
  cr.id AS collection_run_id,
  cr.source_id,
  s.name AS source_name,
  cr.started_at,
  cr.finished_at,
  cr.status,
  cr.items_found,
  cr.items_inserted,
  cr.error_message,
  COALESCE(cr.finished_at, now()) - cr.started_at AS duration
FROM collection_runs cr
LEFT JOIN sources s ON s.id = cr.source_id;

CREATE OR REPLACE VIEW vw_article_deduplication_keys AS
SELECT
  id AS article_id,
  source_id,
  canonical_url,
  content_hash,
  collected_at
FROM articles;
