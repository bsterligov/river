# RIVER-19: Configuration
Status: In Progress
Priority: Should
Test Approach: TDD
Why: Each component reads env vars ad-hoc with inconsistent naming and hardcoded credential defaults, making configuration error-prone and violating the `RIVER_` prefix convention.
<!-- STOP -->

## Problem

Three crates (`sidecar`, `api`, `ingestion`) each roll their own inline `std::env::var` calls with no shared structure. Several env vars lack the `RIVER_` prefix (`CLICKHOUSE_URL`, `CLICKHOUSE_DB`, `CLICKHOUSE_USER`, `CLICKHOUSE_PASSWORD`, `VICTORIAMETRICS_URL`, `S3_BUCKET`, `SIDECAR_BUFFER_MAX_BYTES`, `SIDECAR_FLUSH_INTERVAL_SECS`). Credential fields default to the literal string `"river"`, which silently passes with wrong credentials in any environment that hasn't set the vars.

## Goal

Every component loads configuration through a `config.rs` module backed by the `config` crate. All env vars are `RIVER_`-prefixed. Missing required vars (credentials) cause an immediate startup failure with a clear error message rather than silently using wrong defaults.

## Scope

**In**
- Add `config` crate to workspace dependencies; add it to `api`, `ingestion`, and `sidecar`
- Add a `config.rs` module to each crate; move all `std::env::var` calls into it (test: `Config::from_env()` returns correct values when env vars are set; returns defaults when optional vars are absent)
- Rename non-prefixed env vars to `RIVER_` prefix across all three crates: `CLICKHOUSE_URL` → `RIVER_CLICKHOUSE_URL`, `CLICKHOUSE_DB` → `RIVER_CLICKHOUSE_DB`, `CLICKHOUSE_USER` → `RIVER_CLICKHOUSE_USER`, `CLICKHOUSE_PASSWORD` → `RIVER_CLICKHOUSE_PASSWORD`, `VICTORIAMETRICS_URL` → `RIVER_VICTORIAMETRICS_URL`, `S3_BUCKET` → `RIVER_S3_BUCKET`, `SIDECAR_BUFFER_MAX_BYTES` → `RIVER_BUFFER_MAX_BYTES`, `SIDECAR_FLUSH_INTERVAL_SECS` → `RIVER_FLUSH_INTERVAL_SECS`
- Make `RIVER_CLICKHOUSE_USER` and `RIVER_CLICKHOUSE_PASSWORD` required — startup fails with a descriptive error if either is absent (test: missing required var returns `Err`)
- Update `docker-compose.yml` and any `.env` files to use the new var names

**Out**
- File-based config (TOML/YAML) — env vars are sufficient for the current deployment model
- Shared workspace crate for common config fields — duplication between `api` and `ingestion` is acceptable until a third consumer appears
- Hot reloading
- Secret management integration (Vault, AWS SSM)

## Decisions

- Use `config` crate (not `envy` or raw `std::env`) — supports layered sources if file-based config is added later without restructuring
- Credentials are required, no default — docker-compose always sets them; defaulting to `"river"` is a silent misconfiguration risk
- File-based config is out of scope — adds complexity (path discovery, precedence) with no current need; can be layered in later via `config` crate without API changes
