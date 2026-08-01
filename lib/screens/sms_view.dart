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
    final suspendedCount = state.clubs.where((c) => !c.smsEnabled).length;

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
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Per-club SMS',
                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                suspendedCount == 0
                    ? 'Every club currently has SMS on. Suspend an individual '
                        'club from the Clubs tab, or use the bulk actions '
                        'below to affect every club at once.'
                    : '$suspendedCount of ${state.clubs.length} club'
                        '${state.clubs.length == 1 ? '' : 's'} currently '
                        'has SMS suspended.',
                style: const TextStyle(
                    fontSize: 12.5, color: AdminColors.textMuted, height: 1.5),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => state.askBulkSms(false),
                    icon: const Icon(Icons.sms_failed_outlined, size: 16),
                    label: const Text('Suspend All'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AdminColors.overdueColor),
                      foregroundColor: AdminColors.overdueColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: () => state.askBulkSms(true),
                    icon: const Icon(Icons.sms_outlined, size: 16),
                    label: const Text('Activate All'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AdminColors.paidColor),
                      foregroundColor: AdminColors.paidColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
