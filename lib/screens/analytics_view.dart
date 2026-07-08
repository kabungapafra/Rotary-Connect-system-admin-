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
      ],
    );
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
