# RIVER-29: UI: Page Layout + Time Range Selector + Search Bar
Status: In Progress
Priority: Must
Test Approach: BDD
Why: Operators have no way to scope log queries by time or filter expression without leaving the app — the current Logs page loads everything with no controls.
<!-- STOP -->

## Problem

The existing Logs page is a single-widget dump with no toolbar, no time range control, and no search input. Operators who need to investigate an incident must use external tools (curl, Swagger UI) to issue filtered queries. There is no layout scaffolding to add richer controls (facets, histogram) in future phases.

## Goal

An operator opens the Logs page and sees a toolbar at the top with preset time range buttons (15m, 1h, 6h, 24h, 3d, 7d) and a search bar. Selecting a preset or submitting a filter expression causes the table below to refresh with results from `/v1/logs` scoped to that range and filter. A fixed-width panel placeholder sits to the left of the table, ready for facets in a later phase.

**Scenarios**

Given the Logs page is open with the default time range,
When the operator clicks "Last 1h",
Then the table reloads with rows from the last hour and no other time range button appears active.

Given the Logs page is open,
When the operator types a valid filter expression in the search bar and presses Enter,
Then `LogsController` issues a new `/v1/logs` request with `filter=<expression>` and the table updates.

Given the operator submits an empty search bar,
When the submit fires,
Then no API call is made and the search bar shows an inline validation message.

Given the API returns HTTP 400 for the submitted filter,
When the response arrives,
Then an inline error row appears below the search bar with the server's error message.

## Scope

**In**
- `lib/pages/logs/` directory; `logs_page.dart` moved there; barrel file (`logs.dart`) exporting all page symbols
- `LogsController` (`ChangeNotifier`): owns `filter`, `from`, `to`, `rows`, `loading`, `error`; exposes `setFilter`, `setRange`, `reload`; calls API on any state change
- `TimeRangePicker` widget: preset buttons (Last 15m, 1h, 6h, 24h, 3d, 7d) + Custom option (date/time dialogs); emits `(DateTime, DateTime)` via callback
- `LogSearchBar` widget: monospace `TextField` with DSL hint; validates non-empty on submit; shows inline error on API 400
- `LogsPage` layout: toolbar row (TimeRangePicker left, LogSearchBar expanded right); below it a row with 220px-wide facet placeholder and expanded main area; wired to `LogsController` via `ListenableBuilder`
- `apiClient` threaded from `main.dart` into `LogsController`
- All existing widget tests continue to pass (`mise exec -- flutter test`)

**Out**
- Actual facet panel content (placeholder only in this phase)
- Distribution histogram
- Column visibility management
- Log detail panel
- Persistence of selected time range or filter across sessions

## Decisions

- `LogsController` is a `ChangeNotifier` (not Riverpod or Bloc) — consistent with the existing Flutter MVP pattern and avoids new state-management dependencies at this stage.
- Preset time ranges are computed relative to `DateTime.now()` at the moment the button is pressed, not at page load.
- "Custom" range uses Flutter's built-in `showDatePicker` / `showTimePicker` — no third-party date picker.
- Empty filter string is caught client-side before any network call; 400 errors are caught after.
- The facet panel placeholder is a plain `Container` with fixed 220px width — no behavior, no styling beyond width constraint.
