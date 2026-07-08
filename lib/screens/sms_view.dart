import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/gap_row.dart';

/// SMS module. No gateway is connected yet, so every figure is an honest
/// zero and the panel says so — nothing here is demo data.
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
            StatCard(label: 'Sent Today', value: '0'),
            StatCard(
              label: 'Delivered',
              value: '0',
              labelColor: AdminColors.smsDeliveredLabel,
              valueColor: AdminColors.smsDeliveredValue,
            ),
            StatCard(
              label: 'Pending',
              value: '0',
              labelColor: AdminColors.smsPendingLabel,
              valueColor: AdminColors.smsPendingValue,
            ),
            StatCard(
              label: 'Failed',
              value: '0',
              labelColor: AdminColors.smsFailedLabel,
              valueColor: AdminColors.smsFailedValue,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(28),
          decoration: cardDecoration(),
          child: const Column(
            children: [
              Icon(Icons.sms_outlined, size: 34, color: AdminColors.textMuted),
              SizedBox(height: 12),
              Text(
                'No SMS gateway connected',
                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 6),
              Text(
                'Once an SMS provider is connected, delivery stats and per-message '
                'costs across all clubs will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12.5, color: AdminColors.textMuted, height: 1.5),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
