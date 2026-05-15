import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:river_api/api.dart';

import 'package:ui/pages/logs/logs.dart';
import 'package:ui/controllers/time_range_controller.dart';

import 'helpers.dart';

void main() {
  testWidgets(
      'Given the histogram loads successfully, '
      'When the operator views the Logs page, '
      'Then a bar chart is rendered above the table',
      (tester) async {
    final t0 = DateTime.utc(2024, 1, 1, 0, 0);
    final t1 = DateTime.utc(2024, 1, 1, 0, 1);
    final api = FakeApi(
      histogram: [
        HistogramBucket(bucket: t0.toIso8601String(), count: 10),
        HistogramBucket(bucket: t1.toIso8601String(), count: 5),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: LogsPage(apiClient: api, rangeController: TimeRangeController()))),
    );
    await tester.pumpAndSettle();
    await loadRows(tester);

    expect(find.byKey(const Key('histogram_chart')), findsOneWidget);
    expect(find.text('Log distribution'), findsOneWidget);
  });

  testWidgets(
      'Given the histogram is loading, '
      'When data has not yet arrived, '
      'Then a flat grey placeholder row is shown',
      (tester) async {
    final holdingApi = HoldingHistogramApi();

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: LogsPage(apiClient: holdingApi, rangeController: TimeRangeController()))),
    );
    await tester.tap(find.byKey(const Key('logs_search')));
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(find.byKey(const Key('histogram_placeholder')), findsOneWidget);

    holdingApi.complete([]);
    await tester.pumpAndSettle();
  });

  testWidgets(
      'Given the histogram response is empty, '
      'When there are no log counts to display, '
      'Then the histogram widget renders nothing',
      (tester) async {
    final api = FakeApi(histogram: []);

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: LogsPage(apiClient: api, rangeController: TimeRangeController()))),
    );
    await tester.pumpAndSettle();
    await loadRows(tester);

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
    final api = FakeApi(
      histogram: [
        HistogramBucket(bucket: t0.toIso8601String(), count: 10),
        HistogramBucket(bucket: t1.toIso8601String(), count: 5),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: LogsPage(apiClient: api, rangeController: TimeRangeController()))),
    );
    await tester.pumpAndSettle();
    await loadRows(tester);

    final chart = find.byKey(const Key('histogram_chart'));
    expect(chart, findsOneWidget);

    final callsBefore = api.calls.length;
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
    final api = FakeApi(
      histogram: [HistogramBucket(bucket: t0.toIso8601String(), count: 3)],
    );

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: LogsPage(apiClient: api, rangeController: TimeRangeController()))),
    );
    await tester.pumpAndSettle();
    await loadRows(tester);

    expect(find.byKey(const Key('histogram_chart')), findsOneWidget);

    await tester.tap(find.text('Log distribution'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('histogram_chart')), findsNothing);

    await tester.tap(find.text('Log distribution'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('histogram_chart')), findsOneWidget);
  });
}
