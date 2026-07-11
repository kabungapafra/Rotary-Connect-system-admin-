/// Thin client for the Rotary Connect backend's admin endpoints
/// (FastAPI + PostgreSQL). Base URL defaults to localhost:8000 for local
/// development, but is overridable at build time for deployment:
///   flutter build web --release --dart-define=API_BASE_URL=https://api.example.com
library;

import 'dart:convert';
import 'package:http/http.dart' as http;

import 'models.dart';

const String apiBaseUrl =
    String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:8000');

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
      this.enabled, this.sentToday, this.failedToday, this.sentTotal);
}

class ApiClient {
  /// Fire-and-forget ping that wakes a sleeping free-tier backend while the
  /// user is still typing their credentials.
  void warmUp() {
    http
        .get(Uri.parse('$apiBaseUrl/health'))
        .timeout(_requestTimeout)
        .ignore();
  }

  Future<AdminLoginResult> adminLogin(String email, String password) async {
    final res = await _post('/admin/auth/login', {'email': email, 'password': password});
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
  }) async {
    final res = await _post(
      '/admin/clubs',
      {
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
      },
      token: token,
    );
    final president = res['president'] as Map<String, dynamic>?;
    return CreateClubResult(
      Club.fromJson(res['club'] as Map<String, dynamic>),
      president == null
          ? null
          : PresidentCredentials(
              president['name'] as String,
              president['member_number'] as String,
              president['pin'] as String,
            ),
    );
  }

  Future<Club> setClubStatus(String token, int clubId, String status) async {
    final res = await _patch('/admin/clubs/$clubId/status', {'status': status}, token: token);
    return Club.fromJson(res);
  }

  Future<Club> recordPayment(
    String token,
    int clubId, {
    required int amount,
    String? datePaid,
    String? nextDue,
  }) async {
    final res = await _post(
      '/admin/clubs/$clubId/payment',
      {'amount': amount, 'date_paid': datePaid, 'next_due': nextDue},
      token: token,
    );
    return Club.fromJson(res);
  }

  /// Remove a club and everything belonging to it (members, meetings,
  /// check-ins, events, projects).
  Future<void> deleteClub(String token, int clubId) async {
    final http.Response res;
    try {
      res = await http
          .delete(Uri.parse('$apiBaseUrl/admin/clubs/$clubId'),
              headers: {'Authorization': 'Bearer $token'})
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

  Future<List<Member>> fetchMembers(
    String token, {
    String search = '',
    String club = 'all',
    String status = 'all',
  }) async {
    final uri = Uri.parse('$apiBaseUrl/admin/members').replace(queryParameters: {
      'search': search,
      'club': club,
      'status_filter': status,
    });
    final res = await _getListUri(uri, token: token);
    return res.map((e) => Member.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Member> setMemberStatus(String token, int memberId, String status) async {
    final res =
        await _patch('/admin/members/$memberId/status', {'status': status}, token: token);
    return Member.fromJson(res);
  }

  Future<ResetPasswordResult> resetPassword(String token, int memberId) async {
    final res = await _post('/admin/members/$memberId/reset-password', null, token: token);
    return ResetPasswordResult(res['member_name'] as String, res['new_pin'] as String);
  }

  Future<void> deleteMember(String token, int memberId) async {
    final http.Response res;
    try {
      res = await http
          .delete(Uri.parse('$apiBaseUrl/admin/members/$memberId'),
              headers: {'Authorization': 'Bearer $token'})
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

  // ── http plumbing ────────────────────────────────────────────────────
  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic>? body,
      {String? token}) async {
    final headers = {'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';
    final http.Response res;
    try {
      res = await http
          .post(Uri.parse('$apiBaseUrl$path'),
              headers: headers, body: body == null ? null : jsonEncode(body))
          .timeout(_requestTimeout);
    } catch (_) {
      throw ApiException('Could not reach the server. Check your connection.');
    }
    return _decode(res);
  }

  Future<Map<String, dynamic>> _patch(String path, Map<String, dynamic> body,
      {String? token}) async {
    final headers = {'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';
    final http.Response res;
    try {
      res = await http
          .patch(Uri.parse('$apiBaseUrl$path'), headers: headers, body: jsonEncode(body))
          .timeout(_requestTimeout);
    } catch (_) {
      throw ApiException('Could not reach the server. Check your connection.');
    }
    return _decode(res);
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
