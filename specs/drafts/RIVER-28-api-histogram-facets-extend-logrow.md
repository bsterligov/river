# DRAFT -- Issue #28
# Run `/po-spec-writer` on this branch to generate the full spec.

Issue:    #28
Task:     RIVER-28
Title:    API: Histogram & Facets + Extend LogRow
Why:
The query API exposes two new endpoints (`/v1/logs/histogram`, `/v1/logs/facets`) and `LogRow` carries all fields needed for the detail panel. The Dart client is regenerated and committed.

Steps:
1. Extend `LogRow` in `clickhouse.rs` to add `severity_number: i64`, `span_id: String`, `attributes: serde_json::Value` (parse the JSON string on read; emit `{}` on failure).
2. Update `query_logs` SELECT to include `severity_number`, `span_id`, `attributes`; map them into the extended `LogRow`.
3. Add `HistogramBucket { bucket: String, count: u64 }` schema struct (derive `ToSchema`, `Serialize`).
4. Add `query_logs_histogram(filter, from, to, step_secs: u64) -> Result<Vec<HistogramBucket>>` to `clickhouse::Reader`. SQL: `SELECT toStartOfInterval(timestamp, INTERVAL {step_secs} SECOND) AS bucket, count() AS count FROM logs{where_clause} GROUP BY bucket ORDER BY bucket FORMAT JSONEachRow`. Auto-select `step_secs` from the range duration if not supplied (target ~30 buckets; use the nearest value from [60, 300, 900, 3600, 21600, 86400]).
5. Add `GET /v1/logs/histogram` handler in `main.rs` with params `filter`, `from`, `to`, `step` (e.g. `60s`, `5m`). Parse the step string to seconds; default to auto.
6. Add `FacetValue { value: String, count: u64 }` and `FacetField { field: String, values: Vec<FacetValue> }` structs.
7. Add `query_logs_facets(filter, from, to) -> Result<Vec<FacetField>>` to `clickhouse::Reader`. For each faceted column (`service_name`, `severity_text`): `SELECT {col} AS value, count() AS count FROM logs{where_clause} GROUP BY value ORDER BY count DESC LIMIT 20 FORMAT JSONEachRow`. Run both queries sequentially; return a `FacetField` per column. Skip a field if the query errors (return empty values).
8. Add `GET /v1/logs/facets` handler.
9. Register both routes and new schema types in `ApiDoc` (the `#[derive(OpenApi)]` block).
10. Run `mise exec -- cargo test` — all existing tests must pass; add one new unit test per handler (mock ClickHouse, assert 200 + shape).
11. Start the API locally (`mise exec -- cargo run -p river-query-api`), fetch `/openapi.json`, run `openapi-generator` to regenerate the Dart client into `src/ui/lib/api/generated/`, commit the result.

Done when: `GET /v1/logs/histogram` and `GET /v1/logs/facets` return 200 with correct JSON; `GET /v1/logs` response includes `severity_number`, `span_id`, `attributes`; `mise exec -- cargo test` is green; Dart client is committed.

Part of feature plan: logs-ui-full-page
Why: Replace the minimal logs page with a full observability UI — time range selector, Kibana-style search, auto-facets, distribution histogram, column-managed table, and a log detail panel — so operators can explore logs without leaving the app.
Priority: must
Category: features
