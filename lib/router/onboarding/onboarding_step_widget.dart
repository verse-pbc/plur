import 'package:flutter/material.dart';
import '../../component/primary_button_widget.dart';
import '../../util/theme_util.dart';

/// Represents a button in the onboarding step.
/// It is used to create a button in the onboarding step.
///
class OnboardingStepButton {
  final String text;
  final VoidCallback onTap;

  OnboardingStepButton({
    required this.text,
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
  final String description;
  final List<OnboardingStepButton> buttons;

  const OnboardingStepWidget({
    super.key,
    required this.emoji,
    required this.title,
    this.titleKey,
    required this.description,
    required this.buttons,
  });

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final primaryForegroundColor =
        themeData.customColors.primaryForegroundColor;

    return Padding(
      padding: const EdgeInsets.all(62),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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

          const SizedBox(height: 32),

          Text(
            title,
            key: titleKey,
            textAlign: TextAlign.start,
            style: TextStyle(
              color: primaryForegroundColor,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),

          const SizedBox(height: 52),

          Text(
            description,
            textAlign: TextAlign.start,
            style: TextStyle(
              color: themeData.customColors.secondaryForegroundColor,
              fontSize: 17,
              height: 1.4,
            ),
          ),

          const Spacer(),

          Row(
            children: List.generate(
              buttons.length,
              (index) => [
                if (index > 0) const SizedBox(width: 22),
                Expanded(
                  child: PrimaryButtonWidget(
                    text: buttons[index].text,
                    borderRadius: 4,
                    onTap: buttons[index].onTap,
                  ),
                ),
              ],
            ).expand((widgets) => widgets).toList(),
          )
        ],
      ),
    );
  }
}
