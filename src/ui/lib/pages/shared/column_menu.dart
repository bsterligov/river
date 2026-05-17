import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class ColumnMenuItem {
  const ColumnMenuItem({
    required this.id,
    required this.label,
    required this.visible,
    this.required = false,
  });

  final String id;
  final String label;
  final bool visible;
  final bool required;
}

/// Computes the [top] and [right] offsets for the column menu popup.
///
/// [iconGlobal] and [iconSize] describe the filter icon's global position and
/// size. [stackGlobal] and [stackWidth] describe the outer table Stack.
/// Returns `(top: 36, right: 8)` as fallback defaults when null is passed.
({double top, double right}) columnMenuOffset({
  required Offset? iconGlobal,
  required Size? iconSize,
  required Offset? stackGlobal,
  required double? stackWidth,
}) {
  if (iconGlobal == null || iconSize == null || stackGlobal == null || stackWidth == null) {
    return (top: 36, right: 8);
  }
  return (
    top: iconGlobal.dy - stackGlobal.dy + iconSize.height + 4,
    right: stackWidth - (iconGlobal.dx - stackGlobal.dx) - iconSize.width,
  );
}

/// Positioned column-visibility overlay.
///
/// Renders a checkbox list anchored below [menuKey]. The caller owns open/close
/// state; [onToggle] fires when a checkbox is tapped.
class ColumnMenu extends StatelessWidget {
  const ColumnMenu({
    super.key,
    required this.menuKey,
    required this.stackKey,
    required this.items,
    required this.onToggle,
  });

  final GlobalKey menuKey;
  final GlobalKey stackKey;
  final List<ColumnMenuItem> items;
  final void Function(String id) onToggle;

  @override
  Widget build(BuildContext context) {
    final iconBox = menuKey.currentContext?.findRenderObject() as RenderBox?;
    final stackBox = stackKey.currentContext?.findRenderObject() as RenderBox?;
    final offset = columnMenuOffset(
      iconGlobal: iconBox?.localToGlobal(Offset.zero),
      iconSize: iconBox?.size,
      stackGlobal: stackBox?.localToGlobal(Offset.zero),
      stackWidth: stackBox?.size.width,
    );

    return Positioned(
      top: offset.top,
      right: offset.right,
      child: GestureDetector(
        onTap: () {},
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(AppLayout.radius),
          child: Container(
            width: 180,
            padding: const EdgeInsets.symmetric(vertical: AppLayout.gapS),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppLayout.radius),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: items.map((item) {
                return CheckboxListTile(
                  key: Key('col_toggle_${item.id}'),
                  dense: true,
                  title: Text(item.label, style: AppText.label),
                  value: item.visible,
                  onChanged: item.required ? null : (_) => onToggle(item.id),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: AppLayout.tilePadding,
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
