import 'package:flutter/material.dart';

import 'river_logo.dart';
import 'time_range_picker.dart';
import '../theme/app_theme.dart';
import '../controllers/time_range_controller.dart';

class TopPanel extends StatelessWidget {
  const TopPanel({
    super.key,
    required this.rangeController,
    this.tabs,
  });

  final TimeRangeController rangeController;

  /// Optional tab bar surfaced between the title and the time range picker.
  /// Only supplied by pages that use sub-tabs (e.g. MetricsPage).
  final Widget? tabs;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: const BoxDecoration(
        color: AppColors.topPanel,
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppLayout.gapXL),
      child: Row(
        children: [
          const RiverLogo(),
          const SizedBox(width: AppLayout.gapM),
          Text(
            'River',
            style: AppText.appTitle.copyWith(color: Colors.white),
          ),
          if (tabs != null) ...[
            const SizedBox(width: AppLayout.gapXL),
            tabs!,
          ],
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
