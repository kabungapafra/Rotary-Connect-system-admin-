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
    final filtered = state.filteredClubs;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            SizedBox(
              width: 280,
              child: TextField(
                onChanged: state.setClubSearch,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Search by name, district, or location',
                  hintStyle: const TextStyle(fontSize: 13, color: AdminColors.placeholder),
                  prefixIcon: const Icon(Icons.search, size: 17, color: AdminColors.textMuted),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AdminColors.inputBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AdminColors.inputBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: state.accentColor),
                  ),
                ),
              ),
            ),
            const Spacer(),
            Text(
              '${filtered.length} of ${state.totalClubs} clubs · ${state.activeClubs} active',
              style: const TextStyle(fontSize: 12.5, color: AdminColors.textMuted, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
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
                    Expanded(flex: 1, child: TableHeaderCell('Type')),
                    Expanded(flex: 2, child: TableHeaderCell('Members')),
                    Expanded(flex: 2, child: TableHeaderCell('Next Payment')),
                    Expanded(flex: 2, child: TableHeaderCell('Status')),
                    Expanded(flex: 2, child: TableHeaderCell('Actions', align: TextAlign.right)),
                  ],
                ),
              ),
              for (final club in filtered) _ClubRow(club: club, state: state),
              if (filtered.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                    child: Text(
                      state.clubs.isEmpty
                          ? 'No clubs onboarded yet — use "New Club" to add the first one.'
                          : 'No clubs match your search.',
                      style: const TextStyle(fontSize: 13.5, color: AdminColors.textMuted),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ClubRow extends StatelessWidget {
  final Club club;
  final DashboardState state;
  const _ClubRow({required this.club, required this.state});

  @override
  Widget build(BuildContext context) {
    final paymentStyle = paymentStyleFor(club.paymentStatus);
    final activeStyle = clubStyleFor(club.status);
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
          Expanded(
            flex: 1,
            child: Text(
              club.clubType == 'rotaract' ? 'Rotaract' : 'Rotary',
              style: const TextStyle(fontSize: 13, color: AdminColors.textMuted),
            ),
          ),
          Expanded(flex: 2, child: Text('${club.members}', style: const TextStyle(fontSize: 13))),
          Expanded(
            flex: 2,
            child: Text(club.nextDueDate, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                StatusBadge(paymentStyle),
                const SizedBox(height: 4),
                StatusBadge(activeStyle),
              ],
            ),
          ),
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
                  ActionsMenuItem('Add Member', () => state.openAddMemberModal(club.id)),
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
