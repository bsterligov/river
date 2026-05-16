import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class RiverSearchBar extends StatelessWidget {
  const RiverSearchBar({
    super.key,
    required this.fieldKey,
    required this.controller,
    required this.onSubmit,
    required this.hintText,
    this.errorText,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final void Function(String) onSubmit;
  final String hintText;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          key: fieldKey,
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: const Icon(Icons.search, size: AppIcons.sizeL),
            errorText: errorText,
          ),
          onSubmitted: onSubmit,
          style: AppText.mono,
        ),
      ],
    );
  }
}
