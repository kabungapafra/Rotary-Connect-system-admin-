import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/dashboard_state.dart';
import '../theme.dart';
import 'modal_scrim.dart';

/// Confirmation before suspending or activating SMS for every club at
/// once — a wide-blast-radius action, so it gets the same
/// confirm-before-acting treatment as deleting a club.
class BulkSmsModal extends StatelessWidget {
  const BulkSmsModal({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DashboardState>();
    final enabling = state.confirmBulkSmsEnabled;
    if (enabling == null) return const SizedBox.shrink();

    return ModalScrim(
      onDismiss: state.bulkSmsSaving ? null : state.cancelBulkSms,
      child: Container(
        width: 420,
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.92,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AdminColors.modalShadow,
              blurRadius: 64,
              offset: const Offset(0, 24),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              color: enabling ? AdminColors.paidTint : AdminColors.overdueTint,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    enabling ? 'ACTIVATE ALL SMS' : 'SUSPEND ALL SMS',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: enabling
                          ? AdminColors.paidColor
                          : AdminColors.overdueColor,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'This affects every club',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                enabling
                    ? 'Turn SMS back on for every club platform-wide, including '
                          'any club that had it suspended individually?'
                    : 'Turn off SMS for every club platform-wide — birthday '
                          'wishes, guest thank-yous, event reminders, new-member '
                          'and PIN-reset texts will stop going out for all clubs '
                          'until reactivated?',
                style: const TextStyle(
                  fontSize: 13,
                  color: AdminColors.textBase,
                  height: 1.6,
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
                    onPressed: state.bulkSmsSaving ? null : state.cancelBulkSms,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AdminColors.inputBorder),
                      backgroundColor: Colors.white,
                      foregroundColor: AdminColors.textBase,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 9,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 9),
                  ElevatedButton(
                    onPressed: state.bulkSmsSaving
                        ? null
                        : state.confirmBulkSmsAction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: enabling
                          ? AdminColors.paidDot
                          : AdminColors.overdueDot,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 9,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: state.bulkSmsSaving
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(enabling ? 'Activate All' : 'Suspend All'),
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
