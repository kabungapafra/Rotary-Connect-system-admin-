import 'package:flutter/material.dart';
import '../theme.dart';

/// Full-screen dimmed backdrop behind every modal, matching the source
/// design's `position:fixed; inset:0; background: oklch(20% 0.02 260 / 0.45)`.
class ModalScrim extends StatelessWidget {
  final Widget child;
  final VoidCallback? onDismiss;
  const ModalScrim({super.key, required this.child, this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: onDismiss,
              child: Container(color: AdminColors.modalOverlay),
            ),
          ),
          Center(
            child: GestureDetector(
              onTap: () {},
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
