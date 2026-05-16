import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

class CustomRangeForm extends StatefulWidget {
  const CustomRangeForm({super.key, required this.onApply});

  final void Function(DateTime from, DateTime to) onApply;

  @override
  State<CustomRangeForm> createState() => _CustomRangeFormState();
}

class _CustomRangeFormState extends State<CustomRangeForm> {
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  String? _error;

  static final _fmt = RegExp(r'^\d{4}-\d{2}-\d{2} \d{2}:\d{2}$');

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
              padding: const EdgeInsets.symmetric(
                  vertical: AppLayout.cellPaddingV + 4),
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
        Text(label,
            style: AppText.label.copyWith(color: AppColors.textMuted)),
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
