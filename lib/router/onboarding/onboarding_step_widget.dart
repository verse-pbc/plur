import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../component/primary_button_widget.dart';
import '../../component/input_field_widget.dart';
import '../../consts/plur_colors.dart';

/// Represents a button in the onboarding step.
/// It is used to create a button in the onboarding step.
///
class OnboardingStepButton {
  final String text;
  final bool enabled;
  final VoidCallback onTap;

  OnboardingStepButton({
    required this.text,
    this.enabled = true,
    required this.onTap,
  });
}

/// Represents a single step in the onboarding process.
/// It is a template used to create a step in the onboarding process, for consistency.
///
class OnboardingStepWidget extends StatelessWidget {
  final String emoji;
  final String title;
  final Key? titleKey;
  final String? description;
  final TextEditingController? textController;
  final String? textFieldHint;
  final List<OnboardingStepButton> buttons;

  const OnboardingStepWidget({
    super.key,
    required this.emoji,
    required this.title,
    this.titleKey,
    this.description,
    this.textController,
    this.textFieldHint,
    required this.buttons,
  }) : assert(
          (description != null && textController == null) ||
              (description == null && textController != null),
          'Either description or textController must be provided, but not both',
        );

  @override
  Widget build(BuildContext context) {
    // Get the current theme mode to adapt colors
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Define theme-adaptive colors
    final cardBgColor = isDarkMode ? PlurColors.cardBackground : Colors.white;
    final titleColor = isDarkMode ? PlurColors.highlightText : PlurColors.primaryPurple;
    final descriptionColor = isDarkMode 
        ? PlurColors.highlightText // Higher contrast in dark mode
        : PlurColors.primaryDark;
    final emojiContainerColor = PlurColors.primaryPurple.withAlpha(isDarkMode ? 38 : 26);
    final shadowColor = isDarkMode 
        ? Colors.black.withAlpha(60) 
        : Colors.black.withAlpha(28);
    
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(viewInsets: EdgeInsets.zero),
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card container for the content
            Container(
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: shadowColor,
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Emoji container with improved styling
                  Container(
                    decoration: BoxDecoration(
                      color: emojiContainerColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      emoji,
                      textAlign: TextAlign.start,
                      style: const TextStyle(
                        fontSize: 48,
                        height: 1.0,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Title with improved contrast
                  Text(
                    title,
                    key: titleKey,
                    textAlign: TextAlign.start,
                    style: GoogleFonts.nunito(
                      textStyle: TextStyle(
                        color: titleColor,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Description or input field with improved contrast
                  description != null
                      ? Text(
                          description!,
                          textAlign: TextAlign.start,
                          style: GoogleFonts.nunito(
                            textStyle: TextStyle(
                              color: descriptionColor,
                              fontSize: 17,
                              fontWeight: FontWeight.w500, // Slightly bolder for better contrast
                              height: 1.4,
                              letterSpacing: 0.2,
                            ),
                          ),
                        )
                      : InputFieldWidget(
                          controller: textController!,
                          hintText: textFieldHint,
                          isDarkMode: isDarkMode,
                        ),
                ],
              ),
            ),

            const Spacer(),

            // Buttons with enhanced styling
            Row(
              children: List.generate(
                buttons.length,
                (index) => [
                  if (index > 0) const SizedBox(width: 16),
                  Expanded(
                    child: AnimatedOpacity(
                      opacity: buttons[index].enabled ? 1.0 : 0.6,
                      duration: const Duration(milliseconds: 200),
                      child: PrimaryButtonWidget(
                        text: buttons[index].text,
                        borderRadius: 14,
                        height: 52,
                        onTap: buttons[index].onTap,
                        enabled: buttons[index].enabled,
                      ),
                    ),
                  ),
                ],
              ).expand((widgets) => widgets).toList(),
            )
          ],
        ),
      ),
    );
  }
}
