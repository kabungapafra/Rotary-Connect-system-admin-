import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/gap_row.dart';

class SmsView extends StatelessWidget {
  const SmsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const GapRow(
          gap: 14,
          children: [
            StatCard(label: 'Sent Today', value: '983'),
            StatCard(
              label: 'Delivered',
              value: '941',
              labelColor: AdminColors.smsDeliveredLabel,
              valueColor: AdminColors.smsDeliveredValue,
            ),
            StatCard(
              label: 'Pending',
              value: '27',
              labelColor: AdminColors.smsPendingLabel,
              valueColor: AdminColors.smsPendingValue,
            ),
            StatCard(
              label: 'Failed',
              value: '15',
              labelColor: AdminColors.smsFailedLabel,
              valueColor: AdminColors.smsFailedValue,
            ),
          ],
        ),
        const SizedBox(height: 16),
        const GapRow(
          gap: 14,
          flexes: [14, 10],
          children: [_DeliveryBreakdownCard(), _CostCard()],
        ),
      ],
    );
  }
}

class _DeliveryBreakdownCard extends StatelessWidget {
  const _DeliveryBreakdownCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Delivery Breakdown', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: SizedBox(
              height: 14,
              child: Row(
                children: [
                  Expanded(flex: 957, child: Container(color: AdminColors.paidDot)),
                  Expanded(flex: 27, child: Container(color: AdminColors.dueSoonDot)),
                  Expanded(flex: 16, child: Container(color: AdminColors.overdueDot)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Row(
            children: [
              _LegendDot(color: AdminColors.paidDot, label: 'Delivered'),
              SizedBox(width: 18),
              _LegendDot(color: AdminColors.dueSoonDot, label: 'Pending'),
              SizedBox(width: 18),
              _LegendDot(color: AdminColors.overdueDot, label: 'Failed'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: AdminColors.textMuted)),
      ],
    );
  }
}

class _CostCard extends StatelessWidget {
  const _CostCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: cardDecoration(),
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: const [
          Text('Cost This Month', style: TextStyle(fontSize: 12.5, color: AdminColors.textMuted)),
          SizedBox(height: 6),
          Text('UGX 1,547,000', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          SizedBox(height: 8),
          Text(
            'Billed per message sent across all clubs, reconciled monthly with subscription invoices.',
            style: TextStyle(fontSize: 11.5, color: AdminColors.textMuted),
          ),
        ],
      ),
    );
  }
}
