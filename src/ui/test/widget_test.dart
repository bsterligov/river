import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:river_api/api.dart';

import 'package:ui/main.dart';
import 'package:ui/pages/logs_page.dart';

class _FakeApi extends DefaultApi {
  final List<LogRow> rows;
  final Exception? error;

  _FakeApi({this.rows = const [], this.error});

  @override
  Future<List<LogRow>?> getLogs({
    String? filter,
    String? from,
    String? to,
    int? limit,
  }) async {
    if (error != null) throw error!;
    return rows;
  }
}

void main() {
  // Scenario: app launches and shows navigation panel
  testWidgets('Given app is running, Then sidebar and default page are visible',
      (tester) async {
    await tester.pumpWidget(const RiverApp());
    await tester.pumpAndSettle();

    expect(find.text('River'), findsOneWidget);
    expect(find.text('Logs'), findsOneWidget);
  });

  // Scenario: Logs page shows search bar and empty table message
  testWidgets(
      'Given I am on the Logs page, Then I see a search bar and logs table area',
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
    expect(find.text('No logs found.'), findsOneWidget);
  });

  // Scenario: search returns rows displayed in table
  testWidgets('Given stub rows, When search submitted, Then table shows entries',
      (tester) async {
    final fakeRow = LogRow(
      timestamp: '2024-01-01T00:00:00Z',
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

    await tester.enterText(
        find.byKey(const Key('logs_search')), 'service:svc');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('logs_table')), findsOneWidget);
    expect(find.text('hello world'), findsOneWidget);
  });

  // Scenario: API error is surfaced in the UI
  testWidgets('Given an API error, When search submitted, Then error is shown',
      (tester) async {
    final api = _FakeApi(error: Exception('connection refused'));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LogsPage(apiClient: api),
        ),
      ),
    );

    await tester.enterText(
        find.byKey(const Key('logs_search')), 'service:svc');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.textContaining('connection refused'), findsOneWidget);
  });
}
