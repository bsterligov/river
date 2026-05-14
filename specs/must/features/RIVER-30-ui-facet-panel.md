# RIVER-30: UI: Facet Panel
Status: In Progress
Priority: Must
Test Approach: BDD
Why: Operators have no way to narrow down logs without knowing exact field values — the facet panel lets them explore and filter by clicking rather than typing.
<!-- STOP -->

## Problem

The current logs page requires operators to type raw filter expressions by hand. There is no way to discover what values exist for a given field without running a query first. This slows down root-cause investigation and puts the full burden of syntax recall on the operator.

## Goal

An operator opens the logs page and sees a left panel listing facet groups (e.g. `service_name`, `severity_text`) with value counts. Clicking any value immediately narrows the table to matching logs and appends the filter token to the search bar, so the operator can see exactly what filter was applied and continue refining it.

**Scenarios**

Given the logs page is open and the API returns facets for `service_name` and `severity_text`,
When the facet panel finishes loading,
Then two `ExpansionTile` groups are visible, each expanded, showing value rows with counts.

Given a facet value row is visible,
When the operator taps it,
Then the search bar appends `field:value` (joined with ` AND ` if a filter was already present) and the log table re-fetches.

Given the `/v1/logs/facets` request is in flight,
When the panel is rendered,
Then a grey shimmer placeholder is shown in place of facet content.

Given the `/v1/logs/facets` request fails,
When the error is received,
Then the facet panel shows nothing (no error message, no broken state).

Given facets have loaded,
When the operator changes the time range or edits the search bar,
Then the facet panel re-fetches to reflect the new context.

## Scope

**In**
- `FacetPanel` widget (`facet_panel.dart`) — takes `LogsController`, calls `apiClient.getLogsFacets(filter, from, to)`, renders one `ExpansionTile` per `FacetField`
- Each `FacetValue` row: value label + count chip; tap calls `controller.appendFilter('field:value')`
- `appendFilter(String token)` on `LogsController`: sets filter if empty, otherwise appends ` AND token`, then calls `reload()`
- Grey `Container` shimmer while facets load
- Silent failure on facet fetch error (no UI feedback)
- Re-fetch facets on every `LogsController` notify (time range or filter change)
- Replace the existing facet placeholder in `LogsPage` with `FacetPanel`

**Out**
- Multi-select within a facet group (AND across values of the same field)
- Facet search / filter-by-name within a group
- Collapsible facet panel sidebar
- Configuring which fields appear as facets

## Decisions

- Fail silently on facet errors — facets are additive UI; the table still works without them, and surfacing an error here would distract from the primary workflow.
- Re-fetch facets on every controller notify rather than debouncing — consistent with how the table re-fetches; avoids stale counts without added complexity.
