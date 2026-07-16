import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../state/dashboard_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/gap_row.dart';

/// Everything an admin needs to see when "the app isn't working" for a
/// member: failed PIN attempts and lockouts (with the member and club
/// named when the identifier matched someone), self-service PIN resets,
/// slow/5xx API requests, and the live API latency — next to the backend
/// exception log that already existed on Analytics.
class HealthView extends StatelessWidget {
  const HealthView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DashboardState>();
    final monitoring = state.monitoring;
    if (state.monitoringLoading && monitoring == null) {
      return const Padding(
        padding: EdgeInsets.all(60),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GapRow(
          gap: 14,
          children: [
            _ApiStatusCard(latencyMs: state.healthLatencyMs),
            StatCard(
              label: 'Member Issues Today',
              value: '${monitoring?.eventsToday ?? 0}',
              valueColor: (monitoring?.eventsToday ?? 0) > 0
                  ? AdminColors.dueSoonColor
                  : null,
            ),
            StatCard(
              label: 'Slow Requests Today',
              value: '${monitoring?.slowToday ?? 0}',
              valueColor: (monitoring?.slowToday ?? 0) > 0
                  ? AdminColors.dueSoonColor
                  : null,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _MemberIssuesCard(events: monitoring?.memberEvents ?? const []),
        const SizedBox(height: 16),
        _SlowRequestsCard(requests: monitoring?.slowRequests ?? const []),
        const SizedBox(height: 16),
        _BackendErrorsCard(errors: state.errorLogs),
      ],
    );
  }
}

class _ApiStatusCard extends StatelessWidget {
  final int? latencyMs;
  const _ApiStatusCard({required this.latencyMs});

  @override
  Widget build(BuildContext context) {
    final String value;
    final Color color;
    if (latencyMs == null) {
      value = 'Checking…';
      color = AdminColors.textMuted;
    } else if (latencyMs == -1) {
      value = 'DOWN';
      color = AdminColors.overdueColor;
    } else if (latencyMs! >= 1500) {
      value = 'Slow · ${latencyMs}ms';
      color = AdminColors.dueSoonColor;
    } else {
      value = 'Up · ${latencyMs}ms';
      color = AdminColors.paidColor;
    }
    return StatCard(label: 'API Status (live)', value: value, valueColor: color);
  }
}

const Map<String, String> _kindLabels = {
  'login_failed': 'Failed sign-in',
  'login_locked_out': 'Account locked',
  'pin_reset_requested': 'PIN reset',
};

Color _kindColor(String kind) {
  switch (kind) {
    case 'login_locked_out':
      return AdminColors.overdueColor;
    case 'pin_reset_requested':
      return AdminColors.clubInitialsText;
    default:
      return AdminColors.dueSoonColor;
  }
}

class _MemberIssuesCard extends StatelessWidget {
  final List<MemberEventEntry> events;
  const _MemberIssuesCard({required this.events});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: cardDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _CardHeader(
            title: 'Member Issues',
            subtitle:
                'Failed PIN attempts, lockouts, and PIN resets from the last 30 days — most recent first.',
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 9),
            child: Row(
              children: [
                Expanded(flex: 3, child: TableHeaderCell('Member')),
                Expanded(flex: 3, child: TableHeaderCell('Club')),
                Expanded(flex: 2, child: TableHeaderCell('Issue')),
                Expanded(flex: 4, child: TableHeaderCell('Detail')),
                Expanded(flex: 2, child: TableHeaderCell('When', align: TextAlign.right)),
              ],
            ),
          ),
          if (events.isEmpty)
            const Padding(
              padding: EdgeInsets.all(28),
              child: Center(
                child: Text('No member issues recorded — all quiet.',
                    style: TextStyle(fontSize: 12.5, color: AdminColors.textMuted)),
              ),
            )
          else
            for (final e in events) _EventRow(e),
        ],
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  final MemberEventEntry event;
  const _EventRow(this.event);

  @override
  Widget build(BuildContext context) {
    final kindColor = _kindColor(event.kind);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AdminColors.rowBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              event.memberName ?? 'Unknown (${event.identifier})',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontStyle: event.memberName == null ? FontStyle.italic : FontStyle.normal,
                color: event.memberName == null ? AdminColors.textMuted : AdminColors.textBase,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(event.clubName ?? '—',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: AdminColors.textMuted)),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: kindColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _kindLabels[event.kind] ?? event.kind,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kindColor),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(event.detail,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: AdminColors.textMuted)),
          ),
          Expanded(
            flex: 2,
            child: Text(relativeTime(event.createdAt),
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 11.5, color: AdminColors.textMuted)),
          ),
        ],
      ),
    );
  }
}

class _SlowRequestsCard extends StatelessWidget {
  final List<SlowRequestEntry> requests;
  const _SlowRequestsCard({required this.requests});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: cardDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _CardHeader(
            title: 'Slow & Failing API Requests',
            subtitle:
                'Requests that took over 1.5 seconds or returned a server error, last 30 days.',
          ),
          if (requests.isEmpty)
            const Padding(
              padding: EdgeInsets.all(28),
              child: Center(
                child: Text('No slow or failing requests recorded — the API has been fast.',
                    style: TextStyle(fontSize: 12.5, color: AdminColors.textMuted)),
              ),
            )
          else
            for (final r in requests)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AdminColors.rowBorder)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('${r.method} ${r.path}',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 12),
                    Text('${r.durationMs}ms',
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: r.durationMs >= 1500
                                ? AdminColors.dueSoonColor
                                : AdminColors.textMuted)),
                    const SizedBox(width: 12),
                    Text('${r.statusCode}',
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: r.statusCode >= 500
                                ? AdminColors.overdueColor
                                : AdminColors.paidColor)),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 70,
                      child: Text(relativeTime(r.createdAt),
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 11.5, color: AdminColors.textMuted)),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _BackendErrorsCard extends StatelessWidget {
  final List<ErrorLogEntry> errors;
  const _BackendErrorsCard({required this.errors});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: cardDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _CardHeader(
            title: 'Backend Exceptions',
            subtitle: 'Unhandled API errors from the last 30 days.',
          ),
          if (errors.isEmpty)
            const Padding(
              padding: EdgeInsets.all(28),
              child: Center(
                child: Text('No errors recorded.',
                    style: TextStyle(fontSize: 12.5, color: AdminColors.textMuted)),
              ),
            )
          else
            for (final e in errors.take(15))
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AdminColors.rowBorder)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${e.method} ${e.path}',
                              style:
                                  const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                          Text('${e.exceptionType}: ${e.message}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 11.5, color: AdminColors.textMuted)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(relativeTime(e.createdAt),
                        style: const TextStyle(fontSize: 11, color: AdminColors.textMuted)),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _CardHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(subtitle, style: const TextStyle(fontSize: 11.5, color: AdminColors.textMuted)),
        ],
      ),
    );
  }
}

String relativeTime(DateTime time) {
  final diff = DateTime.now().toUtc().difference(time.toUtc());
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}
