# DRAFT -- Issue #82
# Run `/spec` on this branch to generate the full spec.

Issue:    #82
Task:     RIVER-82
Title:    Fix code quality issues from codebase audit
Why:
Address the code quality issues identified in a full codebase audit.

## Error handling
- Replace `unwrap_or_default()` (~37 instances) with explicit error handling or `.expect("description")`
- Fix silent `catch (_)` in Dart (trace_detail_panel.dart) — store and show error to user
- Fix HTTP body reads that silently discard network errors (`resp.text().await.unwrap_or_default()`)

## Oversized files (split into focused modules)
- `river-query-api/src/clickhouse.rs` (831 lines) — extract `models.rs`, `query_builder.rs`, `parser.rs`
- `river-sidecar/src/metrics_aggregator.rs` (693 lines) — extract series types and test utilities
- `river-ingestion/src/clickhouse.rs` (665 lines) — separate `Writer` from parsing functions

## Duplication
- `build_events()` and `build_links()` share an identical 3-vector fold pattern — extract generic helper
- `query_logs`, `query_logs_histogram`, `query_logs_facets` follow the same WHERE→SQL→execute→parse pattern — extract `execute_query<T>()`
- `logs_controller.dart` and `traces_controller.dart` duplicate ~40 lines of loading/error/reload/filter logic — extract `BasePageController<T>`

## Naming
- Expand single-letter abbreviations in `metrics_aggregator.rs`: `rk`, `sn`, `sv`, `sm`
- Standardize function naming: `ch_datetime64_to_rfc3339` vs `rfc3339_to_ch` — use `parse_*` / `convert_*` / `build_*`
- Rename `_kMaxSpans` → `maxSpans` (Objective-C prefix not idiomatic Dart)
- Single-letter params in `filter.rs` (`s`, `f`) — use `input`, `field`, `filter`

## Flutter
- `log_histogram.dart`: remove manual `setState` for expansion — let `ExpansionTile` manage its own state
- `logs_page.dart`: scope `ListenableBuilder` to individual sub-widgets instead of the whole column
- `logs_table.dart`: add `ValueKey` to `Expanded`/`SizedBox` children in column loop
- Move hardcoded `36.0` collapsed width to a theme constant

## Public API
- `LogRow`, `Span`, `TraceGroup` in `river-query-api/src/clickhouse.rs` are internal query types used as API response types — move to `models/` module and convert at the API boundary

## Testing
- Replace `.unwrap()` in `db_tests.rs` helper with `Result<()>` return + `?`
- Add `addTearDown()` disposal for controllers in Flutter tests
- Add concurrent access tests for `MetricsAggregator` (`tokio::join!`)
- Implement or remove generated API test stubs (`// TODO` in generated/test/)

## Documentation
- Add rustdoc to `pub struct MetricsAggregator`, `pub fn push()`, `pub fn parse_logs()`
- Group the 9 parameters of `upsert()` in `metrics_aggregator.rs` into a `MetricContext` struct
Priority: could
Category: refactoring
