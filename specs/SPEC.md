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

## Spec System
`/po-spec-writer` → spec PR → merge(main) → [GHA: impl branch + draft PR] → `/dev-spec` → impl PR → merge(main)
Path: `/specs/{priority}/{category}/RIVER-{issue_number}-title.md`
Priorities: `must` `should` `could` `wont`
Categories: `bugs` `docs` `features` `refactoring` `tools`
Status tracked in `specs/QUEUE.md` · History in `specs/HISTORY.md`
Queue: flat list; done tasks stay, marked `~~strikethrough~~`
