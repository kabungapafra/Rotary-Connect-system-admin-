import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/dashboard_state.dart';
import '../theme.dart';
import 'labeled_field.dart';
import 'modal_scrim.dart';

class NewClubWizard extends StatelessWidget {
  const NewClubWizard({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DashboardState>();
    return ModalScrim(
      onDismiss: state.closeNewClub,
      child: Container(
        width: 500,
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
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 22, 26, 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Onboard New Club', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.17)),
                      SizedBox(height: 2),
                      Text('Add a Rotary club to the platform', style: TextStyle(fontSize: 12.5, color: AdminColors.textMuted)),
                    ],
                  ),
                  GestureDetector(
                    onTap: state.closeNewClub,
                    child: const Icon(Icons.close, size: 19, color: AdminColors.textMuted),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 0, 26, 20),
              child: _StepIndicator(state: state),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(26, 20, 26, 26),
              constraints: const BoxConstraints(minHeight: 220),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AdminColors.rowBorder)),
              ),
              child: _StepContent(state: state),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
              decoration: const BoxDecoration(
                color: AdminColors.pageBg,
                border: Border(top: BorderSide(color: AdminColors.borderLight)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Opacity(
                    opacity: state.wizardStep == 0 ? 0.4 : 1,
                    child: OutlinedButton(
                      onPressed: state.wizardStep == 0 ? null : state.prevStep,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AdminColors.inputBorder),
                        backgroundColor: Colors.white,
                        foregroundColor: AdminColors.textBase,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      child: const Text('Back'),
                    ),
                  ),
                  if (state.wizardStep == 2)
                    ElevatedButton(
                      onPressed: state.createClub,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: state.accentColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 9),
                        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      child: const Text('Create Club'),
                    )
                  else
                    Opacity(
                      opacity: state.nextDisabled ? 0.5 : 1,
                      child: ElevatedButton(
                        onPressed: state.nextDisabled ? null : state.nextStep,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: state.accentColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 9),
                          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                        child: const Text('Next'),
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

class _StepIndicator extends StatelessWidget {
  final DashboardState state;
  const _StepIndicator({required this.state});

  static const _labels = ['Details', 'Contact', 'Billing'];

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    for (var i = 0; i < _labels.length; i++) {
      if (i > 0) {
        final lineColor = i <= state.wizardStep ? state.accentColor : AdminColors.wizardInactiveBar;
        items.add(Expanded(
          child: SizedBox(height: 26, child: Center(child: Container(height: 2, color: lineColor))),
        ));
      }
      items.add(_StepDot(index: i, label: _labels[i], state: state));
    }
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: items);
  }
}

class _StepDot extends StatelessWidget {
  final int index;
  final String label;
  final DashboardState state;
  const _StepDot({required this.index, required this.label, required this.state});

  @override
  Widget build(BuildContext context) {
    final done = index < state.wizardStep;
    final active = index == state.wizardStep;
    final isFilled = done || active;
    final circleBg = isFilled ? state.accentColor : AdminColors.wizardInactiveBar;
    final circleColor = isFilled ? Colors.white : AdminColors.textMuted;
    final labelColor = isFilled ? AdminColors.wizardActiveLabel : AdminColors.wizardTodoLabel;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: circleBg,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          alignment: Alignment.center,
          child: Text(
            done ? '✓' : '${index + 1}',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: circleColor),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 64,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: labelColor),
          ),
        ),
      ],
    );
  }
}

class _StepContent extends StatelessWidget {
  final DashboardState state;
  const _StepContent({required this.state});

  @override
  Widget build(BuildContext context) {
    switch (state.wizardStep) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AdminColors.statsPlaceholderBg,
                    shape: BoxShape.circle,
                    border: Border.all(color: AdminColors.statsDashedBorder, style: BorderStyle.solid),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'Logo',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10.5, color: AdminColors.statsPlaceholderText),
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    "Drop the club's logo here.\n\nOptional, but shows across the admin.",
                    style: TextStyle(fontSize: 12, color: AdminColors.textMuted, height: 1.4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),
            LabeledField(
              label: 'Club Name',
              value: state.draft.name,
              placeholder: 'Rotary Club of ...',
              accentColor: state.accentColor,
              onChanged: state.setDraftName,
            ),
            const SizedBox(height: 13),
            LabeledField(
              label: 'District',
              value: state.draft.district,
              placeholder: 'e.g. D9213',
              accentColor: state.accentColor,
              onChanged: state.setDraftDistrict,
            ),
            const SizedBox(height: 13),
            LabeledField(
              label: 'Location',
              value: state.draft.location,
              placeholder: 'City, Country',
              accentColor: state.accentColor,
              onChanged: state.setDraftLocation,
            ),
          ],
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LabeledField(
              label: 'Club President Email',
              value: state.draft.email,
              placeholder: 'president@club.org',
              accentColor: state.accentColor,
              onChanged: state.setDraftEmail,
            ),
            const SizedBox(height: 13),
            LabeledField(
              label: 'Contact Phone',
              value: state.draft.phone,
              placeholder: '+256 700 000 000',
              accentColor: state.accentColor,
              onChanged: state.setDraftPhone,
            ),
            const SizedBox(height: 13),
            LabeledField(
              label: 'Estimated Members',
              value: state.draft.members,
              placeholder: 'e.g. 45',
              accentColor: state.accentColor,
              onChanged: state.setDraftMembers,
            ),
          ],
        );
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LabeledField(
              label: 'Monthly Fee (UGX)',
              value: state.draft.feeAmount,
              placeholder: 'e.g. 150000',
              accentColor: state.accentColor,
              onChanged: state.setDraftFeeAmount,
            ),
            const SizedBox(height: 13),
            LabeledField(
              label: 'First Payment Date',
              value: state.draft.firstPaymentDate,
              placeholder: 'e.g. 08 Jul 2026',
              accentColor: state.accentColor,
              onChanged: state.setDraftFirstPaymentDate,
            ),
            const SizedBox(height: 13),
            LabeledField(
              label: 'Next Payment Due',
              value: state.draft.nextDueDate,
              placeholder: 'e.g. 08 Aug 2026',
              accentColor: state.accentColor,
              onChanged: state.setDraftNextDueDate,
            ),
          ],
        );
    }
  }
}
