# Sprint 3 — Website Collection Pipeline

Sprint 3 replaces the prototype homepage-link collector with the first full website news collection pipeline. The workflow visits official source websites, discovers article URLs, downloads article pages, extracts article fields, saves articles to PostgreSQL, and records collection statistics.

## Scope

Implemented:

- n8n workflow: `workflows/workflow_05_collect_websites.json`.
- Manual Trigger and hourly Schedule Trigger.
- PostgreSQL source queue read from `vw_website_collection_queue`.
- Official website homepage download.
- Article link extraction and URL normalization.
- Duplicate removal before article-page downloads.
- Article page download for each normalized URL.
- Article field extraction: title, publication date, content, and URL.
- Parameterized PostgreSQL calls for starting runs, saving articles, and finishing runs.
- Source `last_checked_at` / `last_success_at` updates.
- Collection statistics in `collection_runs`.
- Helper SQL functions and views in `postgres/004_sprint3_collection_functions.sql`.

Not implemented:

- Facebook ingestion.
- X ingestion.
- AI analysis.
- Telegram ingestion or notifications.
- Email delivery.

## Installation

1. Start the Docker stack:

   ```bash
   docker compose up -d
   ```

2. Confirm the Sprint 3 SQL helpers loaded:

   ```bash
   docker compose exec -T postgres psql -U postgres -d lgnm -c "SELECT COUNT(*) FROM vw_website_collection_queue;"
   docker compose exec -T postgres psql -U postgres -d lgnm -c "SELECT proname FROM pg_proc WHERE proname IN ('start_website_collection_run', 'record_collected_article', 'record_collected_articles_bulk', 'finish_website_collection_run');"
   ```

3. Open n8n at <http://localhost:5680>.
4. Import `workflows/workflow_05_collect_websites.json`.
5. Create/select the `LGNM PostgreSQL` credential:

   | Field | Value |
   | --- | --- |
   | Host | `postgres` |
   | Port | `5432` |
   | Database | `lgnm` |
   | User | `postgres` |
   | Password | `postgres123` |

6. Assign that credential to every PostgreSQL node in the imported workflow.
7. Run the workflow manually once.
8. Review articles and run statistics:

   ```bash
   docker compose exec -T postgres psql -U postgres -d lgnm -c "SELECT COUNT(*) FROM articles;"
   docker compose exec -T postgres psql -U postgres -d lgnm -c "SELECT * FROM vw_collection_run_summary ORDER BY started_at DESC LIMIT 10;"
   docker compose exec -T postgres psql -U postgres -d lgnm -c "SELECT title, canonical_url, published_at FROM vw_recent_collected_articles LIMIT 10;"
   ```

9. Enable the hourly schedule only after the manual run succeeds.

## Workflow behavior

1. Manual Trigger or Schedule Trigger starts the pipeline.
2. PostgreSQL reads enabled official website sources.
3. The workflow processes one source at a time.
4. A collection run is created with `start_website_collection_run($1, $2, $3)`.
5. The homepage is downloaded.
6. Homepage links are extracted and normalized with the JavaScript `URL` API.
7. Duplicate URLs are removed in-memory before article downloads.
8. Every normalized article URL is downloaded by the article extraction Code node.
9. The workflow extracts title, date, and content from common HTML patterns.
10. Articles and run statistics are saved with `record_collected_articles_bulk($1, $2, $3, $4, $5)`, which internally uses the single-article upsert helper and finalizes source timestamps.

## SQL parameterization

All dynamic database writes in the workflow use PostgreSQL placeholders and n8n query replacements:

- `$1::bigint`, `$2::bigint`, `$3::text` for starting collection runs.
- `$1` through `$5` for bulk article persistence and run finalization.
- `$1` through `$8` inside the database-side single article persistence helper.

The static source queue query does not interpolate user or workflow data.

## Validation

Validate workflow JSON:

```bash
python3 - <<'PY'
from pathlib import Path
import json
for path in sorted(Path('workflows').glob('*.json')):
    json.loads(path.read_text())
    print(f'valid json: {path}')
PY
```

Validate repository whitespace:

```bash
git diff --check
```

Validate with Docker where available:

```bash
docker compose config
docker compose up -d
docker compose exec -T postgres psql -U postgres -d lgnm -c "SELECT COUNT(*) FROM vw_website_collection_queue;"
```
