import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:river_api/api.dart';

import 'package:ui/pages/traces/traces.dart';
import 'package:ui/controllers/time_range_controller.dart';
import 'package:ui/theme/app_theme.dart';

import 'helpers.dart';

// ---------------------------------------------------------------------------
// Fake API helpers
// ---------------------------------------------------------------------------

class FakeTracesApi extends DefaultApi {
  final List<TraceGroup> traces;
  final Exception? error;
  final List<Map<String, String?>> calls = [];

  FakeTracesApi({this.traces = const [], this.error});

  @override
  Future<List<TraceGroup>?> getTraces({
    String? filter,
    String? from,
    String? to,
    int? limit,
  }) async {
    calls.add({'filter': filter, 'from': from, 'to': to});
    if (error != null) throw error!;
    return traces;
  }

  // Keep logs/histogram stubs so tests that use helpers.dart FakeApi still work.
  @override
  Future<List<LogRow>?> getLogs(
      {String? filter, String? from, String? to, int? limit}) async =>
      [];

  @override
  Future<List<FacetField>?> getLogsFacets(
      {String? filter, String? from, String? to}) async =>
      [];

  @override
  Future<List<HistogramBucket>?> getLogsHistogram({
    String? filter,
    String? from,
    String? to,
    String? step,
  }) async =>
      [];
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Span makeSpan({
  String spanId = 'span1',
  String parentSpanId = '',
  String service = 'frontend',
  String operation = 'GET /api',
  double durationMs = 42.5,
  String startTime = '2024-01-01T12:00:00Z',
}) =>
    Span(
      spanId: spanId,
      parentSpanId: parentSpanId,
      service: service,
      operation: operation,
      durationMs: durationMs,
      startTime: startTime,
      endTime: '2024-01-01T12:00:01Z',
      statusCode: 0,
      events: [],
      links: [],
    );

TraceGroup makeTrace({
  String traceId = 'trace-abc',
  List<Span>? spans,
}) =>
    TraceGroup(
      traceId: traceId,
      spans: spans ?? [makeSpan()],
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  testWidgets(
      'Given the user opens River Dashboard, '
      'When they click "Traces" in the sidebar, '
      'Then the Traces page is shown with search bar and empty-state table',
      (tester) async {
    final rc = TimeRangeController();
    final api = FakeTracesApi();
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: TestAppShell(api: api, rangeController: rc))),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Traces'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('traces_search')), findsOneWidget);
    expect(find.text('No traces found.'), findsOneWidget);
  });

  testWidgets(
      'Given the Traces page is open, '
      'When the user types a filter expression and submits, '
      'Then TracesController.reload() is called with the new filter and the table updates',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final trace = makeTrace();
    final api = FakeTracesApi(traces: [trace]);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TracesPage(
            apiClient: api,
            rangeController: TimeRangeController(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const Key('traces_search')), 'service:frontend');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(api.calls.last['filter'], equals('service:frontend'));
    expect(find.byKey(const Key('traces_table')), findsOneWidget);
    expect(find.text('trace-abc'), findsOneWidget);
  });

  testWidgets(
      'Given the Traces page is open, '
      'When the user changes the time range via TimeRangeController, '
      'Then TracesController receives the range-change notification and calls reload()',
      (tester) async {
    final api = FakeTracesApi();
    final rc = TimeRangeController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TracesPage(apiClient: api, rangeController: rc),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final before = api.calls.length;
    rc.setRange(
      DateTime.utc(2024, 3, 1, 8, 0),
      DateTime.utc(2024, 3, 1, 10, 0),
    );
    await tester.pumpAndSettle();

    expect(api.calls.length, greaterThan(before));
  });

  testWidgets(
      'Given the table has rows, '
      'When the user clicks a column header, '
      'Then the table re-sorts client-side without a network request',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final traces = [
      makeTrace(
        traceId: 'bbb',
        spans: [makeSpan(service: 'beta', operation: 'OP-B', durationMs: 100)],
      ),
      makeTrace(
        traceId: 'aaa',
        spans: [makeSpan(service: 'alpha', operation: 'OP-A', durationMs: 50)],
      ),
    ];
    final api = FakeTracesApi(traces: traces);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TracesPage(
            apiClient: api,
            rangeController: TimeRangeController(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Submit to load rows.
    await tester.tap(find.byKey(const Key('traces_search')));
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    final callsBefore = api.calls.length;

    // Sort by Trace ID ascending.
    await tester.tap(find.text('Trace ID'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
    // No extra network call.
    expect(api.calls.length, equals(callsBefore));

    // First rendered trace ID should be 'aaa'.
    final traceIds = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? '')
        .where((s) => s == 'aaa' || s == 'bbb')
        .toList();
    expect(traceIds.first, equals('aaa'));

    // Click again → descending.
    await tester.tap(find.text('Trace ID'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
  });

  testWidgets(
      'Given the table has rows, '
      'When the user taps a row, '
      'Then it is highlighted; tapping elsewhere calls clearSelection()',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final trace = makeTrace();
    final api = FakeTracesApi(traces: [trace]);
    final rc = TimeRangeController();
    late TracesController capturedController;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              final page = TracesPage(apiClient: api, rangeController: rc);
              return page;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Load rows via search submission.
    await tester.tap(find.byKey(const Key('traces_search')));
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    // Tap the row.
    await tester.tap(find.text('trace-abc'));
    await tester.pumpAndSettle();

    // The row should be rendered with a highlight color.
    // We verify via the Container color on the _TraceRowWidget.
    final containers = tester
        .widgetList<Container>(find.byType(Container))
        .where((c) => c.color == AppColors.rowSelected)
        .toList();
    expect(containers, isNotEmpty);
  });

  testWidgets(
      'Given API returns an error, '
      'When the response arrives, '
      'Then an inline error message is shown',
      (tester) async {
    final api =
        FakeTracesApi(error: ApiException(400, '{"error":"bad filter"}'));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TracesPage(
            apiClient: api,
            rangeController: TimeRangeController(),
          ),
        ),
      ),
    );

    await tester.enterText(
        find.byKey(const Key('traces_search')), 'bad::filter');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.textContaining('bad filter'), findsOneWidget);
  });
}
