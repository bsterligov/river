import 'package:flutter/material.dart';

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
    _Preset('Last 15m', Duration(minutes: 15)),
    _Preset('Last 1h', Duration(hours: 1)),
    _Preset('Last 6h', Duration(hours: 6)),
    _Preset('Last 24h', Duration(hours: 24)),
    _Preset('Last 3d', Duration(days: 3)),
    _Preset('Last 7d', Duration(days: 7)),
  ];

  int _activeIndex = 1;

  void _applyPreset(int index) {
    setState(() => _activeIndex = index);
    final now = DateTime.now().toUtc();
    widget.onRange(now.subtract(_presets[index].duration), now);
  }

  Future<void> _pickCustom() async {
    final now = DateTime.now();
    final fromDate = await showDatePicker(
      context: context,
      initialDate: now.subtract(const Duration(hours: 1)),
      firstDate: DateTime(2020),
      lastDate: now,
    );
    if (fromDate == null || !mounted) return;
    final fromTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.subtract(const Duration(hours: 1))),
    );
    if (fromTime == null || !mounted) return;
    final toDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: fromDate,
      lastDate: now,
    );
    if (toDate == null || !mounted) return;
    final toTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
    );
    if (toTime == null || !mounted) return;

    final from = DateTime(
      fromDate.year, fromDate.month, fromDate.day,
      fromTime.hour, fromTime.minute,
    ).toUtc();
    final to = DateTime(
      toDate.year, toDate.month, toDate.day,
      toTime.hour, toTime.minute,
    ).toUtc();

    setState(() => _activeIndex = -1);
    widget.onRange(from, to);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < _presets.length; i++)
            _PresetButton(
              label: _presets[i].label,
              active: _activeIndex == i,
              onTap: () => _applyPreset(i),
            ),
          _PresetButton(
            label: 'Custom',
            active: _activeIndex == -1,
            onTap: _pickCustom,
          ),
        ],
      ),
    );
  }
}

class _PresetButton extends StatelessWidget {
  const _PresetButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: active ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: AppText.label.copyWith(
              color: active ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}

class _Preset {
  const _Preset(this.label, this.duration);
  final String label;
  final Duration duration;
}
