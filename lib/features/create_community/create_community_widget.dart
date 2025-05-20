import 'package:flutter/material.dart';
import 'package:nostrmo/theme/app_colors.dart';

import '../../component/styled_input_field_widget.dart';
import '../../generated/l10n.dart';

class CreateCommunityWidget extends StatefulWidget {
  final void Function(String) onCreateCommunity;

  const CreateCommunityWidget({super.key, required this.onCreateCommunity});

  @override
  State<CreateCommunityWidget> createState() => _CreateCommunityWidgetState();
}

class _CreateCommunityWidgetState extends State<CreateCommunityWidget> {
  final TextEditingController _communityNameController =
      TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final localization = S.of(context);
    final colors = context.colors;
    Color accentColor = colors.accent;
    Color buttonTextColor = colors.buttonText;
    
    // Get screen width for responsive design
    var screenWidth = MediaQuery.of(context).size.width;
    bool isDesktop = screenWidth >= 900;

    // Wrapper function for responsive elements
    Widget wrapResponsive(Widget child) {
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isDesktop ? 400 : 500),
          child: child,
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Title text
        wrapResponsive(
          Center(
            child: Text(
              localization.createYourCommunity,
              style: TextStyle(
                fontFamily: 'SF Pro Rounded',
                color: buttonTextColor,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Subtitle
        wrapResponsive(
          Text(
            localization.nameYourCommunity,
            style: TextStyle(
              fontFamily: 'SF Pro Rounded',
              color: colors.secondaryText,
              fontSize: 16,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Community name input
        wrapResponsive(
          StyledInputFieldWidget(
            controller: _communityNameController,
            hintText: localization.communityName,
            autofocus: true,
            onChanged: (text) {
              setState(() {});
            },
          ),
        ),
        
        const SizedBox(height: 32),
        
        // Confirm button
        wrapResponsive(
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: _communityNameController.text.isNotEmpty
                  ? _createCommunity
                  : null,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: _communityNameController.text.isNotEmpty
                    ? accentColor
                    : accentColor.withAlpha((255 * 0.4).round()),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: _communityNameController.text.isNotEmpty
                    ? [
                        BoxShadow(
                          color: accentColor.withAlpha(77),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  localization.confirm,
                  style: TextStyle(
                    fontFamily: 'SF Pro Rounded',
                    color: _communityNameController.text.isNotEmpty
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
      ],
    );
  }

  void _createCommunity() {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    widget.onCreateCommunity(_communityNameController.text);
    // No need to set _isLoading back to false as we'll transition to the next screen
  }

  @override
  void dispose() {
    _communityNameController.dispose();
    super.dispose();
  }
}
