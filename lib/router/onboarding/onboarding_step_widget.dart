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
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(viewInsets: EdgeInsets.zero),
      child: Container(
        color: PlurColors.appBackground,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card container for the content
            Container(
              decoration: BoxDecoration(
                color: PlurColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Emoji
                  Text(
                    emoji,
                    textAlign: TextAlign.start,
                    style: const TextStyle(
                      fontSize: 64,
                      height: 1.2,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Title
                  Text(
                    title,
                    key: titleKey,
                    textAlign: TextAlign.start,
                    style: GoogleFonts.nunito(
                      textStyle: const TextStyle(
                        color: PlurColors.highlightText,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Description or input field
                  description != null
                      ? Text(
                          description!,
                          textAlign: TextAlign.start,
                          style: GoogleFonts.nunito(
                            textStyle: const TextStyle(
                              color: PlurColors.primaryText,
                              fontSize: 17,
                              height: 1.4,
                            ),
                          ),
                        )
                      : InputFieldWidget(
                          controller: textController!,
                          hintText: textFieldHint,
                        ),
                ],
              ),
            ),

            const Spacer(),

            // Buttons
            Row(
              children: List.generate(
                buttons.length,
                (index) => [
                  if (index > 0) const SizedBox(width: 16),
                  Expanded(
                    child: PrimaryButtonWidget(
                      text: buttons[index].text,
                      borderRadius: 12,
                      height: 48,
                      onTap: buttons[index].onTap,
                      enabled: buttons[index].enabled,
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
