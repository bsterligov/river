import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:river_api/api.dart';

import 'package:ui/main.dart';
import 'package:ui/pages/logs/logs.dart';

class _FakeApi extends DefaultApi {
  final List<LogRow> rows;
  final Exception? error;
  final List<Map<String, String?>> calls = [];
  List<FacetField> facets;
  Exception? facetError;

  _FakeApi({this.rows = const [], this.error, this.facets = const [], this.facetError});

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

  @override
  Future<List<FacetField>?> getLogsFacets({
    String? filter,
    String? from,
    String? to,
  }) async {
    if (facetError != null) throw facetError!;
    return facets;
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

  // --- FacetPanel BDD scenarios ---

  testWidgets(
      'Given the logs page is open and the API returns facets for service_name and severity_text, '
      'When the facet panel finishes loading, '
      'Then two ExpansionTile groups are visible, each expanded, showing value rows with counts',
      (tester) async {
    final api = _FakeApi(
      facets: [
        FacetField(
          field: 'service_name',
          values: [FacetValue(value: 'svc-a', count: 42)],
        ),
        FacetField(
          field: 'severity_text',
          values: [FacetValue(value: 'ERROR', count: 7)],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: LogsPage(apiClient: api))),
    );
    await tester.pumpAndSettle();

    expect(find.text('service_name'), findsOneWidget);
    expect(find.text('severity_text'), findsOneWidget);
    expect(find.text('svc-a'), findsOneWidget);
    expect(find.text('42'), findsOneWidget);
    expect(find.text('ERROR'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
  });

  testWidgets(
      'Given a facet value row is visible, '
      'When the operator taps it, '
      'Then the search bar appends field:value and the log table re-fetches',
      (tester) async {
    final api = _FakeApi(
      facets: [
        FacetField(
          field: 'service_name',
          values: [FacetValue(value: 'svc-a', count: 3)],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: LogsPage(apiClient: api))),
    );
    await tester.pumpAndSettle();

    final callsBefore = api.calls.length;
    await tester.tap(find.text('svc-a'));
    await tester.pumpAndSettle();

    expect(api.calls.length, greaterThan(callsBefore));
    expect(api.calls.last['filter'], equals('service_name:svc-a'));
    expect(find.widgetWithText(TextField, 'service_name:svc-a'), findsOneWidget);
  });

  testWidgets(
      'Given a filter is already present in the search bar, '
      'When the operator taps a facet value, '
      'Then the filter is extended with AND token',
      (tester) async {
    final api = _FakeApi(
      facets: [
        FacetField(
          field: 'severity_text',
          values: [FacetValue(value: 'ERROR', count: 2)],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: LogsPage(apiClient: api))),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('logs_search')), 'service:svc');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    await tester.tap(find.text('ERROR'));
    await tester.pumpAndSettle();

    expect(api.calls.last['filter'], equals('service:svc AND severity_text:ERROR'));
  });

  testWidgets(
      'Given the /v1/logs/facets request is in flight, '
      'When the panel is rendered, '
      'Then a grey shimmer placeholder is shown in place of facet content',
      (tester) async {
    // Use a completer-based api so we can hold the fetch in-flight
    final api = _HoldingFacetApi();

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: LogsPage(apiClient: api))),
    );
    // One pump builds the widget; _fetch starts but completer hasn't resolved
    await tester.pump();

    expect(find.byKey(const Key('facet_shimmer')), findsOneWidget);

    // Release to avoid timer leaks
    api.complete([]);
    await tester.pumpAndSettle();
  });

  testWidgets(
      'Given the /v1/logs/facets request fails, '
      'When the error is received, '
      'Then the facet panel shows nothing',
      (tester) async {
    final api = _FakeApi(facetError: Exception('network error'));

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: LogsPage(apiClient: api))),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('facet_panel')), findsOneWidget);
    expect(find.byType(ExpansionTile), findsNothing);
  });

  testWidgets(
      'Given facets have loaded, '
      'When the operator changes the time range, '
      'Then the facet panel re-fetches',
      (tester) async {
    int facetFetchCount = 0;
    final api = _FakeApi(facets: []);
    final originalGetFacets = api.getLogsFacets;
    // Use a custom api subclass to count calls
    final countingApi = _CountingFacetApi(
      onFetch: () => facetFetchCount++,
      facets: [
        FacetField(field: 'service_name', values: [FacetValue(value: 'svc', count: 1)]),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: LogsPage(apiClient: countingApi))),
    );
    await tester.pumpAndSettle();

    final fetchesAfterInit = countingApi.facetFetchCount;

    // Open time range picker and click a preset to trigger setRange
    await tester.tap(find.text('Last 1 hour'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Last 15 minutes'));
    await tester.pumpAndSettle();

    expect(countingApi.facetFetchCount, greaterThan(fetchesAfterInit));
  });
}

class _HoldingFacetApi extends DefaultApi {
  late void Function(List<FacetField>) _resolve;

  void complete(List<FacetField> facets) => _resolve(facets);

  @override
  Future<List<LogRow>?> getLogs({String? filter, String? from, String? to, int? limit}) async => [];

  @override
  Future<List<FacetField>?> getLogsFacets({String? filter, String? from, String? to}) {
    final completer = Completer<List<FacetField>?>();
    _resolve = (f) => completer.complete(f);
    return completer.future;
  }
}

class _CountingFacetApi extends DefaultApi {
  int facetFetchCount = 0;
  final VoidCallback onFetch;
  final List<FacetField> facets;

  _CountingFacetApi({required this.onFetch, required this.facets});

  @override
  Future<List<LogRow>?> getLogs({String? filter, String? from, String? to, int? limit}) async {
    return [];
  }

  @override
  Future<List<FacetField>?> getLogsFacets({String? filter, String? from, String? to}) async {
    facetFetchCount++;
    onFetch();
    return facets;
  }
}
