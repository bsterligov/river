# DRAFT -- Issue #79
# Run `/spec` on this branch to generate the full spec.

Issue:    #79
Task:     RIVER-79
Title:    Fix Rust code quality issues found in analysis
Why:
Static analysis of the Rust codebase identified a range of code quality issues across the 5-crate workspace. This issue tracks all findings for resolution.

## Priority 1 — Fix Immediately

- **Clippy deny error** — `river-ingestion/src/clickhouse.rs:434`: hardcoded `3.14` instead of `std::f64::consts::PI`
- **Silent error discard** — `.unwrap_or_default()` on HTTP response text swallows errors in `river-ingestion/src/clickhouse.rs:69`, `migrations.rs:79`, and `river-query-api/src/victoriametrics.rs:47`; log with `log::error!()` before fallback
- **Hardcoded gRPC port** — `river-sidecar/src/main.rs:182`: `"0.0.0.0:4317"` should come from config or env var (`RIVER_SIDECAR_PORT`)

## Priority 2 — Refactor for Maintainability

- **Overly long functions** — `row_to_span()` (59 lines, `river-query-api/src/clickhouse.rs:324`) and `ingest()` (112 lines, `river-sidecar/src/metrics_aggregator.rs:159`) need helpers extracted
- **Three passes over one vec** — `river-ingestion/src/clickhouse.rs:106`: three separate `.map()` over `span.events`; use a single `unzip` instead
- **Unnecessary hot-path clones** — `resource.clone()` 3x per metric in `river-sidecar/src/metrics_aggregator.rs:173`; pass `&Option<Resource>` instead
- **Nested for loops** — `river-ingestion/src/clickhouse.rs:78`: triple nested loops over resource_logs -> scope_logs -> log_records; replace with `.flat_map()` chains

## Priority 3 — Polish

- **Confusing sibling names** — `attrs_map` / `attrs_as_string_map` (`river-ingestion/src/clickhouse.rs:189`); rename to `to_json_attrs()` / `to_string_attrs()`
- **Magic number arrays** — step ladder in `river-query-api/src/clickhouse.rs:423` and sentinel separator in `river-sidecar/src/metrics_aggregator.rs:256` should be named constants
- **Missing public API docs** — `river-config/src/lib.rs:14`, `river-index/src/walker.rs:73`, `river-query-api/src/filter.rs` module level all lack doc comments
- **Option combinator improvements** — `service_name()` in `river-ingestion/src/clickhouse.rs:156` and `parse_attributes()` in `river-query-api/src/clickhouse.rs:179` use verbose nested match/if-else blocks; replace with `.and_then()` / `.or_else()` chains
- **Untested SQL escaping** — `river-query-api/src/filter.rs:303` escapes quotes but has no test for input like `trace_id:abc'def`
Priority: could
Category: refactoring
