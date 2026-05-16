import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class KvRow extends StatelessWidget {
  const KvRow({super.key, required this.k, required this.v});

  final String k;
  final String v;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppLayout.sectionPadding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: AppLayout.detailLabelWidth,
            child: Text(k, style: AppText.label),
          ),
          Expanded(child: SelectableText(v, style: AppText.mono)),
        ],
      ),
    );
  }
}
