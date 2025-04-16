import 'package:flutter/material.dart';
import 'onboarding_step_widget.dart';
import '../../generated/l10n.dart';

/// Handles name/nickname collection in the onboarding process.
class NameInputStepWidget extends StatefulWidget {
  final void Function(String name) onContinue;

  const NameInputStepWidget({
    super.key,
    required this.onContinue,
  });

  @override
  State<NameInputStepWidget> createState() => _NameInputStepWidgetState();
}

class _NameInputStepWidgetState extends State<NameInputStepWidget> {
  final TextEditingController _nameController = TextEditingController();
  bool _isButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_updateButtonState);
  }

  @override
  void dispose() {
    _nameController.removeListener(_updateButtonState);
    _nameController.dispose();
    super.dispose();
  }

  void _updateButtonState() {
    final newState = _nameController.text.trim().isNotEmpty;
    if (_isButtonEnabled != newState) {
      setState(() {
        _isButtonEnabled = newState;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = S.of(context);
    
    // Note: We're using a simple emoji instead of a custom IconWidget
    // to keep the implementation simpler and consistent with other steps

    return OnboardingStepWidget(
      // Use the custom icon widget instead of a simple emoji
      emoji: "👤", // Better emoji for user profile
      title: localization.onboardingNameInputTitle,
      titleKey: const Key('name_input_title'),
      textController: _nameController,
      textFieldHint: localization.onboardingNameInputHint,
      buttons: [
        OnboardingStepButton(
          text: localization.continueButton,
          enabled: _isButtonEnabled,
          onTap: () {
            final name = _nameController.text.trim();
            if (name.isNotEmpty) {
              widget.onContinue(name);
            }
          },
        ),
      ],
    );
  }
}
