import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/analytics_view.dart';
import 'screens/billing_view.dart';
import 'screens/clubs_view.dart';
import 'screens/dashboard_view.dart';
import 'screens/members_view.dart';
import 'screens/sms_view.dart';
import 'state/dashboard_state.dart';
import 'theme.dart';
import 'widgets/new_club_wizard.dart';
import 'widgets/record_payment_modal.dart';
import 'widgets/sidebar.dart';
import 'widgets/stats_modal.dart';
import 'widgets/toast_overlay.dart';
import 'widgets/topbar.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => DashboardState(),
      child: const AdminApp(),
    ),
  );
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    final accent = context.watch<DashboardState>().accentColor;
    return MaterialApp(
      title: 'Rotary Admin',
      debugShowCheckedModeBanner: false,
      theme: buildAdminTheme(accent),
      home: const AdminShell(),
    );
  }
}

class AdminShell extends StatelessWidget {
  const AdminShell({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DashboardState>();
    return Scaffold(
      body: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AdminSidebar(),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const AdminTopbar(),
                    Expanded(
                      child: Scrollbar(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(32, 24, 32, 40),
                          child: _CurrentView(view: state.view),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (state.newClubOpen) const NewClubWizard(),
          if (state.paymentModalClubId != null) const RecordPaymentModal(),
          if (state.statsModalClubId != null) const StatsModal(),
          const ToastOverlay(),
        ],
      ),
    );
  }
}

class _CurrentView extends StatelessWidget {
  final String view;
  const _CurrentView({required this.view});

  @override
  Widget build(BuildContext context) {
    switch (view) {
      case 'clubs':
        return const ClubsView();
      case 'members':
        return const MembersView();
      case 'billing':
        return const BillingView();
      case 'analytics':
        return const AnalyticsView();
      case 'sms':
        return const SmsView();
      default:
        return const DashboardView();
    }
  }
}
