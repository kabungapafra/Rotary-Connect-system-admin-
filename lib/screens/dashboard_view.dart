import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../state/dashboard_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/donut_chart.dart';
import '../widgets/gap_row.dart';
import '../widgets/status_badge.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DashboardState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GapRow(
          gap: 14,
          children: [for (final k in state.kpis) _KpiCard(k)],
        ),
        const SizedBox(height: 22),
        GapRow(
          gap: 16,
          flexes: const [16, 10],
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _RecentClubsCard(clubs: state.recentClubs),
            _PaymentStatusCard(state: state),
          ],
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final KpiData kpi;
  const _KpiCard(this.kpi);

  @override
  Widget build(BuildContext context) {
    final deltaColor = kpi.isPositive ? const Color(0xFF1F7A45) : AdminColors.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            kpi.label.toUpperCase(),
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AdminColors.textMuted,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(kpi.value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
              if (kpi.delta.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  kpi.delta,
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: deltaColor),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _RecentClubsCard extends StatelessWidget {
  final List<Club> clubs;
  const _RecentClubsCard({required this.clubs});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: cardDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AdminColors.borderLight)),
            ),
            child: const Text(
              'Recently Onboarded Clubs',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
            child: const Row(
              children: [
                Expanded(flex: 3, child: TableHeaderCell('Club')),
                Expanded(flex: 2, child: TableHeaderCell('District')),
                Expanded(flex: 2, child: TableHeaderCell('Members')),
                Expanded(flex: 2, child: TableHeaderCell('Status')),
              ],
            ),
          ),
          for (final c in clubs) _ClubRow(c),
        ],
      ),
    );
  }
}

class _ClubRow extends StatelessWidget {
  final Club club;
  const _ClubRow(this.club);

  @override
  Widget build(BuildContext context) {
    final style = paymentStyleFor(club.paymentStatus);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AdminColors.rowBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                ClubAvatar(initialsFor(club.name), logo: club.logo),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    club.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(club.district, style: const TextStyle(fontSize: 13, color: AdminColors.textMuted)),
          ),
          Expanded(flex: 2, child: Text('${club.members}', style: const TextStyle(fontSize: 13))),
          Expanded(flex: 2, child: StatusBadge(style)),
        ],
      ),
    );
  }
}

class _PaymentStatusCard extends StatelessWidget {
  final DashboardState state;
  const _PaymentStatusCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final counts = state.paymentStatusCounts;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Payment Status', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              DonutChart(
                counts: counts,
                order: const ['paid', 'due-soon', 'overdue'],
                total: state.totalClubs,
                center: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${state.totalClubs}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    const Text('clubs', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AdminColors.textMuted)),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final item in state.paymentLegend)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.5),
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
                                Text(item.name, style: const TextStyle(fontSize: 12.5)),
                              ],
                            ),
                            Text('${item.count}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.only(top: 14),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AdminColors.rowBorder)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Expected Monthly Revenue', style: TextStyle(fontSize: 12.5, color: AdminColors.textMuted)),
                Text(state.mrrFormatted, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
