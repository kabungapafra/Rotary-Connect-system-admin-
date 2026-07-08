import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/dashboard_state.dart';
import '../theme.dart';

class ToastOverlay extends StatelessWidget {
  const ToastOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final message = context.watch<DashboardState>().toastMessage;
    return Positioned(
      bottom: 26,
      right: 26,
      child: IgnorePointer(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(animation),
              child: child,
            ),
          ),
          child: message == null
              ? const SizedBox.shrink(key: ValueKey('empty'))
              : Container(
                  key: ValueKey(message),
                  padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 13),
                  decoration: BoxDecoration(
                    color: AdminColors.sidebarBg,
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: [
                      BoxShadow(color: AdminColors.modalShadow, blurRadius: 32, offset: const Offset(0, 12)),
                    ],
                  ),
                  child: Text(
                    message,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
        ),
      ),
    );
  }
}
