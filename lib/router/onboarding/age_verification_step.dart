import 'package:flutter/material.dart';
import '../../generated/l10n.dart';
import '../../theme/app_colors.dart';

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
    final colors = context.colors;
    final accentColor = colors.accent;
    final primaryTextColor = colors.primaryText;
    final buttonTextColor = colors.buttonText;
    
    // Get screen width for responsive design
    var screenWidth = MediaQuery.of(context).size.width;
    bool isTablet = screenWidth >= 600;
    bool isDesktop = screenWidth >= 900;
    double mainWidth = isDesktop ? 600 : (isTablet ? 600 : double.infinity);
    double buttonMaxWidth = isDesktop ? 400 : (isTablet ? 500 : double.infinity);

    return Center(
      child: SizedBox(
        width: mainWidth,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Group emoji without background container
              const Text(
                '👨‍👩‍👧‍👦',
                style: TextStyle(fontSize: 72),
              ),
              
              const SizedBox(height: 32),
              
              // Title
              Text(
                localization.ageVerificationQuestion,
                key: const Key('age_verification_title'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'SF Pro Rounded',
                  color: primaryTextColor,
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Description
              Text(
                localization.ageVerificationMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'SF Pro Rounded',
                  color: colors.secondaryText,
                  fontSize: 17,
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                ),
              ),
              
              const SizedBox(height: 48),
              
              // Buttons
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: buttonMaxWidth),
                  child: Column(
                    children: [
                      // Yes button - filled with accent color
                      SizedBox(
                        width: double.infinity,
                        child: GestureDetector(
                          onTap: onVerified,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            decoration: BoxDecoration(
                              color: accentColor,
                              borderRadius: BorderRadius.circular(32),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              localization.yes,
                              style: TextStyle(
                                fontFamily: 'SF Pro Rounded',
                                color: buttonTextColor,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // No button - outlined
                      SizedBox(
                        width: double.infinity,
                        child: GestureDetector(
                          onTap: onDenied,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              border: Border.all(
                                color: colors.secondaryText.withAlpha((255 * 0.3).round()),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(32),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              localization.no,
                              style: TextStyle(
                                fontFamily: 'SF Pro Rounded',
                                color: primaryTextColor,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
