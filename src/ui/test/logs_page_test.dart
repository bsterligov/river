import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:river_api/api.dart';

import 'package:ui/pages/logs/logs.dart';
import 'package:ui/time_range_controller.dart';

import 'helpers.dart';

void main() {
  testWidgets(
      'Given Logs page is open, '
      'Then search bar, time picker trigger, and table area are visible',
      (tester) async {
    final rc = TimeRangeController();
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: TestShell(api: FakeApi(), rangeController: rc))),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('logs_search')), findsOneWidget);
    expect(find.text('Last 1 hour'), findsOneWidget);
    expect(find.text('No logs found.'), findsOneWidget);
  });

  testWidgets(
      'Given Logs page is open with default range, '
      'When operator opens picker and clicks "Last 1 hour", '
      'Then controller issues API call with that range',
      (tester) async {
    final api = FakeApi(rows: []);
    final rc = TimeRangeController();

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: TestShell(api: api, rangeController: rc))),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Last 1 hour'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Last 1 hour').last);
    await tester.pumpAndSettle();

    expect(api.calls, isNotEmpty);
  });

  testWidgets(
      'Given operator submits an empty search bar, '
      'Then API is called without a filter parameter',
      (tester) async {
    final api = FakeApi();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LogsPage(apiClient: api, rangeController: TimeRangeController()),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('logs_search')));
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(api.calls, isNotEmpty);
    expect(api.calls.last['filter'], isNull);
  });

  testWidgets(
      'Given Logs page is open, '
      'When operator types a valid filter and presses Enter, '
      'Then LogsController issues /v1/logs with filter= and table updates',
      (tester) async {
    final fakeRow = LogRow(
      timestamp: '2024-01-01T00:00:00Z',
      severityNumber: 9,
      spanId: '',
      attributes: null,
      severity: 'INFO',
      service: 'svc',
      body: 'hello world',
      traceId: '',
    );
    final api = FakeApi(rows: [fakeRow]);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LogsPage(apiClient: api, rangeController: TimeRangeController()),
        ),
      ),
    );

    await tester.enterText(find.byKey(const Key('logs_search')), 'service:svc');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('logs_table')), findsOneWidget);
    expect(find.text('hello world'), findsOneWidget);
    expect(api.calls.last['filter'], equals('service:svc'));
  });

  testWidgets(
      'Given API returns HTTP 400 for submitted filter, '
      'When response arrives, '
      'Then inline error appears below the search bar',
      (tester) async {
    final api = FakeApi(error: ApiException(400, '{"error":"invalid filter"}'));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LogsPage(apiClient: api, rangeController: TimeRangeController()),
        ),
      ),
    );

    await tester.enterText(find.byKey(const Key('logs_search')), 'bad::filter');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.textContaining('invalid filter'), findsOneWidget);
  });
}
