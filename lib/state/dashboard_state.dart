import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';

/// Single shared app state for the admin dashboard, mirroring the source
/// design's one-component `state` object and its actions 1:1 (same seed
/// data, same view/modal/menu flags, same toggle & toast behavior). This is
/// a self-contained prototype exactly like the source bundle — no backend
/// calls, everything lives in memory.
class DashboardState extends ChangeNotifier {
  String view = 'dashboard';
  Color accentColor = AdminColors.accent;

  final List<Club> clubs = [
    Club(
        id: 1,
        name: 'Rotary Club of Mbalwa',
        district: 'D9213',
        location: 'Kampala, Uganda',
        members: 62,
        status: 'active',
        feeAmount: 350000,
        lastPaidDate: '12 Jul 2026',
        nextDueDate: '12 Aug 2026',
        paymentStatus: 'paid',
        joined: '03 Jan 2022'),
    Club(
        id: 2,
        name: 'Rotary Club of Westlands',
        district: 'D9212',
        location: 'Nairobi, Kenya',
        members: 48,
        status: 'active',
        feeAmount: 180000,
        lastPaidDate: '04 Jul 2026',
        nextDueDate: '11 Jul 2026',
        paymentStatus: 'due-soon',
        joined: '17 Jun 2021'),
    Club(
        id: 3,
        name: 'Rotary Club of Kigali Central',
        district: 'D9150',
        location: 'Kigali, Rwanda',
        members: 33,
        status: 'suspended',
        feeAmount: 70000,
        lastPaidDate: '21 May 2026',
        nextDueDate: '21 Jun 2026',
        paymentStatus: 'overdue',
        joined: '09 Nov 2023'),
    Club(
        id: 4,
        name: 'Rotary Club of Dar Harbour',
        district: 'D9211',
        location: 'Dar es Salaam, Tanzania',
        members: 71,
        status: 'active',
        feeAmount: 350000,
        lastPaidDate: '30 Jun 2026',
        nextDueDate: '30 Jul 2026',
        paymentStatus: 'paid',
        joined: '22 Feb 2020'),
    Club(
        id: 5,
        name: 'Rotary Club of Lusaka North',
        district: 'D9210',
        location: 'Lusaka, Zambia',
        members: 29,
        status: 'active',
        feeAmount: 70000,
        lastPaidDate: '15 Jun 2026',
        nextDueDate: '15 Jul 2026',
        paymentStatus: 'due-soon',
        joined: '14 May 2024'),
    Club(
        id: 6,
        name: 'Rotary Club of Accra Coast',
        district: 'D9102',
        location: 'Accra, Ghana',
        members: 55,
        status: 'active',
        feeAmount: 180000,
        lastPaidDate: '02 Jul 2026',
        nextDueDate: '02 Aug 2026',
        paymentStatus: 'paid',
        joined: '30 Mar 2022'),
  ];

  final List<Member> members = [
    Member(id: 1, name: 'Grace Nabirye', phone: '+256 772 145 890', club: 'Rotary Club of Mbalwa', status: 'active'),
    Member(id: 2, name: 'Daniel Otieno', phone: '+254 712 334 210', club: 'Rotary Club of Westlands', status: 'active'),
    Member(id: 3, name: 'Aline Uwase', phone: '+250 788 210 445', club: 'Rotary Club of Kigali Central', status: 'suspended'),
    Member(id: 4, name: 'Samuel Mushi', phone: '+255 754 902 118', club: 'Rotary Club of Dar Harbour', status: 'active'),
    Member(id: 5, name: 'Beatrice Phiri', phone: '+260 977 664 330', club: 'Rotary Club of Lusaka North', status: 'active'),
    Member(id: 6, name: 'Kwame Boateng', phone: '+233 244 887 512', club: 'Rotary Club of Accra Coast', status: 'active'),
    Member(id: 7, name: 'Esther Kato', phone: '+256 701 552 903', club: 'Rotary Club of Mbalwa', status: 'suspended'),
    Member(id: 8, name: 'John Mwangi', phone: '+254 733 210 665', club: 'Rotary Club of Westlands', status: 'active'),
  ];

  int _nextId = 7;

  bool newClubOpen = false;
  int wizardStep = 0;
  ClubDraft draft = ClubDraft();

  int? paymentModalClubId;
  PaymentDraft paymentDraft = PaymentDraft();

  int? statsModalClubId;

  String memberSearch = '';
  String memberClubFilter = 'all';
  String memberStatusFilter = 'all';

  String? toastMessage;
  Timer? _toastTimer;

  void _update(VoidCallback fn) {
    fn();
    notifyListeners();
  }

  void _toast(String msg) {
    _toastTimer?.cancel();
    _update(() => toastMessage = msg);
    _toastTimer = Timer(const Duration(milliseconds: 2600), () {
      _update(() => toastMessage = null);
    });
  }

  void _go(String v) => _update(() => view = v);

  void goDashboard() => _go('dashboard');
  void goClubs() => _go('clubs');
  void goMembers() => _go('members');
  void goBilling() => _go('billing');
  void goAnalytics() => _go('analytics');
  void goSms() => _go('sms');

  void setAccentColor(Color c) => _update(() => accentColor = c);

  // ── new club wizard ──────────────────────────────────────────────────
  void openNewClub() => _update(() {
        newClubOpen = true;
        wizardStep = 0;
        draft = ClubDraft();
      });
  void closeNewClub() => _update(() => newClubOpen = false);
  void nextStep() => _update(() => wizardStep = math.min(2, wizardStep + 1));
  void prevStep() => _update(() => wizardStep = math.max(0, wizardStep - 1));

  void setDraftName(String v) => _update(() => draft.name = v);
  void setDraftDistrict(String v) => _update(() => draft.district = v);
  void setDraftLocation(String v) => _update(() => draft.location = v);
  void setDraftEmail(String v) => _update(() => draft.email = v);
  void setDraftPhone(String v) => _update(() => draft.phone = v);
  void setDraftMembers(String v) => _update(() => draft.members = v);
  void setDraftFeeAmount(String v) => _update(() => draft.feeAmount = v);
  void setDraftFirstPaymentDate(String v) => _update(() => draft.firstPaymentDate = v);
  void setDraftNextDueDate(String v) => _update(() => draft.nextDueDate = v);

  bool get nextDisabled => wizardStep == 0 && draft.name.trim().isEmpty;

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  void createClub() {
    final parsedMembers = int.tryParse(draft.members) ?? 0;
    final membersNum = parsedMembers == 0 ? 10 : parsedMembers;
    final feeNum = int.tryParse(draft.feeAmount) ?? 0;
    final now = DateTime.now();
    final joined = '${now.day.toString().padLeft(2, '0')} ${_months[now.month - 1]} ${now.year}';
    final newClub = Club(
      id: _nextId,
      name: draft.name.trim().isEmpty ? 'Untitled Club' : draft.name.trim(),
      district: draft.district.trim().isEmpty ? '—' : draft.district.trim(),
      location: draft.location.trim().isEmpty ? '—' : draft.location.trim(),
      members: membersNum,
      status: 'active',
      feeAmount: feeNum,
      lastPaidDate: draft.firstPaymentDate.trim().isEmpty ? '—' : draft.firstPaymentDate.trim(),
      nextDueDate: draft.nextDueDate.trim().isEmpty ? '—' : draft.nextDueDate.trim(),
      paymentStatus: 'paid',
      joined: joined,
    );
    _update(() {
      clubs.insert(0, newClub);
      _nextId++;
      newClubOpen = false;
    });
    _toast('${newClub.name} onboarded successfully');
  }

  // ── clubs ───────────────────────────────────────────────────────────
  void toggleClubStatus(int id) {
    final club = clubs.firstWhere((c) => c.id == id);
    final willBe = club.status == 'active' ? 'suspended' : 'activated';
    _update(() => club.status = club.status == 'active' ? 'suspended' : 'active');
    _toast('${club.name} $willBe');
  }

  void openPaymentModal(int id) {
    final club = clubs.firstWhere((c) => c.id == id);
    _update(() {
      paymentModalClubId = id;
      paymentDraft = PaymentDraft(amount: club.feeAmount > 0 ? club.feeAmount.toString() : '');
    });
  }

  void closePaymentModal() => _update(() => paymentModalClubId = null);
  void setPaymentAmount(String v) => _update(() => paymentDraft.amount = v);
  void setPaymentDatePaid(String v) => _update(() => paymentDraft.datePaid = v);
  void setPaymentNextDue(String v) => _update(() => paymentDraft.nextDue = v);

  void savePayment() {
    final id = paymentModalClubId;
    if (id == null) return;
    final club = clubs.firstWhere((c) => c.id == id);
    _update(() {
      final parsedAmount = int.tryParse(paymentDraft.amount) ?? 0;
      if (parsedAmount != 0) club.feeAmount = parsedAmount;
      if (paymentDraft.datePaid.trim().isNotEmpty) club.lastPaidDate = paymentDraft.datePaid.trim();
      if (paymentDraft.nextDue.trim().isNotEmpty) club.nextDueDate = paymentDraft.nextDue.trim();
      club.paymentStatus = 'paid';
      paymentModalClubId = null;
    });
    _toast('Payment recorded for ${club.name}');
  }

  void openStatsModal(int id) => _update(() => statsModalClubId = id);
  void closeStatsModal() => _update(() => statsModalClubId = null);

  // ── members ─────────────────────────────────────────────────────────
  void setMemberSearch(String v) => _update(() => memberSearch = v);
  void setMemberClubFilter(String v) => _update(() => memberClubFilter = v);
  void setMemberStatusFilter(String v) => _update(() => memberStatusFilter = v);

  void toggleMemberStatus(int id) {
    final m = members.firstWhere((m) => m.id == id);
    final willBe = m.status == 'active' ? 'suspended' : 'reactivated';
    _update(() => m.status = m.status == 'active' ? 'suspended' : 'active');
    _toast('${m.name} $willBe');
  }

  void resetPassword(int id) {
    final m = members.firstWhere((m) => m.id == id);
    _toast('Password reset link sent to ${m.name}');
  }

  void viewActivity(int id) {
    final m = members.firstWhere((m) => m.id == id);
    _toast('Opening activity log for ${m.name}');
  }

  // ── derived data ────────────────────────────────────────────────────
  int get totalClubs => clubs.length;
  int get totalMembers => clubs.fold(0, (sum, c) => sum + c.members);
  int get activeClubs => clubs.where((c) => c.status == 'active').length;
  int get activeMembersCount => members.where((m) => m.status == 'active').length;

  List<Club> get recentClubs => clubs.take(5).toList();
  List<String> get clubNameOptions => clubs.map((c) => c.name).toList();

  List<Member> get filteredMembers {
    final q = memberSearch.trim().toLowerCase();
    return members.where((m) {
      final matchesQ = q.isEmpty || m.name.toLowerCase().contains(q) || m.phone.contains(q);
      final matchesClub = memberClubFilter == 'all' || m.club == memberClubFilter;
      final matchesStatus = memberStatusFilter == 'all' || m.status == memberStatusFilter;
      return matchesQ && matchesClub && matchesStatus;
    }).toList();
  }

  static const List<String> _statusOrder = ['paid', 'due-soon', 'overdue'];

  Map<String, int> get paymentStatusCounts {
    final counts = {'paid': 0, 'due-soon': 0, 'overdue': 0};
    for (final c in clubs) {
      counts[c.paymentStatus] = (counts[c.paymentStatus] ?? 0) + 1;
    }
    return counts;
  }

  List<LegendItem> get paymentLegend {
    final counts = paymentStatusCounts;
    return _statusOrder
        .map((k) => LegendItem(paymentStyleFor(k).label, counts[k] ?? 0, k))
        .toList();
  }

  String get mrrFormatted => formatUgx(clubs.fold(0, (sum, c) => sum + c.feeAmount));

  List<KpiData> get kpis => [
        KpiData('Total Clubs', '$totalClubs', '$activeClubs active'),
        KpiData('Total Members', commas(totalMembers), '+3.2%'),
        const KpiData("Today's Meetings", '31', '+4'),
        const KpiData('Online Users', '216', ''),
        const KpiData('SMS Sent Today', '983', ''),
      ];

  static const attendanceVals = [62, 71, 68, 80, 74, 78];
  static const attendanceLabels = ['Wk 1', 'Wk 2', 'Wk 3', 'Wk 4', 'Wk 5', 'Wk 6'];

  Club? get paymentModalClub {
    final id = paymentModalClubId;
    if (id == null) return null;
    return clubs.where((c) => c.id == id).firstOrNull;
  }

  Club? get statsModalClub {
    final id = statsModalClubId;
    if (id == null) return null;
    return clubs.where((c) => c.id == id).firstOrNull;
  }

  int statsAttendanceFor(Club c) => math.max(58, math.min(96, 70 + (c.id * 7) % 27));

  @override
  void dispose() {
    _toastTimer?.cancel();
    super.dispose();
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
