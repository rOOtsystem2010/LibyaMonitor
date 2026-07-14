# LGNM — Libyan Government News Monitor

LGNM is a Docker-based foundation for monitoring public news and announcements from Libyan government entities. Sprint 1 delivers the production database foundation, seed source registry, and local operations documentation only.

## Sprint 1 scope

Implemented:

- PostgreSQL 16 database with a normalized schema for government entities, source URLs, articles, collection runs, reports, and settings.
- Indexes for source scheduling, URL lookup, article deduplication, article chronology, JSON metadata, and run history.
- Seed data for 50+ Libyan government entities and official source websites.
- Docker Compose stack for PostgreSQL, pgAdmin, and n8n.
- Placeholder n8n workflow files for future source management, collection, and reporting.
- Sprint 3 website collection pipeline for homepage discovery, article-page downloads, title/date/author/content extraction, duplicate-safe persistence, and collection stats.

Out of scope for current implemented sprints:

- AI analysis.
- Facebook collection.
- X collection.
- Telegram ingestion or notifications.
- Email delivery.

## Repository structure

```text
.
├── docker-compose.yml
├── postgres/
│   ├── 000_create_databases.sql
│   ├── 001_schema.sql
│   └── 002_seed_sources.sql
├── sources/
│   ├── categories.json
│   └── libya_sources.csv
└── workflows/
    ├── workflow_01_source_manager.json
    ├── workflow_02_news_collector.json
    ├── workflow_04_daily_report.json
    └── workflow_05_collect_websites.json
```

## Prerequisites

- Docker Engine 24+ or Docker Desktop.
- Docker Compose v2.
- A free local port for PostgreSQL (`5432` by default), pgAdmin (`8081`), and n8n (`5680`).

## Configuration

The stack works with defaults, but environment variables can override common settings:

| Variable | Default | Purpose |
| --- | --- | --- |
| `POSTGRES_USER` | `postgres` | PostgreSQL superuser for local development. |
| `POSTGRES_PASSWORD` | `postgres123` | PostgreSQL password for local development. |
| `POSTGRES_DB` | `lgnm` | LGNM application database. |
| `POSTGRES_PORT` | `5432` | Host PostgreSQL port. |
| `PGADMIN_DEFAULT_EMAIL` | `admin@libyamonitor.local` | pgAdmin login email. |
| `PGADMIN_DEFAULT_PASSWORD` | `admin123` | pgAdmin login password. |
| `PGADMIN_PORT` | `8081` | Host pgAdmin port. |
| `N8N_DB` | `n8n` | n8n service database created at startup. |
| `N8N_PORT` | `5680` | Host n8n port. |

For production, store secrets in a protected environment file or secret manager and replace all default passwords.

## Installation

1. Clone the repository and enter the project directory.
2. Start the stack:

   ```bash
   docker compose up -d
   ```

3. Confirm containers are healthy/running:

   ```bash
   docker compose ps
   ```

4. Verify the schema and seed data:

   ```bash
   docker compose exec -T postgres psql -U postgres -d lgnm -c "SELECT COUNT(*) FROM government_entities;"
   docker compose exec -T postgres psql -U postgres -d lgnm -c "SELECT COUNT(*) FROM sources;"
   docker compose exec -T postgres psql -U postgres -d lgnm -c "SELECT COUNT(*) FROM vw_website_collection_queue;"
   ```

## Local service URLs

- pgAdmin: <http://localhost:8081>
- n8n: <http://localhost:5680>
- PostgreSQL: `localhost:5432`, database `lgnm`

## Database design

The Sprint 1 schema separates:

- `source_categories`: controlled source classification values.
- `government_entities`: canonical Libyan government organizations.
- `sources`: monitorable sources tied to entities.
- `source_urls`: one or more website, RSS, or API endpoints per source.
- `articles`: collected article records with canonical URL and content-hash deduplication.
- `collection_runs`: operational collection audit history.
- `reports`: generated daily report storage for future workflows.
- `app_settings`: feature flags and operational settings.

## Validation commands

```bash
docker compose config
docker compose up -d
docker compose ps
docker compose exec -T postgres psql -U postgres -d lgnm -c "SELECT COUNT(*) FROM government_entities;"
docker compose down
```

## Sprint 3 website collection pipeline

Import `workflows/workflow_05_collect_websites.json` into n8n after starting the stack, assign the `LGNM PostgreSQL` credential to its PostgreSQL nodes, and run it manually before enabling the hourly schedule. Detailed instructions are in `docs/Sprint3.md`.

## License

MIT. See [LICENSE](LICENSE).
