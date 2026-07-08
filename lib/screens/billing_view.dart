import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../state/dashboard_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/status_badge.dart';

class BillingView extends StatelessWidget {
  const BillingView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DashboardState>();
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.maxWidth / 300).floor().clamp(1, 6);
        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            for (final club in state.clubs)
              SizedBox(
                width: (constraints.maxWidth - (columns - 1) * 14) / columns,
                child: _BillingCard(club: club, state: state),
              ),
          ],
        );
      },
    );
  }
}

class _BillingCard extends StatelessWidget {
  final Club club;
  final DashboardState state;
  const _BillingCard({required this.club, required this.state});

  @override
  Widget build(BuildContext context) {
    final style = paymentStyleFor(club.paymentStatus);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  club.name,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
              StatusBadge(style),
            ],
          ),
          const SizedBox(height: 14),
          _row('Monthly Fee', '${formatUgx(club.feeAmount)}/mo', valueWeight: FontWeight.w700),
          const SizedBox(height: 9),
          _row('Last Paid', club.lastPaidDate),
          const SizedBox(height: 9),
          _row('Next Payment Due', club.nextDueDate),
          const SizedBox(height: 14),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => state.openPaymentModal(club.id),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: AdminColors.buttonBorder),
                  borderRadius: BorderRadius.circular(8),
                  color: AdminColors.pageBg,
                ),
                child: const Text(
                  'Record Payment',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {FontWeight valueWeight = FontWeight.w600}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12.5, color: AdminColors.textMuted)),
        Text(value, style: TextStyle(fontSize: 12.5, fontWeight: valueWeight)),
      ],
    );
  }
}
