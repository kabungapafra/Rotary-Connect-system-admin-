import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/dashboard_state.dart';
import '../theme.dart';
import 'modal_scrim.dart';

/// Confirmation before deleting a club — the deletion cascades to the
/// club's members, meetings, check-ins, events, and projects.
class DeleteClubModal extends StatelessWidget {
  const DeleteClubModal({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DashboardState>();
    final club = state.confirmDeleteClub;
    if (club == null) return const SizedBox.shrink();

    return ModalScrim(
      onDismiss: state.deletingClub ? null : state.cancelDeleteClub,
      child: Container(
        width: 420,
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.92),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: AdminColors.modalShadow, blurRadius: 64, offset: const Offset(0, 24))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              color: AdminColors.overdueTint,
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DELETE CLUB',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AdminColors.overdueColor,
                      letterSpacing: 0.4,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'This cannot be undone',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text.rich(
                TextSpan(
                  style: const TextStyle(fontSize: 13, color: AdminColors.textBase, height: 1.6),
                  children: [
                    const TextSpan(text: 'Delete '),
                    TextSpan(
                        text: club.name,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    const TextSpan(
                        text: ' permanently? All of its members, meetings, '
                            'check-in history, events, and projects will be '
                            'removed, and its members will no longer be able '
                            'to sign in to the app.'),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                color: AdminColors.pageBg,
                border: Border(top: BorderSide(color: AdminColors.borderLight)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: state.deletingClub ? null : state.cancelDeleteClub,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AdminColors.inputBorder),
                      backgroundColor: Colors.white,
                      foregroundColor: AdminColors.textBase,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 9),
                  ElevatedButton(
                    onPressed: state.deletingClub ? null : state.deleteClubConfirmed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AdminColors.overdueDot,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    child: state.deletingClub
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Delete Club'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
