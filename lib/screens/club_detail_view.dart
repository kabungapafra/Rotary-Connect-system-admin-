import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api_client.dart';
import '../models.dart';
import '../state/dashboard_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/progress_bar.dart';
import '../widgets/status_badge.dart';
import 'health_view.dart' show relativeTime;

/// The club management screen: everything about one club in one place —
/// its usage (members, SMS, storage), what has been failing for it, and
/// every action that can be taken on it.
class ClubDetailView extends StatelessWidget {
  const ClubDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DashboardState>();
    final club = state.openClub;

    // The club can vanish underneath this screen — deleting it from here
    // is one of the actions on offer. Fall back to the list rather than
    // rendering a half-empty screen for something that no longer exists.
    if (club == null) {
      return const _MissingClub();
    }

    final overview = state.clubOverview;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(club: club, state: state),
        const SizedBox(height: 18),
        if (state.clubOverviewError != null)
          _ErrorBanner(
            message: state.clubOverviewError!,
            onRetry: state.refreshClubOverview,
          )
        else if (overview == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 60),
            child: Center(child: CircularProgressIndicator()),
          )
        else ...[
          _UsageGrid(overview: overview, accent: state.accentColor),
          const SizedBox(height: 18),
          _OfficersCard(overview: overview),
          const SizedBox(height: 18),
          _AttendanceCard(
            percent: overview.attendancePercent,
            accent: state.accentColor,
          ),
          const SizedBox(height: 18),
          _ActionsCard(club: club, state: state),
          const SizedBox(height: 18),
          _ErrorsCard(overview: overview),
        ],
      ],
    );
  }
}

class _MissingClub extends StatelessWidget {
  const _MissingClub();

  @override
  Widget build(BuildContext context) {
    final state = context.read<DashboardState>();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          const Icon(
            Icons.domain_disabled_outlined,
            size: 34,
            color: AdminColors.textMuted,
          ),
          const SizedBox(height: 12),
          const Text(
            'This club is no longer available.',
            style: TextStyle(fontSize: 13.5, color: AdminColors.textMuted),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: state.closeClubScreen,
            child: const Text('Back to clubs'),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final Club club;
  final DashboardState state;
  const _Header({required this.club, required this.state});

  @override
  Widget build(BuildContext context) {
    final paymentStyle = paymentStyleFor(club.paymentStatus);
    final activeStyle = clubStyleFor(club.effectiveStatus);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: state.closeClubScreen,
            borderRadius: BorderRadius.circular(6),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.arrow_back,
                    size: 15,
                    color: AdminColors.textMuted,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'All clubs',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AdminColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Logo(logo: club.logo, name: club.name),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      club.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      [
                        club.clubType == 'rotaract' ? 'Rotaract' : 'Rotary',
                        if (club.district.isNotEmpty && club.district != '—')
                          'District ${club.district}',
                        if (club.location.isNotEmpty && club.location != '—')
                          club.location,
                      ].join(' · '),
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AdminColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        StatusBadge(paymentStyle),
                        StatusBadge(activeStyle),
                        if (!club.smsEnabled) const StatusBadge(smsOffStyle),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _MetaLine('Joined', club.joined),
                  const SizedBox(height: 6),
                  _MetaLine('Next payment', club.nextDueDate),
                  const SizedBox(height: 6),
                  _MetaLine('Monthly fee', '${formatUgx(club.feeAmount)}/mo'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  final String? logo;
  final String name;
  const _Logo({required this.logo, required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: AdminColors.pageBg,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: logo == null
          ? Text(
              initialsFor(name),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            )
          : (logo!.startsWith('http')
                ? Image.network(
                    logo!,
                    fit: BoxFit.contain,
                    width: 58,
                    height: 58,
                  )
                : Image.memory(
                    base64Decode(logo!.split(',').last),
                    fit: BoxFit.contain,
                    width: 58,
                    height: 58,
                  )),
    );
  }
}

class _MetaLine extends StatelessWidget {
  final String label;
  final String value;
  const _MetaLine(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label  ',
          style: const TextStyle(fontSize: 11.5, color: AdminColors.textMuted),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _UsageGrid extends StatelessWidget {
  final ClubOverview overview;
  final Color accent;
  const _UsageGrid({required this.overview, required this.accent});

  @override
  Widget build(BuildContext context) {
    final u = overview.usage;
    final tiles = <Widget>[
      _UsageTile(
        label: 'Active members',
        value: '${u.membersActive}',
        detail: u.membersSuspended > 0
            ? '${u.membersTotal} total · ${u.membersSuspended} suspended'
            : '${u.membersTotal} total',
        icon: Icons.people_outline,
        accent: accent,
      ),
      _UsageTile(
        label: 'SMS sent',
        value: '${u.smsSent}',
        detail: u.smsFailed > 0 ? '${u.smsFailed} failed' : 'none failed',
        detailIsWarning: u.smsFailed > 0,
        icon: Icons.sms_outlined,
        accent: accent,
      ),
      _UsageTile(
        label: 'Storage used',
        value: formatBytes(u.storageBytes),
        detail: '${u.storagePhotos} photos · ${u.storageDocuments} documents',
        icon: Icons.cloud_outlined,
        accent: accent,
      ),
      _UsageTile(
        label: 'Errors',
        value: '${u.errorsTotal}',
        detail: u.errorsTotal == 0 ? 'none reported' : 'see below',
        detailIsWarning: u.errorsTotal > 0,
        icon: Icons.error_outline,
        accent: accent,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // Four across on a roomy window, two on a narrow one — the admin
        // dashboard is used on laptops as well as wide desktop monitors.
        final columns = constraints.maxWidth < 720 ? 2 : 4;
        const gap = 14.0;
        final tileWidth =
            (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final tile in tiles) SizedBox(width: tileWidth, child: tile),
          ],
        );
      },
    );
  }
}

class _UsageTile extends StatelessWidget {
  final String label;
  final String value;
  final String detail;
  final bool detailIsWarning;
  final IconData icon;
  final Color accent;

  const _UsageTile({
    required this.label,
    required this.value,
    required this.detail,
    required this.icon,
    required this.accent,
    this.detailIsWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: accent),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AdminColors.textMuted,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            detail,
            style: TextStyle(
              fontSize: 11.5,
              color: detailIsWarning
                  ? AdminColors.overdueColor
                  : AdminColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _OfficersCard extends StatelessWidget {
  final ClubOverview overview;
  const _OfficersCard({required this.overview});

  @override
  Widget build(BuildContext context) {
    final slots = <(String, ClubOfficer?)>[
      ('President', overview.president),
      ('President-Elect', overview.presidentElect),
      ('Secretary', overview.secretary),
    ];
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Club leadership',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              // Three across when there's room, stacked when there isn't.
              final columns = constraints.maxWidth < 720 ? 1 : 3;
              const gap = 12.0;
              final width =
                  (constraints.maxWidth - gap * (columns - 1)) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final (title, officer) in slots)
                    SizedBox(
                      width: width,
                      child: _OfficerCell(title: title, officer: officer),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _OfficerCell extends StatelessWidget {
  final String title;
  final ClubOfficer? officer;
  const _OfficerCell({required this.title, required this.officer});

  @override
  Widget build(BuildContext context) {
    final o = officer;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AdminColors.pageBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: AdminColors.textMuted,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          if (o == null)
            // An unfilled post is worth seeing: it means nobody in this club
            // can do what the role gates (a missing Secretary blocks minutes
            // and documents; a missing President-Elect blocks the rollover).
            const Text(
              'Not assigned',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AdminColors.overdueColor,
              ),
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    o.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (o.status != 'active') ...[
                  const SizedBox(width: 6),
                  Text(
                    o.status,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AdminColors.overdueColor,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 5),
            _OfficerLine(Icons.badge_outlined, o.memberNumber),
            if (o.phone.isNotEmpty) ...[
              const SizedBox(height: 3),
              _OfficerLine(Icons.phone_outlined, o.phone),
            ],
            if (o.email.isNotEmpty) ...[
              const SizedBox(height: 3),
              _OfficerLine(Icons.mail_outline, o.email),
            ],
          ],
        ],
      ),
    );
  }
}

class _OfficerLine extends StatelessWidget {
  final IconData icon;
  final String value;
  const _OfficerLine(this.icon, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: AdminColors.textMuted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: AdminColors.textMuted),
          ),
        ),
      ],
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  final int percent;
  final Color accent;
  const _AttendanceCard({required this.percent, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Attendance at the last meeting',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              Text(
                '$percent%',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ProgressBar(percent: percent.toDouble(), color: accent),
        ],
      ),
    );
  }
}

class _ActionsCard extends StatelessWidget {
  final Club club;
  final DashboardState state;
  const _ActionsCard({required this.club, required this.state});

  @override
  Widget build(BuildContext context) {
    final isActive = club.status == 'active';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Manage this club',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _ActionButton(
                label: 'Add Member',
                icon: Icons.person_add_outlined,
                onTap: () => state.openAddMemberModal(club.id),
              ),
              _ActionButton(
                label: 'Record Payment',
                icon: Icons.payments_outlined,
                onTap: () => state.openPaymentModal(club.id),
              ),
              _ActionButton(
                label: 'SMS Preferences',
                icon: Icons.tune,
                onTap: () => state.openSmsTypesModal(club.id),
              ),
              _ActionButton(
                label: 'Show QR Code',
                icon: Icons.qr_code_2,
                onTap: () => state.openQrModal(club.id),
              ),
              _ActionButton(
                label: club.smsEnabled ? 'Suspend SMS' : 'Activate SMS',
                icon: club.smsEnabled
                    ? Icons.sms_failed_outlined
                    : Icons.sms_outlined,
                color: club.smsEnabled
                    ? AdminColors.overdueColor
                    : AdminColors.paidColor,
                onTap: () => state.toggleClubSms(club.id),
              ),
              _ActionButton(
                label: isActive ? 'Suspend Club' : 'Activate Club',
                icon: isActive
                    ? Icons.pause_circle_outline
                    : Icons.play_circle_outline,
                color: isActive
                    ? AdminColors.overdueColor
                    : AdminColors.paidColor,
                onTap: () => state.toggleClubStatus(club.id),
              ),
              _ActionButton(
                label: 'Delete Club',
                icon: Icons.delete_outline,
                color: AdminColors.overdueColor,
                onTap: () => state.askDeleteClub(club.id),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tint = color ?? const Color(0xFF1F2328);
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 15, color: tint),
      label: Text(label, style: TextStyle(fontSize: 12.5, color: tint)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        side: const BorderSide(color: AdminColors.inputBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      ),
    );
  }
}

class _ErrorsCard extends StatelessWidget {
  final ClubOverview overview;
  const _ErrorsCard({required this.overview});

  @override
  Widget build(BuildContext context) {
    final errors = overview.recentErrors;
    return Container(
      decoration: cardDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Row(
              children: [
                const Text(
                  'Problems this club has hit',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                if (errors.isNotEmpty)
                  Text(
                    'Showing ${errors.length} of ${overview.usage.errorsTotal}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AdminColors.textMuted,
                    ),
                  ),
              ],
            ),
          ),
          if (errors.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 4, 18, 24),
              child: Text(
                'Nothing has failed for this club since error tracking began.',
                style: TextStyle(fontSize: 12.5, color: AdminColors.textMuted),
              ),
            )
          else
            for (final error in errors) _ErrorRow(error: error),
        ],
      ),
    );
  }
}

class _ErrorRow extends StatelessWidget {
  final ErrorLogEntry error;
  const _ErrorRow({required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
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
                Text(
                  '${error.method} ${error.path}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${error.exceptionType}: ${error.message}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AdminColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            relativeTime(error.createdAt),
            style: const TextStyle(
              fontSize: 11.5,
              color: AdminColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: cardDecoration(),
      child: Row(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 18,
            color: AdminColors.overdueColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12.5,
                color: AdminColors.overdueColor,
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
