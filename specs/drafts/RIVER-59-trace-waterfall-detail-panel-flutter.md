# DRAFT -- Issue #59
# Run `/po-spec-writer` on this branch to generate the full spec.

Issue:    #59
Task:     RIVER-59
Title:    Trace waterfall detail panel (Flutter)
Why:
Clicking a trace row opens a side panel that renders a Gantt-style span waterfall, showing relative start/duration bars for every span in the trace.

Steps:
1. Implement `TraceDetailPanel` in `src/ui/lib/pages/traces/trace_detail_panel.dart`:
   - `AnimatedSize` slide-in (same 420px / 200ms easeInOut pattern as `LogDetailPanel`), shown when `controller.selectedTraceId != null`.
   - On show, calls `getTrace(traceId)` (Phase 1 endpoint) and stores spans locally.
   - Builds a flat, indented span tree from `parent_span_id` linkage.
2. Implement `SpanWaterfallPainter` (`CustomPainter`) in `span_waterfall.dart`:
   - Timeline header showing total trace duration.
   - One row per span: service + operation label left, proportional filled bar right; bars colored by `status_code` (ok = primary, error = red, unset = grey).
   - Tap a row to select a span (drives Phase 4 attribute panel).
3. Wire `TraceDetailPanel` into `TracesPage` replacing the Phase 2 placeholder.

Done when: Clicking a trace row fetches and renders the waterfall; spans are indented correctly by parent–child relationship; bar widths are proportional to duration; panel closes when selection is cleared.

Depends on: RIVER-55 (single-trace API endpoint), RIVER-56 (trace list page)
Part of feature plan: trace-explorer
Why: Users have no first-class UI to search and visualize distributed traces, even though trace data is fully ingested and queryable via the existing API.
Priority: must
Category: features
