import 'package:flutter/material.dart';

abstract final class AppColors {
  static const surface = Color(0xFFF8F9FA);
  static const sidebar = Color(0xFF1E2029);
  static const sidebarText = Color(0xFFB0B8C4);
  static const sidebarSelected = Color(0xFFFFFFFF);
  static const sidebarSelectedBg = Color(0xFF2D3142);
  static const primary = Color(0xFF4F74E8);
  static const border = Color(0xFFE2E8F0);
  static const tableHeader = Color(0xFFF1F3F5);
  static const error = Color(0xFFE53E3E);
}

abstract final class AppText {
  static const body = TextStyle(fontSize: 13, height: 1.5);
  static const label = TextStyle(fontSize: 12, fontWeight: FontWeight.w500);
  static const mono = TextStyle(fontSize: 12, fontFamily: 'monospace');
}

final appTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    surface: AppColors.surface,
  ),
  scaffoldBackgroundColor: AppColors.surface,
  dividerColor: AppColors.border,
  textTheme: const TextTheme(
    bodyMedium: AppText.body,
    labelMedium: AppText.label,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
    ),
  ),
);
