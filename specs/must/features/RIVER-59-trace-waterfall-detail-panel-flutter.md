# RIVER-59: Trace waterfall detail panel (Flutter)

Priority: Must
Test Approach: BDD
Why: Operators who select a trace have no way to see its internal span structure — the trace list shows summary rows only, leaving timing and error diagnosis opaque.
<!-- STOP -->

## Problem

Clicking a trace row on the Traces page today does nothing beyond highlighting it. Operators who need to understand the internal timing of a distributed trace — which service called which, how long each span took, and where errors occurred — have no in-app view. They must reach for external tools (Grafana, Jaeger, raw ClickHouse) to answer questions that should be answerable in River.

## Goal

Clicking a trace row opens a 420px-wide side panel on the right of the Traces page. The panel fetches all spans for that trace from the API, builds a tree from `parent_span_id` linkage, and renders a Gantt-style waterfall: one row per span, with a label on the left (service + operation, indented by depth) and a proportional filled bar on the right. Bar colour indicates `status_code`: primary for ok, red for error, grey for unset. Tapping a span row selects it (for the Phase 4 attributes panel). The panel closes when the selection is cleared.

**Scenarios**

Given a trace row is visible in the Traces table,
When the operator clicks it,
Then the waterfall panel slides in on the right and renders one row per span for that trace.

Given the waterfall panel is open,
When the spans are rendered,
Then each span row shows its service name and operation name on the left, indented by its depth in the parent–child tree.

Given the waterfall panel is open,
When the spans are rendered,
Then each span bar width is proportional to the span's duration relative to the total trace duration, and bars align to the trace-start timeline.

Given a span has `status_code = ok`,
When the waterfall renders,
Then its bar is filled with the primary colour.

Given a span has `status_code = error`,
When the waterfall renders,
Then its bar is filled with red.

Given a span has `status_code = unset` or an unrecognised value,
When the waterfall renders,
Then its bar is filled with grey.

Given a span has no parent (`parent_span_id` is empty or not present in the trace),
When the waterfall renders,
Then it is treated as a root span with no indentation.

Given the waterfall panel is open,
When the operator clears the selection (clicks X or selects another trace),
Then the panel closes.

Given the operator clicks a different trace row while the panel is open,
When the new trace loads,
Then the panel updates to show the new trace's spans.

## Scope

**In**
- `TraceDetailPanel` widget in `src/ui/lib/pages/traces/trace_detail_panel.dart`
  - `AnimatedSize` slide-in: width animates 0 → 420px, 200ms easeInOut; shown when `controller.selectedTraceId != null`
  - On show, calls `getTrace(traceId)` (RIVER-55 endpoint) and stores the returned spans in local widget state
  - Builds a flat, depth-first ordered span list from `parent_span_id` linkage; orphan spans (missing parent) treated as root-level
  - X close button calls `controller.clearSelection()`
  - Timeline header row: shows total trace duration (max `end_time` minus min `start_time` across all spans)
- `SpanWaterfallPainter` (`CustomPainter`) in `src/ui/lib/pages/traces/span_waterfall.dart`
  - One row per span: label column (service + operation, left-padded by `depth * 12px`) and bar column
  - Bar x-offset and width computed proportionally from span `start_time_unix_nano` and `duration_ns` relative to trace bounds
  - Bar colour: `AppColors.primary` for ok, `Colors.red` for error, `Colors.grey` for unset or unknown
  - Tap gesture per row calls back to `TraceDetailPanel` to set selected span (drives Phase 4)
- Wiring `TraceDetailPanel` into `TracesPage` in place of the Phase 2 placeholder `SizedBox`
- Cap rendered spans at 200; show a "showing top 200 spans" notice above the waterfall when the limit is hit

**Out**
- Span attribute, event, and link inspection (Phase 4)
- Horizontal scroll for traces with many seconds of duration (bars scale to fit panel width)
- Loading skeleton or shimmer during `getTrace` fetch (plain `CircularProgressIndicator` is acceptable)
- Virtual scrolling for traces beyond the 200-span cap
- Resizable panel width

## Decisions

- `AnimatedSize` for the slide-in matches `LogDetailPanel` exactly — keeps a single animation pattern across the UI.
- `CustomPainter` for the waterfall avoids a charting package dependency, consistent with `LogHistogram`.
- Orphan spans (missing or unresolvable `parent_span_id`) are placed at root level rather than discarded — the waterfall must never crash on malformed trace data.
- The 200-span cap with a visible notice is chosen over silent truncation; the cap value is a constant in `trace_detail_panel.dart` and can be raised without a spec change.
- Bar width scales to fit the panel's available width (no horizontal scroll for MVP); this is called out explicitly in Out scope so Phase 4 can revisit if needed.
