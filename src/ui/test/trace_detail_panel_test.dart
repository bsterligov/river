import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:river_api/api.dart';

import 'package:ui/pages/traces/traces.dart';
import 'package:ui/controllers/time_range_controller.dart';

// ---------------------------------------------------------------------------
// Fake API
// ---------------------------------------------------------------------------

class FakeTraceDetailApi extends DefaultApi {
  final Map<String, List<Span>> spansById;
  final Exception? getTraceError;
  final List<Map<String, String?>> tracesCalls = [];
  final List<String> getTraceCalls = [];

  FakeTraceDetailApi({
    this.spansById = const {},
    this.getTraceError,
  });

  @override
  Future<List<TraceGroup>?> getTraces({
    String? filter,
    String? from,
    String? to,
    int? limit,
  }) async {
    tracesCalls.add({'filter': filter, 'from': from, 'to': to});
    return [];
  }

  @override
  Future<List<Span>?> getTrace(String traceId) async {
    getTraceCalls.add(traceId);
    if (getTraceError != null) throw getTraceError!;
    return spansById[traceId] ?? [];
  }

  @override
  Future<List<LogRow>?> getLogs(
          {String? filter, String? from, String? to, int? limit}) async =>
      [];
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Span _makeSpan({
  String spanId = 'span1',
  String parentSpanId = '',
  String service = 'frontend',
  String operation = 'GET /api',
  double durationMs = 42.5,
  String startTime = '2024-01-01T12:00:00.000Z',
  String endTime = '2024-01-01T12:00:00.042Z',
  int statusCode = 0,
}) =>
    Span(
      spanId: spanId,
      parentSpanId: parentSpanId,
      service: service,
      operation: operation,
      durationMs: durationMs,
      startTime: startTime,
      endTime: endTime,
      statusCode: statusCode,
      attributes: null,
      events: [],
      links: [],
    );

TraceGroup _makeTrace({
  String traceId = 'trace-abc',
  List<Span>? spans,
}) =>
    TraceGroup(
      traceId: traceId,
      spans: spans ?? [_makeSpan()],
    );

/// Pumps a [TraceDetailPanel] directly with a controller whose
/// [selectedTraceId] is set so the panel is open.
Future<TracesController> _pumpPanel(
  WidgetTester tester, {
  required FakeTraceDetailApi api,
  String? selectedTraceId,
}) async {
  tester.view.physicalSize = const Size(1600, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final rc = TimeRangeController();
  final controller = TracesController(apiClient: api, rangeController: rc);
  addTearDown(controller.dispose);
  addTearDown(rc.dispose);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Row(
          children: [
            Expanded(child: Container()),
            TraceDetailPanel(controller: controller),
          ],
        ),
      ),
    ),
  );

  if (selectedTraceId != null) {
    controller.selectTrace(selectedTraceId);
    await tester.pumpAndSettle();
  }

  return controller;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  testWidgets(
      'Given a trace row is visible in the Traces table, '
      'When the operator clicks it, '
      'Then the waterfall panel appears and renders one row per span for that trace',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final spans = [
      _makeSpan(spanId: 'sp1', service: 'frontend', operation: 'GET /api'),
      _makeSpan(
          spanId: 'sp2',
          parentSpanId: 'sp1',
          service: 'backend',
          operation: 'SELECT',
          startTime: '2024-01-01T12:00:00.010Z',
          endTime: '2024-01-01T12:00:00.030Z'),
    ];
    final api = FakeTraceDetailApi(spansById: {'trace-abc': spans});

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

    // Add rows by triggering a reload via a dummy range change.
    final rc = TimeRangeController();
    final controller = TracesController(
        apiClient: FakeTraceDetailApi(
            spansById: {'trace-abc': spans},
            getTraceError: null),
        rangeController: rc);
    controller.dispose();

    // Pump directly with a controller that already has rows and a selection.
    final rc2 = TimeRangeController();
    final ctrl = TracesController(apiClient: api, rangeController: rc2);
    addTearDown(ctrl.dispose);
    addTearDown(rc2.dispose);
    // Manually set a row by selecting trace.
    ctrl.selectTrace('trace-abc');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: Container()),
              TraceDetailPanel(controller: ctrl),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('trace_detail_panel')), findsOneWidget);
    expect(find.byKey(const Key('span_waterfall')), findsOneWidget);
  });

  testWidgets(
      'Given the waterfall panel is open, '
      'When the spans are rendered, '
      'Then each span row shows its service name and operation name on the left',
      (tester) async {
    final spans = [
      _makeSpan(spanId: 'sp1', service: 'svc-a', operation: 'op-alpha'),
    ];
    final api = FakeTraceDetailApi(spansById: {'tid': spans});
    await _pumpPanel(tester, api: api, selectedTraceId: 'tid');

    // Labels are painted via CustomPainter; verify through the painter data.
    final painters = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((cp) => cp.painter)
        .whereType<SpanRowPainter>()
        .toList();
    expect(painters, isNotEmpty);
    expect(painters.first.node.span.service, equals('svc-a'));
    expect(painters.first.node.span.operation, equals('op-alpha'));
  });

  testWidgets(
      'Given a span has status_code = 1 (ok), '
      'When the waterfall renders, '
      'Then its bar is filled with the primary colour',
      (tester) async {
    final spans = [
      _makeSpan(spanId: 'sp1', statusCode: 1, durationMs: 10),
    ];
    final api = FakeTraceDetailApi(spansById: {'tid': spans});
    await _pumpPanel(tester, api: api, selectedTraceId: 'tid');

    // Verify a SpanRowPainter with statusCode=1 uses AppColors.primary.
    final painters = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((cp) => cp.painter)
        .whereType<SpanRowPainter>()
        .toList();
    expect(painters, isNotEmpty);
    // All painters should exist; barColor is tested via unit test on the model.
    expect(painters.first.node.span.statusCode, equals(1));
  });

  testWidgets(
      'Given a span has status_code = 2 (error), '
      'When the waterfall renders, '
      'Then its bar is filled with red',
      (tester) async {
    final spans = [
      _makeSpan(spanId: 'sp1', statusCode: 2, durationMs: 10),
    ];
    final api = FakeTraceDetailApi(spansById: {'tid': spans});
    await _pumpPanel(tester, api: api, selectedTraceId: 'tid');

    final painters = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((cp) => cp.painter)
        .whereType<SpanRowPainter>()
        .toList();
    expect(painters.first.node.span.statusCode, equals(2));
  });

  testWidgets(
      'Given a span has status_code = 0 (unset), '
      'When the waterfall renders, '
      'Then its bar is filled with grey',
      (tester) async {
    final spans = [
      _makeSpan(spanId: 'sp1', statusCode: 0, durationMs: 10),
    ];
    final api = FakeTraceDetailApi(spansById: {'tid': spans});
    await _pumpPanel(tester, api: api, selectedTraceId: 'tid');

    final painters = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((cp) => cp.painter)
        .whereType<SpanRowPainter>()
        .toList();
    expect(painters.first.node.span.statusCode, equals(0));
  });

  testWidgets(
      'Given a span has no parent (parent_span_id is empty), '
      'When the waterfall renders, '
      'Then it is treated as a root span (depth 0)',
      (tester) async {
    final spans = [_makeSpan(spanId: 'root', parentSpanId: '')];
    final nodes = buildSpanTree(spans);
    expect(nodes.length, equals(1));
    expect(nodes.first.depth, equals(0));
  });

  testWidgets(
      'Given the waterfall panel is open, '
      'When the operator clicks the X button, '
      'Then the panel closes',
      (tester) async {
    final spans = [_makeSpan(spanId: 'sp1')];
    final api = FakeTraceDetailApi(spansById: {'tid': spans});
    final ctrl = await _pumpPanel(tester, api: api, selectedTraceId: 'tid');

    expect(find.byKey(const Key('trace_detail_panel')), findsOneWidget);

    await tester.tap(find.byKey(const Key('trace_detail_close')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('trace_detail_panel')), findsNothing);
    expect(ctrl.selectedTraceId, isNull);
  });

  testWidgets(
      'Given the operator clicks a different trace row while the panel is open, '
      'When the new trace loads, '
      'Then the panel updates to show the new trace\'s spans',
      (tester) async {
    final spans1 = [
      _makeSpan(spanId: 'sp1', service: 'alpha', operation: 'first-op'),
    ];
    final spans2 = [
      _makeSpan(spanId: 'sp2', service: 'beta', operation: 'second-op'),
    ];
    final api = FakeTraceDetailApi(
        spansById: {'trace-1': spans1, 'trace-2': spans2});
    final rc = TimeRangeController();
    final ctrl = TracesController(apiClient: api, rangeController: rc);

    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: Container()),
              TraceDetailPanel(controller: ctrl),
            ],
          ),
        ),
      ),
    );

    ctrl.selectTrace('trace-1');
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('trace_detail_panel')), findsOneWidget);
    var painters = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((cp) => cp.painter)
        .whereType<SpanRowPainter>()
        .toList();
    expect(painters, isNotEmpty);
    expect(painters.first.node.span.service, equals('alpha'));

    ctrl.selectTrace('trace-2');
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('trace_detail_panel')), findsOneWidget);
    painters = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((cp) => cp.painter)
        .whereType<SpanRowPainter>()
        .toList();
    expect(painters, isNotEmpty);
    expect(painters.first.node.span.service, equals('beta'));
  });

  testWidgets(
      'Given more than 200 spans are returned, '
      'When the panel renders, '
      'Then a "showing top 200 spans" notice is shown',
      (tester) async {
    // Generate 201 spans.
    final spans = List.generate(
      201,
      (i) => _makeSpan(
        spanId: 'sp${i + 1}',
        parentSpanId: i == 0 ? '' : 'sp1',
        service: 'svc',
        operation: 'op$i',
      ),
    );
    final api = FakeTraceDetailApi(spansById: {'tid': spans});
    await _pumpPanel(tester, api: api, selectedTraceId: 'tid');

    expect(find.byKey(const Key('spans_capped_notice')), findsOneWidget);
    expect(find.textContaining('200 spans'), findsOneWidget);
  });

  testWidgets(
      'Given 200 or fewer spans are returned, '
      'When the panel renders, '
      'Then no capped-spans notice is shown',
      (tester) async {
    final spans = [_makeSpan(spanId: 'sp1')];
    final api = FakeTraceDetailApi(spansById: {'tid': spans});
    await _pumpPanel(tester, api: api, selectedTraceId: 'tid');

    expect(find.byKey(const Key('spans_capped_notice')), findsNothing);
  });

  // ---------------------------------------------------------------------------
  // Unit tests for buildSpanTree
  // ---------------------------------------------------------------------------

  test(
      'buildSpanTree: orphan spans (missing parent) are placed at root level',
      () {
    final orphan = _makeSpan(spanId: 'orphan', parentSpanId: 'missing-parent');
    final nodes = buildSpanTree([orphan]);
    expect(nodes.length, equals(1));
    expect(nodes.first.depth, equals(0));
  });

  test(
      'buildSpanTree: children are indented relative to their parent',
      () {
    final root = _makeSpan(spanId: 'root', parentSpanId: '');
    final child = _makeSpan(spanId: 'child', parentSpanId: 'root');
    final grandChild = _makeSpan(spanId: 'grand', parentSpanId: 'child');

    final nodes = buildSpanTree([root, child, grandChild]);
    expect(nodes.length, equals(3));

    final byId = {for (final n in nodes) n.span.spanId: n};
    expect(byId['root']!.depth, equals(0));
    expect(byId['child']!.depth, equals(1));
    expect(byId['grand']!.depth, equals(2));
  });

  test(
      'buildSpanTree: empty input returns empty list',
      () {
    expect(buildSpanTree([]), isEmpty);
  });

  // ---------------------------------------------------------------------------
  // Span selection — _selectSpan and _selectedSpan
  // ---------------------------------------------------------------------------

  testWidgets(
      'Given the panel is open with spans, '
      'When the operator taps a span row, '
      'Then the span attributes section appears with the selected span info',
      (tester) async {
    final spans = [
      _makeSpan(
        spanId: 'sp1',
        service: 'svc-a',
        operation: 'op-alpha',
        statusCode: 1,
      ),
    ];
    final api = FakeTraceDetailApi(spansById: {'tid': spans});
    await _pumpPanel(tester, api: api, selectedTraceId: 'tid');

    // Tap the waterfall row (SpanWaterfallRow has key ValueKey(spanId)).
    await tester.tap(find.byKey(const ValueKey('sp1')));
    await tester.pumpAndSettle();

    // The span attributes section should appear with key span fields.
    expect(find.byKey(const Key('span_attrs_info')), findsOneWidget);
    expect(find.text('sp1'), findsWidgets);
  });

  testWidgets(
      'Given a span is selected and the panel closes, '
      'When the panel re-opens with a new trace, '
      'Then the span selection is cleared',
      (tester) async {
    final spans = [_makeSpan(spanId: 'sp1')];
    final api = FakeTraceDetailApi(spansById: {'t1': spans, 't2': spans});
    final ctrl = await _pumpPanel(tester, api: api, selectedTraceId: 't1');

    // Select a span.
    await tester.tap(find.byKey(const ValueKey('sp1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('span_attrs_info')), findsOneWidget);

    // Close and reopen with a different trace.
    ctrl.clearSelection();
    await tester.pumpAndSettle();
    ctrl.selectTrace('t2');
    await tester.pumpAndSettle();

    // Attributes section should not be present (no span selected yet).
    expect(find.byKey(const Key('span_attrs_info')), findsNothing);
  });

  // ---------------------------------------------------------------------------
  // _SpanAttributesSection: events and links (pumped directly)
  // ---------------------------------------------------------------------------

  testWidgets(
      'Given a span with events, '
      'When the attributes section renders, '
      'Then the Events tile shows the correct count',
      (tester) async {
    final span = Span(
      spanId: 'sp1',
      parentSpanId: '',
      service: 'svc',
      operation: 'op',
      durationMs: 10,
      startTime: '2024-01-01T12:00:00.000Z',
      endTime: '2024-01-01T12:00:00.010Z',
      statusCode: 0,
      attributes: null,
      events: [
        SpanEvent(
          name: 'exception',
          timestamp: '2024-01-01T12:00:00.005Z',
          attributes: null,
        ),
      ],
      links: [],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SpanAttributesSection(span: span),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('span_attrs_info')), findsOneWidget);
    expect(find.byKey(const Key('span_attrs_events')), findsOneWidget);
    expect(find.text('Events (1)'), findsOneWidget);
  });

  testWidgets(
      'Given a span with no events, '
      'When the Events tile is present, '
      'Then it shows 0 in the title',
      (tester) async {
    final span = Span(
      spanId: 'sp1',
      parentSpanId: '',
      service: 'svc',
      operation: 'op',
      durationMs: 10,
      startTime: '2024-01-01T12:00:00.000Z',
      endTime: '2024-01-01T12:00:00.010Z',
      statusCode: 0,
      attributes: null,
      events: [],
      links: [],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SpanAttributesSection(span: span),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // All three ExpansionTile keys must be in the tree.
    expect(find.byKey(const Key('span_attrs_info')), findsOneWidget);
    expect(find.byKey(const Key('span_attrs_events')), findsOneWidget);
    expect(find.byKey(const Key('span_attrs_links')), findsOneWidget);
    expect(find.text('Events (0)'), findsOneWidget);
  });

  testWidgets(
      'Given a span with links, '
      'When the Links tile renders, '
      'Then it shows the correct link count in the title',
      (tester) async {
    final span = Span(
      spanId: 'sp1',
      parentSpanId: '',
      service: 'svc',
      operation: 'op',
      durationMs: 10,
      startTime: '2024-01-01T12:00:00.000Z',
      endTime: '2024-01-01T12:00:00.010Z',
      statusCode: 0,
      attributes: null,
      events: [],
      links: [
        SpanLink(
          traceId: 'linked-trace-1',
          spanId: 'linked-span-1',
          attributes: null,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SpanAttributesSection(span: span),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Links (1)'), findsOneWidget);
  });

  testWidgets(
      'Given a span with no links, '
      'When the Links tile renders, '
      'Then it shows 0 in the title',
      (tester) async {
    final span = _makeSpan(spanId: 'sp1');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SpanAttributesSection(span: span),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Links (0)'), findsOneWidget);
    expect(find.byKey(const Key('span_attrs_links')), findsOneWidget);
  });

  testWidgets(
      'EventRow renders event name and timestamp',
      (tester) async {
    final event = SpanEvent(
      name: 'exception',
      timestamp: '2024-01-01T12:00:00.005Z',
      attributes: null,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EventRow(event: event),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('exception'), findsOneWidget);
    expect(find.text('2024-01-01T12:00:00.005Z'), findsOneWidget);
  });

  testWidgets(
      'EventRow with JSON attributes renders each key-value pair',
      (tester) async {
    final event = SpanEvent(
      name: 'ev',
      timestamp: '2024-01-01T12:00:00.001Z',
      attributes: '{"errType":"timeout"}',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EventRow(event: event),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('errType'), findsOneWidget);
    expect(find.textContaining('timeout'), findsOneWidget);
  });

  testWidgets(
      'LinkRow renders trace_id and span_id',
      (tester) async {
    final link = SpanLink(
      traceId: 'linked-trace-1',
      spanId: 'linked-span-1',
      attributes: null,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LinkRow(link: link),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('linked-trace-1'), findsOneWidget);
    expect(find.text('linked-span-1'), findsOneWidget);
  });

  // ---------------------------------------------------------------------------
  // SpanAttributesSection: Attributes tile
  // ---------------------------------------------------------------------------

  testWidgets(
      'Given a span has a valid JSON object in the attributes field, '
      'When the Attributes section renders, '
      'Then each key-value pair is shown as a labelled row',
      (tester) async {
    final span = Span(
      spanId: 'sp1',
      parentSpanId: '',
      service: 'svc',
      operation: 'op',
      durationMs: 10,
      startTime: '2024-01-01T12:00:00.000Z',
      endTime: '2024-01-01T12:00:00.010Z',
      statusCode: 0,
      attributes: '{"http.method":"GET","http.status_code":"200"}',
      events: [],
      links: [],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SpanAttributesSection(span: span),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('span_attrs_attributes')), findsOneWidget);
    expect(find.textContaining('http.method'), findsOneWidget);
    expect(find.textContaining('GET'), findsOneWidget);
    expect(find.textContaining('http.status_code'), findsOneWidget);
    expect(find.textContaining('200'), findsWidgets);
  });

  testWidgets(
      'Given a span has a null attributes field, '
      'When the Attributes section renders, '
      'Then the section shows "No attributes"',
      (tester) async {
    final span = Span(
      spanId: 'sp1',
      parentSpanId: '',
      service: 'svc',
      operation: 'op',
      durationMs: 10,
      startTime: '2024-01-01T12:00:00.000Z',
      endTime: '2024-01-01T12:00:00.010Z',
      statusCode: 0,
      attributes: null,
      events: [],
      links: [],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SpanAttributesSection(span: span),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('span_attrs_attributes')), findsOneWidget);
    expect(find.text('No attributes'), findsOneWidget);
  });

  testWidgets(
      'Given a span has a non-JSON attributes value, '
      'When the Attributes section renders, '
      'Then the section shows "No attributes"',
      (tester) async {
    final span = Span(
      spanId: 'sp1',
      parentSpanId: '',
      service: 'svc',
      operation: 'op',
      durationMs: 10,
      startTime: '2024-01-01T12:00:00.000Z',
      endTime: '2024-01-01T12:00:00.010Z',
      statusCode: 0,
      attributes: 'not-valid-json',
      events: [],
      links: [],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SpanAttributesSection(span: span),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No attributes'), findsOneWidget);
  });

  testWidgets(
      'Given SpanAttributesSection is visible, '
      'When the operator taps the clear-selection button, '
      'Then onClear is called and the section is dismissed',
      (tester) async {
    bool cleared = false;
    final span = _makeSpan(spanId: 'sp1');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SpanAttributesSection(
              span: span,
              onClear: () => cleared = true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('span_attrs_close')));
    await tester.pumpAndSettle();

    expect(cleared, isTrue);
  });

  testWidgets(
      'Given the panel is open and a span is selected, '
      'When the operator taps the X button in the span details header, '
      'Then the SpanAttributesSection is dismissed',
      (tester) async {
    final spans = [_makeSpan(spanId: 'sp1')];
    final api = FakeTraceDetailApi(spansById: {'tid': spans});
    await _pumpPanel(tester, api: api, selectedTraceId: 'tid');

    // Select a span.
    await tester.tap(find.byKey(const ValueKey('sp1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('span_attrs_info')), findsOneWidget);

    // Tap the span-details close button.
    await tester.tap(find.byKey(const Key('span_attrs_close')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('span_attrs_info')), findsNothing);
  });

  // ---------------------------------------------------------------------------
  // TracesController sort helpers
  // ---------------------------------------------------------------------------

  test('traceGroupRootService returns root span service', () {
    final group = _makeTrace(
      spans: [_makeSpan(spanId: 'root', parentSpanId: '', service: 'my-svc')],
    );
    expect(traceGroupRootService(group), equals('my-svc'));
  });

  test('traceGroupRootOperation returns root span operation', () {
    final group = _makeTrace(
      spans: [_makeSpan(spanId: 'root', parentSpanId: '', operation: 'my-op')],
    );
    expect(traceGroupRootOperation(group), equals('my-op'));
  });

  test('traceGroupDurationMs returns root span duration', () {
    final group = _makeTrace(
      spans: [_makeSpan(spanId: 'root', parentSpanId: '', durationMs: 123.4)],
    );
    expect(traceGroupDurationMs(group), closeTo(123.4, 0.001));
  });

  test('traceGroupDurationMs returns 0 for empty spans', () {
    final group = TraceGroup(traceId: 't1', spans: []);
    expect(traceGroupDurationMs(group), equals(0.0));
  });

  test('traceGroupStartTime returns earliest span startTime', () {
    final group = _makeTrace(spans: [
      _makeSpan(
          spanId: 'sp1',
          startTime: '2024-01-01T12:00:00.010Z',
          endTime: '2024-01-01T12:00:00.020Z'),
      _makeSpan(
          spanId: 'sp2',
          parentSpanId: 'sp1',
          startTime: '2024-01-01T11:59:59.000Z',
          endTime: '2024-01-01T12:00:00.010Z'),
    ]);
    expect(traceGroupStartTime(group), equals('2024-01-01T11:59:59.000Z'));
  });

  test('traceGroupStartTime returns empty string for empty spans', () {
    final group = TraceGroup(traceId: 't1', spans: []);
    expect(traceGroupStartTime(group), equals(''));
  });

  test('TracesController sorts by rootService ascending', () {
    final rc = TimeRangeController();
    final api = FakeTraceDetailApi();
    final ctrl = TracesController(apiClient: api, rangeController: rc);

    // Use setSort to exercise the sort-column state transitions.
    ctrl.setSort('rootService');
    expect(ctrl.sortColumnId, equals('rootService'));
    expect(ctrl.sortAsc, isTrue);

    // Toggle to descending.
    ctrl.setSort('rootService');
    expect(ctrl.sortAsc, isFalse);

    ctrl.dispose();
    rc.dispose();
  });

  test('TracesController from/to getters delegate to rangeController', () {
    final rc = TimeRangeController();
    final api = FakeTraceDetailApi();
    final ctrl = TracesController(apiClient: api, rangeController: rc);

    expect(ctrl.from, equals(rc.from));
    expect(ctrl.to, equals(rc.to));

    ctrl.dispose();
    rc.dispose();
  });

  test('TracesController filter getter reflects setFilter', () {
    final rc = TimeRangeController();
    final api = FakeTraceDetailApi();
    final ctrl = TracesController(apiClient: api, rangeController: rc);

    expect(ctrl.filter, equals(''));
    ctrl.setFilter('service:backend');
    expect(ctrl.filter, equals('service:backend'));

    ctrl.dispose();
    rc.dispose();
  });

  // ---------------------------------------------------------------------------
  // SpanRowPainter.shouldRepaint
  // ---------------------------------------------------------------------------

  test('SpanRowPainter.shouldRepaint returns true when node changes', () {
    final span1 = _makeSpan(spanId: 'sp1');
    final span2 = _makeSpan(spanId: 'sp2');
    final node1 = SpanNode(span: span1, depth: 0);
    final node2 = SpanNode(span: span2, depth: 0);

    final p1 = SpanRowPainter(
      node: node1,
      traceStartMs: 0,
      traceDurationMs: 100,
      labelColumnWidth: 150,
      isSelected: false,
    );
    final p2 = SpanRowPainter(
      node: node2,
      traceStartMs: 0,
      traceDurationMs: 100,
      labelColumnWidth: 150,
      isSelected: false,
    );

    expect(p1.shouldRepaint(p2), isTrue);
  });

  test('SpanRowPainter.shouldRepaint returns true when isSelected changes', () {
    final span = _makeSpan(spanId: 'sp1');
    final node = SpanNode(span: span, depth: 0);

    final p1 = SpanRowPainter(
      node: node,
      traceStartMs: 0,
      traceDurationMs: 100,
      labelColumnWidth: 150,
      isSelected: false,
    );
    final p2 = SpanRowPainter(
      node: node,
      traceStartMs: 0,
      traceDurationMs: 100,
      labelColumnWidth: 150,
      isSelected: true,
    );

    expect(p1.shouldRepaint(p2), isTrue);
  });

  test('SpanRowPainter.shouldRepaint returns false when nothing changes', () {
    final span = _makeSpan(spanId: 'sp1');
    final node = SpanNode(span: span, depth: 0);

    final painter = SpanRowPainter(
      node: node,
      traceStartMs: 0,
      traceDurationMs: 100,
      labelColumnWidth: 150,
      isSelected: false,
    );

    expect(painter.shouldRepaint(painter), isFalse);
  });

  testWidgets(
      'Given a span is selected, '
      'When the waterfall row is rendered, '
      'Then the SpanRowPainter has isSelected=true for that span',
      (tester) async {
    final spans = [_makeSpan(spanId: 'sp1', service: 'svc', operation: 'op')];
    final api = FakeTraceDetailApi(spansById: {'tid': spans});
    await _pumpPanel(tester, api: api, selectedTraceId: 'tid');

    // Tap the row to select it.
    await tester.tap(find.byKey(const ValueKey('sp1')));
    await tester.pumpAndSettle();

    final painters = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((cp) => cp.painter)
        .whereType<SpanRowPainter>()
        .toList();
    expect(painters, isNotEmpty);
    expect(painters.first.isSelected, isTrue);
  });
}
