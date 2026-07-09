import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/dashboard_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/gap_row.dart';

/// SMS module — real counts from the send log (see GET /admin/sms/summary),
/// not static placeholders. "Delivered"/"Pending" aren't shown because
/// there's no delivery-receipt webhook from the gateway; what we actually
/// know is whether each send attempt was accepted or rejected.
class SmsView extends StatelessWidget {
  const SmsView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DashboardState>();
    final summary = state.smsSummary;
    final loading = state.smsSummaryLoading && summary == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GapRow(
          gap: 14,
          children: [
            StatCard(label: 'Sent Today', value: loading ? '—' : '${summary?.sentToday ?? 0}'),
            StatCard(
              label: 'Failed Today',
              value: loading ? '—' : '${summary?.failedToday ?? 0}',
              labelColor: AdminColors.smsFailedLabel,
              valueColor: AdminColors.smsFailedValue,
            ),
            StatCard(
              label: 'Sent All-Time',
              value: loading ? '—' : '${summary?.sentTotal ?? 0}',
              labelColor: AdminColors.smsDeliveredLabel,
              valueColor: AdminColors.smsDeliveredValue,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(28),
          decoration: cardDecoration(),
          child: Column(
            children: [
              Icon(
                summary?.enabled == true ? Icons.sms_outlined : Icons.sms_failed_outlined,
                size: 34,
                color: AdminColors.textMuted,
              ),
              const SizedBox(height: 12),
              Text(
                summary == null
                    ? 'Loading…'
                    : summary.enabled
                        ? 'SMS gateway connected'
                        : 'No SMS gateway connected',
                style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                summary == null
                    ? ''
                    : summary.enabled
                        ? 'Login credentials, birthday wishes, new fellowship '
                            'announcements, and visitor thank-yous are sent '
                            'automatically across every club.'
                        : 'Once an SMS provider is connected, delivery stats '
                            'across all clubs will appear here.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12.5, color: AdminColors.textMuted, height: 1.5),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
