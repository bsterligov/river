# RIVER-85: Fix column filter popup position
Priority: Must
Test Approach: TDD
Why: The column filter popup appears in a random position because ColumnMenu uses the wrong RenderBox as its coordinate origin.
<!-- STOP -->

## Problem

`ColumnMenu.build` calls `context.findRenderObject()` to get the Stack's global offset for coordinate subtraction. At runtime, `context` resolves to the overlay Stack (the inner `Positioned.fill > GestureDetector > Stack`), not the outer table Stack. The subtraction produces wrong offsets, so the popup jumps to an unpredictable position every time the filter icon is clicked. Affects both the Logs and Traces views.

## Goal

Clicking the filter (settings) icon opens the column visibility popup anchored directly below the icon, right-aligned to it, consistently across Logs and Traces pages.

## Scope

**In**
- Pass the outer Stack's `GlobalKey` into `ColumnMenu` and use it to obtain the correct `RenderBox` for offset calculation
- Unit tests for the offset math: given known icon and stack positions, assert correct `menuTop` / `menuRight` values
- Verify fix applies to both `logs_table.dart` and `traces_table.dart` (both use `TableShell`)

**Out**
- Changing the popup's visual appearance or animation
- Replacing the manual positioning approach with a Flutter overlay/portal system

## Decisions

- `TableShell` already holds `_menuKey` (the icon's `GlobalKey`); a second `GlobalKey` for the outer Stack will be added and passed to `ColumnMenu` as `stackKey`
- `ColumnMenu` receives `stackKey: GlobalKey` instead of deriving the stack `RenderBox` from its own `context`
