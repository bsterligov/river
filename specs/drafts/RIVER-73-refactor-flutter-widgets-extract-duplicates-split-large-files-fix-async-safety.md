# DRAFT -- Issue #73
# Run `/spec` on this branch to generate the full spec.

Issue:    #73
Task:     RIVER-73
Title:    Refactor Flutter widgets: extract duplicates, split large files, fix async safety
Why:
Code review surfaced several quality issues in the Flutter UI layer.

## Duplication (High Priority)
- `_KvRow` widget is defined identically in `log_detail_panel.dart` and `trace_detail_panel.dart` — extract to `widgets/kv_row.dart`
- Attribute parsing logic (`_parseAttributes` / `_parseAttrs`) is duplicated 3× across the same two files with inconsistent naming — extract to `utils/parse_attributes.dart`
- `LogSearchBar` and `_TracesSearchBar` are near-identical — consolidate into one shared widget

## File Size
- `logs_table.dart` (398 lines): split column-width math and `_ColumnMenu` out
- `trace_detail_panel.dart` (554 lines): extract `SpanAttributesSection`, `EventRow`, `LinkRow`, `_KvRow` to `span_detail_widgets.dart`
- `time_range_picker.dart` (448 lines): extract `_CustomForm` to its own file

## Hardcoded Colors
- `log_histogram.dart:233` — `Colors.black45` → theme color
- `logs_table.dart:393` — `Colors.orange` for WARN severity → add `AppColors.warning`
- `span_waterfall.dart:79-82` — raw pixel literals → theme constants

## Async Safety
- `facet_panel.dart:98` — `mounted` check inside `setState` callback instead of before it
- `logs_page.dart:33` — unawaited `_controller.reload()` in `initState` with no error handler
- `time_range_picker.dart:91` — `Overlay.of(context).insert()` without `mounted` check

## Minor
- `log_detail_panel.dart` — `_Shimmer` missing `const` constructor
- `logs_table.dart:336` — `final dynamic row` should be typed as `LogRow`
- `facet_panel.dart:104` — `catch (_) {}` silently swallows exceptions

## Acceptance Criteria
- No duplicate widget/function definitions across files
- All files under 300 lines
- No hardcoded colors outside the theme
- All async callbacks guarded with `mounted` checks before `setState`
- `flutter analyze` passes with no new warnings
Priority: could
Category: refactoring
