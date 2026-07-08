import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../state/dashboard_state.dart';
import '../theme.dart';
import 'modal_scrim.dart';
import 'progress_bar.dart';

class StatsModal extends StatelessWidget {
  const StatsModal({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DashboardState>();
    final club = state.statsModalClub;
    if (club == null) return const SizedBox.shrink();
    final style = paymentStyleFor(club.paymentStatus);
    final attendance = state.statsAttendanceFor(club);

    return ModalScrim(
      onDismiss: state.closeStatsModal,
      child: Container(
        width: 420,
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.92),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: AdminColors.modalShadow, blurRadius: 64, offset: const Offset(0, 24))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 40),
              color: style.tint,
              child: Stack(
                children: [
                  Positioned(
                    top: -4,
                    right: -4,
                    child: GestureDetector(
                      onTap: state.closeStatsModal,
                      child: const Icon(Icons.close, size: 19, color: AdminColors.closeIcon),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 6, height: 6, decoration: BoxDecoration(color: style.dot, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text(style.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: style.color)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
              child: Transform.translate(
                offset: const Offset(0, -32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AdminColors.statsPlaceholderBg,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [BoxShadow(color: AdminColors.modalShadow2, blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      alignment: Alignment.center,
                      child: const Text('Logo', style: TextStyle(fontSize: 10.5, color: AdminColors.statsPlaceholderText)),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      club.name,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.17),
                    ),
                    const SizedBox(height: 2),
                    Text(club.location, style: const TextStyle(fontSize: 12.5, color: AdminColors.textMuted)),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Attendance', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AdminColors.textMuted)),
                        Text('$attendance%', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ProgressBar(percent: attendance.toDouble(), color: state.accentColor),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(child: _StatCell('Members', '${club.members}')),
                        const SizedBox(width: 10),
                        Expanded(child: _StatCell('Monthly Fee', '${formatUgx(club.feeAmount)}/mo')),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _StatCell('Next Due', club.nextDueDate)),
                        const SizedBox(width: 10),
                        Expanded(child: _StatCell('Joined', club.joined)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  const _StatCell(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(color: AdminColors.pageBg, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AdminColors.textMuted, letterSpacing: 0.3),
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
