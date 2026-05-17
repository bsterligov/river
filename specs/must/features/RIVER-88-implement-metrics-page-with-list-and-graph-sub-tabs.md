# RIVER-88: Implement metrics page with list and graph sub-tabs
Priority: Must
Test Approach: BDD
Why: Users have no way to explore or visualize metrics from within the River UI today.
<!-- STOP -->

## Problem

Metrics are stored and queryable in VictoriaMetrics, and the query API exposes them, but the Flutter UI has no metrics page. Users must leave the app and use Grafana (a dev-only tool) to see any metric data. This breaks the "unified dashboard" promise of River.

## Goal

An operator opens the Metrics page from the sidebar, browses the full list of available metrics, selects one or more, and sees a time-series graph for those metrics — all within River's own UI, scoped to the active time range.

**Scenarios**

*Given* the user navigates to the Metrics page,
*When* the "All Metrics" tab is active,
*Then* a list of all available metric names is displayed.

*Given* the user is on the "All Metrics" tab,
*When* they tap one or more metrics,
*Then* those metrics are marked as selected.

*Given* one or more metrics are selected,
*When* the user switches to the "Graph" tab,
*Then* a time-series graph is rendered for each selected metric over the active time range.

*Given* a metric is selected and the user changes the global time range,
*When* the Graph tab is active,
*Then* the graph refreshes with the new range.

*Given* the user switches from Graph back to All Metrics,
*When* the tab changes,
*Then* previously selected metrics remain selected.

## Scope

**In**
- Sidebar nav item for Metrics (`Icons.show_chart_outlined`)
- `MetricsPage` with two tabs: "All Metrics" and "Graph"
- "All Metrics" tab: fetches metric names from the API, renders a scrollable list with selection state
- Multi-select: tapping a metric toggles selection; selected metrics highlighted with `AppColors.primary.withOpacity(0.08)`
- "Graph" tab: renders a time-series chart for each selected metric using the active `TimeRangeController` range
- `MetricsController` (`ChangeNotifier`) owns metric list, selection set, loading/error state; subscribes to `TimeRangeController`
- Chart implemented with `CustomPainter` (no charting package dependency — matches `LogHistogram` precedent)
- Module at `lib/pages/metrics/` with barrel `metrics.dart`

**Out**
- Filtering or searching the metric list
- Metric metadata display (type, description, labels) beyond the metric name
- Aggregation controls (sum, avg, rate) — raw metric values only
- Alerting or threshold overlays
- Persisting selection across app restarts

## Decisions

- Query metrics via the existing generated Dart API client (`river_api`); no direct VictoriaMetrics calls from the UI
- Chart uses `CustomPainter` to stay consistent with `LogHistogram` and avoid adding a charting dependency
- Selection state lives on `MetricsController` (in-memory only, lost on page dispose)
- Tab switching uses Flutter's built-in `TabBar`/`TabBarView`
