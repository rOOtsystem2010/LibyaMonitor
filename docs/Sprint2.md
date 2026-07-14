# Sprint 2 — Website Collector

Sprint 2 adds the first working LGNM collection pipeline for public website homepages. It is intentionally limited to website collection only.

## Scope

Implemented:

- Sprint 2 prototype n8n workflow, superseded in Sprint 3 by `workflows/workflow_05_collect_websites.json`.
- Manual and scheduled execution triggers.
- PostgreSQL lookup of enabled website sources through `vw_enabled_website_sources`.
- Homepage download using n8n HTTP Request.
- Link extraction from downloaded HTML.
- URL normalization and filtering in a Code node.
- Duplicate-safe article insertion into PostgreSQL using `ON CONFLICT DO NOTHING`.
- Source `last_checked_at` / `last_success_at` updates.
- Per-source collection run statistics in `collection_runs`.
- Helper SQL views in `postgres/003_sprint2_views.sql`.

Not implemented:

- Facebook ingestion.
- X ingestion.
- AI analysis.
- Telegram ingestion or notifications.
- Email delivery.

## Installation

1. Start from a clean checkout with Docker and Docker Compose v2 installed.
2. Start the stack:

   ```bash
   docker compose up -d
   ```

3. Open n8n at <http://localhost:5680>.
4. Create or select a PostgreSQL credential in n8n with these local defaults:

   | Field | Value |
   | --- | --- |
   | Host | `postgres` |
   | Port | `5432` |
   | Database | `lgnm` |
   | User | `postgres` |
   | Password | `postgres123` |

5. For current installs, import `workflows/workflow_05_collect_websites.json` as documented in `docs/Sprint3.md`.
6. Assign the PostgreSQL credential to every PostgreSQL node in the workflow.
7. Save the workflow. Keep it inactive until you are ready to run it manually or enable the schedule.

## Workflow behavior

The collector performs these steps for each run:

1. Manual Trigger or Schedule Trigger starts the workflow.
2. PostgreSQL reads enabled website sources from `vw_enabled_website_sources`.
3. n8n splits sources into individual items.
4. HTTP Request downloads each source homepage.
5. HTML Extract collects anchor `href` values.
6. Code node normalizes relative links, drops non-HTTP links, removes fragments, filters duplicate URLs, and prepares article rows.
7. PostgreSQL inserts one `collection_runs` row for the source.
8. PostgreSQL inserts discovered article URLs with `ON CONFLICT DO NOTHING` so duplicates are ignored.
9. PostgreSQL updates collection statistics and source timestamps.

## SQL helpers

`postgres/003_sprint2_views.sql` creates:

- `vw_enabled_website_sources`: enabled website source queue for n8n.
- `vw_collection_run_summary`: operational run history with source names and durations.
- `vw_article_deduplication_keys`: compact deduplication audit view.

## Validation

Validate workflow JSON locally:

```bash
python3 - <<'PY'
from pathlib import Path
import json
for path in sorted(Path('workflows').glob('*.json')):
    json.loads(path.read_text())
    print(f'valid json: {path}')
PY
```

Validate Docker configuration and startup where Docker is available:

```bash
docker compose config
docker compose up -d
docker compose ps
docker compose exec -T postgres psql -U postgres -d lgnm -c "SELECT COUNT(*) FROM vw_enabled_website_sources;"
docker compose exec -T postgres psql -U postgres -d lgnm -c "SELECT * FROM vw_collection_run_summary ORDER BY started_at DESC LIMIT 5;"
```

## Operational notes

- The schedule is configured for hourly execution and can be adjusted in n8n.
- The workflow stores discovered links as article records with `status = 'new'`; full article-page scraping is reserved for a later sprint.
- The workflow does not call AI services or social network APIs.
