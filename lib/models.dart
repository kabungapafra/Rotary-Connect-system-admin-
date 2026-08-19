/// Every per-message-type SMS toggle, keyed by its JSON field name (also
/// what PATCH /admin/clubs/{id}/sms-types expects back) — labels are what
/// the SMS-types modal shows next to each switch.
const Map<String, String> smsTypeLabels = {
  'sms_birthday_enabled': 'Birthday wishes',
  'sms_guest_thank_you_enabled': 'Guest thank-you',
  'sms_event_reminder_enabled': 'Event reminders',
  'sms_event_thank_you_enabled': 'Event/meeting thank-you',
  'sms_new_member_enabled': 'New member welcome (login credentials)',
  'sms_new_president_enabled': 'New club president welcome',
  'sms_admin_pin_reset_enabled': 'PIN reset (admin-initiated)',
  'sms_self_service_pin_reset_enabled': 'PIN reset (self-service / forgot PIN)',
};

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
  bool smsEnabled;
  Map<String, bool> smsTypes;

  /// At least one member of this club is currently online.
  bool isOnline;
  int onlineMemberCount;

  /// Mirrors the backend's is_club_access_blocked(): the app also suspends
  /// access when dues are overdue, not just when status is manually set to
  /// 'suspended'. Self-heals back to 'active' once a payment moves
  /// paymentStatus off 'overdue' — no separate unsuspend action needed.
  String get effectiveStatus =>
      (status == 'suspended' || paymentStatus == 'overdue')
      ? 'suspended'
      : 'active';

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
    this.smsEnabled = true,
    this.isOnline = false,
    this.onlineMemberCount = 0,
    Map<String, bool>? smsTypes,
  }) : smsTypes = smsTypes ?? {for (final k in smsTypeLabels.keys) k: true};

  factory Club.fromJson(Map<String, dynamic> json) => Club(
    id: json['id'] as int,
    name: json['name'] as String,
    district: json['district'] as String,
    location: json['location'] as String,
    members: json['members_count'] as int,
    status: json['status'] as String,
    clubType: json['club_type'] as String? ?? 'rotary',
    isOnline: json['is_online'] as bool? ?? false,
    onlineMemberCount: json['online_member_count'] as int? ?? 0,
    feeAmount: json['fee_amount'] as int,
    lastPaidDate: json['last_paid_date'] as String? ?? '—',
    nextDueDate: json['next_due_date'] as String? ?? '—',
    paymentStatus: json['payment_status'] as String,
    joined: json['joined'] as String,
    logo: json['logo'] as String?,
    smsEnabled: json['sms_enabled'] as bool? ?? true,
    smsTypes: {for (final k in smsTypeLabels.keys) k: json[k] as bool? ?? true},
  );
}

/// A member of a club, managed platform-wide by the system admin.
class Member {
  final int id;
  String name;
  String phone;
  String club;
  String status; // active | suspended

  /// Seen by the API within its online window — drives the green dot.
  /// Defaults false so an older API response simply reads as offline
  /// rather than failing to parse.
  bool isOnline;

  Member({
    required this.id,
    required this.name,
    required this.phone,
    required this.club,
    required this.status,
    this.isOnline = false,
  });

  factory Member.fromJson(Map<String, dynamic> json) => Member(
    id: json['id'] as int,
    name: json['name'] as String,
    phone: json['phone'] as String,
    club: json['club'] as String,
    status: json['status'] as String,
    isOnline: json['is_online'] as bool? ?? false,
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
  String dob = '';
  String members = '';
  String feeAmount = '';
  String firstPaymentDate = '';
  String nextDueDate = '';
  String? logoDataUrl;
}

/// One-time credentials for a club's first administrator (the Club
/// President), returned when the club is created.
class PresidentCredentials {
  final int id;
  final String name;
  final String phone;
  final String memberNumber;
  final String pin;
  const PresidentCredentials(
    this.id,
    this.name,
    this.phone,
    this.memberNumber,
    this.pin,
  );
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

  factory ClubAttendanceItem.fromJson(Map<String, dynamic> json) =>
      ClubAttendanceItem(
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

  factory MemberEventEntry.fromJson(Map<String, dynamic> json) =>
      MemberEventEntry(
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

  factory SlowRequestEntry.fromJson(Map<String, dynamic> json) =>
      SlowRequestEntry(
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
  final stripped = name
      .replaceFirst(RegExp(r'^Rotary Club (of )?', caseSensitive: false), '')
      .trim();
  final words = stripped
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .toList();
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

const _monthAbbr = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// "06 Sep 2026" — the same shape the backend already formats club dates
/// into, so dates the dashboard formats itself don't read differently from
/// the ones it is handed. Numeric D/M/Y is deliberately avoided: it reads
/// as a different date to a US audience.
String formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')} ${_monthAbbr[d.month - 1]} ${d.year}';

/// Byte count as a short human-readable size ("4.2 MB"). Uses 1024-based
/// units, matching how object storage reports usage. Whole numbers below
/// 10 keep one decimal so small libraries don't all collapse to "1 MB".
String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  const units = ['KB', 'MB', 'GB', 'TB'];
  double value = bytes / 1024;
  int unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  final digits = value < 10 ? 1 : 0;
  return '${value.toStringAsFixed(digits)} ${units[unit]}';
}

/// A club's "request to join" submitted from the public marketing site.
///
/// Not a [Club]: the backend keeps these in their own triage table because
/// anyone on the internet can submit one. The admin reads it here, then
/// onboards the club through the normal new-club wizard.
class JoinRequest {
  final int id;
  final String clubName;
  final String clubType; // rotary | rotaract
  final String district;
  final String location;
  final String? charterDate;
  final int membersCount;
  final String? logo;
  final String contactName;
  final String contactRole;
  final String phone;
  final String email;
  final String dob;
  final String heardAbout;
  final String problems;
  final String notes;
  String status; // new | contacted | approved | declined
  final String createdAt;

  JoinRequest({
    required this.id,
    required this.clubName,
    required this.clubType,
    required this.district,
    required this.location,
    required this.charterDate,
    required this.membersCount,
    required this.logo,
    required this.contactName,
    required this.contactRole,
    required this.phone,
    required this.email,
    required this.dob,
    required this.heardAbout,
    required this.problems,
    required this.notes,
    required this.status,
    required this.createdAt,
  });

  factory JoinRequest.fromJson(Map<String, dynamic> json) => JoinRequest(
    id: json['id'] as int,
    clubName: json['club_name'] as String,
    clubType: json['club_type'] as String? ?? 'rotary',
    district: json['district'] as String? ?? '',
    location: json['location'] as String? ?? '',
    charterDate: json['charter_date'] as String?,
    membersCount: json['members_count'] as int? ?? 0,
    logo: json['logo'] as String?,
    contactName: json['contact_name'] as String? ?? '',
    contactRole: json['contact_role'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    email: json['email'] as String? ?? '',
    dob: json['dob'] as String? ?? '',
    heardAbout: json['heard_about'] as String? ?? '',
    problems: json['problems'] as String? ?? '',
    notes: json['notes'] as String? ?? '',
    status: json['status'] as String? ?? 'new',
    createdAt: json['created_at'] as String? ?? '',
  );
}

/// An event shown on the public marketing site. Unrelated to a club's own
/// events — this is website copy, and publishing it notifies nobody.
class SiteEvent {
  final int id;
  String eventDate; // ISO yyyy-MM-dd
  String title;
  String meta;
  String kind;
  bool published;

  SiteEvent({
    required this.id,
    required this.eventDate,
    required this.title,
    required this.meta,
    required this.kind,
    required this.published,
  });

  factory SiteEvent.fromJson(Map<String, dynamic> json) => SiteEvent(
    id: json['id'] as int,
    eventDate: json['event_date'] as String,
    title: json['title'] as String,
    meta: json['meta'] as String? ?? '',
    kind: json['kind'] as String? ?? '',
    published: json['published'] as bool? ?? true,
  );

  Map<String, dynamic> toJson() => {
    'event_date': eventDate,
    'title': title,
    'meta': meta,
    'kind': kind,
    'published': published,
  };
}

/// A news item on the public marketing site.
class SiteNews {
  final int id;
  String publishedOn; // ISO yyyy-MM-dd
  String title;
  String body;
  bool published;

  SiteNews({
    required this.id,
    required this.publishedOn,
    required this.title,
    required this.body,
    required this.published,
  });

  factory SiteNews.fromJson(Map<String, dynamic> json) => SiteNews(
    id: json['id'] as int,
    publishedOn: json['published_on'] as String,
    title: json['title'] as String,
    body: json['body'] as String? ?? '',
    published: json['published'] as bool? ?? true,
  );

  Map<String, dynamic> toJson() => {
    'published_on': publishedOn,
    'title': title,
    'body': body,
    'published': published,
  };
}

/// A showcase project on the public marketing site.
class SiteProject {
  final int id;
  String tag;
  String area;
  String title;
  String body;
  int progressPercent;
  String? deadline; // ISO yyyy-MM-dd
  String photoCaption;
  bool published;

  SiteProject({
    required this.id,
    required this.tag,
    required this.area,
    required this.title,
    required this.body,
    required this.progressPercent,
    required this.deadline,
    required this.photoCaption,
    required this.published,
  });

  factory SiteProject.fromJson(Map<String, dynamic> json) => SiteProject(
    id: json['id'] as int,
    tag: json['tag'] as String? ?? '',
    area: json['area'] as String? ?? '',
    title: json['title'] as String,
    body: json['body'] as String? ?? '',
    progressPercent: json['progress_percent'] as int? ?? 0,
    deadline: json['deadline'] as String?,
    photoCaption: json['photo_caption'] as String? ?? '',
    published: json['published'] as bool? ?? true,
  );

  Map<String, dynamic> toJson() => {
    'tag': tag,
    'area': area,
    'title': title,
    'body': body,
    'progress_percent': progressPercent,
    'deadline': deadline,
    'photo_caption': photoCaption,
    'published': published,
  };
}
