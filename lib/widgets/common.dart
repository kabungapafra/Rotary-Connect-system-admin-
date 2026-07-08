import 'package:flutter/material.dart';
import '../theme.dart';

BoxDecoration cardDecoration({double radius = 12}) => BoxDecoration(
      color: Colors.white,
      border: Border.all(color: AdminColors.borderLight),
      borderRadius: BorderRadius.circular(radius),
    );

class ClubAvatar extends StatelessWidget {
  final String initials;
  const ClubAvatar(this.initials, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(color: AdminColors.clubInitialsBg, borderRadius: BorderRadius.circular(7)),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AdminColors.clubInitialsText),
      ),
    );
  }
}

class MemberAvatar extends StatelessWidget {
  final String initials;
  const MemberAvatar(this.initials, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: const BoxDecoration(color: AdminColors.memberAvatarBg, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AdminColors.memberAvatarText),
      ),
    );
  }
}

class TableHeaderCell extends StatelessWidget {
  final String label;
  final TextAlign align;
  const TableHeaderCell(this.label, {super.key, this.align = TextAlign.left});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      textAlign: align,
      style: const TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        color: AdminColors.textMuted,
        letterSpacing: 0.4,
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final Color? labelColor;
  const StatCard({super.key, required this.label, required this.value, this.valueColor, this.labelColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: labelColor ?? AdminColors.textMuted,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: valueColor ?? AdminColors.textBase),
          ),
        ],
      ),
    );
  }
}
