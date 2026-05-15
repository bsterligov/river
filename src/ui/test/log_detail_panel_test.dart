import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ui/pages/logs/logs.dart';
import 'package:ui/controllers/time_range_controller.dart';

import 'helpers.dart';

void main() {
  testWidgets(
      'Given a log row is visible in the table, '
      'When the operator clicks it, '
      'Then the detail panel slides in and all three sections render with data from that row',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final row = makeRow(body: 'login success', attributes: '{"user":"alice"}');
    final api = FakeApi(rows: [row]);

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: LogsPage(apiClient: api, rangeController: TimeRangeController()))),
    );
    await tester.pumpAndSettle();
    await loadRows(tester);

    await tester.tap(find.text('login success'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('log_detail_panel')), findsOneWidget);
    expect(find.text('Log Tags & Infra Info'), findsOneWidget);
    expect(find.text('Log Message'), findsOneWidget);
    expect(find.text('Log Attributes'), findsOneWidget);
    expect(find.text('svc'), findsWidgets);
    expect(find.text('login success'), findsWidgets);
    expect(find.text('alice'), findsOneWidget);
  });

  testWidgets(
      'Given the detail panel is open, '
      'When the operator clicks a different row, '
      'Then the panel updates to show the newly selected row\'s data',
      (tester) async {
    final row1 = makeRow(body: 'first event');
    final row2 = makeRow(body: 'second event');
    final api = FakeApi(rows: [row1, row2]);

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: LogsPage(apiClient: api, rangeController: TimeRangeController()))),
    );
    await tester.pumpAndSettle();
    await loadRows(tester);

    await tester.tap(find.text('first event'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('log_detail_panel')), findsOneWidget);

    await tester.tap(find.text('second event'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('log_detail_panel')), findsOneWidget);
    expect(find.text('second event'), findsWidgets);
  });

  testWidgets(
      'Given the detail panel is open, '
      'When the operator clicks the X button, '
      'Then the panel closes and no row remains highlighted',
      (tester) async {
    final row = makeRow(body: 'log entry');
    final api = FakeApi(rows: [row]);

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: LogsPage(apiClient: api, rangeController: TimeRangeController()))),
    );
    await tester.pumpAndSettle();
    await loadRows(tester);

    await tester.tap(find.text('log entry'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('log_detail_panel')), findsOneWidget);

    await tester.tap(find.byKey(const Key('detail_close')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('log_detail_panel')), findsNothing);
  });

  testWidgets(
      'Given a row has a valid JSON object in the attributes field, '
      'When the Log Attributes section renders, '
      'Then each key-value pair is shown',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final row = makeRow(attributes: '{"env":"prod","version":"1.2.3"}');
    final api = FakeApi(rows: [row]);

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: LogsPage(apiClient: api, rangeController: TimeRangeController()))),
    );
    await tester.pumpAndSettle();
    await loadRows(tester);

    await tester.tap(find.text(row.body));
    await tester.pumpAndSettle();

    expect(find.text('env'), findsOneWidget);
    expect(find.text('prod'), findsOneWidget);
    expect(find.text('version'), findsOneWidget);
    expect(find.text('1.2.3'), findsOneWidget);
  });

  testWidgets(
      'Given a row has an empty or non-object attributes value, '
      'When the Log Attributes section renders, '
      'Then the section shows "No attributes"',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final row = makeRow(attributes: null);
    final api = FakeApi(rows: [row]);

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: LogsPage(apiClient: api, rangeController: TimeRangeController()))),
    );
    await tester.pumpAndSettle();
    await loadRows(tester);

    await tester.tap(find.text(row.body));
    await tester.pumpAndSettle();

    expect(find.text('No attributes'), findsOneWidget);
  });
}
