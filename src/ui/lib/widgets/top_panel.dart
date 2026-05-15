import 'package:flutter/material.dart';

import 'time_range_picker.dart';
import '../theme/app_theme.dart';
import '../time_range_controller.dart';

class TopPanel extends StatelessWidget {
  const TopPanel({super.key, required this.rangeController});

  final TimeRangeController rangeController;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppLayout.gapXL),
      child: Row(
        children: [
          Text(
            'River',
            style: AppText.appTitle.copyWith(color: AppColors.primary),
          ),
          const Spacer(),
          ListenableBuilder(
            listenable: rangeController,
            builder: (context, _) => TimeRangePicker(
              from: rangeController.from,
              to: rangeController.to,
              onRange: rangeController.setRange,
            ),
          ),
        ],
      ),
    );
  }
}
