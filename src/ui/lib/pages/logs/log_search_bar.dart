import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class LogSearchBar extends StatelessWidget {
  const LogSearchBar({
    super.key,
    required this.controller,
    required this.onSubmit,
    this.errorText,
  });

  final TextEditingController controller;
  final void Function(String) onSubmit;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          key: const Key('logs_search'),
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Filter (e.g. service:myapp AND severity:ERROR)',
            prefixIcon: const Icon(Icons.search, size: 18),
            errorText: errorText,
          ),
          onSubmitted: onSubmit,
          style: AppText.mono,
        ),
      ],
    );
  }
}
