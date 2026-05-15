import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:river_api/api.dart';

import 'package:ui/pages/logs/logs.dart';
import 'package:ui/time_range_controller.dart';
import 'package:ui/widgets/top_panel.dart';

class FakeApi extends DefaultApi {
  final List<LogRow> rows;
  final Exception? error;
  final List<Map<String, String?>> calls = [];
  List<FacetField> facets;
  Exception? facetError;
  List<HistogramBucket> histogram;

  FakeApi({
    this.rows = const [],
    this.error,
    this.facets = const [],
    this.facetError,
    this.histogram = const [],
  });

  @override
  Future<List<LogRow>?> getLogs({String? filter, String? from, String? to, int? limit}) async {
    calls.add({'filter': filter, 'from': from, 'to': to});
    if (error != null) throw error!;
    return rows;
  }

  @override
  Future<List<FacetField>?> getLogsFacets({String? filter, String? from, String? to}) async {
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

class HoldingFacetApi extends DefaultApi {
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
  Future<List<HistogramBucket>?> getLogsHistogram({
    String? filter,
    String? from,
    String? to,
    String? step,
  }) async => [];
}

class CountingFacetApi extends DefaultApi {
  int facetFetchCount = 0;
  final VoidCallback onFetch;
  final List<FacetField> facets;

  CountingFacetApi({required this.onFetch, required this.facets});

  @override
  Future<List<LogRow>?> getLogs({String? filter, String? from, String? to, int? limit}) async => [];

  @override
  Future<List<FacetField>?> getLogsFacets({String? filter, String? from, String? to}) async {
    facetFetchCount++;
    onFetch();
    return facets;
  }

  @override
  Future<List<HistogramBucket>?> getLogsHistogram({
    String? filter,
    String? from,
    String? to,
    String? step,
  }) async => [];
}

class HoldingHistogramApi extends DefaultApi {
  final Completer<List<HistogramBucket>?> _completer = Completer();

  void complete(List<HistogramBucket> buckets) => _completer.complete(buckets);

  @override
  Future<List<LogRow>?> getLogs({String? filter, String? from, String? to, int? limit}) async => [];

  @override
  Future<List<FacetField>?> getLogsFacets({String? filter, String? from, String? to}) async => [];

  @override
  Future<List<HistogramBucket>?> getLogsHistogram({
    String? filter,
    String? from,
    String? to,
    String? step,
  }) {
    return _completer.future;
  }
}

// Mirrors production shell for tests that interact with the time range picker.
class TestShell extends StatelessWidget {
  const TestShell({required this.api, required this.rangeController});

  final DefaultApi api;
  final TimeRangeController rangeController;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TopPanel(rangeController: rangeController),
        Expanded(
          child: LogsPage(apiClient: api, rangeController: rangeController),
        ),
      ],
    );
  }
}

LogRow makeRow({String body = 'hello world', String? attributes}) => LogRow(
      timestamp: '2024-01-01T12:00:00Z',
      severityNumber: 9,
      spanId: 'span-1',
      attributes: attributes,
      severity: 'INFO',
      service: 'svc',
      body: body,
      traceId: 'trace-1',
    );

LogRow makeRowWith({required String severity, required String body, String service = 'svc'}) =>
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

Future<void> loadRows(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('logs_search')));
  await tester.pump();
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pumpAndSettle();
}
