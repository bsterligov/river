# RIVER-56: Trace list page (Flutter)

Priority: Must
Test Approach: BDD
Why: Users have no first-class UI to search and visualize distributed traces, even though trace data is fully ingested and queryable via the existing API.
<!-- STOP -->

## Problem

Trace data is ingested into ClickHouse and queryable via the API, but the UI has no Traces page. Users must rely on Grafana or raw API calls to inspect distributed traces, which breaks the workflow for anyone who wants to correlate a log entry with its trace without leaving the River Dashboard.

## Goal

A "Traces" entry appears in the sidebar. Clicking it opens a page with a filter search bar and a table of trace groups. Changing the filter or the time range refreshes the table automatically. Each row represents one trace, identified by its `trace_id`, with key summary columns. Clicking a row selects it (detail panel will be wired in a later phase).

**Scenarios**

Given the user opens the River Dashboard,
When they click "Traces" in the sidebar,
Then the Traces page is shown with an empty or populated table depending on the selected time range.

Given the Traces page is open,
When the user types a filter expression and submits,
Then `TracesController.reload()` is called with the new filter and the table updates to show matching trace groups.

Given the Traces page is open,
When the user changes the time range via `TimeRangePicker`,
Then `TracesController` receives the range-change notification and calls `reload()` automatically.

Given the table has rows,
When the user clicks a column header,
Then the table re-sorts client-side by that column (ascending on first click, descending on second) without a network request.

Given the table has rows,
When the user taps a row,
Then `TracesController.selectTrace(traceId)` is called and the row is highlighted; tapping elsewhere calls `clearSelection()`.

## Scope

**In**
- `src/ui/lib/pages/traces/` module with barrel `traces.dart` exporting all page symbols
- `TracesController` (`ChangeNotifier`) in `traces_controller.dart`:
  - Fields: `filter` (String), `rows` (`List<TraceGroup>`), `loading` (bool), `error` (String?), `selectedTraceId` (String?)
  - Subscribes to `TimeRangeController` via `addListener`; calls `reload()` on range change
  - `reload()` calls `getTraces(filter, from, to, limit: 200)` where `from`/`to` are read from `TimeRangeController`
  - `selectTrace(String traceId)` and `clearSelection()` notify listeners
- `TracesTable` widget in `traces_table.dart`:
  - Columns: Trace ID (flex 3), Root Service (flex 2), Root Operation (flex 3), Duration ms (flex 2), Span Count (flex 1), Start Time (flex 3)
  - Client-side sort on any column header (same pattern as `LogsTable`)
  - Row tap calls `controller.selectTrace`
- `TracesPage` in `traces_page.dart`:
  - Filter `SearchBar` (same pattern as `LogSearchBar`)
  - `TracesTable`
  - Placeholder `SizedBox` where the detail panel will be wired in Phase 3
- `TracesPage` registered in `main.dart` `_Page` enum and sidebar
- `TracesController` provided above `TracesPage` (same pattern as `LogsController`)

**Out**
- Trace detail panel (Phase 3)
- Server-side sort
- Column visibility toggle
- Persistent filter or sort state across sessions

## Decisions

- `TracesController` follows the `LogsController` pattern exactly — `ChangeNotifier`, no Riverpod/Bloc — to stay consistent with existing architecture.
- `from`/`to` are read from `TimeRangeController` (not stored on `TracesController`) to match the decision made for `LogsController` in RIVER-49.
- Client-side sort keeps the API contract unchanged; server-side sort deferred.
- The detail panel slot is a `SizedBox` placeholder so Phase 3 can wire it without restructuring the page layout.
- `limit: 200` caps the initial fetch; pagination is out of scope for the MVP.
