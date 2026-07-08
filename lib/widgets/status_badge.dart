import 'package:flutter/material.dart';
import '../theme.dart';

class StatusBadge extends StatelessWidget {
  final StatusStyle style;
  const StatusBadge(this.style, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: style.dot, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          style.label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: style.color),
        ),
      ],
    );
  }
}
