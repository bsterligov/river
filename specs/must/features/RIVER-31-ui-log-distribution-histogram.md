# RIVER-31: UI: Log Distribution Histogram

Priority: Must
Test Approach: BDD
Why: Operators need a fast visual read of log volume over time to spot spikes and anomalies without writing queries.
<!-- STOP -->

## Problem

The current logs page shows a flat table with no temporal context. Operators cannot tell at a glance whether a spike happened 10 minutes ago or 2 hours ago. Navigating by scrolling or adjusting filters manually is slow and error-prone when investigating incidents.

## Goal

An operator opens the Logs page and sees a bar chart above the table showing log counts across time buckets. Tapping a bar zooms the view into that bucket's time window — the time range picker updates and all queries re-run automatically. The chart can be collapsed to reclaim vertical space.

**Scenarios**

Given the histogram loads successfully,
When the operator views the Logs page,
Then a row of bars is rendered above the table, each bar height proportional to its bucket's log count.

Given the histogram is loading,
When data has not yet arrived,
Then a flat grey placeholder row is shown in place of the bars.

Given the histogram response is empty,
When there are no log counts to display,
Then the histogram widget renders nothing (no placeholder, no empty state message).

Given the operator sees the histogram,
When they tap a bar,
Then `from` and `to` are set to that bucket's interval, the time range picker reflects the new range, and the logs table re-queries.

Given the histogram is expanded,
When the operator taps the "Log distribution" tile header,
Then the chart collapses; tapping again re-expands it.

## Scope

**In**
- `LogHistogram` widget (`log_histogram.dart`) using `CustomPainter`; no new package dependencies
- `ExpansionTile` wrapper labelled "Log distribution", expanded by default; collapsed state is local widget state (not on the controller)
- `LogsController.reload()` calls `/v1/logs/histogram`; result stored as `List<HistogramBucket> histogram`
- Bar tap sets `from = bucket.time`, `to = bucket.time + step` via `controller.setRange(from, to)`
- Loading state renders a flat grey bar row; empty histogram renders nothing
- Widget placed as first item in the main column, above the logs table
- x-axis labels with abbreviated bucket times; total widget height 80px

**Out**
- Tooltip or hover detail on bars
- Animated transitions on collapse/expand or data refresh
- Any change to the time range picker widget beyond receiving updated values from controller
- Backend `/v1/logs/histogram` endpoint (assumed already complete per Phase 1)

## Decisions

- `CustomPainter` is used instead of a charting package (`fl_chart`) to avoid adding a dependency; if the painter proves too complex or brittle, `fl_chart` can be added in a follow-on without a spec change.
- Collapsed state is stored in the widget, not the controller — it is display-only and has no effect on query results.
- Empty histogram renders nothing rather than a placeholder because an empty range is a valid state (no logs in period) and an empty chart is less confusing than a "no data" message competing with the table.
