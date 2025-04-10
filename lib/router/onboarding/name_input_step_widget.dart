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

    return OnboardingStepWidget(
      emoji: "📛",
      title: localization.onboarding_name_input_title,
      titleKey: const Key('name_input_title'),
      textController: _nameController,
      textFieldHint: localization.onboarding_name_input_hint,
      buttons: [
        OnboardingStepButton(
          text: localization.Continue,
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
