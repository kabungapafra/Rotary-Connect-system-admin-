import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../state/dashboard_state.dart';
import '../theme.dart';
import '../widgets/actions_menu.dart';
import '../widgets/common.dart';
import '../widgets/status_badge.dart';

class ClubsView extends StatelessWidget {
  const ClubsView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DashboardState>();
    return Container(
      decoration: cardDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 11),
            child: Row(
              children: [
                Expanded(flex: 3, child: TableHeaderCell('Club')),
                Expanded(flex: 2, child: TableHeaderCell('District')),
                Expanded(flex: 2, child: TableHeaderCell('Members')),
                Expanded(flex: 2, child: TableHeaderCell('Next Payment')),
                Expanded(flex: 2, child: TableHeaderCell('Status')),
                Expanded(flex: 2, child: TableHeaderCell('Actions', align: TextAlign.right)),
              ],
            ),
          ),
          for (final club in state.clubs) _ClubRow(club: club, state: state),
        ],
      ),
    );
  }
}

class _ClubRow extends StatelessWidget {
  final Club club;
  final DashboardState state;
  const _ClubRow({required this.club, required this.state});

  @override
  Widget build(BuildContext context) {
    final style = paymentStyleFor(club.paymentStatus);
    final isActive = club.status == 'active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
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
          Expanded(
            flex: 2,
            child: Text(club.nextDueDate, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          Expanded(flex: 2, child: StatusBadge(style)),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: ActionsMenu(
                items: [
                  ActionsMenuItem(
                    isActive ? 'Suspend Club' : 'Activate Club',
                    () => state.toggleClubStatus(club.id),
                    color: isActive ? AdminColors.overdueColor : AdminColors.paidColor,
                  ),
                  ActionsMenuItem('Record Payment', () => state.openPaymentModal(club.id)),
                  ActionsMenuItem('View Statistics', () => state.openStatsModal(club.id)),
                  ActionsMenuItem('Show QR Code', () => state.openQrModal(club.id)),
                  ActionsMenuItem(
                    'Delete Club',
                    () => state.askDeleteClub(club.id),
                    color: AdminColors.overdueColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
