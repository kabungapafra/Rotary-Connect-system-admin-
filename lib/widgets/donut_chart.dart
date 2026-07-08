import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// Payment-status donut, matching the source design's
/// `background: conic-gradient(...)` ring with a white center hole —
/// recreated with a [SweepGradient], rotated so 0% starts at 12 o'clock
/// just like CSS conic-gradient's default.
class DonutChart extends StatelessWidget {
  final Map<String, int> counts;
  final List<String> order;
  final int total;
  final Widget center;
  const DonutChart({
    super.key,
    required this.counts,
    required this.order,
    required this.total,
    required this.center,
  });

  @override
  Widget build(BuildContext context) {
    final colors = <Color>[];
    final stops = <double>[];

    if (total == 0) {
      colors.addAll([AdminColors.borderLight, AdminColors.borderLight]);
      stops.addAll([0, 1]);
    } else {
      double acc = 0;
      for (final key in order) {
        final count = counts[key] ?? 0;
        final frac = count / total;
        final start = acc.clamp(0.0, 1.0);
        final end = (acc + frac).clamp(0.0, 1.0);
        final color = paymentStyleFor(key).dot;
        colors.add(color);
        stops.add(start);
        colors.add(color);
        stops.add(end);
        acc += frac;
      }
    }

    return Container(
      width: 104,
      height: 104,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(
          colors: colors,
          stops: stops,
          transform: const GradientRotation(-math.pi / 2),
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Container(
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: center,
      ),
    );
  }
}
