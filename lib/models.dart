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
  });
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
}

/// Working copy of the "Onboard New Club" wizard fields.
class ClubDraft {
  String name = '';
  String district = '';
  String location = '';
  String email = '';
  String phone = '';
  String members = '';
  String feeAmount = '';
  String firstPaymentDate = '';
  String nextDueDate = '';
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
