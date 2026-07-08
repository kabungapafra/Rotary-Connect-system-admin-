/// A Rotary club onboarded onto the platform.
class Club {
  final int id;
  String name;
  String district;
  String location;
  int members;
  String status; // active | suspended
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
