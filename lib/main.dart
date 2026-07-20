import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'screens/admin_login_screen.dart';
import 'screens/analytics_view.dart';
import 'screens/billing_view.dart';
import 'screens/clubs_view.dart';
import 'screens/dashboard_view.dart';
import 'screens/health_view.dart';
import 'screens/members_view.dart';
import 'screens/sms_view.dart';
import 'state/dashboard_state.dart';
import 'theme.dart';
import 'widgets/add_member_modal.dart';
import 'widgets/club_qr_modal.dart';
import 'widgets/delete_club_modal.dart';
import 'widgets/delete_member_modal.dart';
import 'widgets/member_credentials_modal.dart';
import 'widgets/new_club_wizard.dart';
import 'widgets/president_credentials_modal.dart';
import 'widgets/record_payment_modal.dart';
import 'widgets/sidebar.dart';
import 'widgets/stats_modal.dart';
import 'widgets/toast_overlay.dart';
import 'widgets/topbar.dart';

// Unset by default — no-op until a real DSN is passed at build time
// (`flutter build web ... --dart-define=SENTRY_DSN=...`), same convention
// the backend and member app use for optional third-party services.
const _sentryDsn = String.fromEnvironment('SENTRY_DSN');

void _reportError(Object error, StackTrace? stack) {
  debugPrint('Uncaught error: $error');
  if (_sentryDsn.isNotEmpty) {
    Sentry.captureException(error, stackTrace: stack);
  }
}

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    // Previously the only safety net was Flutter's default error screen —
    // an uncaught error (a bad API response shape, a null club, ...) had
    // no logging and no visibility at all.
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      _reportError(details.exception, details.stack);
    };
    if (_sentryDsn.isNotEmpty) {
      await Sentry.init((options) => options.dsn = _sentryDsn);
    }
    runApp(
      ChangeNotifierProvider(
        create: (_) => DashboardState(),
        child: const AdminApp(),
      ),
    );
  }, _reportError);
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
      home: context.watch<DashboardState>().isLoggedIn
          ? const AdminShell()
          : const AdminLoginScreen(),
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
                      child: state.dataLoading && state.clubs.isEmpty
                          ? const Center(child: CircularProgressIndicator())
                          : state.dataError != null && state.clubs.isEmpty
                              ? _LoadErrorView(message: state.dataError!)
                              : Scrollbar(
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
          if (state.presidentCredentials != null) const PresidentCredentialsModal(),
          if (state.addMemberModalClubId != null) const AddMemberModal(),
          if (state.newMemberCredentials != null) const MemberCredentialsModal(),
          if (state.confirmDeleteClubId != null) const DeleteClubModal(),
          if (state.confirmDeleteMemberId != null) const DeleteMemberModal(),
          if (state.qrModalClubId != null) const ClubQrModal(),
          const ToastOverlay(),
        ],
      ),
    );
  }
}

class _LoadErrorView extends StatelessWidget {
  final String message;
  const _LoadErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    final state = context.read<DashboardState>();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 36, color: AdminColors.textMuted),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13.5, color: AdminColors.overdueColor),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  onPressed: state.refresh,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminColors.accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                  ),
                ),
                const SizedBox(width: 10),
                TextButton(
                  onPressed: state.logout,
                  child: const Text('Sign out'),
                ),
              ],
            ),
          ],
        ),
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
      case 'health':
        return const HealthView();
      default:
        return const DashboardView();
    }
  }
}
