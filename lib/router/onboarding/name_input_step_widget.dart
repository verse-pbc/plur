import 'package:flutter/material.dart';
import '../../generated/l10n.dart';
import '../../theme/app_colors.dart';
import '../../widget/material_icon_fix.dart';
import '../../component/styled_input_field_widget.dart';

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
  bool _isHovered = false;
  bool _isFocused = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_updateButtonState);
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _nameController.removeListener(_updateButtonState);
    _nameController.dispose();
    _focusNode.dispose();
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
    final buttonTextColor = colors.buttonText;
    
    // Get screen width for responsive design
    var screenWidth = MediaQuery.of(context).size.width;
    bool isTablet = screenWidth >= 600;
    bool isDesktop = screenWidth >= 900;
    double mainWidth = isDesktop ? 600 : (isTablet ? 600 : double.infinity);
    double buttonMaxWidth = isDesktop ? 400 : (isTablet ? 500 : double.infinity);

    return Stack(
      children: [
        // Back button positioned at top left
        Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          left: 16,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: buttonTextColor.withAlpha((255 * 0.1).round()),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: FixedIcon(
                Icons.chevron_left,
                color: buttonTextColor,
                size: 24,
              ),
            ),
          ),
        ),
        // Main content
        Center(
          child: SizedBox(
            width: mainWidth,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Holis tag icon
                  Image.asset(
                    'assets/imgs/holis-tag.png',
                    width: 80,
                    height: 80,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback to person icon if image fails to load
                      return Icon(
                        Icons.person_rounded,
                        size: 80,
                        color: buttonTextColor,
                      );
                    },
                  ),
              
              const SizedBox(height: 32),
              
              // Title
              Text(
                localization.onboardingNameInputTitle,
                key: const Key('name_input_title'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'SF Pro Rounded',
                  color: colors.titleText,
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
              
              // Input field with styles from the Login with Nostr sheet
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: buttonMaxWidth),
                  child: StyledInputFieldWidget(
                    controller: _nameController,
                    hintText: localization.onboardingNameInputHint,
                    autofocus: true,
                    focusNode: _focusNode,
                    onChanged: (value) {
                      _updateButtonState();
                    },
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
    ),
      ],
    );
  }
}
