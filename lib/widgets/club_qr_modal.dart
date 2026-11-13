import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../state/dashboard_state.dart';
import '../theme.dart';
import 'modal_scrim.dart';

/// The QR code a club prints and displays at their venue: a link to the
/// backend's guest check-in web form, so a guest scanning it with their
/// phone's own camera (no app) lands on a form. The mobile app's scanner
/// recognises the same link — see RotaryConnect's scan_screen.dart
/// `decodeClubQr`, which also still accepts the older
/// {"t":"rc_club","id":N} codes already printed.
///
/// It points at the public check-in domain rather than the API host: that
/// domain serves only the /visit/ form, so it is a clean address to print.
const String guestCheckinBaseUrl = 'https://checkin.digiflecttech.dev';
String clubQrPayload(int clubId) => '$guestCheckinBaseUrl/visit/$clubId';

class ClubQrModal extends StatelessWidget {
  const ClubQrModal({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DashboardState>();
    final id = state.qrModalClubId;
    if (id == null) return const SizedBox.shrink();
    final matches = state.clubs.where((c) => c.id == id);
    if (matches.isEmpty) return const SizedBox.shrink();
    final club = matches.first;

    return ModalScrim(
      onDismiss: state.closeQrModal,
      child: Container(
        width: 380,
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.92,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AdminColors.modalShadow,
              blurRadius: 64,
              offset: const Offset(0, 24),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AdminColors.borderLight),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Check-in QR code',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          club.name,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AdminColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: state.closeQrModal,
                    child: const Icon(
                      Icons.close,
                      size: 19,
                      color: AdminColors.closeIcon,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AdminColors.borderLight),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: QrImageView(
                      data: clubQrPayload(club.id),
                      version: QrVersions.auto,
                      size: 220,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Print this and display it at the venue. Anyone with the '
                    'Rotary Connect app can scan it to check in as a visitor — '
                    'no account needed, and returning visitors won\'t be asked '
                    'for their details again.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AdminColors.textMuted,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
