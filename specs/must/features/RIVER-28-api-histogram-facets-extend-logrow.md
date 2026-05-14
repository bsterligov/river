# RIVER-28: API: Histogram & Facets + Extend LogRow
Status: In Progress
Priority: Must
Test Approach: TDD
Why: The UI needs time-bucketed log counts and top-value facets that the current API does not expose, and `LogRow` is missing fields the detail panel requires.
<!-- STOP -->

## Problem

The query API exposes only `GET /v1/logs` which returns raw rows. There is no way to get log counts grouped by time bucket (for the histogram) or top values per field (for the facet panel). `LogRow` is also missing `severity_number`, `span_id`, and `attributes` — fields the planned log detail panel requires.

## Goal

Two new endpoints exist: `GET /v1/logs/histogram` returns log counts in configurable time buckets; `GET /v1/logs/facets` returns top-20 values for `service_name` and `severity_text`. `GET /v1/logs` responses include the three new fields. The Dart client is regenerated and committed so UI phases can reference updated types.

## Scope

**In**
- `LogRow` extended with `severity_number: i64`, `span_id: String`, `attributes: serde_json::Value` (parse JSON string on read; emit `{}` on failure)
- `query_logs` SELECT updated to include the three new columns
- `HistogramBucket { bucket: String, count: u64 }` struct (derives `ToSchema`, `Serialize`)
- `query_logs_histogram(filter, from, to, step_secs) -> Result<Vec<HistogramBucket>>` on `clickhouse::Reader`; auto-selects step from [60, 300, 900, 3600, 21600, 86400] targeting ~30 buckets when `step_secs` is not supplied
- `GET /v1/logs/histogram` handler with params `filter`, `from`, `to`, `step` (e.g. `60s`, `5m`); defaults to auto step
- `FacetValue { value: String, count: u64 }` and `FacetField { field: String, values: Vec<FacetValue> }` structs
- `query_logs_facets(filter, from, to) -> Result<Vec<FacetField>>` on `clickhouse::Reader`; queries `service_name` and `severity_text` sequentially, LIMIT 20 each, skips a field on query error
- `GET /v1/logs/facets` handler
- Both routes and new schema types registered in `ApiDoc`
- One unit test per new handler (mock ClickHouse, assert 200 + shape); existing tests must remain green
- Dart client regenerated from the updated OpenAPI spec and committed to `src/ui/lib/api/generated/`

**Out**
- Facets over `attributes` JSON keys
- Pagination on histogram or facets endpoints
- Server-side caching of facet or histogram results
- Any UI code

## Decisions

- Step auto-selection targets ~30 buckets from a fixed ladder rather than exact arithmetic — keeps step values human-readable and avoids surprising bucket widths in the chart.
- `query_logs_facets` skips a field silently on error — a partial facet response is better than a 500; the UI facet panel handles empty `FacetField.values` gracefully.
- Dart client is committed alongside API changes so any developer can run the UI without re-running `openapi-generator` locally.
