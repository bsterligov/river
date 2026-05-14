# DRAFT -- Issue #30
# Run `/po-spec-writer` on this branch to generate the full spec.

Issue:    #30
Task:     RIVER-30
Title:    UI: Facet Panel
Why:
The left facet panel auto-populates from `/v1/logs/facets`, and clicking a value appends a filter token to the search bar and re-runs the query.

Steps:
1. Create `FacetPanel` widget (`facet_panel.dart`). Takes `LogsController` as input. On build, calls `apiClient.getLogsFacets(filter, from, to)`. Renders one `ExpansionTile` per `FacetField` (expanded by default). Each `FacetValue` row shows value + count chip; tapping it calls `controller.appendFilter('field:value')`.
2. Add `appendFilter(String token)` to `LogsController`: if the current filter is empty, set it to `token`; otherwise append ` AND token`. Then call `reload()`.
3. Replace the facet placeholder in `LogsPage` with the real `FacetPanel`.
4. Show a loading shimmer (a `Container` with grey color) while facets load; show nothing on error (fail silently, since facets are additive UI).
5. Re-fetch facets whenever `LogsController` notifies (time range or filter changed).

Done when: Opening the logs page shows facet groups for `service_name` and `severity_text`; clicking a facet value updates the search bar and refreshes the table.

Part of feature plan: logs-ui-full-page
Why: Replace the minimal logs page with a full observability UI — time range selector, Kibana-style search, auto-facets, distribution histogram, column-managed table, and a log detail panel — so operators can explore logs without leaving the app.
Priority: must
Category: features
