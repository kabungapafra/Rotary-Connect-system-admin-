import 'package:flutter/material.dart';

/// Subtle, consistent hover treatment for buttons: a small scale-up with an
/// eased animation (and a click cursor). Wraps any child without changing
/// its layout footprint.
class HoverLift extends StatefulWidget {
  final Widget child;
  final double scale;
  const HoverLift({super.key, required this.child, this.scale = 1.03});

  @override
  State<HoverLift> createState() => _HoverLiftState();
}

class _HoverLiftState extends State<HoverLift> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? widget.scale : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
