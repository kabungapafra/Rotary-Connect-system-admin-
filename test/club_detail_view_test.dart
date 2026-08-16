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
    child: const Scaffold(body: SingleChildScrollView(child: ClubDetailView())),
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

ClubOfficer _officer(String name, String role, {String status = 'active'}) =>
    ClubOfficer(
      id: 1,
      name: name,
      role: role,
      memberNumber: 'RCM-0042',
      phone: '256772111222',
      email: 'officer@example.com',
      status: status,
    );

ClubOverview _overview({
  int membersActive = 18,
  int membersTotal = 20,
  int membersSuspended = 2,
  int storageBytes = 4404019,
  List<ErrorLogEntry> errors = const [],
  int errorsTotal = 0,
  ClubOfficer? president,
  ClubOfficer? presidentElect,
  ClubOfficer? secretary,
}) => ClubOverview(
  club: _club(),
  attendancePercent: 65,
  president: president,
  presidentElect: presidentElect,
  secretary: secretary,
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
      find.text('Nothing has failed for this club since error tracking began.'),
      findsOneWidget,
    );
  });

  testWidgets('names the three officers with their contact details', (
    tester,
  ) async {
    await setDesktopSize(tester);
    final state = DashboardState()
      ..openClubId = 7
      ..clubs.add(_club())
      ..clubOverview = _overview(
        president: _officer('Grace Nakato', 'Club President'),
        presidentElect: _officer('Peter Okello', 'President-Elect'),
        secretary: _officer('Sarah Nabirye', 'Secretary'),
      );

    await tester.pumpWidget(_wrap(state));

    expect(find.text('PRESIDENT'), findsOneWidget);
    expect(find.text('PRESIDENT-ELECT'), findsOneWidget);
    expect(find.text('SECRETARY'), findsOneWidget);
    expect(find.text('Grace Nakato'), findsOneWidget);
    expect(find.text('Peter Okello'), findsOneWidget);
    expect(find.text('Sarah Nabirye'), findsOneWidget);
    // Contact details are the point of the card — an admin uses them to
    // reach the club, so a name alone is not enough.
    expect(find.text('256772111222'), findsNWidgets(3));
  });

  testWidgets('an unfilled officer post is shown, not hidden', (tester) async {
    await setDesktopSize(tester);
    // A club with no Secretary cannot file minutes or documents, so the
    // vacancy has to be visible rather than the slot silently disappearing.
    final state = DashboardState()
      ..openClubId = 7
      ..clubs.add(_club())
      ..clubOverview = _overview(
        president: _officer('Grace Nakato', 'Club President'),
      );

    await tester.pumpWidget(_wrap(state));

    expect(find.text('SECRETARY'), findsOneWidget);
    expect(find.text('PRESIDENT-ELECT'), findsOneWidget);
    expect(find.text('Not assigned'), findsNWidgets(2));
  });

  testWidgets('finances name who has not paid, not just a count', (
    tester,
  ) async {
    await setDesktopSize(tester);
    // A count alone is not actionable — the admin needs the names to chase.
    final state = DashboardState()
      ..openClubId = 7
      ..clubs.add(_club())
      ..clubOverview = _overview()
      ..clubFinances = ClubFinances(
        duesAmount: 10000,
        duesPeriod: 'quarterly',
        duesPeriodLabel: '2026-Q3',
        duesCollected: 10000,
        duesOutstanding: 20000,
        totalIncome: 45000,
        totalExpenses: 12000,
        duesPaidCount: 1,
        duesUnpaidCount: 2,
        dues: const [
          DuesMember(
            memberId: 1,
            name: 'Grace Nakato',
            role: 'President',
            paid: true,
          ),
          DuesMember(
            memberId: 2,
            name: 'Peter Okello',
            role: 'Member',
            paid: false,
          ),
          DuesMember(
            memberId: 3,
            name: 'Alice Auma',
            role: 'Member',
            paid: false,
          ),
        ],
        recentTransactions: const [],
      );

    await tester.pumpWidget(_wrap(state));

    expect(find.text("Hasn't paid this period"), findsOneWidget);
    expect(find.text('Peter Okello'), findsOneWidget);
    expect(find.text('Alice Auma'), findsOneWidget);
    // Someone who has paid must not appear in the chase list.
    expect(find.text('Grace Nakato'), findsNothing);
  });

  testWidgets('a past event offers no cancel button', (tester) async {
    await setDesktopSize(tester);
    // Past one-off events are kept as a historical record, so there must be
    // nothing to press — the backend would reject it anyway.
    final state = DashboardState()
      ..openClubId = 7
      ..clubs.add(_club())
      ..clubOverview = _overview()
      ..clubEvents = [
        ClubEventOversight(
          id: 1,
          name: 'Charter night',
          meta: '',
          dow: 'FRI',
          eventDate: DateTime(2026, 12, 1),
          rsvpCount: 12,
          isUpcoming: true,
          canCancel: true,
        ),
        ClubEventOversight(
          id: 2,
          name: "Last month's gala",
          meta: '',
          dow: 'MON',
          eventDate: DateTime(2026, 1, 1),
          rsvpCount: 40,
          isUpcoming: false,
          canCancel: false,
        ),
      ];

    await tester.pumpWidget(_wrap(state));

    expect(find.text('Charter night'), findsOneWidget);
    expect(find.text("Last month's gala"), findsOneWidget);
    expect(find.text('12 RSVP'), findsOneWidget);
    // One cancellable event -> exactly one Cancel button.
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('the audit trail names the actor, not just the action', (
    tester,
  ) async {
    await setDesktopSize(tester);
    final state = DashboardState()
      ..openClubId = 7
      ..clubs.add(_club())
      ..clubOverview = _overview()
      ..clubAudit = [
        AuditEntry(
          id: 1,
          actorEmail: 'admin@rotary.org',
          action: 'club.suspended',
          subject: '',
          detail: 'active -> suspended',
          createdAt: DateTime.now().toUtc(),
        ),
      ];

    await tester.pumpWidget(_wrap(state));

    // The raw action key is translated, but the actor is the point.
    expect(find.text('Club suspended'), findsOneWidget);
    expect(find.textContaining('admin@rotary.org'), findsOneWidget);
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
