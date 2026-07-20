import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/dashboard_state.dart';
import '../theme.dart';
import 'labeled_date_field.dart';
import 'labeled_field.dart';
import 'modal_scrim.dart';

/// Lets the system admin add a member directly to a club — bootstraps a
/// club whose only member (the auto-created president) was removed, or
/// adds one without routing through that club's own president.
class AddMemberModal extends StatelessWidget {
  const AddMemberModal({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DashboardState>();
    final club = state.addMemberModalClub;
    if (club == null) return const SizedBox.shrink();

    return ModalScrim(
      onDismiss: state.addMemberSaving ? null : state.closeAddMemberModal,
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
              color: AdminColors.pageBg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ADD MEMBER',
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
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LabeledField(
                    key: const ValueKey('addMember-name'),
                    label: 'Name',
                    value: state.addMemberDraft.name,
                    placeholder: 'e.g. Jane Doe',
                    accentColor: state.accentColor,
                    onChanged: state.setAddMemberName,
                  ),
                  const SizedBox(height: 13),
                  LabeledField(
                    key: const ValueKey('addMember-phone'),
                    label: 'Phone',
                    value: state.addMemberDraft.phone,
                    placeholder: '+256 700 000 000',
                    accentColor: state.accentColor,
                    onChanged: state.setAddMemberPhone,
                  ),
                  const SizedBox(height: 13),
                  LabeledField(
                    key: const ValueKey('addMember-role'),
                    label: 'Role',
                    value: state.addMemberDraft.role,
                    placeholder: 'e.g. Club President, Secretary, Member',
                    accentColor: state.accentColor,
                    onChanged: state.setAddMemberRole,
                  ),
                  const SizedBox(height: 13),
                  LabeledField(
                    key: const ValueKey('addMember-email'),
                    label: 'Email (optional)',
                    value: state.addMemberDraft.email,
                    placeholder: 'name@example.org',
                    accentColor: state.accentColor,
                    onChanged: state.setAddMemberEmail,
                  ),
                  const SizedBox(height: 13),
                  LabeledDateField(
                    key: const ValueKey('addMember-dob'),
                    label: 'Date of Birth (optional)',
                    value: state.addMemberDraft.dob,
                    placeholder: 'Pick a date',
                    accentColor: state.accentColor,
                    onChanged: state.setAddMemberDob,
                  ),
                ],
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
                    onPressed: state.addMemberSaving ? null : state.closeAddMemberModal,
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
                    onPressed: state.addMemberSaving ? null : state.saveNewMember,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: state.accentColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    child: state.addMemberSaving
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Add Member'),
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
