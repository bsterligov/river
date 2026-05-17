# DRAFT -- Issue #88
# Run `/spec` on this branch to generate the full spec.

Issue:    #88
Task:     RIVER-88
Title:    Implement metrics page with list and graph sub-tabs
Why:
Add a metrics page with two sub-tabs:
1. **All Metrics** — a list view showing all available metrics
2. **Graph** — a view showing a graph for user-selected metrics

**Acceptance criteria:**
- Metrics page is accessible from the main navigation
- "All Metrics" tab displays a list of available metrics with relevant metadata (name, type, description)
- User can select one or more metrics from the list
- "Graph" tab renders a time-series graph for the selected metrics
- Tab state persists when switching between tabs (selection is not lost)
Priority: must
Category: features
