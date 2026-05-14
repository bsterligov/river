# DRAFT -- Issue #37
# Run `/po-spec-writer` on this branch to generate the full spec.

Issue:    #37
Task:     RIVER-37
Title:    UI: Log Detail Panel
Why:
Clicking a log row slides in a right-side detail panel with three collapsible sections: Log Tags & Infra Info, Log Message, Log Attributes.

Steps:
1. Add `LogRow? selectedRow` to `LogsController`. `selectRow(LogRow row)` and `clearSelection()` methods.
2. Build `LogDetailPanel` widget (`log_detail_panel.dart`). Fixed width 420px. An `X` close button calls `controller.clearSelection()`. Three `ExpansionTile` sections (all expanded by default):
   - Log Tags & Infra Info: key-value rows for `timestamp`, `service_name`, `severity_text`, `severity_number`, `trace_id`, `span_id`.
   - Log Message: `SelectableText` of `body` with monospace styling, wrapped.
   - Log Attributes: parse `attributes` JSON; if it is a JSON object, render each key-value pair as a row (key in label style, value in mono). If empty or not an object, show "No attributes".
3. Wrap the main area (histogram + table) and `LogDetailPanel` in a `Row`. Show `LogDetailPanel` only when `selectedRow != null`; use `AnimatedSize` to slide it in (width animates 0 → 420).
4. In `LogsTable`, make each row a `GestureDetector` that calls `controller.selectRow(row)`. Highlight the selected row with a background color.

Done when: Clicking a row opens the right panel; all three sections render correct data from the row; clicking X or another row updates or closes the panel.

Part of feature plan: logs-ui-full-page
Why: Replace the minimal logs page with a full observability UI — time range selector, Kibana-style search, auto-facets, distribution histogram, column-managed table, and a log detail panel — so operators can explore logs without leaving the app.
Priority: must
Category: features
