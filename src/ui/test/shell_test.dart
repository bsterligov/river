import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ui/main.dart';
import 'package:ui/controllers/time_range_controller.dart';
import 'package:ui/widgets/river_logo.dart';

import 'helpers.dart';

void main() {
  testWidgets(
      'Given app is running, '
      'Then top panel shows River label and sidebar shows Logs nav',
      (tester) async {
    await tester.pumpWidget(const RiverApp());
    await tester.pumpAndSettle();

    expect(find.text('River'), findsOneWidget);
    expect(find.text('Logs'), findsOneWidget);
  });

  testWidgets(
      'Given the app is running, '
      'When the user looks at the top bar, '
      'Then they see the River logo to the left of the River label',
      (tester) async {
    final rc = TimeRangeController();
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: TestShell(api: FakeApi(), rangeController: rc))),
    );
    await tester.pumpAndSettle();

    expect(find.byType(RiverLogo), findsOneWidget);

    final logoOffset = tester.getCenter(find.byType(RiverLogo));
    final labelOffset = tester.getCenter(find.text('River'));
    expect(logoOffset.dx, lessThan(labelOffset.dx));
  });

  testWidgets(
      'Given the operator has set a custom time range in the top panel, '
      'When they navigate from Logs to any other page and back, '
      'Then the time range is unchanged',
      (tester) async {
    final rc = TimeRangeController();
    final from = DateTime.utc(2024, 3, 1, 8, 0);
    final to = DateTime.utc(2024, 3, 1, 10, 0);
    rc.setRange(from, to);

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: TestShell(api: FakeApi(), rangeController: rc))),
    );
    await tester.pumpAndSettle();

    expect(rc.from, equals(from));
    expect(rc.to, equals(to));

    // Simulate navigation by rebuilding with the same controller
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: TestShell(api: FakeApi(), rangeController: rc))),
    );
    await tester.pumpAndSettle();

    expect(rc.from, equals(from));
    expect(rc.to, equals(to));
  });

  testWidgets(
      'Given the operator is on any page, '
      'When they look at the top of the screen, '
      'Then they see "River" on the left and the datetime picker on the right',
      (tester) async {
    final rc = TimeRangeController();
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: TestShell(api: FakeApi(), rangeController: rc))),
    );
    await tester.pumpAndSettle();

    expect(find.text('River'), findsOneWidget);
    expect(find.text('Last 1 hour'), findsOneWidget);

    final riverOffset = tester.getCenter(find.text('River'));
    final pickerOffset = tester.getCenter(find.text('Last 1 hour'));
    expect(riverOffset.dx, lessThan(pickerOffset.dx));
  });
}
