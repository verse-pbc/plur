import 'package:flutter/material.dart';
import '../../generated/l10n.dart';
import 'onboarding_step_widget.dart';

/// Handles age verification during the onboarding process.
///
class AgeVerificationStep extends StatelessWidget {
  final VoidCallback onVerified;
  final VoidCallback onDenied;

  const AgeVerificationStep({
    super.key,
    required this.onVerified,
    required this.onDenied,
  });

  @override
  Widget build(BuildContext context) {
    S localization = S.of(context);

    return OnboardingStepWidget(
      emoji: '🪪',
      title: localization.Age_verification_question,
      titleKey: const Key('age_verification_title'),
      description: localization.Age_verification_message,
      buttons: [
        OnboardingStepButton(
          text: localization.No,
          onTap: onDenied,
        ),
        OnboardingStepButton(
          text: localization.Yes,
          onTap: onVerified,
        ),
      ],
    );
  }
}
