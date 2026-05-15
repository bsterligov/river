# DRAFT -- Issue #55
# Run `/po-spec-writer` on this branch to generate the full spec.

Issue:    #55
Task:     RIVER-55
Title:    Single-trace API endpoint
Why:
`GET /v1/traces/{trace_id}` returns all spans for a given trace ID, allowing the UI to fetch a complete trace on demand.

Steps:
1. Add a `GET /v1/traces/{trace_id}` route in `src/river-query-api/src/main.rs` that queries ClickHouse for all spans with the given `trace_id` and returns `Vec<Span>` (reuse existing `Span` struct).
2. Annotate with `utoipa` so the route appears in `/openapi.json`.
3. Add an integration test covering the happy path and a 404 when the trace does not exist.
4. Regenerate the Dart client: `mise exec -- openapi-generator generate -i http://localhost:8080/openapi.json -g dart -o src/ui/lib/api/generated`.

Done when: `GET /v1/traces/{trace_id}` returns the correct spans in manual testing; Dart client contains a `getTrace(traceId)` method; integration test passes under `mise exec -- cargo test`.

Part of feature plan: trace-explorer
Why: Users have no first-class UI to search and visualize distributed traces, even though trace data is fully ingested and queryable via the existing API.
Priority: must
Category: features
