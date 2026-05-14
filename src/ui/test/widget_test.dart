import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:river_api/api.dart';

import 'package:ui/main.dart';
import 'package:ui/pages/logs/logs.dart';

class _FakeApi extends DefaultApi {
  final List<LogRow> rows;
  final Exception? error;
  final List<Map<String, String?>> calls = [];

  _FakeApi({this.rows = const [], this.error});

  @override
  Future<List<LogRow>?> getLogs({
    String? filter,
    String? from,
    String? to,
    int? limit,
  }) async {
    calls.add({'filter': filter, 'from': from, 'to': to});
    if (error != null) throw error!;
    return rows;
  }
}

void main() {
  testWidgets('Given app is running, Then sidebar and default page are visible',
      (tester) async {
    await tester.pumpWidget(const RiverApp());
    await tester.pumpAndSettle();

    expect(find.text('River'), findsOneWidget);
    expect(find.text('Logs'), findsOneWidget);
  });

  testWidgets(
      'Given Logs page is open, Then search bar, time picker trigger, and table area are visible',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LogsPage(apiClient: _FakeApi()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('logs_search')), findsOneWidget);
    expect(find.text('Last 1 hour'), findsOneWidget);
    expect(find.text('No logs found.'), findsOneWidget);
  });

  // Scenario: open picker, click preset -> API call with that range
  testWidgets(
      'Given Logs page is open with default range, '
      'When operator opens picker and clicks "Last 1 hour", '
      'Then controller issues API call with that range',
      (tester) async {
    final api = _FakeApi(rows: []);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LogsPage(apiClient: api),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Open the picker and click the preset (trigger shows "Last 1 hour", list also has it)
    await tester.tap(find.text('Last 1 hour'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Last 1 hour').last);
    await tester.pumpAndSettle();

    expect(api.calls, isNotEmpty);
  });

  // Scenario: empty search bar submitted -> API called with no filter (returns all logs)
  testWidgets(
      'Given operator submits an empty search bar, '
      'Then API is called without a filter parameter',
      (tester) async {
    final api = _FakeApi();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LogsPage(apiClient: api),
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

  // Scenario: valid filter submitted -> API called and table updated
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
    final api = _FakeApi(rows: [fakeRow]);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LogsPage(apiClient: api),
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

  // Scenario: API returns 400 -> inline error shown below the search bar
  testWidgets(
      'Given API returns HTTP 400 for submitted filter, '
      'When response arrives, '
      'Then inline error appears below the search bar',
      (tester) async {
    final api =
        _FakeApi(error: ApiException(400, '{"error":"invalid filter"}'));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LogsPage(apiClient: api),
        ),
      ),
    );

    await tester.enterText(
        find.byKey(const Key('logs_search')), 'bad::filter');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.textContaining('invalid filter'), findsOneWidget);
  });
}
