# RIVER-10: Database Migration Management
Status: In Progress
Priority: Must
Test Approach: TDD
Why: Schema changes are embedded in application code with no versioning, rollback path, or separation from runtime logic.
<!-- STOP -->

## Problem

The ingestion service creates the `logs` and `traces` tables via hardcoded DDL strings in `clickhouse.rs` that run at startup. There is no record of when a schema changed, no way to apply a change independently of a deploy, and no recovery path if a migration partially fails. As the schema evolves, this approach will cause silent drift between environments.

## Goal

A migration tool owns all ClickHouse DDL. Running migrations is a discrete, repeatable step that produces the correct schema regardless of prior state. Engineers add a new migration file when the schema changes; the tool handles ordering and idempotency.

## Scope

**In**
- Select and integrate a migration tool with ClickHouse support
- Write initial migrations replicating the current `logs` and `traces` DDL
- Remove `ensure_tables()` and the inline DDL constants from `clickhouse.rs`
- Integration tests: run migrations against a real ClickHouse instance and assert the expected tables and columns exist

**Out**
- Transactional rollback (ClickHouse MergeTree does not support it)
- VictoriaMetrics schema management (schema-less)
- UI or API layer schema changes

## Decisions

- Migration scripts live under `infra/migrations/clickhouse/`
- Tool choice is left to the implementer; must support ClickHouse natively without a shim
