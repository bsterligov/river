# DRAFT -- Issue #85
# Run `/spec` on this branch to generate the full spec.

Issue:    #85
Task:     RIVER-85
Title:    Fix column filter popup position in logs and traces views
Why:
When clicking the filter (settings) icon in the logs or traces table header, the column visibility popup appears in a random/incorrect position instead of anchored below the icon.

**Root cause:** `ColumnMenu.build` calls `context.findRenderObject()` to get the parent Stack's RenderBox for coordinate subtraction. However, `context` resolves to the overlay Stack (the inner `Positioned.fill > GestureDetector > Stack`), not the outer Stack that contains the table. This makes `stackGlobal` wrong, so the computed `menuTop`/`menuRight` offsets are incorrect.

**Expected:** Popup appears directly below the filter icon, right-aligned.
**Actual:** Popup jumps to a random position each time it is opened.

**Affected files:**
- `src/ui/lib/pages/shared/column_menu.dart` — positioning logic in `build`
- `src/ui/lib/pages/shared/table_shell.dart` — passes no stack key to ColumnMenu
Priority: must
Category: bugs
