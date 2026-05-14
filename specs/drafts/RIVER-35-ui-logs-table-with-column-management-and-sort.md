# DRAFT -- Issue #35
# Run `/po-spec-writer` on this branch to generate the full spec.

Issue:    #35
Task:     RIVER-35
Title:    UI: Logs Table with Column Management and Sort
Why:
The logs table supports show/hide columns and client-side sort by any column header click.

Steps:
1. Define `LogColumn` model: `{id: String, label: String, flex: int, visible: bool, getValue: LogRow -> String}`. Default columns: Timestamp (flex 3), Severity (flex 1), Service (flex 2), Message (flex 5), TraceID (flex 3, hidden by default), SpanID (flex 2, hidden by default).
2. Store `List<LogColumn> columns` and `String? sortColumnId` + `bool sortAsc` in `LogsController` (in-memory only; not persisted).
3. Build `LogsTable` widget. Header row: each visible column renders a `GestureDetector`-wrapped header cell; tap sets sort column + toggles direction on the controller; an up/down arrow icon shows current sort. A settings icon at the header right opens a `ColumnMenu`.
4. `ColumnMenu`: a `Positioned` overlay with a `CheckboxListTile` per column. Toggling calls `controller.toggleColumn(id)`. Dismiss on tap outside.
5. Sort rows in `LogsController.reload()` after receiving the API response (client-side, applied to the `rows` list).
6. Replace the existing `_LogsTable` with `LogsTable`.

Done when: Clicking a column header sorts the table; unchecking a column in the menu hides it from the header and rows; toggling back restores it.

Part of feature plan: logs-ui-full-page
Why: Replace the minimal logs page with a full observability UI — time range selector, Kibana-style search, auto-facets, distribution histogram, column-managed table, and a log detail panel — so operators can explore logs without leaving the app.
Priority: must
Category: features
