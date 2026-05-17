import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:river_api/api.dart';

import 'package:ui/pages/metrics/metrics.dart';
import 'package:ui/pages/metrics/metrics_controller.dart';
import 'package:ui/controllers/time_range_controller.dart';
import 'package:ui/theme/app_theme.dart';

class _FakeMetricsApi extends DefaultApi {
  final List<String> names;
  final List<MetricPoint> points;
  final Exception? namesError;

  _FakeMetricsApi({
    this.names = const ['cpu_usage', 'memory_bytes', 'http_requests_total'],
    this.points = const [],
    this.namesError,
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
      'Given the user is on the All Metrics tab, '
      'When they tap one or more metrics, '
      'Then those metrics are marked as selected',
      (tester) async {
        final api = _FakeMetricsApi();
        final rangeController = TimeRangeController();
        final tabController = TabController(length: 2, vsync: tester);

        await tester.pumpWidget(_metricsPage(api, rangeController, tabController));
        await tester.pumpAndSettle();

        // Tap cpu_usage to select it.
        await tester.tap(find.text('cpu_usage'));
        await tester.pump();

        // The selected row should have the highlight colour.
        final selectedContainer = tester.widget<Container>(
          find
              .ancestor(of: find.text('cpu_usage'), matching: find.byType(Container))
              .first,
        );
        expect(selectedContainer.color, AppColors.rowSelected);

        tabController.dispose();
        rangeController.dispose();
      },
    );

    testWidgets(
      'Given the user switches from Graph back to All Metrics, '
      'When the tab changes, '
      'Then previously selected metrics remain selected',
      (tester) async {
        final api = _FakeMetricsApi();
        final rangeController = TimeRangeController();
        final tabController = TabController(length: 2, vsync: tester);

        await tester.pumpWidget(_metricsPage(api, rangeController, tabController));
        await tester.pumpAndSettle();

        await tester.tap(find.text('cpu_usage'));
        await tester.pump();

        // Switch to Graph tab and back.
        tabController.animateTo(1);
        await tester.pumpAndSettle();
        tabController.animateTo(0);
        await tester.pumpAndSettle();

        final selectedContainer = tester.widget<Container>(
          find
              .ancestor(of: find.text('cpu_usage'), matching: find.byType(Container))
              .first,
        );
        expect(selectedContainer.color, AppColors.rowSelected);

        tabController.dispose();
        rangeController.dispose();
      },
    );
  });

  group('MetricsPage — Graph tab', () {
    testWidgets(
      'Given no metrics are selected, '
      'When the Graph tab is active, '
      'Then a prompt to select metrics is shown',
      (tester) async {
        final api = _FakeMetricsApi();
        final rangeController = TimeRangeController();
        final tabController = TabController(length: 2, vsync: tester);

        await tester.pumpWidget(_metricsPage(api, rangeController, tabController));
        await tester.pumpAndSettle();

        tabController.animateTo(1);
        await tester.pumpAndSettle();

        expect(find.textContaining('Select one or more metrics'), findsOneWidget);

        tabController.dispose();
        rangeController.dispose();
      },
    );

    test(
      'Given one or more metrics are selected, '
      'When loadSeries is called, '
      'Then series map is populated for each selected metric',
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

        controller.toggleSelection('cpu_usage');
        await controller.loadSeries();

        expect(controller.series.containsKey('cpu_usage'), isTrue);
        expect(controller.series['cpu_usage']!.length, 1);
        expect(controller.series['cpu_usage']!.first.value, 42);

        controller.dispose();
        rangeController.dispose();
      },
    );
  });
}
