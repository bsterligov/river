# RIVER-82: Fix Code Quality Issues from Codebase Audit
Status: Done
Priority: Could
Test Approach: TDD
Why: Recurring patterns of silent error masking, code duplication, and mixed concerns slow down development and hide real failures from operators.
<!-- STOP -->

## Problem

A full audit of the Rust backend and Flutter UI identified ~37 silent `unwrap_or_default()` calls that swallow field-level failures, duplicate query and controller boilerplate copied across files, and three backend files over 600 lines each that mix data models with query logic. These patterns make bugs harder to diagnose, make the codebase harder to navigate, and cause Flutter widget rebuilds to be broader than necessary.

## Goal

After this work: errors propagate visibly (operators see what failed), each file has a single responsibility, duplicated patterns are extracted once, and naming is consistent and idiomatic across both Rust and Dart.

## Scope

**In**

**Error handling**
- Replace all `unwrap_or_default()` calls in Rust with explicit error handling or `.expect("description")`
- Fix `resp.text().await.unwrap_or_default()` HTTP body reads to include the underlying error in the message
- Fix `catch (_)` in `trace_detail_panel.dart` — store the error and surface it in the UI

**File decomposition**
- Split `river-query-api/src/clickhouse.rs` (831 lines) into `models.rs`, `query_builder.rs`, `parser.rs`
- Split `river-sidecar/src/metrics_aggregator.rs` (693 lines) — extract series types and test utilities
- Split `river-ingestion/src/clickhouse.rs` (665 lines) — separate `Writer` from parsing functions

**Duplication**
- Extract the repeated 3-vector fold pattern shared by `build_events()` and `build_links()` into a generic helper
- Extract the WHERE→SQL→execute→parse pattern shared by `query_logs`, `query_logs_histogram`, `query_logs_facets` into `execute_query<T>()`
- Extract `BasePageController<T>` from the ~40 duplicated lines in `logs_controller.dart` and `traces_controller.dart`

**Naming**
- Expand single-letter abbreviations in `metrics_aggregator.rs`: `rk`, `sn`, `sv`, `sm` → full names
- Standardize conversion function prefixes: adopt `parse_*` / `convert_*` / `build_*` consistently (fixes `ch_datetime64_to_rfc3339` vs `rfc3339_to_ch` inconsistency)
- Rename `_kMaxSpans` → `maxSpans` (Objective-C `k` prefix not idiomatic Dart)
- Rename single-letter params in `filter.rs` (`s`, `f`) → `input`, `field`, `filter`

**Flutter**
- `log_histogram.dart`: remove manual `setState` for expansion tile — let `ExpansionTile` manage its own state
- `logs_page.dart`: scope `ListenableBuilder` to individual sub-widgets instead of wrapping the entire column
- `logs_table.dart`: add `ValueKey` to `Expanded`/`SizedBox` children in column loops
- Move hardcoded `36.0` collapsed panel width to a theme constant

**Testing**
- `db_tests.rs`: return `Result<()>` from test helper; replace `.unwrap()` with `?`
- Flutter tests: add `addTearDown()` disposal for all controllers created in test setup
- `MetricsAggregator`: add concurrent access tests using `tokio::join!`
- Remove or implement generated API test stubs (all `// TODO` in `generated/test/`)

**Documentation**
- Add rustdoc to `pub struct MetricsAggregator`, `pub fn push()`, `pub fn parse_logs()`
- Group the 9 parameters of `upsert()` in `metrics_aggregator.rs` into a `MetricContext` struct

**Out**
- Changing public API response shapes
- Migrating to a different state management library in Flutter
- Adding new test infrastructure (test databases, mocks, fixtures) beyond what the fixes above require
- Any changes to ClickHouse schema or SQL queries beyond mechanical rename/extract refactors
