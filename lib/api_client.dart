/// Thin client for the Rotary Connect backend's admin endpoints
/// (FastAPI + PostgreSQL). Base URL defaults to localhost:8000 for local
/// development, but is overridable at build time for deployment:
///   flutter build web --release --dart-define=API_BASE_URL=https://api.example.com
library;

import 'dart:convert';
import 'package:http/http.dart' as http;

import 'models.dart';

const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8000',
);

// Long enough to ride out Render's free-tier cold start (~30-60s after the
// service has been idle), which is far longer than a normal request.
const Duration _requestTimeout = Duration(seconds: 75);

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class AdminProfile {
  final String name;
  final String email;
  const AdminProfile(this.name, this.email);
}

class AdminLoginResult {
  final String token;
  final AdminProfile admin;
  const AdminLoginResult(this.token, this.admin);
}

class ClubStats {
  final Club club;
  final int attendancePercent;
  const ClubStats(this.club, this.attendancePercent);
}

/// Resource usage for one club, as shown on the club management screen.
///
/// [smsSent], [smsFailed] and [errorsTotal] count only activity recorded
/// after the API started attributing those rows to a club, so they read as
/// "since tracking began" rather than all-time. [storageBytes] has no such
/// gap — it was backfilled from R2.
class ClubUsage {
  final int membersTotal;
  final int membersActive;
  final int membersSuspended;
  final int smsSent;
  final int smsFailed;
  final int storageBytes;
  final int storagePhotos;
  final int storageDocuments;
  final int errorsTotal;

  const ClubUsage({
    required this.membersTotal,
    required this.membersActive,
    required this.membersSuspended,
    required this.smsSent,
    required this.smsFailed,
    required this.storageBytes,
    required this.storagePhotos,
    required this.storageDocuments,
    required this.errorsTotal,
  });

  factory ClubUsage.fromJson(Map<String, dynamic> json) => ClubUsage(
    membersTotal: json['members_total'] as int,
    membersActive: json['members_active'] as int,
    membersSuspended: json['members_suspended'] as int,
    smsSent: json['sms_sent'] as int,
    smsFailed: json['sms_failed'] as int,
    storageBytes: json['storage_bytes'] as int,
    storagePhotos: json['storage_photos'] as int,
    storageDocuments: json['storage_documents'] as int,
    errorsTotal: json['errors_total'] as int,
  );
}

/// One of a club's three key officers. Null on [ClubOverview] when nobody
/// holds that post — a vacancy the screen shows rather than hides.
class ClubOfficer {
  final int id;
  final String name;
  final String role;
  final String memberNumber;
  final String phone;
  final String email;
  final String status;

  const ClubOfficer({
    required this.id,
    required this.name,
    required this.role,
    required this.memberNumber,
    required this.phone,
    required this.email,
    required this.status,
  });

  static ClubOfficer? fromJsonOrNull(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    return ClubOfficer(
      id: json['id'] as int,
      name: json['name'] as String,
      role: json['role'] as String,
      memberNumber: json['member_number'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String,
      status: json['status'] as String,
    );
  }
}

class ClubOverview {
  final Club club;
  final int attendancePercent;
  final ClubUsage usage;
  final ClubOfficer? president;
  final ClubOfficer? presidentElect;
  final ClubOfficer? secretary;
  final List<ErrorLogEntry> recentErrors;

  const ClubOverview({
    required this.club,
    required this.attendancePercent,
    required this.usage,
    this.president,
    this.presidentElect,
    this.secretary,
    required this.recentErrors,
  });
}

class CreateClubResult {
  final Club club;
  final PresidentCredentials? president;
  const CreateClubResult(this.club, this.president);
}

class ResetPasswordResult {
  final String memberName;
  final String newPin;
  const ResetPasswordResult(this.memberName, this.newPin);
}

class MemberActivity {
  final String memberName;
  final int checkInCount;
  final String? lastCheckIn;
  const MemberActivity(this.memberName, this.checkInCount, this.lastCheckIn);
}

class SmsSummary {
  final bool enabled;
  final int sentToday;
  final int failedToday;
  final int sentTotal;
  const SmsSummary(
    this.enabled,
    this.sentToday,
    this.failedToday,
    this.sentTotal,
  );
}

class ApiClient {
  /// Fire-and-forget ping that wakes a sleeping free-tier backend while the
  /// user is still typing their credentials.
  void warmUp() {
    http.get(Uri.parse('$apiBaseUrl/health')).timeout(_requestTimeout).ignore();
  }

  Future<AdminLoginResult> adminLogin(String email, String password) async {
    final res = await _post('/admin/auth/login', {
      'email': email,
      'password': password,
    });
    final admin = res['admin'] as Map<String, dynamic>;
    return AdminLoginResult(
      res['access_token'] as String,
      AdminProfile(admin['name'] as String, admin['email'] as String),
    );
  }

  Future<List<Club>> fetchClubs(String token) async {
    final res = await _getList('/admin/clubs', token: token);
    return res.map((e) => Club.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<CreateClubResult> createClub(
    String token, {
    required String name,
    required String district,
    required String location,
    String clubType = 'rotary',
    required int membersCount,
    required int feeAmount,
    String? firstPaymentDate,
    String? nextDueDate,
    String? logo,
    String presidentName = '',
    String presidentEmail = '',
    String presidentPhone = '',
    String presidentDob = '',
  }) async {
    final res = await _post('/admin/clubs', {
      'name': name,
      'district': district,
      'location': location,
      'club_type': clubType,
      'members_count': membersCount,
      'fee_amount': feeAmount,
      'first_payment_date': firstPaymentDate,
      'next_due_date': nextDueDate,
      'logo': logo,
      'president_name': presidentName,
      'president_email': presidentEmail,
      'president_phone': presidentPhone,
      'president_dob': presidentDob,
    }, token: token);
    final president = res['president'] as Map<String, dynamic>?;
    return CreateClubResult(
      Club.fromJson(res['club'] as Map<String, dynamic>),
      president == null
          ? null
          : PresidentCredentials(
              president['id'] as int,
              president['name'] as String,
              president['phone'] as String,
              president['member_number'] as String,
              president['pin'] as String,
            ),
    );
  }

  Future<Club> setClubStatus(String token, int clubId, String status) async {
    final res = await _patch('/admin/clubs/$clubId/status', {
      'status': status,
    }, token: token);
    return Club.fromJson(res);
  }

  Future<Club> setClubSmsEnabled(String token, int clubId, bool enabled) async {
    final res = await _patch('/admin/clubs/$clubId/sms', {
      'sms_enabled': enabled,
    }, token: token);
    return Club.fromJson(res);
  }

  Future<List<Club>> setAllClubsSmsEnabled(String token, bool enabled) async {
    final res = await _patchList('/admin/clubs/sms', {
      'sms_enabled': enabled,
    }, token: token);
    return res.map((c) => Club.fromJson(c as Map<String, dynamic>)).toList();
  }

  Future<Club> setClubSmsTypes(
    String token,
    int clubId,
    Map<String, bool> smsTypes,
  ) async {
    final res = await _patch(
      '/admin/clubs/$clubId/sms-types',
      smsTypes,
      token: token,
    );
    return Club.fromJson(res);
  }

  Future<Club> recordPayment(
    String token,
    int clubId, {
    required int amount,
    String? datePaid,
    String? nextDue,
  }) async {
    final res = await _post('/admin/clubs/$clubId/payment', {
      'amount': amount,
      'date_paid': datePaid,
      'next_due': nextDue,
    }, token: token);
    return Club.fromJson(res);
  }

  /// Remove a club and everything belonging to it (members, meetings,
  /// check-ins, events, projects).
  Future<void> deleteClub(String token, int clubId) async {
    final http.Response res;
    try {
      res = await http
          .delete(
            Uri.parse('$apiBaseUrl/admin/clubs/$clubId'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(_requestTimeout);
    } catch (_) {
      throw ApiException('Could not reach the server. Check your connection.');
    }
    if (res.statusCode >= 400) {
      throw ApiException(_errorDetail(res));
    }
  }

  Future<ClubStats> fetchClubStats(String token, int clubId) async {
    final res = await _get('/admin/clubs/$clubId/stats', token: token);
    return ClubStats(
      Club.fromJson(res['club'] as Map<String, dynamic>),
      res['attendance_percent'] as int,
    );
  }

  Future<ClubOverview> fetchClubOverview(String token, int clubId) async {
    final res = await _get('/admin/clubs/$clubId/overview', token: token);
    return ClubOverview(
      club: Club.fromJson(res['club'] as Map<String, dynamic>),
      attendancePercent: res['attendance_percent'] as int,
      usage: ClubUsage.fromJson(res['usage'] as Map<String, dynamic>),
      president: ClubOfficer.fromJsonOrNull(res['president']),
      presidentElect: ClubOfficer.fromJsonOrNull(res['president_elect']),
      secretary: ClubOfficer.fromJsonOrNull(res['secretary']),
      recentErrors: (res['recent_errors'] as List)
          .map((e) => ErrorLogEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<List<Member>> fetchMembers(
    String token, {
    String search = '',
    String club = 'all',
    String status = 'all',
  }) async {
    final uri = Uri.parse('$apiBaseUrl/admin/members').replace(
      queryParameters: {
        'search': search,
        'club': club,
        'status_filter': status,
      },
    );
    final res = await _getListUri(uri, token: token);
    return res.map((e) => Member.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Member> setMemberStatus(
    String token,
    int memberId,
    String status,
  ) async {
    final res = await _patch('/admin/members/$memberId/status', {
      'status': status,
    }, token: token);
    return Member.fromJson(res);
  }

  /// Adds a member directly to [clubId] — bootstraps a club whose only
  /// member was removed, or adds one without routing through that club's
  /// own president.
  Future<CreateMemberResult> createMember(
    String token, {
    required int clubId,
    required String name,
    required String phone,
    String email = '',
    String dob = '',
    String role = 'Member',
    bool isBoard = false,
  }) async {
    final res = await _post('/admin/members', {
      'club_id': clubId,
      'name': name,
      'phone': phone,
      'email': email,
      'dob': dob,
      'role': role,
      'is_board': isBoard,
    }, token: token);
    final member = res['member'] as Map<String, dynamic>;
    return CreateMemberResult(
      id: member['id'] as int,
      name: member['name'] as String,
      phone: member['phone'] as String,
      memberNumber: member['member_number'] as String,
      pin: res['pin'] as String,
    );
  }

  Future<ResetPasswordResult> resetPassword(String token, int memberId) async {
    final res = await _post(
      '/admin/members/$memberId/reset-password',
      null,
      token: token,
    );
    return ResetPasswordResult(
      res['member_name'] as String,
      res['new_pin'] as String,
    );
  }

  Future<void> deleteMember(String token, int memberId) async {
    final http.Response res;
    try {
      res = await http
          .delete(
            Uri.parse('$apiBaseUrl/admin/members/$memberId'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(_requestTimeout);
    } catch (_) {
      throw ApiException('Could not reach the server. Check your connection.');
    }
    if (res.statusCode >= 400) {
      throw ApiException(_errorDetail(res));
    }
  }

  Future<SmsSummary> fetchSmsSummary(String token) async {
    final res = await _get('/admin/sms/summary', token: token);
    return SmsSummary(
      res['enabled'] as bool,
      res['sent_today'] as int,
      res['failed_today'] as int,
      res['sent_total'] as int,
    );
  }

  Future<MemberActivity> fetchMemberActivity(String token, int memberId) async {
    final res = await _get('/admin/members/$memberId/activity', token: token);
    return MemberActivity(
      res['member_name'] as String,
      res['check_in_count'] as int,
      res['last_check_in'] as String?,
    );
  }

  Future<AnalyticsData> fetchAnalytics(String token) async {
    final res = await _get('/admin/analytics', token: token);
    return AnalyticsData.fromJson(res);
  }

  Future<MonitoringData> fetchMonitoring(String token) async {
    final res = await _get('/admin/analytics/monitoring', token: token);
    return MonitoringData.fromJson(res);
  }

  /// Times a round-trip to /health so the System Health page can show
  /// live latency. Returns milliseconds, or null when the API is down.
  Future<int?> pingHealth() async {
    final sw = Stopwatch()..start();
    try {
      final res = await http
          .get(Uri.parse('$apiBaseUrl/health'))
          .timeout(const Duration(seconds: 15));
      sw.stop();
      if (res.statusCode >= 400) return null;
      return sw.elapsedMilliseconds;
    } catch (_) {
      return null;
    }
  }

  Future<List<ErrorLogEntry>> fetchErrorLogs(String token) async {
    final res = await _getList('/admin/analytics/errors', token: token);
    return res
        .map((e) => ErrorLogEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── http plumbing ────────────────────────────────────────────────────
  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic>? body, {
    String? token,
  }) async {
    final headers = {'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';
    final http.Response res;
    try {
      res = await http
          .post(
            Uri.parse('$apiBaseUrl$path'),
            headers: headers,
            body: body == null ? null : jsonEncode(body),
          )
          .timeout(_requestTimeout);
    } catch (_) {
      throw ApiException('Could not reach the server. Check your connection.');
    }
    return _decode(res);
  }

  Future<Map<String, dynamic>> _patch(
    String path,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    final headers = {'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';
    final http.Response res;
    try {
      res = await http
          .patch(
            Uri.parse('$apiBaseUrl$path'),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(_requestTimeout);
    } catch (_) {
      throw ApiException('Could not reach the server. Check your connection.');
    }
    return _decode(res);
  }

  Future<List<dynamic>> _patchList(
    String path,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    final headers = {'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';
    final http.Response res;
    try {
      res = await http
          .patch(
            Uri.parse('$apiBaseUrl$path'),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(_requestTimeout);
    } catch (_) {
      throw ApiException('Could not reach the server. Check your connection.');
    }
    if (res.statusCode >= 400) {
      throw ApiException(_errorDetail(res));
    }
    return jsonDecode(res.body) as List<dynamic>;
  }

  Future<Map<String, dynamic>> _get(String path, {String? token}) =>
      _getUri(Uri.parse('$apiBaseUrl$path'), token: token);

  Future<Map<String, dynamic>> _getUri(Uri uri, {String? token}) async {
    final headers = <String, String>{};
    if (token != null) headers['Authorization'] = 'Bearer $token';
    final http.Response res;
    try {
      res = await http.get(uri, headers: headers).timeout(_requestTimeout);
    } catch (_) {
      throw ApiException('Could not reach the server. Check your connection.');
    }
    return _decode(res);
  }

  Future<List<dynamic>> _getList(String path, {String? token}) =>
      _getListUri(Uri.parse('$apiBaseUrl$path'), token: token);

  Future<List<dynamic>> _getListUri(Uri uri, {String? token}) async {
    final headers = <String, String>{};
    if (token != null) headers['Authorization'] = 'Bearer $token';
    final http.Response res;
    try {
      res = await http.get(uri, headers: headers).timeout(_requestTimeout);
    } catch (_) {
      throw ApiException('Could not reach the server. Check your connection.');
    }
    if (res.statusCode >= 400) {
      throw ApiException(_errorDetail(res));
    }
    return jsonDecode(res.body) as List<dynamic>;
  }

  Map<String, dynamic> _decode(http.Response res) {
    if (res.statusCode >= 400) {
      throw ApiException(_errorDetail(res));
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  String _errorDetail(http.Response res) {
    try {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return data['detail'] as String? ?? 'Something went wrong.';
    } catch (_) {
      return 'Something went wrong.';
    }
  }
}
