import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ui/pages/shared/column_menu.dart';

void main() {
  group('columnMenuOffset', () {
    test('returns defaults when all inputs are null', () {
      final result = columnMenuOffset(
        iconGlobal: null,
        iconSize: null,
        stackGlobal: null,
        stackWidth: null,
      );
      expect(result.top, 36);
      expect(result.right, 8);
    });

    test('returns defaults when only iconGlobal is null', () {
      final result = columnMenuOffset(
        iconGlobal: null,
        iconSize: const Size(24, 24),
        stackGlobal: Offset.zero,
        stackWidth: 800,
      );
      expect(result.top, 36);
      expect(result.right, 8);
    });

    test('anchors popup below icon with 4px gap', () {
      // Icon at global (100, 50), size 24x24. Stack at global (0, 0), width 800.
      // top = 50 - 0 + 24 + 4 = 78
      final result = columnMenuOffset(
        iconGlobal: const Offset(100, 50),
        iconSize: const Size(24, 24),
        stackGlobal: Offset.zero,
        stackWidth: 800,
      );
      expect(result.top, 78);
    });

    test('right-aligns popup to the icon right edge', () {
      // Icon at global (760, 50), size 24x24. Stack at global (0, 0), width 800.
      // right = 800 - (760 - 0) - 24 = 16
      final result = columnMenuOffset(
        iconGlobal: const Offset(760, 50),
        iconSize: const Size(24, 24),
        stackGlobal: Offset.zero,
        stackWidth: 800,
      );
      expect(result.right, 16);
    });

    test('accounts for non-zero stack global offset', () {
      // Stack at global (100, 200). Icon at global (700, 240), size 24x24. Stack width 600.
      // top = 240 - 200 + 24 + 4 = 68
      // right = 600 - (700 - 100) - 24 = -24  (icon extends past stack right edge)
      final result = columnMenuOffset(
        iconGlobal: const Offset(700, 240),
        iconSize: const Size(24, 24),
        stackGlobal: const Offset(100, 200),
        stackWidth: 600,
      );
      expect(result.top, 68);
      expect(result.right, -24);
    });

    test('top uses icon height correctly for non-square icons', () {
      // Icon height 32. Stack at (0,0). Icon at (0, 10).
      // top = 10 - 0 + 32 + 4 = 46
      final result = columnMenuOffset(
        iconGlobal: const Offset(0, 10),
        iconSize: const Size(24, 32),
        stackGlobal: Offset.zero,
        stackWidth: 800,
      );
      expect(result.top, 46);
    });
  });
}
