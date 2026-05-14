# DRAFT -- Issue #29
# Run `/po-spec-writer` on this branch to generate the full spec.

Issue:    #29
Task:     RIVER-29
Title:    UI: Page Layout + Time Range Selector + Search Bar
Why:
The Logs page has a structured layout (toolbar on top, facet panel + main area below) with a working time range picker and a search bar that both drive queries to `/v1/logs`.

Steps:
1. Create `lib/pages/logs/` directory; move `logs_page.dart` there and split it into a barrel file.
2. Create `LogsController` (a `ChangeNotifier`) in `logs_controller.dart`. It owns: `String filter`, `DateTime from`, `DateTime to`, `List<LogRow> rows`, `bool loading`, `String? error`. Exposes `setFilter`, `setRange`, `reload`. Calls the API on any state change.
3. Build `TimeRangePicker` widget (`time_range_picker.dart`). Preset buttons: Last 15m, 1h, 6h, 24h, 3d, 7d. A "Custom" option opens two `showDatePicker`/`showTimePicker` dialogs for from/to. Emits `(DateTime, DateTime)` via callback. Sits in the top-left of the toolbar.
4. Build `LogSearchBar` widget (`log_search_bar.dart`). A `TextField` with monospace styling and DSL hint text. On submit, validates that the value is non-empty before calling controller; shows an inline error row if the API returns 400.
5. Restructure `LogsPage.build`: top `Row` toolbar (TimeRangePicker left, LogSearchBar expanded right), below it a `Row` with facet panel placeholder (fixed 220px wide `Container`) and expanded main area. Wire toolbar widgets to `LogsController` via `ListenableBuilder`.
6. Wire `LogsController` into the page; pass `apiClient` down from `main.dart`.
7. Run `mise exec -- flutter test` — existing widget tests must pass.

Done when: Changing the time range or submitting a new filter issues a new `/v1/logs` call and the table updates; the layout matches the described structure.

Part of feature plan: logs-ui-full-page
Why: Replace the minimal logs page with a full observability UI — time range selector, Kibana-style search, auto-facets, distribution histogram, column-managed table, and a log detail panel — so operators can explore logs without leaving the app.
Priority: must
Category: features
