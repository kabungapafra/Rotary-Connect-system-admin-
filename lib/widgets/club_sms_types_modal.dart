import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../state/dashboard_state.dart';
import '../theme.dart';
import 'modal_scrim.dart';

/// Per-club, per-message-type SMS switches — e.g. keep event reminders on
/// but drop birthday texts for one specific club. Independent of (and
/// checked in addition to) that club's overall SMS on/off switch.
class ClubSmsTypesModal extends StatelessWidget {
  const ClubSmsTypesModal({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DashboardState>();
    final club = state.smsTypesModalClub;
    final draft = state.smsTypesDraft;
    if (club == null || draft == null) return const SizedBox.shrink();

    return ModalScrim(
      onDismiss: state.smsTypesSaving ? null : state.closeSmsTypesModal,
      child: Container(
        width: 460,
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.92,
          maxHeight: MediaQuery.of(context).size.height * 0.86,
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
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SMS PREFERENCES',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AdminColors.textMuted,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    club.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'On top of this club\'s overall SMS switch — turn off just '
                    'one kind of message without affecting the rest.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AdminColors.textMuted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    for (final entry in smsTypeLabels.entries)
                      SwitchListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                        title: Text(
                          entry.value,
                          style: const TextStyle(fontSize: 13),
                        ),
                        value: draft[entry.key] ?? true,
                        activeThumbColor: state.accentColor,
                        onChanged: state.smsTypesSaving
                            ? null
                            : (_) => state.toggleSmsTypeDraft(entry.key),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
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
                    onPressed: state.smsTypesSaving
                        ? null
                        : state.closeSmsTypesModal,
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
                    onPressed: state.smsTypesSaving
                        ? null
                        : state.saveSmsTypesModal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: state.accentColor,
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
                    child: state.smsTypesSaving
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Save'),
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
