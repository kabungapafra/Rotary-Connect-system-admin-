import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../state/dashboard_state.dart';
import '../theme.dart';
import '../widgets/actions_menu.dart';
import '../widgets/common.dart';
import '../widgets/status_badge.dart';

class MembersView extends StatelessWidget {
  const MembersView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DashboardState>();
    final filtered = state.filteredMembers;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            SizedBox(
              width: 280,
              child: _SearchField(
                value: state.memberSearch,
                onChanged: state.setMemberSearch,
              ),
            ),
            const SizedBox(width: 10),
            _FilterDropdown<String>(
              value: state.memberClubFilter,
              items: [
                const DropdownMenuItem(value: 'all', child: Text('All Clubs')),
                for (final name in state.clubNameOptions) DropdownMenuItem(value: name, child: Text(name)),
              ],
              onChanged: (v) => state.setMemberClubFilter(v ?? 'all'),
            ),
            const SizedBox(width: 10),
            _FilterDropdown<String>(
              value: state.memberStatusFilter,
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All Statuses')),
                DropdownMenuItem(value: 'active', child: Text('Active')),
                DropdownMenuItem(value: 'suspended', child: Text('Suspended')),
              ],
              onChanged: (v) => state.setMemberStatusFilter(v ?? 'all'),
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
                    Expanded(flex: 3, child: TableHeaderCell('Name')),
                    Expanded(flex: 3, child: TableHeaderCell('Phone')),
                    Expanded(flex: 3, child: TableHeaderCell('Club')),
                    Expanded(flex: 2, child: TableHeaderCell('Status')),
                    Expanded(flex: 2, child: TableHeaderCell('Actions', align: TextAlign.right)),
                  ],
                ),
              ),
              for (final m in filtered) _MemberRow(member: m, state: state),
              if (filtered.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                    child: Text(
                      'No members match your filters.',
                      style: TextStyle(fontSize: 13.5, color: AdminColors.textMuted),
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

class _SearchField extends StatefulWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _SearchField({required this.value, required this.onChanged});

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  late final _controller = TextEditingController(text: widget.value);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        isDense: true,
        hintText: 'Search by name or phone',
        hintStyle: const TextStyle(fontSize: 13, color: AdminColors.placeholder),
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
          borderSide: BorderSide(color: context.watch<DashboardState>().accentColor),
        ),
      ),
    );
  }
}

class _FilterDropdown<T> extends StatelessWidget {
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  const _FilterDropdown({required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AdminColors.inputBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 13, color: AdminColors.textBase),
          icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: AdminColors.textMuted),
        ),
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  final Member member;
  final DashboardState state;
  const _MemberRow({required this.member, required this.state});

  @override
  Widget build(BuildContext context) {
    final style = clubStyleFor(member.status);
    final isActive = member.status == 'active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AdminColors.rowBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                MemberAvatar(memberInitialsFor(member.name)),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    member.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(member.phone, style: const TextStyle(fontSize: 13, color: AdminColors.textMuted)),
          ),
          Expanded(
            flex: 3,
            child: Text(member.club, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
          ),
          Expanded(flex: 2, child: StatusBadge(style)),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: ActionsMenu(
                items: [
                  ActionsMenuItem(
                    isActive ? 'Suspend Member' : 'Activate Member',
                    () => state.toggleMemberStatus(member.id),
                    color: isActive ? AdminColors.overdueColor : AdminColors.paidColor,
                  ),
                  ActionsMenuItem('Reset Password', () => state.resetPassword(member.id)),
                  ActionsMenuItem('View Activity', () => state.viewActivity(member.id)),
                  ActionsMenuItem(
                    'Delete Member',
                    () => state.askDeleteMember(member.id),
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
