# RIVER-70: Add `attributes` field to Span API response and show it in the trace detail panel

Priority: Must
Test Approach: BDD
Why: The `Span` struct omits `attributes`, so `GET /v1/traces/{id}` never returns span-level attributes and the UI cannot display them.
<!-- STOP -->

## Problem

`river-query-api` maps ClickHouse rows to `Span` structs in `row_to_span`, but `SpanAttributes` is never read from ClickHouse and `attributes` is not a field on `Span`. `GET /v1/traces/{id}` therefore returns no attribute data for any span. RIVER-61 (span attributes panel) depends on this field being present in the API response; without it the UI can only show "No attributes" for every span regardless of what ClickHouse holds.

## Goal

An operator opens a trace that has spans with attributes. The trace detail panel shows the correct key-value attribute pairs for each span — pulled from ClickHouse, returned by the API, decoded from the Dart model, and rendered in the UI.

**Scenarios**

Given a trace exists in ClickHouse where at least one span has a non-empty `SpanAttributes` map,
When `GET /v1/traces/{trace_id}` is called,
Then the response includes an `attributes` field on each span containing the key-value pairs recorded at ingest time.

Given a trace exists where a span has no attributes,
When `GET /v1/traces/{trace_id}` is called,
Then the `attributes` field for that span is an empty JSON object `{}`.

Given the Dart API client has been regenerated after the `attributes` field is added,
When the Flutter UI calls `getTrace` and opens the trace detail panel,
Then the `SpanAttributesSection` (RIVER-61) can render real attribute rows instead of the "No attributes" fallback.

## Scope

**In**
- Add `attributes: serde_json::Value` to the `Span` struct in `river-query-api`
- Read `SpanAttributes` from ClickHouse in `row_to_span` and serialize to `serde_json::Value`; fall back to `serde_json::Value::Object(Default::default())` on parse failure
- Regenerate the Dart API client from the updated `/openapi.json` so `Span` gains an `attributes` field
- Verify `flutter build` passes after client regen

**Out**
- Any UI changes beyond what the Dart client regen delivers automatically (UI rendering is RIVER-61's scope)
- Filtering or searching spans by attribute value
- Ingestion changes — attributes are already stored in ClickHouse

## Decisions

- `attributes` serialization reuses the same `serde_json::Value` + fallback pattern as `LogRow.attributes` in `clickhouse.rs` — consistent parsing, no new dependencies.
- The Dart client must be regenerated against a live API server (not from a static JSON snapshot) to preserve non-nullable field types; see [[feedback_dart_client_regen]].
- RIVER-61 depends on this spec: once merged, RIVER-61's "No attributes" fallback becomes live data.
