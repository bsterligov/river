# RIVER-49: Refactor UI Layout — Top Panel with Datetime Picker

Priority: Should
Test Approach: BDD
Why: The time range picker lives inside the Logs page today, so navigating to another page silently discards the selected range.
<!-- STOP -->

## Problem

The datetime picker is owned by the Logs page (`LogsController`), which means it is destroyed and reset whenever the user navigates away. As the product adds more pages (metrics, traces), each page would need its own independent picker — creating duplicated state and a disjointed experience. The app name "River" is buried in the sidebar rather than in a prominent, consistent location.

## Goal

An operator sets a time range once in the top panel and navigates between pages — the selected range stays intact. The "River" brand mark is visible at all times in the top-left of the top panel.

**Scenarios**

*Given* the operator has set a custom time range in the top panel,
*When* they navigate from Logs to any other page and back,
*Then* the time range is unchanged.

*Given* the operator is on any page,
*When* they look at the top of the screen,
*Then* they see "River" on the left and the datetime picker on the right.

## Scope

**In**
- New persistent top panel widget spanning full width above the page content area
- "River" label moved from the sidebar to the left side of the top panel
- Datetime picker widget relocated from the Logs page into the top panel
- Time range state lifted out of `LogsController` into a shared, app-level controller
- Logs page continues to read time range from the shared controller

**Out**
- Changes to the sidebar navigation structure
- Adding a time range picker to pages other than Logs (they will read from shared state but not display their own controls)
- Any visual redesign beyond the structural relocation described above

## Decisions

- The shared time range controller should follow the existing `ChangeNotifier` pattern already used by `LogsController`
- The top panel height and styling should use existing `AppTheme` tokens; no new tokens needed
