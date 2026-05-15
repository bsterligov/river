# RIVER-61: Span attributes panel
Status: In Progress
Priority: Must
Test Approach: BDD
Why: Operators viewing the trace waterfall cannot inspect a span's attributes, events, or links without leaving the UI, because tapping a span row does nothing today.
<!-- STOP -->

## Problem

The trace waterfall (RIVER-59) renders spans as rows but tapping one has no effect. Operators who need to see what a span recorded — its attributes, events attached mid-execution, or links to related traces — must query ClickHouse directly. There is no in-app inspector.

## Goal

An operator taps any row in the waterfall and a `SpanAttributesSection` panel appears below it, showing three collapsible sections: Attributes (parsed key-value pairs from `span.attributes`), Events, and Links. Tapping a clear-selection button or tapping outside the selection dismisses the panel.

**Scenarios**

Given a trace is open in `TraceDetailPanel` and the waterfall is visible,
When the operator taps a span row,
Then `selectedSpan` is set to that span and `SpanAttributesSection` renders below the waterfall with all three sections expanded.

Given `SpanAttributesSection` is visible for a selected span,
When the operator taps a different span row,
Then `selectedSpan` updates and the panel refreshes with the new span's data.

Given `SpanAttributesSection` is visible,
When the operator taps the clear-selection button,
Then `selectedSpan` is cleared and `SpanAttributesSection` is no longer rendered.

Given a span has a valid JSON object in the `attributes` field,
When the Attributes section renders,
Then each key-value pair is shown as a labelled row.

Given a span has an empty, null, or non-JSON `attributes` field,
When the Attributes section renders,
Then the section shows "No attributes".

## Scope

**In**
- `Span? selectedSpan` local state on `TraceDetailPanel`; tapping a waterfall row sets it
- `SpanAttributesSection` widget (inline or `span_attributes_section.dart`); three `ExpansionTile` sections, all expanded by default:
  - Attributes: `jsonDecode` of `span.attributes` in try/catch; key-value rows if result is a JSON object; falls back to "No attributes"
  - Events: list of span event entries; "No events" if empty
  - Links: list of span link entries; "No links" if empty
- `SpanAttributesSection` rendered below the waterfall inside `TraceDetailPanel` when `selectedSpan != null`
- Clear-selection button (X) in the panel header calls `setState(() => selectedSpan = null)`
- Tapping outside the waterfall rows (if feasible without a third-party gesture package) also clears `selectedSpan`

**Out**
- Copying attribute values to clipboard
- Expanding nested JSON objects in the attributes section
- Persisting selected span across navigation or page reload
- Server-side span detail endpoint — all data comes from the already-fetched span model

## Decisions

- `attributes` parsing reuses the same try/catch + fallback pattern as `LogDetailPanel._AttributesSection._parseAttributes`; malformed JSON must not crash the panel.
- `SpanAttributesSection` is local state on `TraceDetailPanel` (not on a controller) — span selection is display-only and does not need to survive navigation.
- All three sections are expanded by default, consistent with `LogDetailPanel` precedent.
- If tapping outside is complex to implement without adding a gesture package, it may be omitted; the X button alone satisfies the done condition.
