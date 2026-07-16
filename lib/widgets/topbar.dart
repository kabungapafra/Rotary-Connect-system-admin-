import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/dashboard_state.dart';
import '../theme.dart';
import 'hover_lift.dart';

const Map<String, List<String>> _pageMeta = {
  'dashboard': ['Dashboard', 'Overview of clubs, members, and system activity'],
  'clubs': ['Club Management', 'Onboard, suspend, and manage Rotary clubs'],
  'members': [
    'Member Management',
    'Search, filter, and manage members across clubs',
  ],
  'billing': ['Billing', 'Track club payments and upcoming due dates'],
  'analytics': ['Analytics', 'Growth, engagement, and usage across all clubs'],
  'sms': ['SMS Dashboard', 'Delivery status and cost for club messaging'],
  'health': [
    'System Health',
    'Member sign-in problems, API speed, and backend errors',
  ],
};

class AdminTopbar extends StatelessWidget {
  const AdminTopbar({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DashboardState>();
    final meta = _pageMeta[state.view]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AdminColors.borderLight)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                meta[0],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.18,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                meta[1],
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AdminColors.textMuted,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Tooltip(
                message: 'Refresh data',
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: state.dataLoading ? null : state.refresh,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        border: Border.all(color: AdminColors.buttonBorder),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: state.dataLoading
                          ? const SizedBox(
                              width: 15,
                              height: 15,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(
                              Icons.refresh,
                              size: 15,
                              color: AdminColors.buttonText,
                            ),
                    ),
                  ),
                ),
              ),
              if (state.view == 'clubs') const SizedBox(width: 10),
              if (state.view == 'clubs') _NewClubButton(state: state),
            ],
          ),
        ],
      ),
    );
  }
}

class _NewClubButton extends StatelessWidget {
  final DashboardState state;
  const _NewClubButton({required this.state});

  @override
  Widget build(BuildContext context) {
    return HoverLift(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: state.openNewClub,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: state.accentColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, size: 14, color: Colors.white),
                SizedBox(width: 7),
                Text(
                  'New Club',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
