import 'dart:async';

import 'package:flutter/material.dart';

import '../api_client.dart';
import '../models.dart';
import '../theme.dart';
import 'session_store.dart';

/// Single shared app state for the admin dashboard. UI/navigation state
/// (current view, open menus/modals, wizard step, form drafts) lives here
/// directly; club/member/analytics data is loaded from the real backend via
/// [ApiClient] and cached in the lists below.
class DashboardState extends ChangeNotifier {
  final ApiClient _api = ApiClient();
  final SessionStore _session = SessionStore();

  DashboardState() {
    // Wake the free-tier backend as soon as the login screen appears, so
    // it's warm by the time credentials are submitted.
    _api.warmUp();
    _restoreSession();
  }

  /// A page reload used to land back on the login screen every time; the
  /// session now survives via localStorage (browser builds only — the
  /// stub store keeps tests VM-safe).
  void _restoreSession() {
    final token = _session.read('admin_token');
    if (token == null || token.isEmpty) return;
    authToken = token;
    adminName = _session.read('admin_name') ?? '';
    adminEmail = _session.read('admin_email') ?? '';
    unawaited(_loadAll());
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
      _session
        ..write('admin_token', result.token)
        ..write('admin_name', result.admin.name)
        ..write('admin_email', result.admin.email);
      await _loadAll();
    } on ApiException catch (e) {
      _update(() {
        loginLoading = false;
        loginError = e.message;
      });
    }
  }

  void logout() {
    _session
      ..remove('admin_token')
      ..remove('admin_name')
      ..remove('admin_email');
    _update(() {
      authToken = null;
      adminName = '';
      adminEmail = '';
      clubs.clear();
      members.clear();
      analytics = null;
      view = 'dashboard';
    });
  }

  /// Manual "pull latest data" — the dashboard had no way to refresh
  /// without logging out and back in.
  Future<void> refresh() => _loadAll();

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

  void _go(String v) => _update(() {
    view = v;
    // Leaving via the sidebar closes the club management screen too —
    // otherwise its data lingers and reappears on the next visit to a
    // different club until the fresh fetch lands.
    openClubId = null;
    clubOverview = null;
    clubOverviewError = null;
    clubFinances = null;
    clubEvents = [];
    clubAudit = [];
  });

  void goDashboard() => _go('dashboard');
  void goClubs() => _go('clubs');
  void goMembers() => _go('members');
  void goBilling() => _go('billing');
  void goAnalytics() => _go('analytics');

  void goSms() {
    _go('sms');
    unawaited(_loadSmsSummary());
  }

  void goHealth() {
    _go('health');
    unawaited(loadMonitoring());
  }

  // ── system health ───────────────────────────────────────────────────
  MonitoringData? monitoring;
  bool monitoringLoading = false;
  // Round-trip time of the live /health probe; null while unknown, -1 for
  // "API unreachable" so the page can tell "still measuring" from "down".
  int? healthLatencyMs;

  Future<void> loadMonitoring() async {
    final token = authToken;
    if (token == null) return;
    _update(() {
      monitoringLoading = true;
      healthLatencyMs = null;
    });
    unawaited(
      _api.pingHealth().then((ms) {
        _update(() => healthLatencyMs = ms ?? -1);
      }),
    );
    try {
      final data = await _api.fetchMonitoring(token);
      _update(() {
        monitoring = data;
        monitoringLoading = false;
      });
    } on ApiException catch (e) {
      _update(() => monitoringLoading = false);
      _toast(e.message);
    }
    unawaited(_refreshErrorLogs());
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
  void nextStep() =>
      _update(() => wizardStep = wizardStep < 2 ? wizardStep + 1 : 2);
  void prevStep() =>
      _update(() => wizardStep = wizardStep > 0 ? wizardStep - 1 : 0);

  void setDraftName(String v) => _update(() => draft.name = v);
  void setDraftClubType(String v) => _update(() => draft.clubType = v);
  void setDraftDistrict(String v) => _update(() => draft.district = v);
  void setDraftLocation(String v) => _update(() => draft.location = v);
  void setDraftPresidentName(String v) =>
      _update(() => draft.presidentName = v);
  void setDraftEmail(String v) => _update(() => draft.email = v);
  void setDraftPhone(String v) => _update(() => draft.phone = v);
  void setDraftDob(String v) => _update(() => draft.dob = v);
  void setDraftMembers(String v) => _update(() => draft.members = v);
  void setDraftFeeAmount(String v) => _update(() => draft.feeAmount = v);
  void setDraftFirstPaymentDate(String v) =>
      _update(() => draft.firstPaymentDate = v);
  void setDraftNextDueDate(String v) => _update(() => draft.nextDueDate = v);
  void setDraftLogo(String? dataUrl) =>
      _update(() => draft.logoDataUrl = dataUrl);

  bool get nextDisabled => wizardStep == 0 && draft.name.trim().isEmpty;

  /// Credentials of the president account just created, shown once in a
  /// modal so the admin can hand them to the Club President.
  PresidentCredentials? presidentCredentials;
  void dismissPresidentCredentials() =>
      _update(() => presidentCredentials = null);

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
        firstPaymentDate: draft.firstPaymentDate.trim().isEmpty
            ? null
            : draft.firstPaymentDate.trim(),
        nextDueDate: draft.nextDueDate.trim().isEmpty
            ? null
            : draft.nextDueDate.trim(),
        logo: draft.logoDataUrl,
        presidentName: draft.presidentName.trim(),
        presidentEmail: draft.email.trim(),
        presidentPhone: draft.phone.trim(),
        presidentDob: draft.dob.trim(),
      );
      _update(() {
        clubs.insert(0, result.club);
        final president = result.president;
        if (president != null) {
          members.insert(
            0,
            Member(
              id: president.id,
              name: president.name,
              phone: president.phone,
              club: result.club.name,
              status: 'active',
            ),
          );
        }
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
  String clubSearch = '';
  void setClubSearch(String v) => _update(() => clubSearch = v);

  List<Club> get filteredClubs {
    final q = clubSearch.trim().toLowerCase();
    if (q.isEmpty) return clubs;
    return clubs
        .where(
          (c) =>
              c.name.toLowerCase().contains(q) ||
              c.district.toLowerCase().contains(q) ||
              c.location.toLowerCase().contains(q),
        )
        .toList();
  }

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
      _toast(
        '${updated.name} ${nextStatus == 'suspended' ? 'suspended' : 'activated'}',
      );
    } on ApiException catch (e) {
      _toast(e.message);
    }
  }

  /// Independent of [toggleClubStatus] — a club can stay fully active
  /// while its SMS specifically is withheld (e.g. hasn't paid for SMS
  /// credits).
  Future<void> toggleClubSms(int id) async {
    final token = authToken;
    if (token == null) return;
    final club = clubs.firstWhere((c) => c.id == id);
    final nextEnabled = !club.smsEnabled;
    try {
      final updated = await _api.setClubSmsEnabled(token, id, nextEnabled);
      _update(() => _replaceClub(updated));
      _toast('${updated.name} SMS ${nextEnabled ? 'activated' : 'suspended'}');
    } on ApiException catch (e) {
      _toast(e.message);
    }
  }

  // ── per-club, per-message-type SMS toggles ─────────────────────────────
  int? smsTypesModalClubId;
  Map<String, bool>? smsTypesDraft; // working copy while the modal is open
  bool smsTypesSaving = false;

  Club? get smsTypesModalClub {
    final id = smsTypesModalClubId;
    if (id == null) return null;
    final matches = clubs.where((c) => c.id == id);
    return matches.isEmpty ? null : matches.first;
  }

  void openSmsTypesModal(int id) {
    final club = clubs.firstWhere((c) => c.id == id);
    _update(() {
      smsTypesModalClubId = id;
      smsTypesDraft = Map<String, bool>.from(club.smsTypes);
    });
  }

  void closeSmsTypesModal() => _update(() {
    smsTypesModalClubId = null;
    smsTypesDraft = null;
  });

  void toggleSmsTypeDraft(String key) =>
      _update(() => smsTypesDraft?[key] = !(smsTypesDraft?[key] ?? true));

  Future<void> saveSmsTypesModal() async {
    final token = authToken;
    final id = smsTypesModalClubId;
    final draft = smsTypesDraft;
    if (token == null || id == null || draft == null) return;
    _update(() => smsTypesSaving = true);
    try {
      final updated = await _api.setClubSmsTypes(token, id, draft);
      _update(() {
        _replaceClub(updated);
        smsTypesSaving = false;
        smsTypesModalClubId = null;
        smsTypesDraft = null;
      });
      _toast('${updated.name} SMS preferences saved');
    } on ApiException catch (e) {
      _update(() => smsTypesSaving = false);
      _toast(e.message);
    }
  }

  // ── bulk SMS suspend/activate (all clubs at once, with confirmation) ──
  bool? confirmBulkSmsEnabled; // null = no confirmation pending
  bool bulkSmsSaving = false;

  void askBulkSms(bool enabled) =>
      _update(() => confirmBulkSmsEnabled = enabled);
  void cancelBulkSms() => _update(() => confirmBulkSmsEnabled = null);

  Future<void> confirmBulkSmsAction() async {
    final token = authToken;
    final enabled = confirmBulkSmsEnabled;
    if (token == null || enabled == null) return;
    _update(() => bulkSmsSaving = true);
    try {
      final updated = await _api.setAllClubsSmsEnabled(token, enabled);
      _update(() {
        clubs
          ..clear()
          ..addAll(updated);
        bulkSmsSaving = false;
        confirmBulkSmsEnabled = null;
      });
      _toast('SMS ${enabled ? 'activated' : 'suspended'} for every club');
    } on ApiException catch (e) {
      _update(() {
        bulkSmsSaving = false;
        confirmBulkSmsEnabled = null;
      });
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
      paymentDraft = PaymentDraft(
        amount: club.feeAmount > 0 ? club.feeAmount.toString() : '',
      );
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
        datePaid: paymentDraft.datePaid.trim().isEmpty
            ? null
            : paymentDraft.datePaid.trim(),
        nextDue: paymentDraft.nextDue.trim().isEmpty
            ? null
            : paymentDraft.nextDue.trim(),
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

  // ── add member (directly from a club row) ─────────────────────────
  int? addMemberModalClubId;
  AddMemberDraft addMemberDraft = AddMemberDraft();
  bool addMemberSaving = false;

  /// One-time credentials for a member just added this way, shown once
  /// so the admin can hand them over — same "shown once, never again"
  /// contract as [presidentCredentials].
  CreateMemberResult? newMemberCredentials;
  void dismissNewMemberCredentials() =>
      _update(() => newMemberCredentials = null);

  Club? get addMemberModalClub {
    final id = addMemberModalClubId;
    if (id == null) return null;
    final matches = clubs.where((c) => c.id == id);
    return matches.isEmpty ? null : matches.first;
  }

  void openAddMemberModal(int clubId) {
    _update(() {
      addMemberModalClubId = clubId;
      addMemberDraft = AddMemberDraft();
    });
  }

  void closeAddMemberModal() {
    if (addMemberSaving) return;
    _update(() => addMemberModalClubId = null);
  }

  void setAddMemberName(String v) => _update(() => addMemberDraft.name = v);
  void setAddMemberPhone(String v) => _update(() => addMemberDraft.phone = v);
  void setAddMemberEmail(String v) => _update(() => addMemberDraft.email = v);
  void setAddMemberDob(String v) => _update(() => addMemberDraft.dob = v);
  void setAddMemberRole(String v) => _update(() => addMemberDraft.role = v);

  Future<void> saveNewMember() async {
    final token = authToken;
    final clubId = addMemberModalClubId;
    if (token == null || clubId == null) return;
    final name = addMemberDraft.name.trim();
    final phone = addMemberDraft.phone.trim();
    if (name.isEmpty || phone.isEmpty) {
      _toast('Name and phone are required');
      return;
    }
    final club = clubs.firstWhere((c) => c.id == clubId);
    _update(() => addMemberSaving = true);
    try {
      final result = await _api.createMember(
        token,
        clubId: clubId,
        name: name,
        phone: phone,
        email: addMemberDraft.email.trim(),
        dob: addMemberDraft.dob.trim(),
        role: addMemberDraft.role.trim().isEmpty
            ? 'Member'
            : addMemberDraft.role.trim(),
      );
      _update(() {
        members.insert(
          0,
          Member(
            id: result.id,
            name: result.name,
            phone: result.phone,
            club: club.name,
            status: 'active',
          ),
        );
        club.members += 1;
        addMemberSaving = false;
        addMemberModalClubId = null;
        newMemberCredentials = result;
      });
      _toast('${result.name} added to ${club.name}');
    } on ApiException catch (e) {
      _update(() => addMemberSaving = false);
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

  // ── club management screen ──────────────────────────────────────────
  // A full view rather than a modal (view = 'club'), because it carries
  // the club's whole management surface — usage, errors and every action
  // — which is more than a dialog can hold without becoming a scroll trap.
  int? openClubId;
  ClubOverview? clubOverview;
  bool clubOverviewLoading = false;
  String? clubOverviewError;

  /// The club the management screen is showing, re-read from [clubs] so it
  /// reflects edits made from the screen itself (suspend, SMS toggle, …)
  /// without waiting for a fresh overview fetch. Null if it was deleted.
  Club? get openClub {
    final id = openClubId;
    if (id == null) return null;
    final matches = clubs.where((c) => c.id == id);
    return matches.isEmpty ? null : matches.first;
  }

  // Each panel loads independently rather than through one fat response, so
  // a slow or failing finance query can't blank the whole screen.
  ClubFinances? clubFinances;
  List<ClubEventOversight> clubEvents = [];
  List<AuditEntry> clubAudit = [];

  Future<void> openClubScreen(int id) async {
    _update(() {
      openClubId = id;
      view = 'club';
      clubOverview = null;
      clubOverviewError = null;
      clubOverviewLoading = true;
      clubFinances = null;
      clubEvents = [];
      clubAudit = [];
    });
    await _loadClubOverview(id);
    unawaited(_loadClubPanels(id));
  }

  Future<void> _loadClubPanels(int id) async {
    final token = authToken;
    if (token == null) return;
    // Best-effort and independent: a panel that fails leaves its own section
    // empty instead of taking the others down with it.
    await Future.wait([
      _api
          .fetchClubFinances(token, id)
          .then((f) {
            if (openClubId == id) _update(() => clubFinances = f);
          })
          .catchError((_) {}),
      _api
          .fetchClubEvents(token, id)
          .then((e) {
            if (openClubId == id) _update(() => clubEvents = e);
          })
          .catchError((_) {}),
      _api
          .fetchClubAudit(token, id)
          .then((a) {
            if (openClubId == id) _update(() => clubAudit = a);
          })
          .catchError((_) {}),
    ]);
  }

  Future<void> cancelClubEvent(int eventId) async {
    final token = authToken;
    final id = openClubId;
    if (token == null || id == null) return;
    try {
      await _api.cancelClubEvent(token, id, eventId);
      _toast('Event cancelled.');
      await _loadClubPanels(id);
    } on ApiException catch (e) {
      _toast(e.message);
    }
  }

  bool broadcastSending = false;

  Future<void> sendClubBroadcast({
    required String title,
    required String body,
    required String audience,
  }) async {
    final token = authToken;
    final id = openClubId;
    if (token == null || id == null) return;
    _update(() => broadcastSending = true);
    try {
      final result = await _api.broadcastToClub(
        token,
        id,
        title: title,
        body: body,
        audience: audience,
      );
      _update(() => broadcastSending = false);
      // Report what actually happened: push is silently disabled without
      // Firebase credentials, so "sent" would be a lie in that case.
      if (result.devices == 0) {
        _toast('Nobody to notify — no member of this club has the app.');
      } else if (!result.delivered) {
        _toast('Push is not configured, so nothing was sent.');
      } else {
        _toast(
          'Sent to ${result.recipients} member(s) on ${result.devices} device(s).',
        );
      }
      await _loadClubPanels(id);
    } on ApiException catch (e) {
      _update(() => broadcastSending = false);
      _toast(e.message);
    }
  }

  Future<void> _loadClubOverview(int id) async {
    final token = authToken;
    if (token == null) {
      _update(() => clubOverviewLoading = false);
      return;
    }
    try {
      final overview = await _api.fetchClubOverview(token, id);
      // Guard against a slow response landing after the admin has already
      // navigated to a different club (or back to the list).
      if (openClubId != id) return;
      _update(() {
        clubOverview = overview;
        clubOverviewLoading = false;
      });
    } on ApiException catch (e) {
      if (openClubId != id) return;
      _update(() {
        clubOverviewLoading = false;
        clubOverviewError = e.message;
      });
    }
  }

  /// Re-fetch the open club's figures after an action changed them.
  Future<void> refreshClubOverview() async {
    final id = openClubId;
    if (id == null) return;
    await _loadClubOverview(id);
  }

  void closeClubScreen() => _update(() {
    openClubId = null;
    clubOverview = null;
    clubOverviewError = null;
    view = 'clubs';
  });

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
      _toast(
        '${updated.name} ${nextStatus == 'suspended' ? 'suspended' : 'reactivated'}',
      );
    } on ApiException catch (e) {
      _toast(e.message);
    }
  }

  ResetPasswordResult? resetPasswordResult;
  void dismissResetPasswordResult() =>
      _update(() => resetPasswordResult = null);

  Future<void> resetPassword(int id) async {
    final token = authToken;
    if (token == null) return;
    try {
      final result = await _api.resetPassword(token, id);
      _update(() => resetPasswordResult = result);
    } on ApiException catch (e) {
      _toast(e.message);
    }
  }

  Future<void> viewActivity(int id) async {
    final token = authToken;
    if (token == null) return;
    try {
      final a = await _api.fetchMemberActivity(token, id);
      final suffix = a.lastCheckIn != null
          ? ', last on ${a.lastCheckIn}'
          : ' yet';
      _toast(
        '${a.memberName}: ${a.checkInCount} check-in${a.checkInCount == 1 ? '' : 's'}$suffix',
      );
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
  int get activeMembersCount =>
      members.where((m) => m.status == 'active').length;

  List<Club> get recentClubs => clubs.take(5).toList();
  List<String> get clubNameOptions => clubs.map((c) => c.name).toList();

  List<Member> get filteredMembers {
    final q = memberSearch.trim().toLowerCase();
    return members.where((m) {
      final matchesQ =
          q.isEmpty || m.name.toLowerCase().contains(q) || m.phone.contains(q);
      final matchesClub =
          memberClubFilter == 'all' || m.club == memberClubFilter;
      final matchesStatus =
          memberStatusFilter == 'all' || m.status == memberStatusFilter;
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

  String get mrrFormatted =>
      formatUgx(clubs.fold(0, (sum, c) => sum + c.feeAmount));

  List<KpiData> get kpis => [
    KpiData('Total Clubs', '$totalClubs', '$activeClubs active'),
    KpiData('Total Members', commas(totalMembers), ''),
    KpiData("Today's Meetings", '${analytics?.meetingsToday ?? 0}', ''),
    KpiData('Check-ins Today', '${analytics?.checkinsToday ?? 0}', ''),
    KpiData(
      'Active Members',
      '${analytics?.activeMembers ?? activeMembersCount}',
      '',
    ),
  ];

  // Attendance trend and "new clubs this month" need cross-club check-in
  // history the client doesn't have loaded, so those come from the
  // /admin/analytics endpoint rather than being derived client-side.
  List<int> get attendanceVals =>
      analytics?.attendanceValues ?? const [0, 0, 0, 0, 0, 0];
  List<String> get attendanceLabels =>
      analytics?.attendanceLabels ??
      const ['Wk 1', 'Wk 2', 'Wk 3', 'Wk 4', 'Wk 5', 'Wk 6'];
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
