import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:river_api/api.dart';

import 'package:ui/pages/metrics/metrics.dart';
import 'package:ui/controllers/time_range_controller.dart';
import 'package:ui/theme/app_theme.dart';

class _FakeMetricsApi extends DefaultApi {
  final List<String> names;
  final List<MetricPoint> points;
  final Exception? namesError;
  final Exception? metricsError;

  _FakeMetricsApi({
    this.names = const ['cpu_usage', 'memory_bytes', 'http_requests_total'],
    this.points = const [],
    this.namesError,
    this.metricsError,
  });

  @override
  Future<List<String>?> getMetricNames() async {
    if (namesError != null) throw namesError!;
    return names;
  }

  @override
  Future<List<MetricPoint>?> getMetrics({
    String? filter,
    String? from,
    String? to,
    String? step,
  }) async {
    if (metricsError != null) throw metricsError!;
    return points;
  }
}

Widget _metricsPage(
  DefaultApi api,
  TimeRangeController rangeController,
  TabController tabController,
) =>
    MaterialApp(
      theme: appTheme,
      home: Scaffold(
        body: SizedBox(
          width: 800,
          height: 600,
          child: MetricsPage(
            apiClient: api,
            rangeController: rangeController,
            tabController: tabController,
          ),
        ),
      ),
    );

void main() {
  group('MetricsPage — All Metrics tab', () {
    testWidgets(
      'Given the user navigates to the Metrics page, '
      'When the All Metrics tab is active, '
      'Then a list of all available metric names is displayed',
      (tester) async {
        final api = _FakeMetricsApi();
        final rangeController = TimeRangeController();
        final tabController = TabController(length: 2, vsync: tester);

        await tester.pumpWidget(_metricsPage(api, rangeController, tabController));
        await tester.pumpAndSettle();

        expect(find.text('cpu_usage'), findsOneWidget);
        expect(find.text('memory_bytes'), findsOneWidget);
        expect(find.text('http_requests_total'), findsOneWidget);

        tabController.dispose();
        rangeController.dispose();
      },
    );

    testWidgets(
      'Given the API returns an error, '
      'When names cannot be loaded, '
      'Then an error message is displayed',
      (tester) async {
        final api = _FakeMetricsApi(
          names: [],
          namesError: Exception('network error'),
        );
        final rangeController = TimeRangeController();
        final tabController = TabController(length: 2, vsync: tester);

        await tester.pumpWidget(_metricsPage(api, rangeController, tabController));
        await tester.pumpAndSettle();

        expect(find.textContaining('network error'), findsOneWidget);

        tabController.dispose();
        rangeController.dispose();
      },
    );

    testWidgets(
      'Given the API returns an empty list, '
      'When no metrics exist, '
      'Then a "No metrics found" message is displayed',
      (tester) async {
        final api = _FakeMetricsApi(names: []);
        final rangeController = TimeRangeController();
        final tabController = TabController(length: 2, vsync: tester);

        await tester.pumpWidget(_metricsPage(api, rangeController, tabController));
        await tester.pumpAndSettle();

        expect(find.text('No metrics found.'), findsOneWidget);

        tabController.dispose();
        rangeController.dispose();
      },
    );
  });

  group('MetricsPage — Graph tab', () {
    testWidgets(
      'Given no metrics are selected, '
      'When the Graph tab is active, '
      'Then the metric autocomplete input is shown',
      (tester) async {
        final api = _FakeMetricsApi();
        final rangeController = TimeRangeController();
        final tabController = TabController(length: 2, vsync: tester, initialIndex: 1);

        await tester.pumpWidget(_metricsPage(api, rangeController, tabController));
        await tester.pumpAndSettle();

        expect(find.widgetWithText(TextField, ''), findsWidgets);
        expect(find.text('Add a metric above to render a graph.'), findsOneWidget);

        tabController.dispose();
        rangeController.dispose();
      },
    );

    testWidgets(
      'Given a metric is added via Graph tab, '
      'When it is displayed as a chip and the delete icon is tapped, '
      'Then the metric is removed',
      (tester) async {
        final points = [
          MetricPoint(timestamp: '2024-01-01T00:00:00Z', value: 10),
          MetricPoint(timestamp: '2024-01-01T01:00:00Z', value: 20),
        ];
        final api = _FakeMetricsApi(points: points);
        final rangeController = TimeRangeController();
        final tabController = TabController(length: 2, vsync: tester, initialIndex: 1);

        await tester.pumpWidget(_metricsPage(api, rangeController, tabController));
        await tester.pumpAndSettle();

        // Type into the autocomplete and select.
        await tester.enterText(find.byType(TextField).first, 'cpu');
        await tester.pump();
        // The autocomplete dropdown should show cpu_usage.
        await tester.tap(find.text('cpu_usage').first);
        await tester.pump();

        // Chip should be shown.
        expect(find.byType(Chip), findsWidgets);

        // Tap the delete icon.
        await tester.tap(find.byIcon(Icons.close).first);
        await tester.pump();

        expect(find.byType(Chip), findsNothing);

        tabController.dispose();
        rangeController.dispose();
      },
    );

    testWidgets(
      'Given a metric is added via autocomplete, '
      'When selection is confirmed, '
      'Then MetricsChart is displayed automatically',
      (tester) async {
        final points = [
          MetricPoint(timestamp: '2024-01-01T00:00:00Z', value: 10),
          MetricPoint(timestamp: '2024-01-01T01:00:00Z', value: 20),
        ];
        final api = _FakeMetricsApi(points: points);
        final rangeController = TimeRangeController();
        final tabController = TabController(length: 2, vsync: tester, initialIndex: 1);

        await tester.pumpWidget(_metricsPage(api, rangeController, tabController));
        await tester.pumpAndSettle();

        // Add a metric via autocomplete.
        await tester.enterText(find.byType(TextField).first, 'cpu');
        await tester.pump();
        await tester.tap(find.text('cpu_usage').first);
        await tester.pumpAndSettle();

        expect(find.byType(MetricsChart), findsOneWidget);

        tabController.dispose();
        rangeController.dispose();
      },
    );

    testWidgets(
      'Given a metric is added and the time range changes, '
      'When the range updates, '
      'Then series are reloaded automatically',
      (tester) async {
        final points = [
          MetricPoint(timestamp: '2024-01-01T00:00:00Z', value: 10),
          MetricPoint(timestamp: '2024-01-01T01:00:00Z', value: 20),
        ];
        final api = _FakeMetricsApi(points: points);
        final rangeController = TimeRangeController();
        final tabController = TabController(length: 2, vsync: tester, initialIndex: 1);

        await tester.pumpWidget(_metricsPage(api, rangeController, tabController));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).first, 'cpu');
        await tester.pump();
        await tester.tap(find.text('cpu_usage').first);
        await tester.pumpAndSettle();

        // Trigger a range change.
        rangeController.setRange(
          DateTime.now().subtract(const Duration(hours: 2)),
          DateTime.now(),
        );
        await tester.pumpAndSettle();

        // Chart should still be displayed.
        expect(find.byType(MetricsChart), findsOneWidget);

        tabController.dispose();
        rangeController.dispose();
      },
    );

    testWidgets(
      'Given a metric is added and loading fails, '
      'Then an error message is shown',
      (tester) async {
        final api = _FakeMetricsApi(metricsError: Exception('VM unavailable'));
        final rangeController = TimeRangeController();
        final tabController = TabController(length: 2, vsync: tester, initialIndex: 1);

        await tester.pumpWidget(_metricsPage(api, rangeController, tabController));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).first, 'cpu');
        await tester.pump();
        await tester.tap(find.text('cpu_usage').first);
        await tester.pumpAndSettle();

        expect(find.textContaining('VM unavailable'), findsOneWidget);

        tabController.dispose();
        rangeController.dispose();
      },
    );

    testWidgets(
      'Given a metric is selected in Graph tab, '
      'When viewing All Metrics tab, '
      'Then no row is highlighted (selection is independent)',
      (tester) async {
        final api = _FakeMetricsApi();
        final rangeController = TimeRangeController();
        final tabController = TabController(length: 2, vsync: tester, initialIndex: 1);

        await tester.pumpWidget(_metricsPage(api, rangeController, tabController));
        await tester.pumpAndSettle();

        // Add cpu_usage in Graph tab.
        await tester.enterText(find.byType(TextField).first, 'cpu');
        await tester.pump();
        await tester.tap(find.text('cpu_usage').first);
        await tester.pump();

        // Switch to All Metrics.
        tabController.animateTo(0);
        await tester.pumpAndSettle();

        // cpu_usage row should NOT be highlighted.
        final container = tester.widget<Container>(
          find
              .ancestor(of: find.text('cpu_usage'), matching: find.byType(Container))
              .first,
        );
        expect(container.color, isNot(AppColors.rowSelected));

        tabController.dispose();
        rangeController.dispose();
      },
    );
  });

  group('MetricsChart', () {
    testWidgets(
      'Given series with data, '
      'When MetricsChart is rendered, '
      'Then a CustomPaint is drawn and no exception is thrown',
      (tester) async {
        final series = {
          'cpu_usage': [
            MetricPoint(timestamp: '2024-01-01T00:00:00Z', value: 10),
            MetricPoint(timestamp: '2024-01-01T01:00:00Z', value: 20),
          ],
        };

        await tester.pumpWidget(
          MaterialApp(
            home: SizedBox(
              width: 400,
              height: 300,
              child: MetricsChart(series: series),
            ),
          ),
        );

        expect(find.byType(MetricsChart), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Given multiple series, '
      'When MetricsChart is rendered, '
      'Then the chart handles multi-series without error',
      (tester) async {
        final series = {
          'cpu_usage': [
            MetricPoint(timestamp: '2024-01-01T00:00:00Z', value: 10),
            MetricPoint(timestamp: '2024-01-01T01:00:00Z', value: 20),
          ],
          'memory_bytes': [
            MetricPoint(timestamp: '2024-01-01T00:00:00Z', value: 1000),
            MetricPoint(timestamp: '2024-01-01T01:00:00Z', value: 2000),
          ],
        };

        await tester.pumpWidget(
          MaterialApp(
            home: SizedBox(
              width: 400,
              height: 300,
              child: MetricsChart(series: series),
            ),
          ),
        );

        expect(find.byType(MetricsChart), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Given series with a single data point, '
      'When MetricsChart is rendered, '
      'Then no exception is thrown',
      (tester) async {
        final series = {
          'cpu_usage': [
            MetricPoint(timestamp: '2024-01-01T00:00:00Z', value: 42),
          ],
        };

        await tester.pumpWidget(
          MaterialApp(
            home: SizedBox(
              width: 400,
              height: 300,
              child: MetricsChart(series: series),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Given all series are empty, '
      'When MetricsChart is rendered, '
      'Then a no-data message is shown',
      (tester) async {
        final series = {
          'cpu_usage': <MetricPoint>[],
        };

        await tester.pumpWidget(
          MaterialApp(
            home: SizedBox(
              width: 400,
              height: 300,
              child: MetricsChart(series: series),
            ),
          ),
        );

        expect(
          find.text('No data for selected metrics in this time range.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Given an empty series map, '
      'When MetricsChart is rendered, '
      'Then a no-data message is shown',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: SizedBox(
              width: 400,
              height: 300,
              child: MetricsChart(series: {}),
            ),
          ),
        );

        expect(
          find.text('No data for selected metrics in this time range.'),
          findsOneWidget,
        );
      },
    );
  });

  group('MetricsController', () {
    test(
      'Given the API returns names, '
      'When loadNames is called, '
      'Then names are sorted and available',
      () async {
        final api = _FakeMetricsApi(names: ['z_metric', 'a_metric', 'cpu_usage']);
        final rangeController = TimeRangeController();
        final controller = MetricsController(
          apiClient: api,
          rangeController: rangeController,
        );

        await controller.loadNames();

        expect(controller.names, ['a_metric', 'cpu_usage', 'z_metric']);
        expect(controller.error, isNull);

        controller.dispose();
        rangeController.dispose();
      },
    );

    test(
      'Given the API fails, '
      'When loadNames is called, '
      'Then error is set and names remains empty',
      () async {
        final api = _FakeMetricsApi(
          names: [],
          namesError: Exception('server error'),
        );
        final rangeController = TimeRangeController();
        final controller = MetricsController(
          apiClient: api,
          rangeController: rangeController,
        );

        await controller.loadNames();

        expect(controller.names, isEmpty);
        expect(controller.error, isNotNull);
        expect(controller.error, contains('server error'));

        controller.dispose();
        rangeController.dispose();
      },
    );

    test(
      'Given a metric name, '
      'When fetchSeries is called, '
      'Then it returns the points from the API',
      () async {
        final points = [
          MetricPoint(timestamp: '2024-01-01T00:00:00Z', value: 42),
        ];
        final api = _FakeMetricsApi(points: points);
        final rangeController = TimeRangeController();
        final controller = MetricsController(
          apiClient: api,
          rangeController: rangeController,
        );

        final result = await controller.fetchSeries('cpu_usage', '2024-01-01T00:00:00Z', '2024-01-01T01:00:00Z');

        expect(result.length, 1);
        expect(result.first.value, 42);

        controller.dispose();
        rangeController.dispose();
      },
    );
  });
}
