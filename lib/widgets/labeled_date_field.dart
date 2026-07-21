import 'package:flutter/material.dart';
import '../theme.dart';

const List<String> _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// "08 Jul 2026" — the one format the backend's date parser accepts
/// (see utils.DATE_FORMAT) and the dashboard displays everywhere.
String formatAdminDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')} ${_months[d.month - 1]} ${d.year}';

DateTime? _parseAdminDate(String value) {
  final parts = value.trim().split(RegExp(r'\s+'));
  if (parts.length != 3) return null;
  final day = int.tryParse(parts[0]);
  final month = _months.indexWhere((m) => m.toLowerCase() == parts[1].toLowerCase()) + 1;
  final year = int.tryParse(parts[2]);
  if (day == null || month == 0 || year == null) return null;
  return DateTime(year, month, day);
}

/// Same look as [LabeledField], but read-only: tapping it opens a Material
/// date picker instead of free-typing "08 Jul 2026" by hand.
class LabeledDateField extends StatelessWidget {
  final String label;
  final String value;
  final String? placeholder;
  final Color accentColor;
  final ValueChanged<String> onChanged;
  const LabeledDateField({
    super.key,
    required this.label,
    required this.value,
    required this.accentColor,
    required this.onChanged,
    this.placeholder,
  });

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _parseAdminDate(value) ?? now,
      firstDate: DateTime(now.year - 100),
      lastDate: DateTime(now.year + 5),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: accentColor,
            onPrimary: Colors.white,
            onSurface: AdminColors.textBase,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) onChanged(formatAdminDate(picked));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => _pick(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AdminColors.inputBorder),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value.trim().isEmpty ? (placeholder ?? 'Pick a date') : value,
                      style: TextStyle(
                        fontSize: 13,
                        color: value.trim().isEmpty
                            ? AdminColors.placeholder
                            : AdminColors.textBase,
                      ),
                    ),
                  ),
                  Icon(Icons.calendar_today_outlined, size: 15, color: accentColor),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
