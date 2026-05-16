# RIVER-76: Unify traces table with logs table
Status: In Progress
Priority: Could
Test Approach: BDD
Why: The traces table is a hardcoded second-class citizen while the logs table has content-aware column widths, show/hide, and a consistent sort UX — operators get a worse experience on the Traces page for no reason.
<!-- STOP -->

## Problem

`TracesTable` uses fixed flex ratios, no column menu, and renders every cell in the same mono style regardless of content type. `LogsTable` already has `LogColumn`/`computeColumnWidths` infrastructure with content-width measurement, a settings icon that opens a show/hide `ColumnMenu`, and sort arrows. The two tables feel like different products. Start Time is buried last in traces when it should lead (matching logs), and Trace ID has no visual distinction despite being an identifier.

## Goal

An operator opening the Traces page sees a table that behaves identically to the Logs table: columns sized to content, a settings icon to toggle visibility, sort arrows on every header, Trace ID in mono, and Start Time in the first position.

**Given** the Traces page is open with results,
**When** the operator looks at the table header,
**Then** columns appear left-to-right: Start Time, Trace ID, Root Service, Root Operation, Duration ms, Spans.

**Given** the table has loaded,
**When** the operator reads a Trace ID cell,
**Then** it is rendered in `AppText.mono` (same style as log timestamp/ID columns).

**Given** the table is visible,
**When** the operator clicks the settings icon,
**Then** a `ColumnMenu` overlay appears with one checkbox per column; toggling a checkbox hides or shows that column immediately.

**Given** a column is hidden via the menu,
**When** the operator reopens the menu,
**Then** the checkbox for that column is unchecked and the column is absent from the header and all rows.

**Given** the operator clicks a column header,
**When** the sort arrow appears,
**Then** no extra network request is made (client-side sort only, matching logs behaviour).

## Scope

**In**
- Add `TraceColumn` model mirroring `LogColumn` (`id`, `label`, `visible`, `getValue: TraceGroup → String`); add `columns`, `sortColumnId`, `sortAsc`, `toggleColumn(id)`, `setSort(id)` to `TracesController`
- Default columns (all visible): Start Time, Trace ID, Root Service, Root Operation, Duration ms, Spans
- `TracesTable` rewritten to use `computeColumnWidths` from `column_layout.dart`
- Trace ID column uses `AppText.mono`; all other cells keep `AppText.mono` (unchanged)
- Settings icon + `ColumnMenu` overlay (same widget as `LogsTable._ColumnMenu`, extracted to shared location or duplicated — see Decisions)
- Sort arrows in header matching `LogsTable` pattern
- BDD widget tests for all five scenarios above

**Out**
- Hidden-column persistence across sessions
- Column reordering by drag
- Any changes to `LogsTable` or `LogsController`
- Any changes to the API or `TracesController.reload()`

## Decisions

- `TraceColumn` is a new type parallel to `LogColumn` rather than a generic; `LogColumn` is tightly coupled to `LogRow` via its `getValue` closure and making it generic adds complexity for little gain
- `_ColumnMenu` in `logs_table.dart` is currently private; extract it to `lib/pages/shared/column_menu.dart` so both tables can import it without duplication
- `column_layout.dart` is already importable from `lib/pages/logs/` — `TracesTable` will import it directly (cross-page import within lib is acceptable; no move needed)
