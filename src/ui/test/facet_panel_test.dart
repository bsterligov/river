import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:river_api/api.dart';

import 'package:ui/pages/logs/logs.dart';
import 'package:ui/time_range_controller.dart';

import 'helpers.dart';

void main() {
  testWidgets(
      'Given the logs page is open and the API returns facets for service_name and severity_text, '
      'When the facet panel finishes loading, '
      'Then two ExpansionTile groups are visible, each expanded, showing value rows with counts',
      (tester) async {
    final api = FakeApi(
      facets: [
        FacetField(field: 'service_name', values: [FacetValue(value: 'svc-a', count: 42)]),
        FacetField(field: 'severity_text', values: [FacetValue(value: 'ERROR', count: 7)]),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: LogsPage(apiClient: api, rangeController: TimeRangeController()))),
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
    final api = FakeApi(
      facets: [
        FacetField(field: 'service_name', values: [FacetValue(value: 'svc-a', count: 3)]),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: LogsPage(apiClient: api, rangeController: TimeRangeController()))),
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
    final api = FakeApi(
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
      MaterialApp(home: Scaffold(body: LogsPage(apiClient: api, rangeController: TimeRangeController()))),
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
    final api = FakeApi(
      facets: [
        FacetField(field: 'service_name', values: [FacetValue(value: 'svc-a', count: 3)]),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: LogsPage(apiClient: api, rangeController: TimeRangeController()))),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('svc-a'));
    await tester.pumpAndSettle();
    expect(api.calls.last['filter'], equals('service_name:svc-a'));

    await tester.tap(find.text('svc-a'));
    await tester.pumpAndSettle();
    expect(api.calls.last['filter'], isNull);
  });

  testWidgets(
      'Given the /v1/logs/facets request is in flight, '
      'When the panel is rendered, '
      'Then a grey shimmer placeholder is shown in place of facet content',
      (tester) async {
    final api = HoldingFacetApi();

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: LogsPage(apiClient: api, rangeController: TimeRangeController()))),
    );
    await tester.pump();

    expect(find.byKey(const Key('facet_shimmer')), findsOneWidget);

    api.complete([]);
    await tester.pumpAndSettle();
  });

  testWidgets(
      'Given the /v1/logs/facets request fails, '
      'When the error is received, '
      'Then the facet panel shows nothing',
      (tester) async {
    final api = FakeApi(facetError: Exception('network error'));

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: LogsPage(apiClient: api, rangeController: TimeRangeController()))),
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
    final rc = TimeRangeController();
    final countingApi = CountingFacetApi(
      onFetch: () {},
      facets: [
        FacetField(field: 'service_name', values: [FacetValue(value: 'svc', count: 1)]),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: TestShell(api: countingApi, rangeController: rc))),
    );
    await tester.pumpAndSettle();

    final fetchesAfterInit = countingApi.facetFetchCount;

    await tester.tap(find.text('Last 1 hour'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Last 15 minutes'));
    await tester.pumpAndSettle();

    expect(countingApi.facetFetchCount, greaterThan(fetchesAfterInit));
  });
}
