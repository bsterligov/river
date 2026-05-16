# DRAFT -- Issue #76
# Run `/spec` on this branch to generate the full spec.

Issue:    #76
Task:     RIVER-76
Title:    Unify traces table with logs table: shared columns, column menu, mono Trace ID, Start Time first
Why:
The TracesTable uses a fixed hardcoded layout while LogsTable uses the LogColumn/column_layout infrastructure with content-width measurement, show/hide menu, and sort arrows. They should share the same approach.

Acceptance criteria:
- Columns reordered: Start Time, Trace ID, Root Service, Root Operation, Duration ms, Spans
- Trace ID cell rendered in mono font (matching Logs table ID columns)
- Column show/hide menu (settings icon, same ColumnMenu as LogsTable)
- TracesController gains a `columns` list and `toggleColumn(id)` matching LogsController
- TracesTable uses computeColumnWidths from column_layout.dart
- All existing sort behaviour preserved
Priority: could
Category: refactoring
