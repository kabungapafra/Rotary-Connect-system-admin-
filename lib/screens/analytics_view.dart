import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/dashboard_state.dart';
import '../theme.dart';
import '../widgets/attendance_chart.dart';
import '../widgets/common.dart';
import '../widgets/gap_row.dart';

class AnalyticsView extends StatelessWidget {
  const AnalyticsView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DashboardState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GapRow(
          gap: 14,
          children: [
            StatCard(label: 'New Clubs This Month', value: '${state.newClubsThisMonth}'),
            StatCard(label: 'Active Members', value: '${state.activeMembersCount}'),
            StatCard(label: 'Avg. Attendance', value: '${state.avgAttendancePercent}%'),
          ],
        ),
        const SizedBox(height: 16),
        GapRow(
          gap: 14,
          flexes: const [14, 10],
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AttendanceCard(state: state),
            _UsageRevenueCard(state: state),
          ],
        ),
        const SizedBox(height: 16),
        _ErrorLogCard(state: state),
      ],
    );
  }
}

/// No third-party error tracker (Sentry, etc.) is wired up — this list
/// (backed by main.py's global exception handler on the backend) is the
/// only place an unhandled API exception is visible at all.
class _ErrorLogCard extends StatelessWidget {
  final DashboardState state;
  const _ErrorLogCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final errors = state.errorLogs;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('System Errors',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
              if (errors.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AdminColors.overdueColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text('${errors.length}',
                      style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: AdminColors.overdueColor)),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Unhandled backend exceptions from the last 30 days, most recent first.',
            style: const TextStyle(fontSize: 11.5, color: AdminColors.textMuted),
          ),
          const SizedBox(height: 12),
          if (errors.isEmpty)
            const Text('No errors recorded.',
                style: TextStyle(fontSize: 12.5, color: AdminColors.textMuted))
          else
            for (final e in errors.take(10))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${e.method} ${e.path}',
                              style: const TextStyle(
                                  fontSize: 12.5, fontWeight: FontWeight.w700)),
                          Text('${e.exceptionType}: ${e.message}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 11.5, color: AdminColors.textMuted)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(_relativeTime(e.createdAt),
                        style: const TextStyle(fontSize: 11, color: AdminColors.textMuted)),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  String _relativeTime(DateTime time) {
    final diff = DateTime.now().toUtc().difference(time.toUtc());
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _AttendanceCard extends StatelessWidget {
  final DashboardState state;
  const _AttendanceCard({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Attendance Trend', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text(
            'Average weekly attendance across all clubs',
            style: TextStyle(fontSize: 11.5, color: AdminColors.textMuted),
          ),
          const SizedBox(height: 12),
          AttendanceChart(values: state.attendanceVals, accentColor: state.accentColor),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final lbl in state.attendanceLabels)
                Text(lbl, style: const TextStyle(fontSize: 11, color: AdminColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }
}

class _UsageRevenueCard extends StatelessWidget {
  final DashboardState state;
  const _UsageRevenueCard({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Revenue', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Expected Monthly Revenue', style: TextStyle(fontSize: 12.5, color: AdminColors.textMuted)),
                Text(state.mrrFormatted, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          const SizedBox(height: 2),
          for (final item in state.paymentLegend)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: paymentStyleFor(item.colorKey).dot,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(item.name, style: const TextStyle(fontSize: 12, color: AdminColors.textMuted)),
                    ],
                  ),
                  Text('${item.count} clubs', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
