# Plan: Trace Explorer
Date: 2026-05-15
Why: Users have no first-class UI to search and visualize distributed traces, even though trace data is fully ingested and queryable via the existing API.

## Execution order

Phases 1 and 2 are independent and run in parallel: Phase 1 adds the backend endpoint needed to look up a single trace by ID, while Phase 2 builds the Flutter trace list page using the already-generated `getTraces()` client. Phase 3 depends on both and adds the waterfall detail view. Phase 4 depends on Phase 3 and wires up span attribute inspection.

## Phases

### Phase 1 — Single-trace API endpoint
**Goal:** `GET /v1/traces/{trace_id}` returns all spans for a given trace ID, allowing the UI to fetch a complete trace on demand.

**Steps:**
1. Add a `GET /v1/traces/{trace_id}` route in `src/river-query-api/src/main.rs` that queries ClickHouse for all spans with the given `trace_id` and returns `Vec<Span>` (reuse existing `Span` struct).
2. Annotate with `utoipa` so the route appears in `/openapi.json`.
3. Add an integration test covering the happy path and a 404 when the trace does not exist.
4. Regenerate the Dart client: `mise exec -- openapi-generator generate -i http://localhost:8080/openapi.json -g dart -o src/ui/lib/api/generated`.

**Depends on:** none
**Execution:** parallel
**Done when:** `GET /v1/traces/{trace_id}` returns the correct spans in manual testing; Dart client contains a `getTrace(traceId)` method; integration test passes under `mise exec -- cargo test`.

---

### Phase 2 — Trace list page (Flutter)
**Goal:** A new "Traces" sidebar entry shows a searchable, filterable table of traces grouped by `trace_id`, reusing the existing filter DSL and `TimeRangePicker`.

**Steps:**
1. Create `src/ui/lib/pages/traces/` module with barrel `traces.dart`.
2. Implement `TracesController` (`ChangeNotifier`) in `traces_controller.dart`:
   - Fields: `filter`, `rows` (`List<TraceGroup>`), `loading`, `error`, `selectedTraceId`.
   - Subscribes to `TimeRangeController`; calls `reload()` on range change.
   - `reload()` calls `getTraces(filter, from, to, limit: 200)`.
   - `selectTrace(String traceId)` / `clearSelection()`.
3. Implement `TracesTable` widget in `traces_table.dart`: columns Trace ID (flex 3), Root Service (flex 2), Root Operation (flex 3), Duration ms (flex 2), Span Count (flex 1), Start Time (flex 3); client-side sort on any column; row tap calls `controller.selectTrace`.
4. Implement `TracesPage` in `traces_page.dart`: filter `SearchBar` (same pattern as `LogSearchBar`), `TracesTable`, placeholder `SizedBox` for detail panel (wired in Phase 3).
5. Register `TracesPage` in `main.dart` `_Page` enum and sidebar; provide `TracesController` above the page.

**Depends on:** none
**Execution:** parallel
**Done when:** Traces page renders in the macOS app, filter and time-range changes trigger a reload, rows display correct data from the API, sidebar navigation works.

---

### Phase 3 — Trace waterfall detail panel (Flutter)
**Goal:** Clicking a trace row opens a side panel that renders a Gantt-style span waterfall, showing relative start/duration bars for every span in the trace.

**Steps:**
1. Implement `TraceDetailPanel` in `src/ui/lib/pages/traces/trace_detail_panel.dart`:
   - `AnimatedSize` slide-in (same 420px / 200ms easeInOut pattern as `LogDetailPanel`), shown when `controller.selectedTraceId != null`.
   - On show, calls `getTrace(traceId)` (Phase 1 endpoint) and stores spans locally.
   - Builds a flat, indented span tree from `parent_span_id` linkage.
2. Implement `SpanWaterfallPainter` (`CustomPainter`) in `span_waterfall.dart`:
   - Timeline header showing total trace duration.
   - One row per span: service + operation label left, proportional filled bar right; bars colored by `status_code` (ok = primary, error = red, unset = grey).
   - Tap a row to select a span (drives Phase 4 attribute panel).
3. Wire `TraceDetailPanel` into `TracesPage` replacing the Phase 2 placeholder.

**Depends on:** Phase 1, Phase 2
**Execution:** sequential
**Done when:** Clicking a trace row fetches and renders the waterfall; spans are indented correctly by parent–child relationship; bar widths are proportional to duration; panel closes when selection is cleared.

---

### Phase 4 — Span attributes panel
**Goal:** Tapping a span row in the waterfall expands an attributes inspector showing all key-value pairs for that span, its events, and its links.

**Steps:**
1. Add `selectedSpan` (`Span?`) to `TraceDetailPanel`'s local state; tapping a waterfall row sets it.
2. Implement `SpanAttributesSection` widget (inline or separate file) using `ExpansionTile` sections — Attributes, Events, Links — all expanded by default; attributes parsed from `span.attributes` JSON with the same try/catch fallback pattern as `LogDetailPanel`.
3. Render `SpanAttributesSection` below the waterfall inside `TraceDetailPanel` when a span is selected; dismiss on outside tap or clear-selection button.

**Depends on:** Phase 3
**Execution:** sequential
**Done when:** Tapping a span shows its attributes, events, and links; JSON parse failure falls back gracefully to "No attributes"; panel clears when deselected.

---

## Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Traces with hundreds of spans make the waterfall unreadable | Poor UX on large traces | Cap rendered spans at 200 with a visible "showing top 200 spans" notice; add virtual scrolling if needed |
| Parent–child linkage is broken when `parent_span_id` is empty or mismatched | Flat list instead of tree | Treat orphan spans as root-level; do not crash |
| Dart client regeneration breaks existing Logs page code | Compilation failure | Run `flutter analyze` after regeneration; pin openapi-generator version in mise |
| `getTrace` single-trace endpoint returns large payloads for long-running traces | Slow panel open | Add a `limit` query param (default 500) and surface a "trace truncated" warning in the UI |

## Open Questions

- [ ] Should the waterfall support horizontal scroll for traces spanning many seconds, or scale all bars to fit the panel width? — product decision, resolve before Phase 3 starts
- [ ] What should the Traces sidebar icon be? — design decision; use a placeholder (e.g. `Icons.account_tree`) until resolved
- [ ] Should filter autocomplete suggest `service:`, `operation:`, `status:` tokens (like Logs page)? — scope question; if yes, add to Phase 2 steps
