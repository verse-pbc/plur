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
      emoji: '👨‍👩‍👧‍👦',  // Using family emoji for age verification
      title: localization.ageVerificationQuestion,
      titleKey: const Key('age_verification_title'),
      description: localization.ageVerificationMessage,
      buttons: [
        OnboardingStepButton(
          text: localization.no,
          onTap: onDenied,
        ),
        OnboardingStepButton(
          text: localization.yes,
          onTap: onVerified,
        ),
      ],
    );
  }
}
