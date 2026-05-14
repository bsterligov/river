# RIVER-37: UI: Log Detail Panel
Status: In Progress
Priority: Must
Test Approach: BDD
Why: Operators need to inspect the full context of a log row — tags, message, and structured attributes — without leaving the table view.
<!-- STOP -->

## Problem

Clicking a log row today does nothing. Operators who need the full `attributes` payload or want to copy a `trace_id` must use external tools (curl, Kibana, raw ClickHouse). There is no in-app detail view.

## Goal

An operator clicks any row in the logs table and a 420px-wide panel slides in on the right, showing three collapsible sections: Log Tags & Infra Info (key-value metadata), Log Message (selectable monospace body), and Log Attributes (structured key-value pairs from the `attributes` JSON field). Clicking X or a different row updates or closes the panel.

**Scenarios**

Given a log row is visible in the table,
When the operator clicks it,
Then the detail panel slides in on the right, the clicked row is highlighted, and all three sections render with data from that row.

Given the detail panel is open,
When the operator clicks a different row,
Then the panel updates to show the newly selected row's data.

Given the detail panel is open,
When the operator clicks the X button,
Then the panel closes and no row remains highlighted.

Given a row has a valid JSON object in the `attributes` field,
When the Log Attributes section renders,
Then each key-value pair is shown as a row with the key in label style and the value in monospace.

Given a row has an empty or non-object `attributes` value,
When the Log Attributes section renders,
Then the section shows "No attributes".

## Scope

**In**
- `LogRow? selectedRow` on `LogsController`; `selectRow(LogRow)` and `clearSelection()` methods
- `LogDetailPanel` widget (`log_detail_panel.dart`), fixed width 420px
- X close button calls `controller.clearSelection()`
- Three `ExpansionTile` sections, all expanded by default:
  - Log Tags & Infra Info: key-value rows for `timestamp`, `service_name`, `severity_text`, `severity_number`, `trace_id`, `span_id`
  - Log Message: `SelectableText` of `body`, monospace styling, wrapped
  - Log Attributes: `jsonDecode` inside try/catch; renders key-value rows if result is a JSON object; falls back to "No attributes"
- `AnimatedSize` (width animates 0 → 420) wrapping the panel; shown only when `selectedRow != null`
- `LogsTable` rows wrapped in `GestureDetector` calling `controller.selectRow(row)`; selected row has a background highlight

**Out**
- Copying individual attribute values to clipboard
- Expanding nested JSON objects in the attributes section
- Pinned rows or multi-row comparison

## Decisions

- `attributes` parsing uses `jsonDecode` in a try/catch with a "No attributes" fallback — malformed JSON from ClickHouse must not crash the panel.
- `AnimatedSize` for the width transition avoids a third-party animation package; if the animation proves janky, it can be replaced with a plain `if` toggle without a spec change.
- The panel is a fixed 420px rather than resizable — keeps layout math simple for the MVP; resizable panels are deferred.
