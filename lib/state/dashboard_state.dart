import 'dart:async';

import 'package:flutter/material.dart';

import '../api_client.dart';
import '../models.dart';
import '../theme.dart';

/// Single shared app state for the admin dashboard. UI/navigation state
/// (current view, open menus/modals, wizard step, form drafts) lives here
/// directly; club/member/analytics data is loaded from the real backend via
/// [ApiClient] and cached in the lists below.
class DashboardState extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  DashboardState() {
    // Wake the free-tier backend as soon as the login screen appears, so
    // it's warm by the time credentials are submitted.
    _api.warmUp();
  }

  String view = 'dashboard';
  Color accentColor = AdminColors.accent;

  // ── auth ────────────────────────────────────────────────────────────
  String? authToken;
  String adminName = '';
  String adminEmail = '';
  bool loginLoading = false;
  String? loginError;

  bool get isLoggedIn => authToken != null;

  Future<void> login(String email, String password) async {
    if (email.trim().isEmpty || password.isEmpty) {
      _update(() => loginError = 'Enter your email and password.');
      return;
    }
    _update(() {
      loginLoading = true;
      loginError = null;
    });
    try {
      final result = await _api.adminLogin(email.trim(), password);
      _update(() {
        authToken = result.token;
        adminName = result.admin.name;
        adminEmail = result.admin.email;
        loginLoading = false;
      });
      await _loadAll();
    } on ApiException catch (e) {
      _update(() {
        loginLoading = false;
        loginError = e.message;
      });
    }
  }

  void logout() => _update(() {
        authToken = null;
        adminName = '';
        adminEmail = '';
        clubs.clear();
        members.clear();
        analytics = null;
        view = 'dashboard';
      });

  // ── data (loaded from backend) ─────────────────────────────────────
  final List<Club> clubs = [];
  final List<Member> members = [];
  AnalyticsData? analytics;
  // No third-party error tracker is configured — this is the only place
  // an unhandled backend exception is visible at all. Best-effort only:
  // never blocks the main dashboard load or surfaces as dataError.
  List<ErrorLogEntry> errorLogs = [];
  bool dataLoading = false;
  String? dataError;

  Future<void> _loadAll() async {
    final token = authToken;
    if (token == null) return;
    _update(() {
      dataLoading = true;
      dataError = null;
    });
    try {
      final loadedClubs = await _api.fetchClubs(token);
      final loadedMembers = await _api.fetchMembers(token);
      final loadedAnalytics = await _api.fetchAnalytics(token);
      _update(() {
        clubs
          ..clear()
          ..addAll(loadedClubs);
        members
          ..clear()
          ..addAll(loadedMembers);
        analytics = loadedAnalytics;
        dataLoading = false;
      });
    } on ApiException catch (e) {
      _update(() {
        dataLoading = false;
        dataError = e.message;
      });
    }
    unawaited(_refreshErrorLogs());
  }

  Future<void> _refreshAnalytics() async {
    final token = authToken;
    if (token == null) return;
    try {
      final a = await _api.fetchAnalytics(token);
      _update(() => analytics = a);
    } on ApiException {
      // Best-effort refresh; keep showing the last known analytics rather
      // than surfacing an error for a secondary stat refresh.
    }
    unawaited(_refreshErrorLogs());
  }

  Future<void> _refreshErrorLogs() async {
    final token = authToken;
    if (token == null) return;
    try {
      final logs = await _api.fetchErrorLogs(token);
      _update(() => errorLogs = logs);
    } on ApiException {
      // Best-effort — the errors panel just keeps showing what it last had.
    }
  }

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

  void goSms() {
    _go('sms');
    unawaited(_loadSmsSummary());
  }

  SmsSummary? smsSummary;
  bool smsSummaryLoading = false;

  Future<void> _loadSmsSummary() async {
    final token = authToken;
    if (token == null) return;
    _update(() => smsSummaryLoading = true);
    try {
      final summary = await _api.fetchSmsSummary(token);
      _update(() {
        smsSummary = summary;
        smsSummaryLoading = false;
      });
    } on ApiException catch (e) {
      _update(() => smsSummaryLoading = false);
      _toast(e.message);
    }
  }

  void setAccentColor(Color c) => _update(() => accentColor = c);

  // ── new club wizard ──────────────────────────────────────────────────
  bool newClubOpen = false;
  int wizardStep = 0;
  ClubDraft draft = ClubDraft();
  bool createClubLoading = false;

  void openNewClub() => _update(() {
        newClubOpen = true;
        wizardStep = 0;
        draft = ClubDraft();
      });
  void closeNewClub() => _update(() => newClubOpen = false);
  void nextStep() => _update(() => wizardStep = wizardStep < 2 ? wizardStep + 1 : 2);
  void prevStep() => _update(() => wizardStep = wizardStep > 0 ? wizardStep - 1 : 0);

  void setDraftName(String v) => _update(() => draft.name = v);
  void setDraftClubType(String v) => _update(() => draft.clubType = v);
  void setDraftDistrict(String v) => _update(() => draft.district = v);
  void setDraftLocation(String v) => _update(() => draft.location = v);
  void setDraftPresidentName(String v) => _update(() => draft.presidentName = v);
  void setDraftEmail(String v) => _update(() => draft.email = v);
  void setDraftPhone(String v) => _update(() => draft.phone = v);
  void setDraftMembers(String v) => _update(() => draft.members = v);
  void setDraftFeeAmount(String v) => _update(() => draft.feeAmount = v);
  void setDraftFirstPaymentDate(String v) => _update(() => draft.firstPaymentDate = v);
  void setDraftNextDueDate(String v) => _update(() => draft.nextDueDate = v);
  void setDraftLogo(String? dataUrl) => _update(() => draft.logoDataUrl = dataUrl);

  bool get nextDisabled => wizardStep == 0 && draft.name.trim().isEmpty;

  /// Credentials of the president account just created, shown once in a
  /// modal so the admin can hand them to the Club President.
  PresidentCredentials? presidentCredentials;
  void dismissPresidentCredentials() => _update(() => presidentCredentials = null);

  Future<void> createClub() async {
    final token = authToken;
    if (token == null) return;
    _update(() => createClubLoading = true);
    try {
      final membersNum = int.tryParse(draft.members) ?? 0;
      final result = await _api.createClub(
        token,
        name: draft.name,
        district: draft.district,
        location: draft.location,
        clubType: draft.clubType,
        membersCount: membersNum == 0 ? 10 : membersNum,
        feeAmount: int.tryParse(draft.feeAmount) ?? 0,
        firstPaymentDate: draft.firstPaymentDate.trim().isEmpty ? null : draft.firstPaymentDate.trim(),
        nextDueDate: draft.nextDueDate.trim().isEmpty ? null : draft.nextDueDate.trim(),
        logo: draft.logoDataUrl,
        presidentName: draft.presidentName.trim(),
        presidentEmail: draft.email.trim(),
        presidentPhone: draft.phone.trim(),
      );
      _update(() {
        clubs.insert(0, result.club);
        createClubLoading = false;
        newClubOpen = false;
        presidentCredentials = result.president;
      });
      _toast('${result.club.name} onboarded successfully');
      unawaited(_refreshAnalytics());
    } on ApiException catch (e) {
      _update(() => createClubLoading = false);
      _toast(e.message);
    }
  }

  // ── clubs ───────────────────────────────────────────────────────────
  void _replaceClub(Club updated) {
    final i = clubs.indexWhere((c) => c.id == updated.id);
    if (i != -1) clubs[i] = updated;
  }

  Future<void> toggleClubStatus(int id) async {
    final token = authToken;
    if (token == null) return;
    final club = clubs.firstWhere((c) => c.id == id);
    final nextStatus = club.status == 'active' ? 'suspended' : 'active';
    try {
      final updated = await _api.setClubStatus(token, id, nextStatus);
      _update(() => _replaceClub(updated));
      _toast('${updated.name} ${nextStatus == 'suspended' ? 'suspended' : 'activated'}');
    } on ApiException catch (e) {
      _toast(e.message);
    }
  }

  int? paymentModalClubId;
  PaymentDraft paymentDraft = PaymentDraft();
  bool paymentSaving = false;

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

  Future<void> savePayment() async {
    final token = authToken;
    final id = paymentModalClubId;
    if (token == null || id == null) return;
    _update(() => paymentSaving = true);
    try {
      final updated = await _api.recordPayment(
        token,
        id,
        amount: int.tryParse(paymentDraft.amount) ?? 0,
        datePaid: paymentDraft.datePaid.trim().isEmpty ? null : paymentDraft.datePaid.trim(),
        nextDue: paymentDraft.nextDue.trim().isEmpty ? null : paymentDraft.nextDue.trim(),
      );
      _update(() {
        _replaceClub(updated);
        paymentSaving = false;
        paymentModalClubId = null;
      });
      _toast('Payment recorded for ${updated.name}');
    } on ApiException catch (e) {
      _update(() => paymentSaving = false);
      _toast(e.message);
    }
  }

  // ── delete club (with confirmation) ───────────────────────────────
  int? confirmDeleteClubId;
  bool deletingClub = false;

  void askDeleteClub(int id) => _update(() => confirmDeleteClubId = id);
  void cancelDeleteClub() => _update(() => confirmDeleteClubId = null);

  Club? get confirmDeleteClub {
    final id = confirmDeleteClubId;
    if (id == null) return null;
    final matches = clubs.where((c) => c.id == id);
    return matches.isEmpty ? null : matches.first;
  }

  Future<void> deleteClubConfirmed() async {
    final token = authToken;
    final id = confirmDeleteClubId;
    if (token == null || id == null) return;
    final club = clubs.firstWhere((c) => c.id == id);
    _update(() => deletingClub = true);
    try {
      await _api.deleteClub(token, id);
      _update(() {
        clubs.removeWhere((c) => c.id == id);
        // The backend cascades the delete to this club's members too —
        // mirror that here so the Members view doesn't keep showing
        // people who no longer exist until the next full reload.
        members.removeWhere((m) => m.club == club.name);
        deletingClub = false;
        confirmDeleteClubId = null;
      });
      _toast('${club.name} deleted');
      unawaited(_refreshAnalytics());
    } on ApiException catch (e) {
      _update(() {
        deletingClub = false;
        confirmDeleteClubId = null;
      });
      _toast(e.message);
    }
  }

  int? statsModalClubId;
  ClubStats? statsModalData;
  bool statsModalLoading = false;

  Future<void> openStatsModal(int id) async {
    final token = authToken;
    _update(() {
      statsModalClubId = id;
      statsModalData = null;
      statsModalLoading = token != null;
    });
    if (token == null) return;
    try {
      final stats = await _api.fetchClubStats(token, id);
      if (statsModalClubId == id) {
        _update(() {
          statsModalData = stats;
          statsModalLoading = false;
        });
      }
    } on ApiException catch (e) {
      _update(() => statsModalLoading = false);
      _toast(e.message);
    }
  }

  void closeStatsModal() => _update(() => statsModalClubId = null);

  int? qrModalClubId;
  void openQrModal(int id) => _update(() => qrModalClubId = id);
  void closeQrModal() => _update(() => qrModalClubId = null);

  // ── members ─────────────────────────────────────────────────────────
  String memberSearch = '';
  String memberClubFilter = 'all';
  String memberStatusFilter = 'all';

  void setMemberSearch(String v) => _update(() => memberSearch = v);
  void setMemberClubFilter(String v) => _update(() => memberClubFilter = v);
  void setMemberStatusFilter(String v) => _update(() => memberStatusFilter = v);

  void _replaceMember(Member updated) {
    final i = members.indexWhere((m) => m.id == updated.id);
    if (i != -1) members[i] = updated;
  }

  Future<void> toggleMemberStatus(int id) async {
    final token = authToken;
    if (token == null) return;
    final member = members.firstWhere((m) => m.id == id);
    final nextStatus = member.status == 'active' ? 'suspended' : 'active';
    try {
      final updated = await _api.setMemberStatus(token, id, nextStatus);
      _update(() => _replaceMember(updated));
      _toast('${updated.name} ${nextStatus == 'suspended' ? 'suspended' : 'reactivated'}');
    } on ApiException catch (e) {
      _toast(e.message);
    }
  }

  Future<void> resetPassword(int id) async {
    final token = authToken;
    if (token == null) return;
    try {
      final result = await _api.resetPassword(token, id);
      _toast('New PIN ${result.newPin} generated for ${result.memberName}');
    } on ApiException catch (e) {
      _toast(e.message);
    }
  }

  Future<void> viewActivity(int id) async {
    final token = authToken;
    if (token == null) return;
    try {
      final a = await _api.fetchMemberActivity(token, id);
      final suffix = a.lastCheckIn != null ? ', last on ${a.lastCheckIn}' : ' yet';
      _toast('${a.memberName}: ${a.checkInCount} check-in${a.checkInCount == 1 ? '' : 's'}$suffix');
    } on ApiException catch (e) {
      _toast(e.message);
    }
  }

  // ── delete member (with confirmation) ──────────────────────────────
  int? confirmDeleteMemberId;
  bool deletingMember = false;

  void askDeleteMember(int id) => _update(() => confirmDeleteMemberId = id);
  void cancelDeleteMember() => _update(() => confirmDeleteMemberId = null);

  Member? get confirmDeleteMember {
    final id = confirmDeleteMemberId;
    if (id == null) return null;
    final matches = members.where((m) => m.id == id);
    return matches.isEmpty ? null : matches.first;
  }

  Future<void> deleteMemberConfirmed() async {
    final token = authToken;
    final id = confirmDeleteMemberId;
    if (token == null || id == null) return;
    final member = members.firstWhere((m) => m.id == id);
    _update(() => deletingMember = true);
    try {
      await _api.deleteMember(token, id);
      _update(() {
        members.removeWhere((m) => m.id == id);
        deletingMember = false;
        confirmDeleteMemberId = null;
      });
      _toast('${member.name} deleted');
      unawaited(_refreshAnalytics());
    } on ApiException catch (e) {
      _update(() {
        deletingMember = false;
        confirmDeleteMemberId = null;
      });
      _toast(e.message);
    }
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
        KpiData('Total Members', commas(totalMembers), ''),
        KpiData("Today's Meetings", '${analytics?.meetingsToday ?? 0}', ''),
        KpiData('Check-ins Today', '${analytics?.checkinsToday ?? 0}', ''),
        KpiData('Active Members', '${analytics?.activeMembers ?? activeMembersCount}', ''),
      ];

  // Attendance trend and "new clubs this month" need cross-club check-in
  // history the client doesn't have loaded, so those come from the
  // /admin/analytics endpoint rather than being derived client-side.
  List<int> get attendanceVals => analytics?.attendanceValues ?? const [0, 0, 0, 0, 0, 0];
  List<String> get attendanceLabels =>
      analytics?.attendanceLabels ?? const ['Wk 1', 'Wk 2', 'Wk 3', 'Wk 4', 'Wk 5', 'Wk 6'];
  int get newClubsThisMonth => analytics?.newClubsThisMonth ?? 0;
  int get avgAttendancePercent => analytics?.avgAttendancePercent ?? 0;

  Club? get paymentModalClub {
    final id = paymentModalClubId;
    if (id == null) return null;
    final matches = clubs.where((c) => c.id == id);
    return matches.isEmpty ? null : matches.first;
  }

  Timer? _toastTimer;
  String? toastMessage;

  @override
  void dispose() {
    _toastTimer?.cancel();
    super.dispose();
  }
}
