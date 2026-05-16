import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'logs_controller.dart';

const double _colPad = 16.0;
const double _settingsReserved = AppIcons.sizeM + AppLayout.gapS * 2 + 32.0;
const int _sampleLimit = 50;

double _measureText(String text, TextStyle style) {
  final tp = TextPainter(
    text: TextSpan(text: text, style: style),
    maxLines: 1,
    textDirection: TextDirection.ltr,
  )..layout();
  return tp.width;
}

double _naturalWidth(LogColumn col, List<dynamic> sample) {
  final labelW = _measureText(col.label, AppText.label);
  final dataW = col.fixedSample != null
      ? _measureText(col.fixedSample!, AppText.mono)
      : sample.fold(0.0, (max, row) {
          final w = _measureText(col.getValue(row), AppText.mono);
          return w > max ? w : max;
        });
  return (labelW > dataW ? labelW : dataW) + _colPad;
}

List<double> _scaleToFit(
    List<LogColumn> columns, List<double> natural, double usable) {
  final scale = usable / natural.fold(0.0, (s, w) => s + w);
  return [
    for (int i = 0; i < columns.length; i++)
      columns[i].stretchy == true ? 0.0 : (natural[i] * scale).floorToDouble(),
  ];
}

List<double> _distributeStretch(
  List<LogColumn> columns,
  List<double> natural,
  double usable,
  int stretchCount,
  double fixedTotal,
) {
  final stretchWidth =
      ((usable - fixedTotal) / stretchCount).clamp(60.0, double.infinity);
  final result = [
    for (int i = 0; i < columns.length; i++)
      columns[i].stretchy == true ? stretchWidth : natural[i],
  ];
  final total = result.fold(0.0, (s, w) => s + w);
  if (total <= usable) return result;
  final adjusted =
      (stretchWidth - (total - usable) / stretchCount).clamp(60.0, double.infinity);
  return [
    for (int i = 0; i < columns.length; i++)
      columns[i].stretchy == true ? adjusted : natural[i],
  ];
}

/// Computes pixel widths for [columns] given [available] width and current [rows].
List<double> computeColumnWidths(
  List<LogColumn> columns,
  double available,
  List<dynamic> rows,
) {
  if (available <= 0 || columns.isEmpty) {
    return List.filled(columns.length, 0);
  }
  final usable =
      (available - _settingsReserved - (columns.length - 1) * AppLayout.gapM)
          .clamp(0.0, double.infinity);
  final sample =
      rows.length > _sampleLimit ? rows.sublist(0, _sampleLimit) : rows;

  double fixedTotal = 0;
  int stretchCount = 0;
  final natural = <double>[];

  for (final col in columns) {
    if (col.stretchy == true) {
      natural.add(0);
      stretchCount++;
    } else {
      final w = _naturalWidth(col, sample);
      natural.add(w);
      fixedTotal += w;
    }
  }

  if (fixedTotal >= usable) return _scaleToFit(columns, natural, usable);
  if (stretchCount > 0) {
    return _distributeStretch(
        columns, natural, usable, stretchCount, fixedTotal);
  }
  return natural;
}
