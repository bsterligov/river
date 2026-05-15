import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

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

  // Returns the preset index whose duration matches from→to within 5s, or -1.
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
  const _TriggerButton({required this.label, required this.open, required this.onTap});

  final String label;
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppLayout.radius),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppLayout.cellPaddingH, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppLayout.radius),
          border: Border.all(
            color: open ? AppColors.primary : AppColors.border,
            width: open ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.schedule, size: AppIcons.sizeS, color: Colors.black54),
            const SizedBox(width: AppLayout.gapM - 2),
            Text(label, style: AppText.label),
            const SizedBox(width: AppLayout.gapM - 2),
            Icon(
              open ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              size: AppIcons.sizeS,
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
            padding: const EdgeInsets.fromLTRB(
              AppLayout.cellPaddingH,
              AppLayout.cellPaddingV + 4,
              AppLayout.cellPaddingH,
              AppLayout.gapM - 2,
            ),
            child: Text('Suggested', style: AppText.label.copyWith(color: Colors.black45)),
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
  const _PresetRow({required this.label, required this.active, required this.onTap});

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
      padding: const EdgeInsets.all(AppLayout.gapXL),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Custom range', style: AppText.label),
          const SizedBox(height: AppLayout.gapL),
          _DateField(label: 'From', controller: _fromController),
          const SizedBox(height: AppLayout.gapM),
          _DateField(label: 'To', controller: _toController),
          if (_error != null) ...[
            const SizedBox(height: AppLayout.gapM - 2),
            Text(_error!, style: AppText.label.copyWith(color: AppColors.error)),
          ],
          const SizedBox(height: AppLayout.gapL),
          ElevatedButton(
            onPressed: _apply,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: AppLayout.cellPaddingV + 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppLayout.radius),
              ),
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
        const SizedBox(height: AppLayout.gapS),
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
