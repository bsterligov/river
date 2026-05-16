import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:river_api/api.dart';

import 'package:ui/pages/traces/traces.dart';
import 'package:ui/controllers/time_range_controller.dart';

import 'helpers.dart';

// ---------------------------------------------------------------------------
// Fake API helpers
// ---------------------------------------------------------------------------

class _TracesApi extends DefaultApi {
  final List<TraceGroup> traces;
  final List<Map<String, String?>> calls = [];

  _TracesApi({this.traces = const []});

  @override
  Future<List<TraceGroup>?> getTraces({
    String? filter,
    String? from,
    String? to,
    int? limit,
  }) async {
    calls.add({'filter': filter, 'from': from, 'to': to});
    return traces;
  }

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

Span _span({
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
      attributes: null,
      events: [],
      links: [],
    );

TraceGroup _trace({
  String traceId = 'trace-abc',
  List<Span>? spans,
}) =>
    TraceGroup(
      traceId: traceId,
      spans: spans ?? [_span()],
    );

Future<void> _loadTraces(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('traces_search')));
  await tester.pump();
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pumpAndSettle();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  testWidgets(
      'Given the Traces page is open with results, '
      'When the operator looks at the table header, '
      'Then columns appear left-to-right: Start Time, Trace ID, Root Service, Root Operation, Duration ms, Spans',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final api = _TracesApi(traces: [_trace()]);

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
    await _loadTraces(tester);

    // Collect column header positions (dx) to verify left-to-right order.
    final expectedOrder = [
      'Start Time',
      'Trace ID',
      'Root Service',
      'Root Operation',
      'Duration ms',
      'Spans',
    ];
    final positions = <String, double>{};
    for (final label in expectedOrder) {
      final finder = find.text(label);
      expect(finder, findsOneWidget, reason: 'Column "$label" not found');
      positions[label] = tester.getTopLeft(finder).dx;
    }
    for (int i = 0; i < expectedOrder.length - 1; i++) {
      final a = expectedOrder[i];
      final b = expectedOrder[i + 1];
      expect(
        positions[a]! < positions[b]!,
        isTrue,
        reason: '"$a" should appear before "$b"',
      );
    }
  });

  testWidgets(
      'Given the table has loaded, '
      'When the operator reads a Trace ID cell, '
      'Then it is rendered in AppText.mono (monospace family)',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final api = _TracesApi(traces: [_trace(traceId: 'abc123')]);

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
    await _loadTraces(tester);

    final traceIdTexts = tester
        .widgetList<Text>(find.byType(Text))
        .where((t) => t.data == 'abc123')
        .toList();
    expect(traceIdTexts, isNotEmpty, reason: 'Trace ID cell not found');
    expect(
      traceIdTexts.first.style?.fontFamily,
      equals('monospace'),
      reason: 'Trace ID should use monospace font',
    );
  });

  testWidgets(
      'Given the table is visible, '
      'When the operator clicks the settings icon, '
      'Then a ColumnMenu overlay appears with one checkbox per column',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final api = _TracesApi(traces: [_trace()]);

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
    await _loadTraces(tester);

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    // One checkbox entry per column.
    for (final label in [
      'Start Time',
      'Trace ID',
      'Root Service',
      'Root Operation',
      'Duration ms',
      'Spans',
    ]) {
      expect(
        find.byKey(Key('col_toggle_${_labelToId(label)}')),
        findsOneWidget,
        reason: 'Checkbox for "$label" not found in menu',
      );
    }
  });

  testWidgets(
      'Given a column is hidden via the menu, '
      'When the operator reopens the menu, '
      'Then the checkbox for that column is unchecked and the column is absent from the header and all rows',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final api = _TracesApi(traces: [_trace()]);

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
    await _loadTraces(tester);

    // Open menu and hide "Spans".
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('col_toggle_spanCount')));
    await tester.pump();

    // Close menu by tapping outside.
    final tableCenter = tester.getCenter(find.byType(TracesTable));
    await tester.tapAt(tableCenter + const Offset(0, 200));
    await tester.pumpAndSettle();

    // "Spans" header should be gone.
    expect(find.text('Spans'), findsNothing);

    // Reopen menu: checkbox for 'Spans' should be unchecked.
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    final checkbox = tester.widget<CheckboxListTile>(
      find.byKey(const Key('col_toggle_spanCount')),
    );
    expect(checkbox.value, isFalse, reason: 'Spans checkbox should be unchecked');
  });

  testWidgets(
      'Given the operator clicks a column header, '
      'When the sort arrow appears, '
      'Then no extra network request is made (client-side sort only)',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final traces = [
      _trace(
        traceId: 'bbb',
        spans: [_span(service: 'beta', operation: 'OP-B', durationMs: 100)],
      ),
      _trace(
        traceId: 'aaa',
        spans: [_span(service: 'alpha', operation: 'OP-A', durationMs: 50)],
      ),
    ];
    final api = _TracesApi(traces: traces);

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
    await _loadTraces(tester);

    final callsBefore = api.calls.length;

    await tester.tap(find.text('Trace ID'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
    expect(api.calls.length, equals(callsBefore), reason: 'Sort must not make a network call');

    // Verify client-side sort order.
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
    expect(api.calls.length, equals(callsBefore), reason: 'Second sort must not make a network call');
  });
}

/// Maps a column label to its column ID, matching [defaultTraceColumns].
String _labelToId(String label) => switch (label) {
      'Start Time' => 'startTime',
      'Trace ID' => 'traceId',
      'Root Service' => 'rootService',
      'Root Operation' => 'rootOperation',
      'Duration ms' => 'durationMs',
      'Spans' => 'spanCount',
      _ => label.toLowerCase(),
    };
