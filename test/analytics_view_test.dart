// AnalyticsView's error log card is the only place an unhandled backend
// exception is visible at all (no Sentry/Crashlytics configured) — locks
// in both the empty state and that a real entry actually renders, so a
// future refactor can't silently make the list disappear.

import 'package:admin_dashboard/models.dart';
import 'package:admin_dashboard/screens/analytics_view.dart';
import 'package:admin_dashboard/state/dashboard_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

Widget _wrap(DashboardState state) => MaterialApp(
      home: ChangeNotifierProvider.value(
        value: state,
        child: const Scaffold(body: SingleChildScrollView(child: AnalyticsView())),
      ),
    );

void main() {
  // This dashboard is desktop-width by design (fixed sidebar + content
  // grid) — the default test surface is phone-sized and overflows cards
  // unrelated to what's under test here, so every test in this file uses
  // a realistic desktop viewport instead.
  Future<void> setDesktopSize(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('shows the empty state when there are no logged errors',
      (tester) async {
    await setDesktopSize(tester);
    final state = DashboardState();
    await tester.pumpWidget(_wrap(state));
    expect(find.text('No errors recorded.'), findsOneWidget);
  });

  testWidgets('renders a logged error with method, path, and count badge',
      (tester) async {
    await setDesktopSize(tester);
    final state = DashboardState()
      ..errorLogs = [
        ErrorLogEntry(
          id: 1,
          method: 'GET',
          path: '/admin/analytics',
          exceptionType: 'ValueError',
          message: 'boom: simulated failure',
          createdAt: DateTime.now().toUtc(),
        ),
      ];
    await tester.pumpWidget(_wrap(state));

    expect(find.text('No errors recorded.'), findsNothing);
    expect(find.text('GET /admin/analytics'), findsOneWidget);
    expect(find.textContaining('ValueError'), findsOneWidget);
    expect(find.text('1'), findsOneWidget); // count badge
  });
}
