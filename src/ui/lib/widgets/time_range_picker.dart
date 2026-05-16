import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'custom_range_form.dart';

typedef RangeCallback = void Function(DateTime from, DateTime to);

class TimeRangePicker extends StatefulWidget {
  const TimeRangePicker({
    super.key,
    required this.onRange,
    required this.from,
    required this.to,
  });

  final RangeCallback onRange;
  final DateTime from;
  final DateTime to;

  @override
  State<TimeRangePicker> createState() => _TimeRangePickerState();
}

class _TimeRangePickerState extends State<TimeRangePicker> {
  static const _presets = [
    _Preset('Last 15 minutes', Duration(minutes: 15)),
    _Preset('Last 1 hour', Duration(hours: 1)),
    _Preset('Last 6 hours', Duration(hours: 6)),
    _Preset('Last 24 hours', Duration(hours: 24)),
    _Preset('Last 3 days', Duration(days: 3)),
    _Preset('Last 7 days', Duration(days: 7)),
  ];

  final _link = LayerLink();
  OverlayEntry? _overlay;

  int _matchPreset(DateTime from, DateTime to) {
    final span = to.difference(from);
    for (int i = 0; i < _presets.length; i++) {
      if ((span - _presets[i].duration).abs() < const Duration(seconds: 5)) {
        return i;
      }
    }
    return -1;
  }

  String _label() {
    final idx = _matchPreset(widget.from, widget.to);
    if (idx >= 0) return _presets[idx].label;
    final f = widget.from.toLocal();
    final t = widget.to.toLocal();
    return '${_fmtShort(f)} – ${_fmtShort(t)}';
  }

  static String _fmtShort(DateTime dt) =>
      '${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')} '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  void _applyPreset(int index) {
    final now = DateTime.now().toUtc();
    widget.onRange(now.subtract(_presets[index].duration), now);
    _close();
  }

  void _applyCustom(DateTime from, DateTime to) {
    widget.onRange(from, to);
    _close();
  }

  void _toggle() {
    if (_overlay != null) {
      _close();
    } else {
      _open();
    }
  }

  void _open() {
    if (!mounted) return;
    final activeIndex = _matchPreset(widget.from, widget.to);
    _overlay = OverlayEntry(
      builder: (_) => _DropdownOverlay(
        link: _link,
        presets: _presets,
        activeIndex: activeIndex,
        onPreset: _applyPreset,
        onCustom: _applyCustom,
        onDismiss: _close,
      ),
    );
    Overlay.of(context).insert(_overlay!);
    setState(() {});
  }

  void _close() {
    _overlay?.remove();
    _overlay = null;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _overlay?.remove();
    _overlay = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final open = _overlay != null;
    return CompositedTransformTarget(
      link: _link,
      child: _TriggerButton(
        label: _label(),
        open: open,
        onTap: _toggle,
      ),
    );
  }
}

// ── Trigger button ────────────────────────────────────────────────────────────

class _TriggerButton extends StatelessWidget {
  const _TriggerButton(
      {required this.label, required this.open, required this.onTap});

  final String label;
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppLayout.radius),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppLayout.cellPaddingH, vertical: 7),
        decoration: BoxDecoration(
          color: open
              ? Colors.white.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(AppLayout.radius),
          border: Border.all(
            color: open
                ? Colors.white.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.schedule,
                size: AppIcons.sizeS, color: Colors.white.withValues(alpha: 0.7)),
            const SizedBox(width: AppLayout.gapM - 2),
            Text(label, style: AppText.label.copyWith(color: Colors.white)),
            const SizedBox(width: AppLayout.gapM - 2),
            Icon(
              open ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              size: AppIcons.sizeS,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Dropdown overlay ──────────────────────────────────────────────────────────

class _DropdownOverlay extends StatelessWidget {
  const _DropdownOverlay({
    required this.link,
    required this.presets,
    required this.activeIndex,
    required this.onPreset,
    required this.onCustom,
    required this.onDismiss,
  });

  final LayerLink link;
  final List<_Preset> presets;
  final int activeIndex;
  final void Function(int) onPreset;
  final void Function(DateTime, DateTime) onCustom;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: onDismiss,
          ),
        ),
        CompositedTransformFollower(
          link: link,
          showWhenUnlinked: false,
          offset: const Offset(0, 36),
          targetAnchor: Alignment.topRight,
          followerAnchor: Alignment.topRight,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(AppLayout.radius + 2),
            child: Container(
              width: 480,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppLayout.radius + 2),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PresetList(
                    presets: presets,
                    activeIndex: activeIndex,
                    onSelect: onPreset,
                  ),
                  const VerticalDivider(width: 1, color: AppColors.border),
                  Expanded(
                    child: CustomRangeForm(onApply: onCustom),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Preset list (left column) ─────────────────────────────────────────────────

class _PresetList extends StatelessWidget {
  const _PresetList(
      {required this.presets, required this.activeIndex, required this.onSelect});

  final List<_Preset> presets;
  final int activeIndex;
  final void Function(int) onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppLayout.cellPaddingH,
              AppLayout.cellPaddingV + 4,
              AppLayout.cellPaddingH,
              AppLayout.gapM - 2,
            ),
            child: Text('Suggested',
                style: AppText.label.copyWith(color: AppColors.textMuted)),
          ),
          for (int i = 0; i < presets.length; i++)
            _PresetRow(
              label: presets[i].label,
              active: activeIndex == i,
              onTap: () => onSelect(i),
            ),
          const SizedBox(height: AppLayout.gapM),
        ],
      ),
    );
  }
}

class _PresetRow extends StatelessWidget {
  const _PresetRow(
      {required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: AppLayout.headerPadding,
        color: active ? AppColors.rowSelected : null,
        child: Text(
          label,
          style: AppText.body.copyWith(
            color: active ? AppColors.primary : AppColors.textBody,
            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ── Data ─────────────────────────────────────────────────────────────────────

class _Preset {
  const _Preset(this.label, this.duration);
  final String label;
  final Duration duration;
}
