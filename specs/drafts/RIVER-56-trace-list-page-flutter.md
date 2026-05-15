# DRAFT -- Issue #56
# Run `/po-spec-writer` on this branch to generate the full spec.

Issue:    #56
Task:     RIVER-56
Title:    Trace list page (Flutter)
Why:
A new "Traces" sidebar entry shows a searchable, filterable table of traces grouped by `trace_id`, reusing the existing filter DSL and `TimeRangePicker`.

Steps:
1. Create `src/ui/lib/pages/traces/` module with barrel `traces.dart`.
2. Implement `TracesController` (`ChangeNotifier`) in `traces_controller.dart`:
   - Fields: `filter`, `rows` (`List<TraceGroup>`), `loading`, `error`, `selectedTraceId`.
   - Subscribes to `TimeRangeController`; calls `reload()` on range change.
   - `reload()` calls `getTraces(filter, from, to, limit: 200)`.
   - `selectTrace(String traceId)` / `clearSelection()`.
3. Implement `TracesTable` widget in `traces_table.dart`: columns Trace ID (flex 3), Root Service (flex 2), Root Operation (flex 3), Duration ms (flex 2), Span Count (flex 1), Start Time (flex 3); client-side sort on any column; row tap calls `controller.selectTrace`.
4. Implement `TracesPage` in `traces_page.dart`: filter `SearchBar` (same pattern as `LogSearchBar`), `TracesTable`, placeholder `SizedBox` for detail panel (wired in Phase 3).
5. Register `TracesPage` in `main.dart` `_Page` enum and sidebar; provide `TracesController` above the page.

Done when: Traces page renders in the macOS app, filter and time-range changes trigger a reload, rows display correct data from the API, sidebar navigation works.

Part of feature plan: trace-explorer
Why: Users have no first-class UI to search and visualize distributed traces, even though trace data is fully ingested and queryable via the existing API.
Priority: must
Category: features
