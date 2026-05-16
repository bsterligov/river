import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class ColumnMenuItem {
  const ColumnMenuItem({
    required this.id,
    required this.label,
    required this.visible,
  });

  final String id;
  final String label;
  final bool visible;
}

/// Positioned column-visibility overlay.
///
/// Renders a checkbox list anchored below [menuKey]. The caller owns open/close
/// state; [onToggle] fires when a checkbox is tapped.
class ColumnMenu extends StatelessWidget {
  const ColumnMenu({
    super.key,
    required this.menuKey,
    required this.items,
    required this.onToggle,
  });

  final GlobalKey menuKey;
  final List<ColumnMenuItem> items;
  final void Function(String id) onToggle;

  @override
  Widget build(BuildContext context) {
    final iconBox = menuKey.currentContext?.findRenderObject() as RenderBox?;
    final stackBox = context.findRenderObject() as RenderBox?;
    double menuTop = 36;
    double menuRight = 8;
    if (iconBox != null && stackBox != null) {
      final iconGlobal = iconBox.localToGlobal(Offset.zero);
      final stackGlobal = stackBox.localToGlobal(Offset.zero);
      menuTop = iconGlobal.dy - stackGlobal.dy + iconBox.size.height + 4;
      menuRight = stackBox.size.width - (iconGlobal.dx - stackGlobal.dx) - iconBox.size.width;
    }

    return Positioned(
      top: menuTop,
      right: menuRight,
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
                  onChanged: (_) => onToggle(item.id),
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
