# RIVER-79: Fix Rust Code Quality Issues Found in Analysis
Status: In Progress
Priority: Could
Test Approach: TDD
Why: Static analysis surfaced a Clippy deny error, silent error discard, and a range of maintainability issues across the Rust codebase that will compound as the project grows.
<!-- STOP -->

## Problem

`cargo clippy --deny warnings` fails today due to a hardcoded float literal (`3.14` instead of `std::f64::consts::PI`). Separately, HTTP error bodies are silently swallowed with `.unwrap_or_default()` in three places, making production failures hard to diagnose. Beyond these blockers, several hot-path functions are too long, clone data unnecessarily, and use imperative loops where iterator chains would be clearer.

## Goal

`cargo clippy --deny warnings` passes clean. HTTP response errors are logged before fallback. All identified long functions have helpers extracted, hot-path clones are eliminated, and magic numbers are replaced with named constants. A test covers the SQL quote-escaping path in the filter DSL.

## Scope

**In**
- Fix Clippy deny error: replace `3.14` with `std::f64::consts::PI` in `river-ingestion/src/clickhouse.rs:434`
- Log HTTP error context before `.unwrap_or_default()` fallback in `river-ingestion/src/clickhouse.rs:69`, `migrations.rs:79`, `river-query-api/src/victoriametrics.rs:47`
- Extract `build_events()` and `build_links()` helpers from `row_to_span()` in `river-query-api/src/clickhouse.rs:324`
- Extract helpers from `ingest()` in `river-sidecar/src/metrics_aggregator.rs:159` to reduce it below 50 lines
- Replace three separate `.map()` passes over `span.events` with a single `unzip` in `river-ingestion/src/clickhouse.rs:106`
- Pass `&Option<Resource>` instead of cloning in `river-sidecar/src/metrics_aggregator.rs:173`
- Replace triple nested `for` loops over resource_logs → scope_logs → log_records with `.flat_map()` chains in `river-ingestion/src/clickhouse.rs:78`
- Rename `attrs_map` → `to_json_attrs` and `attrs_as_string_map` → `to_string_attrs` in `river-ingestion/src/clickhouse.rs:189`
- Extract `const STEP_LADDER: &[u64]` in `river-query-api/src/clickhouse.rs:423`
- Extract `const KEY_SEPARATOR: &str` in `river-sidecar/src/metrics_aggregator.rs:256`
- Add unit test: filter DSL rejects / escapes single-quote in `trace_id` value (`river-query-api/src/filter.rs:303`)

**Out**
- Changing `LogRow` fields to borrowed `&'a str` (lifetime complexity not worth it at this scale)
- Adding `RIVER_SIDECAR_PORT` env var (separate issue — touches config crate and docs)
- Adding public API doc comments (separate issue — docs category)
- Fixing `.unwrap_or(0)` precision loss in `rfc3339_to_ns` (separate issue — correctness bug)

## Decisions

- All changes must leave existing tests green and `cargo clippy --deny warnings` clean.
- Renaming `attrs_map` / `attrs_as_string_map` is a pure internal rename — no public API surface is affected.
- The `unzip` refactor on `span.events` must produce identical output to the three-pass version; verify with the existing `parse_traces` test.
