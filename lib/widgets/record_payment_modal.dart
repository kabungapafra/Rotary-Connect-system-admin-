import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../state/dashboard_state.dart';
import '../theme.dart';
import 'labeled_field.dart';
import 'modal_scrim.dart';

class RecordPaymentModal extends StatelessWidget {
  const RecordPaymentModal({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DashboardState>();
    final club = state.paymentModalClub;
    if (club == null) return const SizedBox.shrink();
    return ModalScrim(
      onDismiss: state.closePaymentModal,
      child: Container(
        width: 400,
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
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
              color: AdminColors.clubInitialsBg,
              child: Stack(
                children: [
                  Positioned(
                    top: -4,
                    right: -4,
                    child: GestureDetector(
                      onTap: state.closePaymentModal,
                      child: const Icon(Icons.close, size: 19, color: AdminColors.closeIcon),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'RECORD PAYMENT',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AdminColors.clubInitialsText,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        club.name,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.17),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _headerStat('Current Fee', formatUgx(club.feeAmount)),
                          const SizedBox(width: 16),
                          _headerStat('Last Paid', club.lastPaidDate),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LabeledField(
                    label: 'Amount Paid (UGX)',
                    value: state.paymentDraft.amount,
                    accentColor: state.accentColor,
                    onChanged: state.setPaymentAmount,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: LabeledField(
                          label: 'Date Paid',
                          value: state.paymentDraft.datePaid,
                          placeholder: 'e.g. 08 Jul 2026',
                          accentColor: state.accentColor,
                          onChanged: state.setPaymentDatePaid,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: LabeledField(
                          label: 'Next Due',
                          value: state.paymentDraft.nextDue,
                          placeholder: 'e.g. 08 Aug 2026',
                          accentColor: state.accentColor,
                          onChanged: state.setPaymentNextDue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
              decoration: const BoxDecoration(
                color: AdminColors.pageBg,
                border: Border(top: BorderSide(color: AdminColors.borderLight)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: state.closePaymentModal,
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
                    onPressed: state.savePayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: state.accentColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    child: const Text('Save Payment'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AdminColors.clubInitialsText),
        ),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      ],
    );
  }
}
