// The club management screen is where an admin decides whether a club is
// healthy — its usage tiles and error list are read as fact. These lock in
// the parts that would mislead rather than merely look wrong if they broke:
// active-vs-total members, storage as a human size, and the club falling
// back gracefully after it's deleted from this very screen.

import 'package:admin_dashboard/api_client.dart';
import 'package:admin_dashboard/models.dart';
import 'package:admin_dashboard/screens/club_detail_view.dart';
import 'package:admin_dashboard/state/dashboard_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

Widget _wrap(DashboardState state) => MaterialApp(
  home: ChangeNotifierProvider.value(
    value: state,
    child: const Scaffold(
      body: SingleChildScrollView(child: ClubDetailView()),
    ),
  ),
);

Club _club({String status = 'active', bool smsEnabled = true}) => Club(
  id: 7,
  name: 'Rotary Club of Mbalwa',
  district: '9213',
  location: 'Kampala',
  members: 20,
  status: status,
  feeAmount: 50000,
  lastPaidDate: '01 Aug 2026',
  nextDueDate: '01 Sep 2026',
  paymentStatus: 'paid',
  joined: '12 Jul 2026',
  smsEnabled: smsEnabled,
);

ClubOverview _overview({
  int membersActive = 18,
  int membersTotal = 20,
  int membersSuspended = 2,
  int storageBytes = 4404019,
  List<ErrorLogEntry> errors = const [],
  int errorsTotal = 0,
}) => ClubOverview(
  club: _club(),
  attendancePercent: 65,
  usage: ClubUsage(
    membersTotal: membersTotal,
    membersActive: membersActive,
    membersSuspended: membersSuspended,
    smsSent: 143,
    smsFailed: 2,
    storageBytes: storageBytes,
    storagePhotos: 31,
    storageDocuments: 4,
    errorsTotal: errorsTotal,
  ),
  recentErrors: errors,
);

void main() {
  // Desktop viewport, same reasoning as the other view tests: this
  // dashboard is laid out for a sidebar + content grid.
  Future<void> setDesktopSize(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('headline member count is active members, not the total', (
    tester,
  ) async {
    await setDesktopSize(tester);
    final state = DashboardState()
      ..openClubId = 7
      ..clubs.add(_club())
      ..clubOverview = _overview();

    await tester.pumpWidget(_wrap(state));

    // A club that has shed members must not read as fully active: the big
    // number is the active count, with the total relegated to the detail.
    expect(find.text('18'), findsOneWidget);
    expect(find.text('20 total · 2 suspended'), findsOneWidget);
  });

  testWidgets('storage is shown as a human size, not a raw byte count', (
    tester,
  ) async {
    await setDesktopSize(tester);
    final state = DashboardState()
      ..openClubId = 7
      ..clubs.add(_club())
      ..clubOverview = _overview(storageBytes: 4404019);

    await tester.pumpWidget(_wrap(state));

    expect(find.text('4.2 MB'), findsOneWidget);
    expect(find.text('4404019'), findsNothing);
    expect(find.text('31 photos · 4 documents'), findsOneWidget);
  });

  testWidgets('an error the club hit is listed with its route', (tester) async {
    await setDesktopSize(tester);
    final state = DashboardState()
      ..openClubId = 7
      ..clubs.add(_club())
      ..clubOverview = _overview(
        errorsTotal: 1,
        errors: [
          ErrorLogEntry(
            id: 1,
            method: 'GET',
            path: '/club/events',
            exceptionType: 'OperationalError',
            message: 'SSL connection has been closed unexpectedly',
            createdAt: DateTime.now().toUtc(),
          ),
        ],
      );

    await tester.pumpWidget(_wrap(state));

    expect(find.text('GET /club/events'), findsOneWidget);
    expect(find.textContaining('OperationalError'), findsOneWidget);
  });

  testWidgets('a club with no recorded problems says so explicitly', (
    tester,
  ) async {
    await setDesktopSize(tester);
    final state = DashboardState()
      ..openClubId = 7
      ..clubs.add(_club())
      ..clubOverview = _overview();

    await tester.pumpWidget(_wrap(state));

    expect(
      find.text(
        'Nothing has failed for this club since error tracking began.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('deleting the club from this screen falls back, not crashes', (
    tester,
  ) async {
    await setDesktopSize(tester);
    // Deleting is one of the actions offered here, so the club can vanish
    // while the screen is still mounted. It must degrade to a way back
    // rather than rendering a header for something that no longer exists.
    final state = DashboardState()
      ..openClubId = 7
      ..clubOverview = _overview();

    await tester.pumpWidget(_wrap(state));

    expect(find.text('This club is no longer available.'), findsOneWidget);
    expect(find.text('Back to clubs'), findsOneWidget);
    expect(find.text('Rotary Club of Mbalwa'), findsNothing);
  });

  testWidgets('the suspend action reflects the club\'s current state', (
    tester,
  ) async {
    await setDesktopSize(tester);
    final state = DashboardState()
      ..openClubId = 7
      ..clubs.add(_club(status: 'suspended', smsEnabled: false))
      ..clubOverview = _overview();

    await tester.pumpWidget(_wrap(state));

    // A suspended club offers to activate, not to suspend again.
    expect(find.text('Activate Club'), findsOneWidget);
    expect(find.text('Suspend Club'), findsNothing);
    expect(find.text('Activate SMS'), findsOneWidget);
  });
}
