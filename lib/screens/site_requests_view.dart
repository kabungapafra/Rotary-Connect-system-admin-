import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../state/dashboard_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Clubs that asked to join through the public marketing site's form.
///
/// Read-only apart from triage: approving here does not create the club.
/// The admin still runs the new-club wizard, because these submissions are
/// unverified — see the JoinRequest model.
const Map<String, StatusStyle> joinStatusStyles = {
  'new': StatusStyle(
    'New',
    AdminColors.dueSoonDot,
    AdminColors.dueSoonColor,
    AdminColors.dueSoonTint,
  ),
  'contacted': StatusStyle(
    'Contacted',
    AdminColors.accent,
    AdminColors.accent,
    Color(0xFFE5EBF9),
  ),
  'approved': StatusStyle(
    'Approved',
    AdminColors.paidDot,
    AdminColors.paidColor,
    AdminColors.paidTint,
  ),
  'declined': StatusStyle(
    'Declined',
    AdminColors.overdueDot,
    AdminColors.overdueColor,
    AdminColors.overdueTint,
  ),
};

class SiteRequestsView extends StatelessWidget {
  const SiteRequestsView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DashboardState>();
    final rows = state.joinRequests;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _StatusFilter(
              value: state.joinRequestFilter,
              onChanged: state.setJoinRequestFilter,
            ),
            const Spacer(),
            Text(
              '${rows.length} request${rows.length == 1 ? '' : 's'}',
              style: const TextStyle(
                fontSize: 12.5,
                color: AdminColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Submitted from the website. Approving here does not create the '
          'club — use the New Club wizard once the details check out.',
          style: TextStyle(fontSize: 12.5, color: AdminColors.textMuted),
        ),
        const SizedBox(height: 14),
        if (state.joinRequestsLoading && rows.isEmpty)
          const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (rows.isEmpty)
          Container(
            decoration: cardDecoration(),
            padding: const EdgeInsets.all(40),
            child: const Center(
              child: Text(
                'No join requests yet.',
                style: TextStyle(fontSize: 13.5, color: AdminColors.textMuted),
              ),
            ),
          )
        else
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _RequestCard(request: r, state: state),
            ),
      ],
    );
  }
}

class _StatusFilter extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _StatusFilter({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AdminColors.inputBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          style: const TextStyle(fontSize: 13, color: AdminColors.textBase),
          items: const [
            DropdownMenuItem(value: 'all', child: Text('All statuses')),
            DropdownMenuItem(value: 'new', child: Text('New')),
            DropdownMenuItem(value: 'contacted', child: Text('Contacted')),
            DropdownMenuItem(value: 'approved', child: Text('Approved')),
            DropdownMenuItem(value: 'declined', child: Text('Declined')),
          ],
          onChanged: (v) => onChanged(v ?? 'all'),
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final JoinRequest request;
  final DashboardState state;
  const _RequestCard({required this.request, required this.state});

  @override
  Widget build(BuildContext context) {
    final style = joinStatusStyles[request.status] ?? joinStatusStyles['new']!;
    return Container(
      decoration: cardDecoration(),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Logo(logo: request.logo, name: request.clubName),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            request.clubName,
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: AdminColors.textBase,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _Pill(
                          text: request.clubType == 'rotaract'
                              ? 'Rotaract'
                              : 'Rotary',
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      [
                        if (request.district.isNotEmpty)
                          'District ${request.district}',
                        if (request.location.isNotEmpty) request.location,
                        '${request.membersCount} members',
                      ].join(' · '),
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AdminColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: style.tint,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  style.label,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: style.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 28,
            runSpacing: 10,
            children: [
              _Detail(label: 'Contact', value: request.contactName),
              _Detail(
                label: 'Role',
                value: request.contactRole.isEmpty ? '—' : request.contactRole,
              ),
              _Detail(label: 'Phone', value: request.phone),
              _Detail(
                label: 'Email',
                value: request.email.isEmpty ? '—' : request.email,
              ),
              if (request.charterDate != null)
                _Detail(label: 'Chartered', value: request.charterDate!),
              if (request.heardAbout.isNotEmpty)
                _Detail(label: 'Heard via', value: request.heardAbout),
            ],
          ),
          if (request.problems.isNotEmpty) ...[
            const SizedBox(height: 12),
            _Detail(label: 'Wants to solve', value: request.problems),
          ],
          if (request.notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            _Detail(label: 'Notes', value: request.notes),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Submitted ${_shortDate(request.createdAt)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AdminColors.textMuted,
                ),
              ),
              const Spacer(),
              for (final next in const ['contacted', 'approved', 'declined'])
                if (request.status != next)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _SmallButton(
                      label: 'Mark ${joinStatusStyles[next]!.label}',
                      onTap: () =>
                          state.setJoinRequestStatus(request.id, next),
                    ),
                  ),
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: _SmallButton(
                  label: 'Delete',
                  danger: true,
                  onTap: () => state.deleteJoinRequest(request.id),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The submitted logo arrives as a data URL (the site resizes it to 512px
/// before sending), so it renders straight from memory with no upload yet —
/// nothing is stored in R2 until the club is actually created.
class _Logo extends StatelessWidget {
  final String? logo;
  final String name;
  const _Logo({required this.logo, required this.name});

  @override
  Widget build(BuildContext context) {
    if (logo == null || !logo!.contains(',')) {
      final initials = name.isEmpty ? '?' : name.trim()[0].toUpperCase();
      return Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AdminColors.clubInitialsBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          initials,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: AdminColors.clubInitialsText,
          ),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.memory(
        base64Decode(logo!.split(',').last),
        width: 44,
        height: 44,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => const SizedBox(width: 44, height: 44),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  final String label;
  final String value;
  const _Detail({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: AdminColors.navSectionLabel,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 13, color: AdminColors.textBase),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  const _Pill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AdminColors.clubInitialsBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AdminColors.clubInitialsText,
        ),
      ),
    );
  }
}

class _SmallButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool danger;
  const _SmallButton({
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: danger
                ? AdminColors.overdueDot.withValues(alpha: 0.4)
                : AdminColors.buttonBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: danger ? AdminColors.overdueColor : AdminColors.buttonText,
          ),
        ),
      ),
    );
  }
}

/// Trims the API's ISO timestamp to the date — the exact minute a request
/// arrived has never mattered for triage.
String _shortDate(String isoTimestamp) {
  if (isoTimestamp.length < 10) return isoTimestamp;
  return isoTimestamp.substring(0, 10);
}
