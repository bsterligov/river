# RIVER-91: Replace manual serde_json::Value field extraction with typed ClickHouse row structs
Priority: Could
Test Approach: TDD
Why: Manual field-by-field extraction from raw `serde_json::Value` in `clickhouse.rs` is brittle — missing or renamed columns silently produce empty strings instead of a compile or deserialisation error.
<!-- STOP -->

## Problem

Every ClickHouse reader method (logs, traces, histogram, facets) deserialises results as `Vec<serde_json::Value>` and then manually extracts each field with `.as_str().unwrap_or_default()` or `.as_u64().unwrap_or(0)`. There is no compiler or runtime signal when a column is missing or mis-typed — the field just silently defaults. Adding a new column or renaming one requires touching both the SQL and the manual extraction block.

## Goal

ClickHouse rows deserialise directly into typed Rust structs. A missing or mis-typed column surfaces as a deserialisation error at the query boundary, not as a silent default embedded deep in business logic. The public API surface and all existing tests remain unchanged.

## Scope

**In**
- Introduce private intermediate structs (`ChLogRow`, `ChSpanRow`, `ChHistogramRow`, `ChFacetValueRow`) with `#[derive(Deserialize)]` and field names matching ClickHouse column aliases exactly.
- Replace or wrap `query_json` with a generic `query_typed<T: DeserializeOwned>` helper that deserialises each `JSONEachRow` line directly into `T`.
- Keep the existing output DTOs (`LogRow`, `Span`, `HistogramBucket`, etc.) and their `From<Ch*>` / conversion logic unchanged in shape — only the _source_ of field values changes.
- All unit and integration tests in `clickhouse.rs` and `main.rs` pass without modification.

**Out**
- Changes to the public HTTP API shape or OpenAPI schema.
- Changes to VictoriaMetrics reader (`victoriametrics.rs`).
- Changes to any Flutter/Dart code.
- Adding new columns or changing query SQL beyond what is needed for the refactor.

## Decisions

- Deserialisation errors from `query_typed` propagate as `anyhow::Error` and surface as `503 Service Unavailable` via the existing `map_backend_error` path — same as today for ClickHouse connectivity failures.
- `query_json` can be removed once `query_typed` covers all call sites; no need to keep both.
- The `parse_attributes` fallback (`{}` on bad JSON) stays as-is — it handles a known ClickHouse encoding quirk and is not replaced by serde.
