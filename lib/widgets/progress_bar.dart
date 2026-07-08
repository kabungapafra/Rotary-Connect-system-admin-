import 'package:flutter/material.dart';
import '../theme.dart';

class ProgressBar extends StatelessWidget {
  final double percent;
  final Color color;
  const ProgressBar({super.key, required this.percent, required this.color});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 7,
        color: AdminColors.statsPlaceholderBg,
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: (percent / 100).clamp(0.0, 1.0),
          child: Container(color: color),
        ),
      ),
    );
  }
}
