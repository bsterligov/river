# DRAFT -- Issue #61
# Run `/po-spec-writer` on this branch to generate the full spec.

Issue:    #61
Task:     RIVER-61
Title:    Span attributes panel
Why:
Tapping a span row in the waterfall expands an attributes inspector showing all key-value pairs for that span, its events, and its links.

Steps:
1. Add `selectedSpan` (`Span?`) to `TraceDetailPanel`'s local state; tapping a waterfall row sets it.
2. Implement `SpanAttributesSection` widget (inline or separate file) using `ExpansionTile` sections — Attributes, Events, Links — all expanded by default; attributes parsed from `span.attributes` JSON with the same try/catch fallback pattern as `LogDetailPanel`.
3. Render `SpanAttributesSection` below the waterfall inside `TraceDetailPanel` when a span is selected; dismiss on outside tap or clear-selection button.

Done when: Tapping a span shows its attributes, events, and links; JSON parse failure falls back gracefully to "No attributes"; panel clears when deselected.

Depends on: RIVER-59 (trace waterfall detail panel)
Part of feature plan: trace-explorer
Why: Users have no first-class UI to search and visualize distributed traces, even though trace data is fully ingested and queryable via the existing API.
Priority: must
Category: features
