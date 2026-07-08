import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/dashboard_state.dart';
import '../theme.dart';
import 'nav_icons.dart';

class AdminSidebar extends StatelessWidget {
  const AdminSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DashboardState>();
    return Container(
      width: 240,
      color: AdminColors.sidebarBg,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 20),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: state.accentColor,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  alignment: Alignment.center,
                  child: const TargetLogoIcon(),
                ),
                const SizedBox(width: 9),
                const Text(
                  'Rotary Admin',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                    color: Colors.white,
                    letterSpacing: -0.14,
                  ),
                ),
              ],
            ),
          ),
          const _SectionLabel('Overview', topPad: 14),
          _NavItem(
            icon: NavIconShape.dashboard,
            label: 'Dashboard',
            active: state.view == 'dashboard',
            onTap: state.goDashboard,
          ),
          _NavItem(
            icon: NavIconShape.analytics,
            label: 'Analytics',
            active: state.view == 'analytics',
            onTap: state.goAnalytics,
          ),
          const _SectionLabel('Manage', topPad: 16),
          _NavItem(
            icon: NavIconShape.clubs,
            label: 'Clubs',
            active: state.view == 'clubs',
            onTap: state.goClubs,
          ),
          _NavItem(
            icon: NavIconShape.members,
            label: 'Members',
            active: state.view == 'members',
            onTap: state.goMembers,
          ),
          _NavItem(
            icon: NavIconShape.billing,
            label: 'Billing',
            active: state.view == 'billing',
            onTap: state.goBilling,
          ),
          const _SectionLabel('Comms', topPad: 16),
          _NavItem(
            icon: NavIconShape.sms,
            label: 'SMS',
            active: state.view == 'sms',
            onTap: state.goSms,
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            margin: const EdgeInsets.only(top: 8),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AdminColors.sidebarFooterBorder)),
            ),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(
                    color: AdminColors.sidebarAvatarBg,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'SA',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'System Admin',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                      Text(
                        'admin@rotary.org',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: AdminColors.sidebarEmailText),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final double topPad;
  const _SectionLabel(this.text, {required this.topPad});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(10, topPad, 10, 6),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AdminColors.navSectionLabel,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final NavIconShape icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _NavItem({required this.icon, required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DashboardState>();
    final bg = active ? state.accentColor : Colors.transparent;
    final color = active ? Colors.white : AdminColors.navInactiveText;
    return Padding(
      padding: const EdgeInsets.only(bottom: 1),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                NavIcon(icon, color: color),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
