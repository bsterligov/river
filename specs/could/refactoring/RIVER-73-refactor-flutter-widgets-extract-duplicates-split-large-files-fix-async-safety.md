# RIVER-73: Refactor Flutter widgets: extract duplicates, split large files, fix async safety

Priority: Could
Test Approach: TDD
Why: A code review found duplicated widgets and logic, oversized files, hardcoded colors, and unsafe async patterns that make the Flutter UI harder to maintain and extend.
<!-- STOP -->

## Problem

The Flutter UI has accumulated several structural issues during rapid feature development. `_KvRow` and attribute-parsing logic are copy-pasted across `log_detail_panel.dart` and `trace_detail_panel.dart`. Three files exceed 400 lines, mixing unrelated concerns. Hardcoded color literals (`Colors.black45`, `Colors.orange`) bypass the theme system. Async callbacks in `facet_panel.dart`, `logs_page.dart`, and `time_range_picker.dart` are missing `mounted` guards or swallow errors silently.

## Goal

The codebase passes `flutter analyze` with no new warnings, no widget or function is defined in more than one file, all source files are under 300 lines, all colors route through `AppColors`/`AppText`/`AppLayout`, and async callbacks check `mounted` before touching widget state.

## Scope

**In**
- Extract `_KvRow` to `lib/widgets/kv_row.dart`; delete both inline copies
- Extract attribute parsing to `lib/utils/parse_attributes.dart`; rename all call sites to `parseAttributes`
- Consolidate `LogSearchBar` and `_TracesSearchBar` into one shared widget
- Split `logs_table.dart`: move column-width math to `lib/pages/logs/column_layout.dart` and `_ColumnMenu` to its own file
- Split `trace_detail_panel.dart`: move `SpanAttributesSection`, `EventRow`, `LinkRow` to `lib/pages/traces/span_detail_widgets.dart`
- Split `time_range_picker.dart`: extract `_CustomForm` to `lib/widgets/custom_range_form.dart`
- Replace `Colors.black45` in `log_histogram.dart:233` with a theme color
- Add `AppColors.warning` and use it for WARN severity in `logs_table.dart:393`
- Replace raw pixel literals in `span_waterfall.dart:79-82` with named constants (local or theme)
- Fix `mounted` check order in `facet_panel.dart:98` (`if (!mounted) return;` before `setState`)
- Add error handler to unawaited `_controller.reload()` in `logs_page.dart:33`
- Add `mounted` check before `Overlay.of(context).insert()` in `time_range_picker.dart:91`
- Add `const` constructor to `_Shimmer` in `log_detail_panel.dart`
- Type `final dynamic row` as `LogRow` in `logs_table.dart:336`
- Replace `catch (_) {}` with logged error in `facet_panel.dart:104`

**Out**
- Changing any visible behavior or UI layout
- Introducing new state management patterns (Riverpod, Bloc, etc.)
- Splitting files that are already under 300 lines

## Decisions

- All extracted files go under the existing `lib/` directory tree — no new top-level folders
- `parseAttributes` (public, no underscore) is the canonical name after deduplication
- The `AppColors.warning` token is the only new theme addition; no other theme refactoring in this spec
- Silent `catch` blocks should log via `debugPrint` at minimum — no structured logging framework required yet
