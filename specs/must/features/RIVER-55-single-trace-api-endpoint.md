# RIVER-55: Single-trace API endpoint

Priority: Must
Test Approach: TDD
Why: The UI cannot fetch or display a complete trace because no endpoint exists to retrieve all spans for a given trace ID.
<!-- STOP -->

## Problem

Trace data is fully ingested into ClickHouse and spans are queryable via the existing `GET /v1/traces` list endpoint, but there is no way to retrieve all spans for one specific trace in a single call. Any UI that wants to render a trace timeline must either over-fetch from the list endpoint or have no path at all. This blocks building the trace-explorer UI.

## Goal

A caller sends a trace ID and gets back every span that belongs to that trace, in one request. If the trace does not exist, the API returns a clear 404.

- `GET /v1/traces/{trace_id}` returns a JSON array of `Span` objects for a known trace ID.
- `GET /v1/traces/{trace_id}` returns `404` with `{ "error": "trace not found" }` for an unknown trace ID.
- The route appears in `/openapi.json` so the Dart client can be regenerated with a `getTrace(traceId)` method.

## Scope

**In**
- New `GET /v1/traces/{trace_id}` route in `src/river-query-api/src/main.rs`
- Queries ClickHouse for all spans where `trace_id = ?`; reuses the existing `Span` struct
- Returns `200 Vec<Span>` on match, `404 { "error": "trace not found" }` when no spans found
- `utoipa` annotation so the route is included in `/openapi.json`
- Integration test: happy path (known trace ID returns correct spans) and not-found path (unknown ID returns 404)
- Dart client regenerated: `mise exec -- openapi-generator generate -i http://localhost:8080/openapi.json -g dart -o src/ui/lib/api/generated`; `getTrace(traceId)` method must be present in the output

**Out**
- UI changes (trace explorer UI is a separate phase)
- Pagination of spans within a trace
- Filtering or sorting spans beyond the basic trace ID lookup
- Any changes to how spans are ingested or stored

## Decisions

- Reuse the existing `Span` struct — no new response type
- Return 404 (not 200 with empty array) when no spans are found for the given trace ID — an empty result means the trace does not exist
- `trace_id` is a path parameter, not a query string, to match REST conventions for a resource lookup
