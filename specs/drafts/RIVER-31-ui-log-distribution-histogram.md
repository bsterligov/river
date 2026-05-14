# DRAFT -- Issue #31
# Run `/po-spec-writer` on this branch to generate the full spec.

Issue:    #31
Task:     RIVER-31
Title:    UI: Log Distribution Histogram
Why:
A collapsible time-distribution bar chart sits above the logs table. It calls `/v1/logs/histogram` and renders bucket counts as bars. Clicking a bar narrows the time range to that bucket's interval.

Steps:
1. Add `query_logs_histogram` call to `LogsController.reload()`; store `List<HistogramBucket> histogram` on the controller.
2. Build `LogHistogram` widget (`log_histogram.dart`) using `CustomPainter` (no new package dependency). Draw a horizontal row of filled rectangles scaled to max count; label the x-axis with abbreviated bucket times. Height: 80px.
3. Wrap `LogHistogram` in an `ExpansionTile` (label "Log distribution", starts expanded). Store collapsed state in the widget (not the controller — it's display-only).
4. On bar tap: compute `from = bucket.time`, `to = bucket.time + step`; call `controller.setRange(from, to)`.
5. Show a flat grey bar row while loading; show nothing when histogram is empty.
6. Place `LogHistogram` as the first item in the main area column, above the logs table.

Done when: The histogram renders bars matching the fetched log counts; tapping a bar updates the time range picker and re-issues all queries; the tile collapses and re-expands cleanly.

Part of feature plan: logs-ui-full-page
Why: Replace the minimal logs page with a full observability UI — time range selector, Kibana-style search, auto-facets, distribution histogram, column-managed table, and a log detail panel — so operators can explore logs without leaving the app.
Priority: must
Category: features
