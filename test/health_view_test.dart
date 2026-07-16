// The System Health page is the only place a member's sign-in trouble
// (failed PINs, lockouts) and API slowness are visible to the admin —
// these lock in that a recorded event actually renders with the member
// and club named, and that an unmatched identifier is shown as such
// rather than silently dropped.

import 'package:admin_dashboard/models.dart';
import 'package:admin_dashboard/screens/health_view.dart';
import 'package:admin_dashboard/state/dashboard_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

Widget _wrap(DashboardState state) => MaterialApp(
      home: ChangeNotifierProvider.value(
        value: state,
        child: const Scaffold(body: SingleChildScrollView(child: HealthView())),
      ),
    );

MonitoringData _data({List<MemberEventEntry>? events, List<SlowRequestEntry>? slow}) =>
    MonitoringData(
      memberEvents: events ?? [],
      slowRequests: slow ?? [],
      eventsToday: events?.length ?? 0,
      slowToday: slow?.length ?? 0,
    );

void main() {
  Future<void> setDesktopSize(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('shows empty states when nothing has gone wrong', (tester) async {
    await setDesktopSize(tester);
    final state = DashboardState()..monitoring = _data();
    await tester.pumpWidget(_wrap(state));
    expect(find.text('No member issues recorded — all quiet.'), findsOneWidget);
    expect(find.textContaining('the API has been fast'), findsOneWidget);
  });

  testWidgets('renders a failed sign-in with member and club named', (tester) async {
    await setDesktopSize(tester);
    final state = DashboardState()
      ..monitoring = _data(events: [
        MemberEventEntry(
          id: 1,
          kind: 'login_failed',
          identifier: 'RC-0007',
          memberName: 'Jane Doe',
          clubName: 'Rotary Club of Mbalwa',
          detail: 'Wrong PIN entered',
          createdAt: DateTime.now().toUtc(),
        ),
      ]);
    await tester.pumpWidget(_wrap(state));
    expect(find.text('Jane Doe'), findsOneWidget);
    expect(find.text('Rotary Club of Mbalwa'), findsOneWidget);
    expect(find.text('Failed sign-in'), findsOneWidget);
    expect(find.text('Wrong PIN entered'), findsOneWidget);
  });

  testWidgets('an unmatched identifier is shown as Unknown, not dropped', (tester) async {
    await setDesktopSize(tester);
    final state = DashboardState()
      ..monitoring = _data(events: [
        MemberEventEntry(
          id: 2,
          kind: 'login_failed',
          identifier: 'RC-9999',
          memberName: null,
          clubName: null,
          detail: 'Unknown member number/phone',
          createdAt: DateTime.now().toUtc(),
        ),
      ]);
    await tester.pumpWidget(_wrap(state));
    expect(find.text('Unknown (RC-9999)'), findsOneWidget);
  });

  testWidgets('a slow request renders with its duration', (tester) async {
    await setDesktopSize(tester);
    final state = DashboardState()
      ..monitoring = _data(slow: [
        SlowRequestEntry(
          id: 1,
          method: 'GET',
          path: '/club/me/summary',
          statusCode: 200,
          durationMs: 4200,
          createdAt: DateTime.now().toUtc(),
        ),
      ]);
    await tester.pumpWidget(_wrap(state));
    expect(find.text('GET /club/me/summary'), findsOneWidget);
    expect(find.text('4200ms'), findsOneWidget);
  });
}
