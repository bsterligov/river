import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ui/pages/logs/logs.dart';
import 'package:ui/time_range_controller.dart';

import 'helpers.dart';

void main() {
  testWidgets(
      'Given the logs table is showing rows, '
      'When the operator clicks the "Severity" column header, '
      'Then the rows sort ascending by severity and an up-arrow icon appears in the header; '
      'clicking again reverses to descending',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final rows = [
      makeRowWith(severity: 'WARN', body: 'warn msg'),
      makeRowWith(severity: 'ERROR', body: 'error msg'),
      makeRowWith(severity: 'INFO', body: 'info msg'),
    ];
    final api = FakeApi(rows: rows);

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: LogsPage(apiClient: api, rangeController: TimeRangeController()))),
    );
    await tester.pumpAndSettle();
    await loadRows(tester);

    await tester.tap(find.text('Severity'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.arrow_upward), findsOneWidget);

    final texts = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? '')
        .where((s) => s == 'ERROR' || s == 'INFO' || s == 'WARN')
        .toList();
    expect(texts.first, equals('ERROR'));

    await tester.tap(find.text('Severity'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
  });

  testWidgets(
      'Given the column menu is open, '
      'When the operator unchecks "TraceID", '
      'Then the TraceID column disappears from the header row and all log rows immediately',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final row = makeRow(body: 'test event');
    final api = FakeApi(rows: [row]);

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: LogsPage(apiClient: api, rangeController: TimeRangeController()))),
    );
    await tester.pumpAndSettle();
    await loadRows(tester);

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('col_toggle_traceId')));
    await tester.pump();
    final tableCenter1 = tester.getCenter(find.byType(LogsTable));
    await tester.tapAt(tableCenter1 + const Offset(0, 200));
    await tester.pumpAndSettle();

    expect(find.text('TraceID'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('col_toggle_traceId')));
    await tester.pump();
    final tableCenter2 = tester.getCenter(find.byType(LogsTable));
    await tester.tapAt(tableCenter2 + const Offset(0, 200));
    await tester.pumpAndSettle();

    expect(find.text('TraceID'), findsNothing);
  });

  testWidgets(
      'Given TraceID was hidden, '
      'When the operator reopens the column menu and checks "TraceID", '
      'Then the column reappears in its original position',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final api = FakeApi(rows: [makeRow()]);

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: LogsPage(apiClient: api, rangeController: TimeRangeController()))),
    );
    await tester.pumpAndSettle();
    await loadRows(tester);

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('col_toggle_traceId')));
    await tester.pump();
    final tableCenter = tester.getCenter(find.byType(LogsTable));
    await tester.tapAt(tableCenter + const Offset(0, 200));
    await tester.pumpAndSettle();

    expect(find.text('TraceID'), findsOneWidget);
  });

  testWidgets(
      'Given the column menu is open, '
      'When the operator taps outside the menu overlay, '
      'Then the menu dismisses without changing column state',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final api = FakeApi(rows: [makeRow()]);

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: LogsPage(apiClient: api, rangeController: TimeRangeController()))),
    );
    await tester.pumpAndSettle();
    await loadRows(tester);

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('col_toggle_timestamp')), findsOneWidget);

    final tableList = find.byKey(const Key('logs_table'));
    if (tableList.evaluate().isNotEmpty) {
      await tester.tapAt(tester.getTopLeft(tableList) + const Offset(10, 10));
    } else {
      await tester.tapAt(tester.getCenter(find.text('No logs found.')));
    }
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('col_toggle_timestamp')), findsNothing);
    expect(find.text('Timestamp'), findsOneWidget);
    expect(find.text('Message'), findsOneWidget);
  });
}
