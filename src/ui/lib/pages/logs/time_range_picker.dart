import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';

typedef RangeCallback = void Function(DateTime from, DateTime to);

class TimeRangePicker extends StatefulWidget {
  const TimeRangePicker({super.key, required this.onRange});

  final RangeCallback onRange;

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

  int _activeIndex = 1;
  final _link = LayerLink();
  OverlayEntry? _overlay;

  String get _activeLabel => _activeIndex >= 0 ? _presets[_activeIndex].label : 'Custom';

  void _applyPreset(int index) {
    final now = DateTime.now().toUtc();
    widget.onRange(now.subtract(_presets[index].duration), now);
    setState(() => _activeIndex = index);
    _close();
  }

  void _applyCustom(DateTime from, DateTime to) {
    widget.onRange(from, to);
    setState(() => _activeIndex = -1);
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
    _overlay = OverlayEntry(
      builder: (_) => _DropdownOverlay(
        link: _link,
        presets: _presets,
        activeIndex: _activeIndex,
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
        label: _activeLabel,
        open: open,
        onTap: _toggle,
      ),
    );
  }
}

// ── Trigger button ────────────────────────────────────────────────────────────

class _TriggerButton extends StatelessWidget {
  const _TriggerButton({required this.label, required this.open, required this.onTap});

  final String label;
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: open ? AppColors.primary : AppColors.border,
            width: open ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.schedule, size: 14, color: Colors.black54),
            const SizedBox(width: 6),
            Text(label, style: AppText.label),
            const SizedBox(width: 6),
            Icon(
              open ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              size: 14,
              color: Colors.black54,
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
        // Tap-outside dismissal
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
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 480,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
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
                  VerticalDivider(width: 1, color: AppColors.border),
                  Expanded(
                    child: _CustomForm(onApply: onCustom),
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
  const _PresetList({required this.presets, required this.activeIndex, required this.onSelect});

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
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Text('Suggested', style: AppText.label.copyWith(color: Colors.black45)),
          ),
          for (int i = 0; i < presets.length; i++)
            _PresetRow(
              label: presets[i].label,
              active: activeIndex == i,
              onTap: () => onSelect(i),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _PresetRow extends StatelessWidget {
  const _PresetRow({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        color: active ? AppColors.primary.withValues(alpha: 0.08) : null,
        child: Text(
          label,
          style: AppText.body.copyWith(
            color: active ? AppColors.primary : Colors.black87,
            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ── Custom date/time form (right column) ──────────────────────────────────────

class _CustomForm extends StatefulWidget {
  const _CustomForm({required this.onApply});

  final void Function(DateTime from, DateTime to) onApply;

  @override
  State<_CustomForm> createState() => _CustomFormState();
}

class _CustomFormState extends State<_CustomForm> {
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  String? _error;

  static final _fmt = RegExp(
    r'^\d{4}-\d{2}-\d{2} \d{2}:\d{2}$',
  );

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final from = now.subtract(const Duration(hours: 1));
    _fromController.text = _format(from);
    _toController.text = _format(now);
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  String _format(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-'
      '${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')} '
      '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}';

  DateTime? _parse(String s) {
    if (!_fmt.hasMatch(s)) return null;
    try {
      final parts = s.split(' ');
      final d = parts[0].split('-');
      final t = parts[1].split(':');
      return DateTime(
        int.parse(d[0]), int.parse(d[1]), int.parse(d[2]),
        int.parse(t[0]), int.parse(t[1]),
      );
    } catch (_) {
      return null;
    }
  }

  void _apply() {
    final from = _parse(_fromController.text);
    final to = _parse(_toController.text);
    if (from == null || to == null) {
      setState(() => _error = 'Use format: YYYY-MM-DD HH:MM');
      return;
    }
    if (!to.isAfter(from)) {
      setState(() => _error = '"To" must be after "From"');
      return;
    }
    widget.onApply(from.toUtc(), to.toUtc());
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Custom range', style: AppText.label),
          const SizedBox(height: 12),
          _DateField(label: 'From', controller: _fromController),
          const SizedBox(height: 8),
          _DateField(label: 'To', controller: _toController),
          if (_error != null) ...[
            const SizedBox(height: 6),
            Text(_error!, style: AppText.label.copyWith(color: AppColors.error)),
          ],
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _apply,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              elevation: 0,
            ),
            child: const Text('Apply', style: AppText.label),
          ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: AppText.label.copyWith(color: Colors.black54)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          style: AppText.mono,
          decoration: const InputDecoration(
            hintText: 'YYYY-MM-DD HH:MM',
            isDense: true,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d\- :]')),
            LengthLimitingTextInputFormatter(16),
          ],
        ),
      ],
    );
  }
}

// ── Data ─────────────────────────────────────────────────────────────────────

class _Preset {
  const _Preset(this.label, this.duration);
  final String label;
  final Duration duration;
}
