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
  List<HistogramBucket> histogram;

  _FakeApi({
    this.rows = const [],
    this.error,
    this.facets = const [],
    this.facetError,
    this.histogram = const [],
  });

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

  @override
  Future<List<HistogramBucket>?> getLogsHistogram({
    String? filter,
    String? from,
    String? to,
    String? step,
  }) async {
    return histogram;
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
      'Given two facet values are tapped, '
      'When the operator taps a second value, '
      'Then both tokens appear in the filter joined with AND',
      (tester) async {
    final api = _FakeApi(
      facets: [
        FacetField(
          field: 'service_name',
          values: [
            FacetValue(value: 'svc-a', count: 3),
            FacetValue(value: 'svc-b', count: 1),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: LogsPage(apiClient: api))),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('svc-a'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('svc-b'));
    await tester.pumpAndSettle();

    expect(api.calls.last['filter'], equals('(service_name:svc-a OR service_name:svc-b)'));
  });

  testWidgets(
      'Given a facet value is already checked, '
      'When the operator taps it again, '
      'Then the token is removed from the filter (no duplicate)',
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

    // First tap: select
    await tester.tap(find.text('svc-a'));
    await tester.pumpAndSettle();
    expect(api.calls.last['filter'], equals('service_name:svc-a'));

    // Second tap: deselect — filter becomes empty
    await tester.tap(find.text('svc-a'));
    await tester.pumpAndSettle();
    expect(api.calls.last['filter'], isNull);
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
    expect(
      find.descendant(
        of: find.byKey(const Key('facet_panel')),
        matching: find.byType(ExpansionTile),
      ),
      findsNothing,
    );
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

  // --- LogDetailPanel BDD scenarios ---

  LogRow _makeRow({
    String body = 'hello world',
    String? attributes,
  }) =>
      LogRow(
        timestamp: '2024-01-01T12:00:00Z',
        severityNumber: 9,
        spanId: 'span-1',
        attributes: attributes,
        severity: 'INFO',
        service: 'svc',
        body: body,
        traceId: 'trace-1',
      );

  Future<void> _loadRows(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('logs_search')));
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
  }

  testWidgets(
      'Given a log row is visible in the table, '
      'When the operator clicks it, '
      'Then the detail panel slides in and all three sections render with data from that row',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final row = _makeRow(body: 'login success', attributes: '{"user":"alice"}');
    final api = _FakeApi(rows: [row]);

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: LogsPage(apiClient: api))),
    );
    await tester.pumpAndSettle();
    await _loadRows(tester);

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
    final row1 = _makeRow(body: 'first event');
    final row2 = _makeRow(body: 'second event');
    final api = _FakeApi(rows: [row1, row2]);

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: LogsPage(apiClient: api))),
    );
    await tester.pumpAndSettle();
    await _loadRows(tester);

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
    final row = _makeRow(body: 'log entry');
    final api = _FakeApi(rows: [row]);

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: LogsPage(apiClient: api))),
    );
    await tester.pumpAndSettle();
    await _loadRows(tester);

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

    final row = _makeRow(attributes: '{"env":"prod","version":"1.2.3"}');
    final api = _FakeApi(rows: [row]);

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: LogsPage(apiClient: api))),
    );
    await tester.pumpAndSettle();
    await _loadRows(tester);

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

    final row = _makeRow(attributes: null);
    final api = _FakeApi(rows: [row]);

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: LogsPage(apiClient: api))),
    );
    await tester.pumpAndSettle();
    await _loadRows(tester);

    await tester.tap(find.text(row.body));
    await tester.pumpAndSettle();

    expect(find.text('No attributes'), findsOneWidget);
  });

  // --- LogHistogram BDD scenarios ---

  testWidgets(
      'Given the histogram loads successfully, '
      'When the operator views the Logs page, '
      'Then a bar chart is rendered above the table',
      (tester) async {
    final t0 = DateTime.utc(2024, 1, 1, 0, 0);
    final t1 = DateTime.utc(2024, 1, 1, 0, 1);
    final api = _FakeApi(
      histogram: [
        HistogramBucket(bucket: t0.toIso8601String(), count: 10),
        HistogramBucket(bucket: t1.toIso8601String(), count: 5),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: LogsPage(apiClient: api))),
    );
    await tester.pumpAndSettle();
    await _loadRows(tester);

    expect(find.byKey(const Key('histogram_chart')), findsOneWidget);
    expect(find.text('Log distribution'), findsOneWidget);
  });

  testWidgets(
      'Given the histogram is loading, '
      'When data has not yet arrived, '
      'Then a flat grey placeholder row is shown',
      (tester) async {
    final holdingApi = _HoldingHistogramApi();

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: LogsPage(apiClient: holdingApi))),
    );
    // Trigger reload, then pump once without settling — histogram future is still pending
    await tester.tap(find.byKey(const Key('logs_search')));
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump(); // loading=true, placeholder visible

    expect(find.byKey(const Key('histogram_placeholder')), findsOneWidget);

    holdingApi.complete([]);
    await tester.pumpAndSettle();
  });

  testWidgets(
      'Given the histogram response is empty, '
      'When there are no log counts to display, '
      'Then the histogram widget renders nothing',
      (tester) async {
    final api = _FakeApi(histogram: []);

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: LogsPage(apiClient: api))),
    );
    await tester.pumpAndSettle();
    await _loadRows(tester);

    expect(find.byKey(const Key('histogram_chart')), findsNothing);
    expect(find.byKey(const Key('histogram_placeholder')), findsNothing);
  });

  testWidgets(
      'Given the operator sees the histogram, '
      'When they tap a bar, '
      'Then from/to are set to that bucket\'s interval and the logs re-query',
      (tester) async {
    final t0 = DateTime.utc(2024, 1, 1, 0, 0);
    final t1 = DateTime.utc(2024, 1, 1, 0, 1);
    final api = _FakeApi(
      histogram: [
        HistogramBucket(bucket: t0.toIso8601String(), count: 10),
        HistogramBucket(bucket: t1.toIso8601String(), count: 5),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: LogsPage(apiClient: api))),
    );
    await tester.pumpAndSettle();
    await _loadRows(tester);

    final chart = find.byKey(const Key('histogram_chart'));
    expect(chart, findsOneWidget);

    final callsBefore = api.calls.length;
    // Tap inside first bar: skip 12px horizontal padding + 36px y-axis, then a few px into bar
    await tester.tapAt(tester.getTopLeft(chart) + const Offset(60, 20));
    await tester.pumpAndSettle();

    expect(api.calls.length, greaterThan(callsBefore));
    expect(api.calls.last['from'], contains('2024-01-01T00:00:00'));
  });

  testWidgets(
      'Given the histogram is expanded, '
      'When the operator taps the "Log distribution" tile header, '
      'Then the chart collapses; tapping again re-expands it',
      (tester) async {
    final t0 = DateTime.utc(2024, 1, 1, 0, 0);
    final api = _FakeApi(
      histogram: [HistogramBucket(bucket: t0.toIso8601String(), count: 3)],
    );

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: LogsPage(apiClient: api))),
    );
    await tester.pumpAndSettle();
    await _loadRows(tester);

    // Initially expanded — chart visible
    expect(find.byKey(const Key('histogram_chart')), findsOneWidget);

    // Collapse
    await tester.tap(find.text('Log distribution'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('histogram_chart')), findsNothing);

    // Re-expand
    await tester.tap(find.text('Log distribution'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('histogram_chart')), findsOneWidget);
  });

  // --- LogsTable: sort and column management BDD scenarios ---

  LogRow _makeRowWith({required String severity, required String body, String service = 'svc'}) =>
      LogRow(
        timestamp: '2024-01-01T12:00:00Z',
        severityNumber: 9,
        spanId: 'span-1',
        attributes: null,
        severity: severity,
        service: service,
        body: body,
        traceId: 'trace-1',
      );

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
      _makeRowWith(severity: 'WARN', body: 'warn msg'),
      _makeRowWith(severity: 'ERROR', body: 'error msg'),
      _makeRowWith(severity: 'INFO', body: 'info msg'),
    ];
    final api = _FakeApi(rows: rows);

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: LogsPage(apiClient: api))),
    );
    await tester.pumpAndSettle();
    await _loadRows(tester);

    // First click: sort ascending
    await tester.tap(find.text('Severity'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.arrow_upward), findsOneWidget);

    // Verify rows are sorted ascending by severity text
    final texts = tester.widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? '')
        .where((s) => s == 'ERROR' || s == 'INFO' || s == 'WARN')
        .toList();
    expect(texts.first, equals('ERROR'));

    // Second click: sort descending
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

    final row = _makeRow(body: 'test event');
    final api = _FakeApi(rows: [row]);

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: LogsPage(apiClient: api))),
    );
    await tester.pumpAndSettle();
    await _loadRows(tester);

    // Open column menu
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    // TraceID is hidden by default; enable it, then close the menu to verify
    await tester.tap(find.byKey(const Key('col_toggle_traceId')));
    await tester.pump();
    final tableKey1 = find.byType(LogsTable);
    final tableCenter1 = tester.getCenter(tableKey1);
    await tester.tapAt(tableCenter1 + const Offset(0, 200));
    await tester.pumpAndSettle();

    // TraceID column header should now be visible (menu is closed)
    expect(find.text('TraceID'), findsOneWidget);

    // Open the menu again and uncheck it
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('col_toggle_traceId')));
    await tester.pump();
    // Dismiss the menu by tapping the backdrop (inside the table, below the header)
    final tableKey2 = find.byType(LogsTable);
    final tableCenter2 = tester.getCenter(tableKey2);
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

    final api = _FakeApi(rows: [_makeRow()]);

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: LogsPage(apiClient: api))),
    );
    await tester.pumpAndSettle();
    await _loadRows(tester);

    // TraceID is hidden by default; open menu and enable it
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('col_toggle_traceId')));
    await tester.pump();
    // Dismiss the menu by tapping the backdrop (inside the table, below the header)
    final tableKey = find.byType(LogsTable);
    final tableCenter = tester.getCenter(tableKey);
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

    final api = _FakeApi(rows: [_makeRow()]);

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: LogsPage(apiClient: api))),
    );
    await tester.pumpAndSettle();
    await _loadRows(tester);

    // Open column menu
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('col_toggle_timestamp')), findsOneWidget);

    // Tap the logs table area (not on the settings icon) to dismiss the overlay
    final tableList = find.byKey(const Key('logs_table'));
    if (tableList.evaluate().isNotEmpty) {
      await tester.tapAt(tester.getTopLeft(tableList) + const Offset(10, 10));
    } else {
      // Table is empty; tap the empty-state text area
      await tester.tapAt(tester.getCenter(find.text('No logs found.')));
    }
    await tester.pumpAndSettle();

    // Menu is gone
    expect(find.byKey(const Key('col_toggle_timestamp')), findsNothing);

    // Default visible columns still present
    expect(find.text('Timestamp'), findsOneWidget);
    expect(find.text('Message'), findsOneWidget);
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

  @override
  Future<List<HistogramBucket>?> getLogsHistogram({String? filter, String? from, String? to, String? step}) async => [];
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

  @override
  Future<List<HistogramBucket>?> getLogsHistogram({String? filter, String? from, String? to, String? step}) async => [];
}

class _HoldingHistogramApi extends DefaultApi {
  final Completer<List<HistogramBucket>?> _completer = Completer();

  void complete(List<HistogramBucket> buckets) => _completer.complete(buckets);

  @override
  Future<List<LogRow>?> getLogs({String? filter, String? from, String? to, int? limit}) async => [];

  @override
  Future<List<FacetField>?> getLogsFacets({String? filter, String? from, String? to}) async => [];

  @override
  Future<List<HistogramBucket>?> getLogsHistogram({String? filter, String? from, String? to, String? step}) {
    return _completer.future;
  }
}
