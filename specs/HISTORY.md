# HISTORY

Oldest first. Append new entries at the bottom.

---

### 2026-05-06 — RIVER-2: Open questions resolved

Rust river-sidecar confirmed as a permanent river-ingestion component (not a dev scaffold). .NET demo app will emit signals on a continuous background loop.

### 2026-05-07 — RIVER-3: Decisions recorded

Closed both open questions: raw OTLP protobuf as payload; object key includes service name from OTLP resource attributes (`spans/{service_name}/{timestamp}-{uuid}.pb`).

### 2026-05-07 — RIVER-3: Metric aggregation deferred

Metrics should be aggregated before batching to S3 rather than storing raw repeated points. Deferred to a future iteration — captured in Out scope.

### 2026-05-08 — RIVER-1: implementation done

Ingestion service implemented in Rust: S3 poll loop routing OTLP protobuf files by key prefix to VictoriaMetrics (metrics via OTLP HTTP) and ClickHouse (logs/traces via JSONEachRow). ClickHouse and VictoriaMetrics services added to docker-compose.

### 2026-05-08 — RIVER-4: implementation done

GitHub Actions CI workflow added: fmt-check, clippy (-D warnings), and test via mise tasks, followed by SonarQube scan and quality gate. Two pre-existing clippy issues in river-sidecar fixed as part of rollout.

### 2026-05-08 — RIVER-6: spec created

PO spec written for automated release and tagging workflow. Scope limited to tag-push trigger and GitHub release creation; binary asset uploads deferred until CI builds exist.

### 2026-05-08 — RIVER-6: implementation done

Release job added to ci.yml: runs after SonarQube on pushes to main. Uses cocogitto (`cog bump --auto`) for Conventional Commits versioning, `git push` to publish the tag, and `gh release create` for the GitHub release. No-op when no releasable commits are present.

### 2026-05-08 — RIVER-6: implementation done

Release job added to ci.yml: runs after SonarQube on pushes to main, creates a semver tag via Conventional Commits (mathieudutour/github-tag-action), and publishes a GitHub release. No-op if no releasable commits.

### 2026-05-09 — RIVER-10: implementation done

Migration management added to the river-ingestion service: SQL files under `infra/migrations/clickhouse/` are embedded in the binary and applied at startup via a `Migrator` that tracks versions in a `schema_migrations` table. `ensure_tables()` and all inline DDL removed from `clickhouse.rs`.

### 2026-05-09 — RIVER-12: implementation done

Grafana added to docker-compose with anonymous admin access and plugin-based ClickHouse datasource (`grafana-clickhouse-datasource`). VictoriaMetrics and ClickHouse are provisioned as datasources automatically. Two dashboards provisioned as code: APM (traces + logs correlated by service and time) and Metrics (request rate and total for demo-app).

### 2026-05-09 — RIVER-14: implementation done

SDD process updated to a fully branch-based flow: spec authoring and implementation now both go through PRs. QUEUE.md redesigned as a flat persistent list with strikethrough for done items. GHA extended to auto-create an impl branch and draft PR on spec PR merge. spec-dev updated to infer the task from the current branch name.

### 2026-05-10 — RIVER-16: implementation done

Query API implemented as a new `api` Rust binary (`src/river-query-api/`) using axum 0.8 with routes `GET /v1/logs`, `GET /v1/traces`, `GET /v1/metrics`, `GET /health`, and `GET /openapi.json`. A filter DSL parser translates `key:value`, comparison operators, `AND`/`OR`/`NOT`, and wildcards to ClickHouse SQL or VictoriaMetrics label selectors. OpenAPI 3.0 spec is generated from code using `utoipa`. `api` service added to docker-compose, listening on port 8080 via `RIVER_API_PORT`.

### 2026-05-10 — RIVER-16: Swagger UI added

Swagger UI mounted at `GET /swagger-ui/` via `utoipa-swagger-ui 9` (axum 0.8-compatible). The bundled UI fetches the spec from the existing `/openapi.json` endpoint.

### 2026-05-10 — RIVER-19: implementation done

Each crate (`api`, `river-ingestion`, `river-sidecar`) now has a `config.rs` module backed by the `config` crate. All env vars are standardised to the `RIVER_` prefix; `RIVER_CLICKHOUSE_USER` and `RIVER_CLICKHOUSE_PASSWORD` are required and cause an immediate startup failure if absent. docker-compose updated to use the new names.

### 2026-05-10 — RIVER-22: spec created

PO spec written for fixing Grafana trace linking. Root cause is a missing trace configuration in the ClickHouse datasource provisioning YAML; Grafana generates queries against the database name instead of the `traces` table and uses camelCase column names that don't match the schema.

### 2026-05-10 — RIVER-22: implementation done

Added trace configuration to the ClickHouse datasource provisioning YAML: database `river`, table `traces`, and all column mappings (`trace_id`, `span_id`, `parent_span_id`, `service_name`, `operation_name`, `start_time_unix_nano`, `duration_ns`). Grafana can now resolve trace links without SQL errors or configuration warnings.

### 2026-05-11 — RIVER-25: implementation done

Flutter MVP app created at `src/ui/` (macOS-only). Includes a dark sidebar with NavigationRail-style navigation, a Logs page with search bar and stub-data table, a theme module under `lib/theme/`, and a Dart API client generated from the query-api's OpenAPI spec. Four BDD widget tests pass; `flutter analyze` reports zero issues.

### 2026-05-14 — RIVER-28: implementation done

Extended `LogRow` with `severity_number`, `span_id`, and `attributes` (JSON parsed on read). Added `GET /v1/logs/histogram` (configurable time buckets, auto-step targeting ~30 buckets) and `GET /v1/logs/facets` (top-20 values for `service_name` and `severity_text`, silent skip on field error). Dart client regenerated and committed with new `HistogramBucket`, `FacetField`, and `FacetValue` models.

### 2026-05-14 — RIVER-29: implementation done

Restructured the Logs page into `src/ui/lib/pages/logs/`: added `LogsController` (ChangeNotifier owning filter, time range, rows, and error state), `TimeRangePicker` (7 preset buttons + Custom via date/time dialogs), and `LogSearchBar` (inline validation for empty input, shows API 400 errors). Updated `main.dart` to use the new barrel file. Six BDD widget tests cover all four spec scenarios.

### 2026-05-14 — RIVER-30: implementation done

Added `FacetPanel` widget and `appendFilter` to `LogsController`. The panel calls `/v1/logs/facets` on every controller notify, renders one expanded `ExpansionTile` per field with value/count rows, and on tap appends `field:value` to the search bar (joined with ` AND ` when a filter already exists). Grey shimmer shown while loading; silent failure on fetch error. Five BDD widget tests cover all spec scenarios.

### 2026-05-14 — RIVER-37: implementation done

Added `LogDetailPanel` (420px, `AnimatedSize` width transition) with three expanded `ExpansionTile` sections: Log Tags & Infra Info (6 key-value metadata fields), Log Message (`SelectableText` monospace), and Log Attributes (JSON-parsed key-value pairs with "No attributes" fallback). `LogsController` gained `selectedRow`, `selectRow`, and `clearSelection`; table rows wrapped in `GestureDetector` with a highlight on the selected row. Five BDD widget tests pass.

### 2026-05-15 — RIVER-31: implementation done

Added `LogHistogram` widget above the logs table using `CustomPainter` (no charting dependency). `LogsController.reload()` now also fetches `/v1/logs/histogram`; buckets are stored as `List<HistogramBucket>`. Tapping a bar calls `setRange(bucket.time, bucket.time + step)` which re-queries both the table and histogram. The tile collapses/expands locally via `ExpansionTile`. Five BDD widget tests cover all spec scenarios.

### 2026-05-15 — RIVER-35: implementation done

Added `LogColumn` model and column/sort state to `LogsController`. Replaced the fixed `_LogsTable` with a new `LogsTable` widget in `lib/pages/logs/logs_table.dart`: clicking any column header sorts ascending then descending with an arrow indicator; a settings icon opens a `ColumnMenu` positioned overlay with `CheckboxListTile` per column; tapping outside dismisses the menu. TraceID and SpanID are hidden by default. All cell text uses `softWrap: false` with ellipsis clip. Four BDD widget tests cover all spec scenarios.

### 2026-05-15 — RIVER-46: implementation done

Added `flutter-quality` job to both `pull-request.yml` and `release.yml`: runs `mise run flutter:coverage` (new mise task using `flutter test --coverage`), uploads `lcov.info` as an artifact, and is listed as a required dependency of the `sonarqube` job. Updated `sonar-project.properties` to include `src/ui/` in sources, exclude the generated API client and build dirs, and point `sonar.dart.lcov.reportPaths` to the Flutter coverage output.

### 2026-05-15 — RIVER-49: implementation done

Added a persistent `TopPanel` widget (River label left, `TimeRangePicker` right) above the sidebar+content area. Extracted time range state into a new `TimeRangeController` (app-level `ChangeNotifier`); `LogsController` now listens to it instead of owning `from`/`to` directly. The Logs page toolbar retains only the search bar. Two new BDD widget tests verify the top panel layout and range persistence across navigation.

### 2026-05-15 — RIVER-52: implementation done

Added a `RiverLogo` widget (`CustomPainter`-drawn stylised "R" on a rounded primary-colour square) to `lib/widgets/river_logo.dart`; displayed in `TopPanel` left of the "River" label. Changed `MaterialApp(title:)` to "River Dashboard" which sets the macOS window title. No new packages required.

### 2026-05-15 — RIVER-55: implementation done

Added `GET /v1/traces/{trace_id}` to `river-query-api`: returns all spans for a known trace (200) or `{ "error": "trace not found" }` (404) for an unknown one. Refactored span row mapping into a shared `row_to_span` helper, eliminating duplication with `query_traces`. Dart client regenerated; `getTrace(String traceId)` method is present in `lib/api/generated/`.

### 2026-05-15 — RIVER-56: implementation done

Added a Traces page to the River Dashboard: `lib/pages/traces/` module with `TracesController` (ChangeNotifier subscribing to `TimeRangeController`), `TracesTable` (client-side sort on all columns), and `TracesPage` (filter search bar + table). Wired into `main.dart` as a new `_Page.traces` enum value with an "account_tree_outlined" sidebar nav item. Five BDD widget tests cover sidebar navigation, filter submission, time range reload, column sort, and row selection.

### 2026-05-15 — RIVER-59: spec created

PO spec written for the trace waterfall detail panel. Covers `TraceDetailPanel` (420px `AnimatedSize` slide-in matching `LogDetailPanel`), `SpanWaterfallPainter` (`CustomPainter` Gantt rows with proportional bars coloured by `status_code`), span tree building from `parent_span_id`, orphan-span handling, a 200-span cap with visible notice, and wiring into `TracesPage`. Depends on RIVER-55 (single-trace API) and RIVER-56 (trace list page).

### 2026-05-15 — RIVER-67: implementation done

Fixed Traces page blank state (missing `reload()` in `initState`). Extracted duplicate `_extractError` and timestamp formatter into shared utils (`lib/utils/api_error.dart`, `lib/utils/format_time.dart`), eliminating identical code across logs and traces controllers/widgets.

### 2026-05-15 — RIVER-61: spec created

PO spec written for the span attributes panel. BDD approach chosen. Scope covers `selectedSpan` local state on `TraceDetailPanel`, a `SpanAttributesSection` widget with three `ExpansionTile` sections (Attributes, Events, Links), and a clear-selection X button. Attributes parsing reuses the `LogDetailPanel` try/catch pattern. Panel is local widget state only — no controller changes required.

### 2026-05-16 — RIVER-59: implementation done

Added `TraceDetailPanel` (420px `AnimatedSize` slide-in) and `SpanWaterfallPainter` (`CustomPainter` Gantt rows) to `lib/pages/traces/`. The panel fetches spans via `getTrace`, builds a depth-first span tree from `parent_span_id`, renders proportional bars coloured by `status_code`, caps at 200 spans with a visible notice, and wires into `TracesPage` replacing the Phase 2 `SizedBox` placeholder. Thirteen BDD widget tests and unit tests cover all specified scenarios.

### 2026-05-16 — RIVER-70: implementation done

Added `attributes: serde_json::Value` to the `Span` struct, read `SpanAttributes` from ClickHouse in `row_to_span` using the same `parse_attributes` fallback pattern as `LogRow`, and updated both `query_trace` and `query_traces` SQL to select the `attributes` column. Regenerated the Dart API client from the live API server; `Span` now has an `attributes: Object?` field. Four BDD tests added for key-value, empty, malformed, and SQL column scenarios.

### 2026-05-16 — RIVER-61: implementation done

Added an "Attributes" `ExpansionTile` to `SpanAttributesSection` that parses `span.attributes` as JSON key-value pairs (same try/catch fallback as `LogDetailPanel`), and added a `_SpanAttrHeader` with an X button (`span_attrs_close` key) that calls `onClear` to dismiss the section. Five new BDD tests cover valid JSON attributes, null attributes, non-JSON fallback, and the close button both standalone and integrated in the full panel.
