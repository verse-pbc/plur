import 'package:flutter/material.dart';
import '../../generated/l10n.dart';
import '../../theme/app_colors.dart';

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
              // User emoji without background container
              const Text(
                '👤',
                style: TextStyle(fontSize: 72),
              ),
              
              const SizedBox(height: 32),
              
              // Title
              Text(
                localization.onboardingNameInputTitle,
                key: const Key('name_input_title'),
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
                localization.onboardingNameInputHint,
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
              
              // Input field
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: buttonMaxWidth),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF2E4052),
                        width: 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: TextField(
                        controller: _nameController,
                        autofocus: true,
                        style: const TextStyle(
                          fontFamily: 'SF Pro Rounded',
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFF11171F),
                          hintText: localization.onboardingNameInputHint,
                          hintStyle: TextStyle(
                            fontFamily: 'SF Pro Rounded',
                            color: colors.secondaryText,
                            fontSize: 16,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 48),
              
              // Continue button
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: buttonMaxWidth),
                  child: SizedBox(
                    width: double.infinity,
                    child: GestureDetector(
                      onTap: _isButtonEnabled ? () {
                        final name = _nameController.text.trim();
                        if (name.isNotEmpty) {
                          widget.onContinue(name);
                        }
                      } : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          color: _isButtonEnabled 
                            ? accentColor
                            : accentColor.withAlpha((255 * 0.4).round()),
                          borderRadius: BorderRadius.circular(32),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          localization.continueButton,
                          style: TextStyle(
                            fontFamily: 'SF Pro Rounded',
                            color: _isButtonEnabled
                              ? buttonTextColor
                              : buttonTextColor.withAlpha((255 * 0.4).round()),
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
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
