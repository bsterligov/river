# River — Project Context
> Agent-facing. Read before specs/decisions. Update when a spec changes anything here.

## Why
Open-source observability platform: infinitely scalable, deployable anywhere. Collects logs, metrics, traces via Rust sidecars; unified storage + querying.

## Signal Flow
`Service → Sidecar (OTLP/gRPC:4317) → S3 buffer → Ingestion → Storage → API → UI`

## Components
| Component | Lang | St | Role |
|-----------|------|----|------|
| river-sidecar | Rust | done | OTLP/gRPC receiver, in-memory buffer, S3 batch writer |
| demo-app | .NET 10 | done | Continuous OTel emitter (dev/validation) |
| river-ingestion | Rust | done | S3 poll loop → ClickHouse (logs/traces) + VictoriaMetrics (metrics); runs migrations at startup |
| river-query-api | Rust | done | Unified HTTP query layer (axum, utoipa, filter DSL) |
| river-config | Rust | done | Shared config library used by all Rust crates |
| ui | Flutter | done | macOS dashboard — sidebar nav, Logs page, generated API client |

## Tech Stack
| Concern | Choice |
|---------|--------|
| Backend | Rust 1.95.0 |
| Frontend | Flutter 3.41.0 (web + desktop) |
| Wire protocol | OTLP/gRPC |
| Log/Trace storage | ClickHouse |
| Metric storage | VictoriaMetrics |
| Buffer | S3-compatible (LocalStack in dev) |
| Toolchain mgmt | mise |

## Decisions
- **S3 buffer** — decouples river-ingestion from processing; survives restarts
- **Raw OTLP protobuf** — no envelope; wire format preserved for downstream
- **Sidecar is permanent** — production entrypoint, not a scaffold
- **ClickHouse + VictoriaMetrics** — best-of-breed per signal type
- **Flutter UI** — one codebase for web + desktop
- **S3 key schema:** `{signal}/{service}/{timestamp}-{uuid}.pb`
- **Env vars:** all prefixed `RIVER_` (e.g. `RIVER_BUFFER_MAX_BYTES`, `RIVER_FLUSH_INTERVAL_SECS`); `RIVER_CLICKHOUSE_USER` and `RIVER_CLICKHOUSE_PASSWORD` are required (no default) — startup fails if absent
- **Config loading:** each crate has a `config.rs` module backed by the `config` crate (env-only source; file-based config is out of scope)
- **Grafana is dev tooling only** — not a permanent product component; anonymous admin access, no RBAC
- **ClickHouse Grafana plugin:** `grafana-clickhouse-datasource` (Grafana Labs), installed via `GF_INSTALL_PLUGINS` at container start; connects on native port 9000
- **Dashboard provisioning:** JSON files under `grafana/dashboards/`, mounted into the container; datasources under `grafana/provisioning/`
- **Query API port:** `8080`, configurable via `RIVER_API_PORT`
- **Filter DSL:** `key:value` (eq), `key:>value` / `key:<value` / `key:>=value` / `key:<=value`, `AND`/`OR`/`NOT`, wildcard `*` suffix; translates to ClickHouse SQL or VictoriaMetrics label selectors
- **OpenAPI spec:** generated from code via `utoipa` 5, served at `GET /openapi.json`
- **Swagger UI:** mounted at `GET /swagger-ui/` via `utoipa-swagger-ui 9` (axum 0.8-compatible); fetches the spec from `/openapi.json`
- **`duration_ms` filter field:** converted to `duration_ns` (×1 000 000) when targeting ClickHouse traces table
- **Grafana trace config:** ClickHouse datasource provisioning includes `traces` block with `defaultDatabase: river`, `defaultTable: traces`, and column mappings matching the schema (`trace_id`, `span_id`, `parent_span_id`, `service_name`, `operation_name`, `start_time_unix_nano`, `duration_ns`, unit `nanoseconds`)
- **Flutter UI location:** `src/ui/` — macOS-only; no iOS/Android/web targets
- **Dart API client:** generated from `/openapi.json` via `openapi-generator 7` into `src/ui/lib/api/generated/`; referenced as a path dependency named `river_api`
- **Flutter theme tokens:** `lib/theme/app_theme.dart` — extends to all pages; light theme only at this stage
- **Navigation:** custom sidebar widget (no third-party library); pages enumerated via `_Page` enum in `main.dart`
- **Histogram step auto-selection:** targets ~30 buckets from fixed ladder `[60, 300, 900, 3600, 21600, 86400]` seconds; keeps bucket widths human-readable
- **Facets endpoint:** queries `service_name` and `severity_text` sequentially, LIMIT 20 each; silently returns empty `values` for a field on query error — partial response preferred over 500
- **LogsController:** ChangeNotifier (not Riverpod/Bloc) owning filter, from, to, rows, loading, error; empty filter blocked client-side before any network call
- **TimeRangePicker presets:** computed relative to DateTime.now() at button press; Custom range uses Flutter built-in showDatePicker/showTimePicker
- **Facet panel placeholder:** plain Container with fixed 220px width; no behavior
- **Logs page module:** lib/pages/logs/ with barrel file logs.dart exporting all page symbols
- **`LogRow` attributes field:** stored as a JSON string in ClickHouse; parsed to `serde_json::Value` on read, falls back to `{}` on parse failure
- **FacetPanel:** stateful widget in `lib/pages/logs/facet_panel.dart`; listens to `LogsController`, re-fetches `/v1/logs/facets` on every notify; shows grey shimmer while loading, silent failure on error; tap appends `field:value` token to filter (joined with ` AND ` if non-empty) and syncs `TextEditingController`
- **`appendFilter(String token)`:** method on `LogsController`; sets filter if empty, otherwise appends ` AND token`, then calls `reload()`
- **LogDetailPanel:** 420px fixed-width panel, `AnimatedSize` (width 0 → 420, 200ms easeInOut); shown when `controller.selectedRow != null`; three `ExpansionTile` sections all expanded by default
- **Log row selection:** `LogsController` holds `LogRow? selectedRow`; `selectRow(LogRow)` and `clearSelection()` notify listeners; table rows wrapped in `GestureDetector` with `AppColors.primary.withOpacity(0.08)` highlight
- **Attributes parsing:** `jsonDecode` in try/catch in `_AttributesSection._parseAttributes`; falls back to empty list → "No attributes" label
- **LogHistogram widget:** `CustomPainter`-based bar chart in `lib/pages/logs/log_histogram.dart`; no charting package dependency
- **Histogram collapse state:** stored in `_LogHistogramTileState` (widget-local), not on `LogsController` — display-only
- **Histogram empty state:** renders `SizedBox.shrink()` (nothing) — no placeholder or message when `histogram = []`
- **Histogram loading state:** renders flat grey `Container` (placeholder) while `controller.loading == true`
- **Bar tap:** calls `controller.setRange(bucket.toUtc(), bucket.toUtc().add(step))` where step is inferred from consecutive bucket timestamps
- **`LogsController.reload()`:** sequentially awaits `getLogs` then `getLogsHistogram` with the same filter/from/to parameters
- **`TimeRangeController`:** app-level `ChangeNotifier` in `lib/time_range_controller.dart`; owns `from`, `to`, and `setRange()`; `LogsController` subscribes via `addListener` and calls `reload()` on every range change
- **`TopPanel`:** persistent widget in `lib/widgets/top_panel.dart`; 48px height, white background, `AppColors.border` bottom border; `RiverLogo` then "River" label left-aligned, `TimeRangePicker` right-aligned; composed into `_ShellState` above the sidebar+content row
- **`RiverLogo`:** `CustomPainter`-based widget in `lib/widgets/river_logo.dart`; draws a stylised "R" in white on a rounded `AppColors.primary` square; default size 28px; no external package dependency
- **Window title:** `MaterialApp(title: 'River Dashboard')` — sets the macOS window/taskbar title
- **`LogsController` range ownership removed:** `LogsController` no longer stores `_from`/`_to`; `from`/`to` getters delegate to `rangeController`; `setRange` method removed (use `rangeController.setRange` directly, e.g. from histogram bar tap)
- **`LogColumn` model:** `id`, `label`, `flex`, `visible`, `getValue: LogRow → String`; default columns: Timestamp (flex 3), Severity (flex 1), Service (flex 2), Message (flex 5), TraceID (flex 3, hidden), SpanID (flex 2, hidden)
- **Column/sort state:** `columns`, `sortColumnId`, `sortAsc` on `LogsController` (in-memory only); `toggleColumn(id)` and `setSort(id)` methods; client-side sort applied via `_sortedRows()` on each `rows` getter call
- **`LogsTable` widget:** `lib/pages/logs/logs_table.dart`; header row has `GestureDetector`-wrapped cells with sort arrow; settings icon opens `ColumnMenu` positioned overlay
- **`ColumnMenu`:** `Positioned` overlay inside the table's `Stack`; position computed from settings icon's `RenderBox` local-to-global coords converted to Stack-local; `CheckboxListTile` per column; backdrop `GestureDetector` dismisses on outside tap
- **Cell text:** `softWrap: false`, `overflow: TextOverflow.ellipsis`, `maxLines: 1` on all data cells — clips mid-word at column boundary
- **`GET /v1/traces/{trace_id}`:** path parameter (not query string); returns 404 with `{ "error": "trace not found" }` (not 200 with empty array) when no spans exist for that ID; reuses the existing `Span` struct; row-to-span mapping extracted into a shared `row_to_span` helper to avoid duplication with `query_traces`
- **`TracesController`:** `ChangeNotifier` in `lib/pages/traces/traces_controller.dart`; subscribes to `TimeRangeController`; `from`/`to` delegated to `rangeController`; calls `getTraces(limit: 200)`; no `reload()` in initState (user-triggered or range-change-triggered only)
- **Traces page module:** `lib/pages/traces/` with barrel `traces.dart`; `TracesPage`, `TracesController`, `TracesTable`; registered in `main.dart` as `_Page.traces` with `Icons.account_tree_outlined` sidebar nav item
- **`TracesTable` columns:** Trace ID (flex 3), Root Service (flex 2), Root Operation (flex 3), Duration ms (flex 2), Spans (flex 1), Start Time (flex 3); client-side sort via `TracesController.setSort(columnId)`; root span identified as the span with empty `parentSpanId`
- **Root span heuristic:** `rootSpan(group)` returns the first span where `parentSpanId.isEmpty`; falls back to `spans.first` if none found

## Spec System
`/spec` → spec PR → merge(main) → [GHA: impl branch + draft PR] → `/spec-dev` → impl PR → merge(main)
Path: `/specs/{priority}/{category}/RIVER-{issue_number}-title.md`
Priorities: `must` `should` `could` `wont`
Categories: `bugs` `docs` `features` `refactoring` `tools`
Status tracked in `specs/QUEUE.md` · History in `specs/HISTORY.md`
Queue: flat list; done tasks stay, marked `~~strikethrough~~`
