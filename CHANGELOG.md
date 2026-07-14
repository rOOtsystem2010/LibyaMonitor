# Changelog

All notable changes to LGNM will be documented in this file.

## [0.3.0] - 2026-07-14

### Added

- Sprint 3 production website collection workflow for source queueing, homepage discovery, article-page download, extraction, and persistence.
- Parameterized PostgreSQL helper functions for collection run lifecycle and article upserts.
- Sprint 3 installation, validation, and operating documentation.

### Changed

- Replaced the Sprint 2 prototype workflow with `workflow_05_collect_websites.json`.

### Not included

- Facebook ingestion.
- X ingestion.
- AI analysis.
- Telegram ingestion or notifications.
- Email delivery.

## [0.2.0] - 2026-07-14

### Added

- Sprint 2 n8n website collector workflow with manual and hourly schedule triggers.
- PostgreSQL helper views for enabled website source queues, collection run summaries, and article deduplication keys.
- Documentation for importing, configuring, and validating the website collector.

### Not included

- Facebook ingestion.
- X ingestion.
- AI analysis.
- Telegram ingestion or notifications.
- Email delivery.

## [0.1.0] - 2026-07-14

### Added

- Sprint 1 Docker Compose foundation for PostgreSQL, pgAdmin, and n8n.
- Normalized PostgreSQL schema for categories, government entities, sources, source URLs, articles, collection runs, reports, and application settings.
- Production-oriented indexes for scheduling, lookups, deduplication, reporting chronology, and JSON metadata.
- Seed registry containing more than 50 Libyan government entities.
- Installation and validation documentation.
- MIT license.

### Not included

- AI analysis.
- Facebook ingestion.
- X ingestion.
