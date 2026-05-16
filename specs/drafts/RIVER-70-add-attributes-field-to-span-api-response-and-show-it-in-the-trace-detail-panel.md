# DRAFT -- Issue #70
# Run `/spec` on this branch to generate the full spec.

Issue:    #70
Task:     RIVER-70
Title:    Add `attributes` field to Span API response and show it in the trace detail panel
Why:
The Rust `Span` struct (river-query-api) does not include an `attributes` field, so span-level attributes are never returned by `GET /v1/traces/{id}` and cannot be displayed in the UI.

## Acceptance criteria

- Add `attributes: serde_json::Value` to the `Span` struct in `clickhouse.rs`
- Pull `SpanAttributes` from ClickHouse in `row_to_span`
- Regenerate the Dart API client so `Span` gains an `attributes` field
- Display parsed span attributes as key-value rows in the "Span Info" section of `TraceDetailPanel` (below the existing metadata fields)
Priority: must
Category: features
