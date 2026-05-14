---
name: flutter
description: Flutter/Dart coding rules for this project — style, file size, and test coverage.
user-invocable: false
---

When writing or reviewing any Flutter/Dart code in this repository:

1. **Never hardcode style values.** Colors, font sizes, spacing, border radii, and icon sizes must come from `app_theme.dart` (`AppColors`, `AppText`, `AppLayout`, `AppIcons`). If a value is missing, add it there first.

2. **Keep files small and focused.** One widget family per file. If a file exceeds ~200 lines, split it. Extract private widget classes (`_SomeWidget`) instead of nesting logic inline inside `build`.

3. **Keep functions simple.** Build methods and helpers should be short. Deep nesting is a signal to extract a named widget.

4. **Cover with tests.** Every new widget needs at least one BDD widget test in `src/ui/test/`. Use fake API implementations (not mocks). Cover the golden path and key edge cases (empty, error, loading). Use `const Key('...')` on widgets so tests can target them reliably.
