# Plan: Logs UI Full Page
Date: 2026-05-14
Why: Replace the minimal logs page with a full observability UI — time range selector, Kibana-style search, auto-facets, distribution histogram, column-managed table, and a log detail panel — so operators can explore logs without leaving the app.

## Phases

### Phase 1 — API: Histogram & Facets + Extend LogRow

**Goal:** The query API exposes two new endpoints (`/v1/logs/histogram`, `/v1/logs/facets`) and `LogRow` carries all fields needed for the detail panel. The Dart client is regenerated and committed.

**Steps:**
1. Extend `LogRow` in `clickhouse.rs` to add `severity_number: i64`, `span_id: String`, `attributes: serde_json::Value` (parse the JSON string on read; emit `{}` on failure).
2. Update `query_logs` SELECT to include `severity_number`, `span_id`, `attributes`; map them into the extended `LogRow`.
3. Add `HistogramBucket { bucket: String, count: u64 }` schema struct (derive `ToSchema`, `Serialize`).
4. Add `query_logs_histogram(filter, from, to, step_secs: u64) -> Result<Vec<HistogramBucket>>` to `clickhouse::Reader`. SQL: `SELECT toStartOfInterval(timestamp, INTERVAL {step_secs} SECOND) AS bucket, count() AS count FROM logs{where_clause} GROUP BY bucket ORDER BY bucket FORMAT JSONEachRow`. Auto-select `step_secs` from the range duration if not supplied (target ~30 buckets; use the nearest value from [60, 300, 900, 3600, 21600, 86400]).
5. Add `GET /v1/logs/histogram` handler in `main.rs` with params `filter`, `from`, `to`, `step` (e.g. `60s`, `5m`). Parse the step string to seconds; default to auto.
6. Add `FacetValue { value: String, count: u64 }` and `FacetField { field: String, values: Vec<FacetValue> }` structs.
7. Add `query_logs_facets(filter, from, to) -> Result<Vec<FacetField>>` to `clickhouse::Reader`. For each faceted column (`service_name`, `severity_text`): `SELECT {col} AS value, count() AS count FROM logs{where_clause} GROUP BY value ORDER BY count DESC LIMIT 20 FORMAT JSONEachRow`. Run both queries sequentially; return a `FacetField` per column. Skip a field if the query errors (return empty values).
8. Add `GET /v1/logs/facets` handler.
9. Register both routes and new schema types in `ApiDoc` (the `#[derive(OpenApi)]` block).
10. Run `mise exec -- cargo test` — all existing tests must pass; add one new unit test per handler (mock ClickHouse, assert 200 + shape).
11. Start the API locally (`mise exec -- cargo run -p river-query-api`), fetch `/openapi.json`, run `openapi-generator` to regenerate the Dart client into `src/ui/lib/api/generated/`, commit the result.

**Dependencies:** None.
**Done when:** `GET /v1/logs/histogram` and `GET /v1/logs/facets` return 200 with correct JSON; `GET /v1/logs` response includes `severity_number`, `span_id`, `attributes`; `mise exec -- cargo test` is green; Dart client is committed.

---

### Phase 2 — UI: Page Layout + Time Range Selector + Search Bar

**Goal:** The Logs page has a structured layout (toolbar on top, facet panel + main area below) with a working time range picker and a search bar that both drive queries to `/v1/logs`.

**Steps:**
1. Create `lib/pages/logs/` directory; move `logs_page.dart` there and split it into a barrel file.
2. Create `LogsController` (a `ChangeNotifier`) in `logs_controller.dart`. It owns: `String filter`, `DateTime from`, `DateTime to`, `List<LogRow> rows`, `bool loading`, `String? error`. Exposes `setFilter`, `setRange`, `reload`. Calls the API on any state change.
3. Build `TimeRangePicker` widget (`time_range_picker.dart`). Preset buttons: Last 15m, 1h, 6h, 24h, 3d, 7d. A "Custom" option opens two `showDatePicker`/`showTimePicker` dialogs for from/to. Emits `(DateTime, DateTime)` via callback. Sits in the top-left of the toolbar.
4. Build `LogSearchBar` widget (`log_search_bar.dart`). A `TextField` with monospace styling and DSL hint text. On submit, validates that the value is non-empty before calling controller; shows an inline error row if the API returns 400.
5. Restructure `LogsPage.build`: top `Row` toolbar (TimeRangePicker left, LogSearchBar expanded right), below it a `Row` with facet panel placeholder (fixed 220px wide `Container`) and expanded main area. Wire toolbar widgets to `LogsController` via `ListenableBuilder`.
6. Wire `LogsController` into the page; pass `apiClient` down from `main.dart`.
7. Run `mise exec -- flutter test` — existing widget tests must pass.

**Dependencies:** Phase 1 (Dart client must expose `from`/`to` params on `getLogs`).
**Done when:** Changing the time range or submitting a new filter issues a new `/v1/logs` call and the table updates; the layout matches the described structure.

---

### Phase 3 — UI: Facet Panel

**Goal:** The left facet panel auto-populates from `/v1/logs/facets`, and clicking a value appends a filter token to the search bar and re-runs the query.

**Steps:**
1. Create `FacetPanel` widget (`facet_panel.dart`). Takes `LogsController` as input. On build, calls `apiClient.getLogsFacets(filter, from, to)`. Renders one `ExpansionTile` per `FacetField` (expanded by default). Each `FacetValue` row shows value + count chip; tapping it calls `controller.appendFilter('field:value')`.
2. Add `appendFilter(String token)` to `LogsController`: if the current filter is empty, set it to `token`; otherwise append ` AND token`. Then call `reload()`.
3. Replace the facet placeholder in `LogsPage` with the real `FacetPanel`.
4. Show a loading shimmer (a `Container` with grey color) while facets load; show nothing on error (fail silently, since facets are additive UI).
5. Re-fetch facets whenever `LogsController` notifies (time range or filter changed).

**Dependencies:** Phase 2 (LogsController exists).
**Done when:** Opening the logs page shows facet groups for `service_name` and `severity_text`; clicking a facet value updates the search bar and refreshes the table.

---

### Phase 4 — UI: Log Distribution Histogram

**Goal:** A collapsible time-distribution bar chart sits above the logs table. It calls `/v1/logs/histogram` and renders bucket counts as bars. Clicking a bar narrows the time range to that bucket's interval.

**Steps:**
1. Add `query_logs_histogram` call to `LogsController.reload()`; store `List<HistogramBucket> histogram` on the controller.
2. Build `LogHistogram` widget (`log_histogram.dart`) using `CustomPainter` (no new package dependency). Draw a horizontal row of filled rectangles scaled to max count; label the x-axis with abbreviated bucket times. Height: 80px.
3. Wrap `LogHistogram` in an `ExpansionTile` (label "Log distribution", starts expanded). Store collapsed state in the widget (not the controller — it's display-only).
4. On bar tap: compute `from = bucket.time`, `to = bucket.time + step`; call `controller.setRange(from, to)`.
5. Show a flat grey bar row while loading; show nothing when histogram is empty.
6. Place `LogHistogram` as the first item in the main area column, above the logs table.

**Dependencies:** Phase 2 (LogsController).
**Done when:** The histogram renders bars matching the fetched log counts; tapping a bar updates the time range picker and re-issues all queries; the tile collapses and re-expands cleanly.

---

### Phase 5 — UI: Logs Table with Column Management and Sort

**Goal:** The logs table supports show/hide columns and client-side sort by any column header click.

**Steps:**
1. Define `LogColumn` model: `{id: String, label: String, flex: int, visible: bool, getValue: LogRow -> String}`. Default columns: Timestamp (flex 3), Severity (flex 1), Service (flex 2), Message (flex 5), TraceID (flex 3, hidden by default), SpanID (flex 2, hidden by default).
2. Store `List<LogColumn> columns` and `String? sortColumnId` + `bool sortAsc` in `LogsController` (in-memory only; not persisted).
3. Build `LogsTable` widget. Header row: each visible column renders a `GestureDetector`-wrapped header cell; tap sets sort column + toggles direction on the controller; an up/down arrow icon shows current sort. A settings icon at the header right opens a `ColumnMenu`.
4. `ColumnMenu`: a `Positioned` overlay with a `CheckboxListTile` per column. Toggling calls `controller.toggleColumn(id)`. Dismiss on tap outside.
5. Sort rows in `LogsController.reload()` after receiving the API response (client-side, applied to the `rows` list).
6. Replace the existing `_LogsTable` with `LogsTable`.

**Dependencies:** Phase 2 (LogsController).
**Done when:** Clicking a column header sorts the table; unchecking a column in the menu hides it from the header and rows; toggling back restores it.

---

### Phase 6 — UI: Log Detail Panel

**Goal:** Clicking a log row slides in a right-side detail panel with three collapsible sections: Log Tags & Infra Info, Log Message, Log Attributes.

**Steps:**
1. Add `LogRow? selectedRow` to `LogsController`. `selectRow(LogRow row)` and `clearSelection()` methods.
2. Build `LogDetailPanel` widget (`log_detail_panel.dart`). Fixed width 420px. An `X` close button calls `controller.clearSelection()`. Three `ExpansionTile` sections (all expanded by default):
   - **Log Tags & Infra Info**: key-value rows for `timestamp`, `service_name`, `severity_text`, `severity_number`, `trace_id`, `span_id`.
   - **Log Message**: `SelectableText` of `body` with monospace styling, wrapped.
   - **Log Attributes**: parse `attributes` JSON; if it is a JSON object, render each key-value pair as a row (key in label style, value in mono). If empty or not an object, show "No attributes".
3. Wrap the main area (histogram + table) and `LogDetailPanel` in a `Row`. Show `LogDetailPanel` only when `selectedRow != null`; use `AnimatedSize` to slide it in (width animates 0 → 420).
4. In `LogsTable`, make each row a `GestureDetector` that calls `controller.selectRow(row)`. Highlight the selected row with a background color.

**Dependencies:** Phase 5 (LogsTable exists and rows are rendered).
**Done when:** Clicking a row opens the right panel; all three sections render correct data from the row; clicking X or another row updates or closes the panel.

---

## Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Faceting over JSON `attributes` string is expensive at scale | `/v1/logs/facets` slow or times out on large data sets | Phase 1 limits facets to top-level scalar columns only; attribute-key facets are deferred. Add a `LIMIT` on the query and a server-side timeout. |
| No charting package; `CustomPainter` histogram is brittle | Histogram looks poor or has hit-test bugs | Keep the painter simple (filled rects, no animations). If it proves painful, add `fl_chart` as a dependency in a follow-on. |
| Dart client regeneration requires a running API | Blocks developers who can't spin up the stack | Commit the generated client alongside API changes. Add a note to SPEC.md. |
| `attributes` JSON from ClickHouse may be malformed | Detail panel crashes on bad data | Parse with `jsonDecode` inside a try/catch; display raw string as fallback. |
| Histogram step auto-selection produces confusing bucket widths | Chart is hard to read | Restrict auto-step to the fixed ladder [60s, 5m, 15m, 1h, 6h, 1d]; label each bucket with its actual interval size. |

## Open Questions

- [ ] Should facets eventually cover attribute keys extracted from the `attributes` JSON? — product owner decision before Phase 1 is closed
- [ ] Should column visibility/sort state be persisted across sessions (using `shared_preferences`) or is in-memory acceptable for the MVP? — decision before Phase 5 begins
- [ ] Is 1000 rows (current API cap) sufficient for the table, or do we need cursor/offset pagination? — decide before Phase 5; pagination would require an API change
