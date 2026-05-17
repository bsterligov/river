# RIVER-35: UI: Logs Table with Column Management and Sort

Priority: Must
Test Approach: BDD
Why: Operators need to show and hide columns and sort by any field to focus on what matters in an incident without switching tools.
<!-- STOP -->

## Problem

The current logs table has a fixed set of columns with no way to hide irrelevant ones (e.g. TraceID when debugging a service-level issue) or to sort by any field. Operators scroll and scan manually, which wastes time during incidents.

## Goal

An operator sees a logs table where clicking any column header sorts the rows by that field (ascending on first click, descending on second). A settings icon in the header row opens a column menu; checking and unchecking boxes immediately shows or hides the corresponding column from both the header and all data rows.

**Scenarios**

Given the logs table is showing rows,
When the operator clicks the "Severity" column header,
Then the rows sort ascending by severity and an up-arrow icon appears in the header; clicking again reverses to descending.

Given the column menu is open,
When the operator unchecks "TraceID",
Then the TraceID column disappears from the header row and all log rows immediately.

Given TraceID was hidden,
When the operator reopens the column menu and checks "TraceID",
Then the column reappears in its original position.

Given the column menu is open,
When the operator taps outside the menu overlay,
Then the menu dismisses without changing column state.

## Scope

**In**
- `LogColumn` model: `id`, `label`, `flex`, `visible`, `getValue: LogRow -> String`
- Default columns: Timestamp (flex 3), Severity (flex 1), Service (flex 2), Message (flex 5), TraceID (flex 3, hidden by default), SpanID (flex 2, hidden by default)
- `columns`, `sortColumnId`, `sortAsc` stored on `LogsController` (in-memory only, not persisted)
- `LogsTable` widget: header row with `GestureDetector`-wrapped cells, up/down arrow icon on sorted column, settings icon opens `ColumnMenu`
- `ColumnMenu`: `Positioned` overlay with `CheckboxListTile` per column; dismiss on tap outside via `GestureDetector` + `Stack`
- `controller.toggleColumn(id)` method
- Client-side sort applied to `rows` list after each `reload()` response
- Existing `_LogsTable` replaced with `LogsTable`

**Out**
- Persistent column visibility across sessions (`shared_preferences` deferred to post-MVP)
- Drag-to-reorder columns
- Server-side sort
- Pagination

## Decisions

- Column state is in-memory only for the MVP — avoids a `shared_preferences` dependency; revisit before Phase 5 closes if product decides persistence is required (see open question in UNRESOLVED.md).
- Client-side sort keeps the API contract simple; server-side sort would require a new API query parameter and is deferred.
- `ColumnMenu` is a `Positioned` overlay (not a `DropdownButton`) to support `CheckboxListTile` rows and arbitrary tap-outside dismissal.
