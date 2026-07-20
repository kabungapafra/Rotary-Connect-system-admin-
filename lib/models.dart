/// A Rotary club onboarded onto the platform.
class Club {
  final int id;
  String name;
  String district;
  String location;
  int members;
  String status; // active | suspended
  String clubType; // rotary | rotaract
  int feeAmount;
  String lastPaidDate;
  String nextDueDate;
  String paymentStatus; // paid | due-soon | overdue
  String joined;
  String? logo; // data URL uploaded at onboarding, shown across the admin

  Club({
    required this.id,
    required this.name,
    required this.district,
    required this.location,
    required this.members,
    required this.status,
    this.clubType = 'rotary',
    required this.feeAmount,
    required this.lastPaidDate,
    required this.nextDueDate,
    required this.paymentStatus,
    required this.joined,
    this.logo,
  });

  factory Club.fromJson(Map<String, dynamic> json) => Club(
        id: json['id'] as int,
        name: json['name'] as String,
        district: json['district'] as String,
        location: json['location'] as String,
        members: json['members_count'] as int,
        status: json['status'] as String,
        clubType: json['club_type'] as String? ?? 'rotary',
        feeAmount: json['fee_amount'] as int,
        lastPaidDate: json['last_paid_date'] as String? ?? '—',
        nextDueDate: json['next_due_date'] as String? ?? '—',
        paymentStatus: json['payment_status'] as String,
        joined: json['joined'] as String,
        logo: json['logo'] as String?,
      );
}

/// A member of a club, managed platform-wide by the system admin.
class Member {
  final int id;
  String name;
  String phone;
  String club;
  String status; // active | suspended

  Member({
    required this.id,
    required this.name,
    required this.phone,
    required this.club,
    required this.status,
  });

  factory Member.fromJson(Map<String, dynamic> json) => Member(
        id: json['id'] as int,
        name: json['name'] as String,
        phone: json['phone'] as String,
        club: json['club'] as String,
        status: json['status'] as String,
      );
}

/// Working copy of the "Onboard New Club" wizard fields.
class ClubDraft {
  String name = '';
  String district = '';
  String location = '';
  String clubType = 'rotary';
  String presidentName = '';
  String email = '';
  String phone = '';
  String members = '';
  String feeAmount = '';
  String firstPaymentDate = '';
  String nextDueDate = '';
  String? logoDataUrl;
}

/// One-time credentials for a club's first administrator (the Club
/// President), returned when the club is created.
class PresidentCredentials {
  final String name;
  final String memberNumber;
  final String pin;
  const PresidentCredentials(this.name, this.memberNumber, this.pin);
}

/// Working copy of the "Add Member" modal fields.
class AddMemberDraft {
  String name;
  String phone;
  String email;
  String dob;
  String role;
  AddMemberDraft({
    this.name = '',
    this.phone = '',
    this.email = '',
    this.dob = '',
    this.role = 'Member',
  });
}

/// Result of the admin adding a member directly to a club — the new
/// member's id (so it can be inserted into the local Members list) plus
/// the one-time login credentials to hand over.
class CreateMemberResult {
  final int id;
  final String name;
  final String phone;
  final String memberNumber;
  final String pin;
  const CreateMemberResult({
    required this.id,
    required this.name,
    required this.phone,
    required this.memberNumber,
    required this.pin,
  });
}

/// Working copy of the "Record Payment" modal fields.
class PaymentDraft {
  String amount;
  String datePaid;
  String nextDue;
  PaymentDraft({this.amount = '', this.datePaid = '', this.nextDue = ''});
}

class KpiData {
  final String label;
  final String value;
  final String delta;
  const KpiData(this.label, this.value, this.delta);
  bool get isPositive => delta.startsWith('+');
}

class LegendItem {
  final String name;
  final int count;
  final String colorKey; // paid | due-soon | overdue
  const LegendItem(this.name, this.count, this.colorKey);

  factory LegendItem.fromJson(Map<String, dynamic> json) => LegendItem(
        json['name'] as String,
        json['count'] as int,
        json['color_key'] as String,
      );
}

/// Aggregate stats backing the Dashboard and Analytics views.
class AnalyticsData {
  final int totalClubs;
  final int activeClubs;
  final int totalMembers;
  final int activeMembers;
  final int newClubsThisMonth;
  final int avgAttendancePercent;
  final int meetingsToday;
  final int checkinsToday;
  final String mrrFormatted;
  final List<LegendItem> paymentLegend;
  final List<String> attendanceLabels;
  final List<int> attendanceValues;
  final List<ClubAttendanceItem> clubAttendance;
  final EngagementData engagement;

  AnalyticsData({
    required this.totalClubs,
    required this.activeClubs,
    required this.totalMembers,
    required this.activeMembers,
    required this.newClubsThisMonth,
    required this.avgAttendancePercent,
    required this.meetingsToday,
    required this.checkinsToday,
    required this.mrrFormatted,
    required this.paymentLegend,
    required this.attendanceLabels,
    required this.attendanceValues,
    this.clubAttendance = const [],
    this.engagement = const EngagementData(),
  });

  factory AnalyticsData.fromJson(Map<String, dynamic> json) => AnalyticsData(
        totalClubs: json['total_clubs'] as int,
        activeClubs: json['active_clubs'] as int,
        totalMembers: json['total_members'] as int,
        activeMembers: json['active_members'] as int,
        newClubsThisMonth: json['new_clubs_this_month'] as int,
        avgAttendancePercent: json['avg_attendance_percent'] as int,
        meetingsToday: json['meetings_today'] as int? ?? 0,
        checkinsToday: json['checkins_today'] as int? ?? 0,
        mrrFormatted: json['mrr_formatted'] as String,
        paymentLegend: (json['payment_legend'] as List)
            .map((e) => LegendItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        attendanceLabels: (json['attendance_labels'] as List).cast<String>(),
        attendanceValues: (json['attendance_values'] as List).cast<int>(),
        clubAttendance: (json['club_attendance'] as List<dynamic>? ?? const [])
            .map((e) => ClubAttendanceItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        engagement: json['engagement'] == null
            ? const EngagementData()
            : EngagementData.fromJson(json['engagement'] as Map<String, dynamic>),
      );
}

class ClubAttendanceItem {
  final String clubName;
  final int attendancePercent;
  final int meetingsHeld;
  final int memberCount;

  ClubAttendanceItem({
    required this.clubName,
    required this.attendancePercent,
    required this.meetingsHeld,
    required this.memberCount,
  });

  factory ClubAttendanceItem.fromJson(Map<String, dynamic> json) => ClubAttendanceItem(
        clubName: json['club_name'] as String,
        attendancePercent: json['attendance_percent'] as int,
        meetingsHeld: json['meetings_held'] as int,
        memberCount: json['member_count'] as int,
      );
}

class EngagementData {
  final int checkins30d;
  final int guestVisits30d;
  final int apologies30d;
  final int galleryUploads30d;

  const EngagementData({
    this.checkins30d = 0,
    this.guestVisits30d = 0,
    this.apologies30d = 0,
    this.galleryUploads30d = 0,
  });

  factory EngagementData.fromJson(Map<String, dynamic> json) => EngagementData(
        checkins30d: json['checkins_30d'] as int? ?? 0,
        guestVisits30d: json['guest_visits_30d'] as int? ?? 0,
        apologies30d: json['apologies_30d'] as int? ?? 0,
        galleryUploads30d: json['gallery_uploads_30d'] as int? ?? 0,
      );
}

/// One unhandled API exception — no third-party error tracker (Sentry,
/// etc.) is configured, so this list is the only place these are visible
/// at all outside server logs.
class ErrorLogEntry {
  final int id;
  final String method;
  final String path;
  final String exceptionType;
  final String message;
  final DateTime createdAt;

  ErrorLogEntry({
    required this.id,
    required this.method,
    required this.path,
    required this.exceptionType,
    required this.message,
    required this.createdAt,
  });

  factory ErrorLogEntry.fromJson(Map<String, dynamic> json) => ErrorLogEntry(
        id: json['id'] as int,
        method: json['method'] as String,
        path: json['path'] as String,
        exceptionType: json['exception_type'] as String,
        message: json['message'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

class MemberEventEntry {
  final int id;
  final String kind;
  final String identifier;
  final String? memberName;
  final String? clubName;
  final String detail;
  final DateTime createdAt;

  MemberEventEntry({
    required this.id,
    required this.kind,
    required this.identifier,
    required this.memberName,
    required this.clubName,
    required this.detail,
    required this.createdAt,
  });

  factory MemberEventEntry.fromJson(Map<String, dynamic> json) => MemberEventEntry(
        id: json['id'] as int,
        kind: json['kind'] as String,
        identifier: json['identifier'] as String,
        memberName: json['member_name'] as String?,
        clubName: json['club_name'] as String?,
        detail: json['detail'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

class SlowRequestEntry {
  final int id;
  final String method;
  final String path;
  final int statusCode;
  final int durationMs;
  final DateTime createdAt;

  SlowRequestEntry({
    required this.id,
    required this.method,
    required this.path,
    required this.statusCode,
    required this.durationMs,
    required this.createdAt,
  });

  factory SlowRequestEntry.fromJson(Map<String, dynamic> json) => SlowRequestEntry(
        id: json['id'] as int,
        method: json['method'] as String,
        path: json['path'] as String,
        statusCode: json['status_code'] as int,
        durationMs: json['duration_ms'] as int,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

class MonitoringData {
  final List<MemberEventEntry> memberEvents;
  final List<SlowRequestEntry> slowRequests;
  final int eventsToday;
  final int slowToday;

  MonitoringData({
    required this.memberEvents,
    required this.slowRequests,
    required this.eventsToday,
    required this.slowToday,
  });

  factory MonitoringData.fromJson(Map<String, dynamic> json) => MonitoringData(
        memberEvents: (json['member_events'] as List<dynamic>)
            .map((e) => MemberEventEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        slowRequests: (json['slow_requests'] as List<dynamic>)
            .map((e) => SlowRequestEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        eventsToday: json['events_today'] as int,
        slowToday: json['slow_today'] as int,
      );
}

String initialsFor(String name) {
  final stripped =
      name.replaceFirst(RegExp(r'^Rotary Club (of )?', caseSensitive: false), '').trim();
  final words = stripped.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  return words.take(2).map((w) => w[0]).join().toUpperCase();
}

String memberInitialsFor(String name) {
  final words = name.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  return words.take(2).map((w) => w[0]).join().toUpperCase();
}

String commas(int n) {
  final s = n.abs().toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return (n < 0 ? '-' : '') + buf.toString();
}

String formatUgx(int amount) => 'UGX ${commas(amount)}';
