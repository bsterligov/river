import 'package:flutter/material.dart';

abstract final class AppColors {
  static const surface = Color(0xFFF8F9FA);
  static const topPanel = Color(0xFF1E2029);
  static const sidebar = Color(0xFF2C3A5C);
  static const sidebarText = Color(0xFFB0B8C4);
  static const sidebarSelected = Color(0xFFFFFFFF);
  static const sidebarSelectedBg = Color(0xFF3D5080);
  static const primary = Color(0xFF4F74E8);
  static const border = Color(0xFFE2E8F0);
  static const tableHeader = Color(0xFFF1F3F5);
  static const error = Color(0xFFE53E3E);
  static const rowSelected = Color(0x144F74E8); // primary @ 8%
  static const shimmer = Color(0xFFE0E0E0);
  static const shadow = Color(0x1A000000); // black @ 10%
}

abstract final class AppText {
  static const body = TextStyle(fontSize: 13, height: 1.5);
  static const label = TextStyle(fontSize: 12, fontWeight: FontWeight.w500);
  static const mono = TextStyle(fontSize: 12, fontFamily: 'monospace');
  static const micro = TextStyle(fontSize: 9);
  static const appTitle = TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5);
  static const navItem = TextStyle(fontSize: 13);
}

abstract final class AppLayout {
  // Border radius used on cards, panels, and inputs
  static const radius = 6.0;
  static const radiusBadge = 10.0;

  // Gaps between major layout sections
  static const gapS = 4.0;
  static const gapM = 8.0;
  static const gapL = 12.0;
  static const gapXL = 16.0;

  // Panel widths
  static const facetPanelWidth = 220.0;
  static const detailPanelWidth = 420.0;
  static const traceDetailPanelWidth = 560.0;
  static const detailLabelWidth = 130.0;

  // Cell / tile padding
  static const cellPaddingH = 12.0;
  static const cellPaddingV = 6.0;
  static const tilePadding = EdgeInsets.symmetric(horizontal: cellPaddingH);
  static const cellPadding = EdgeInsets.symmetric(
    horizontal: cellPaddingH,
    vertical: cellPaddingV,
  );
  static const sectionPadding = EdgeInsets.symmetric(
    horizontal: gapXL,
    vertical: gapM,
  );
  static const headerPadding = EdgeInsets.symmetric(
    horizontal: cellPaddingH,
    vertical: gapM,
  );
}

abstract final class AppIcons {
  static const sizeS = 14.0;
  static const sizeM = 16.0;
  static const sizeL = 18.0;
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
