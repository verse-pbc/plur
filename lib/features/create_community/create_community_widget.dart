import 'package:flutter/material.dart';
import 'package:nostrmo/theme/app_colors.dart';

import '../../component/styled_input_field_widget.dart';
import '../../generated/l10n.dart';

class CreateCommunityWidget extends StatefulWidget {
  final void Function(String, String?) onCreateCommunity;

  const CreateCommunityWidget({super.key, required this.onCreateCommunity});

  @override
  State<CreateCommunityWidget> createState() => _CreateCommunityWidgetState();
}

class _CreateCommunityWidgetState extends State<CreateCommunityWidget> {
  final TextEditingController _communityNameController = TextEditingController();
  final TextEditingController _customInviteLinkController = TextEditingController();
  bool _isLoading = false;
  bool _showCustomLinkField = false;
  bool _isCustomLinkManuallyEdited = false; // Track if user manually edited the custom link

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
              // Auto-populate custom invite link if it hasn't been manually edited
              if (_showCustomLinkField && !_isCustomLinkManuallyEdited) {
                final sanitizedName = _sanitizeForUrl(text);
                _customInviteLinkController.text = sanitizedName;
              }
              setState(() {});
            },
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Custom invite link toggle
        wrapResponsive(
          GestureDetector(
            onTap: () {
              setState(() {
                _showCustomLinkField = !_showCustomLinkField;
                
                // If opening the custom link field and it's empty, auto-populate from community name
                if (_showCustomLinkField && _customInviteLinkController.text.isEmpty) {
                  final sanitizedName = _sanitizeForUrl(_communityNameController.text);
                  _customInviteLinkController.text = sanitizedName;
                  _isCustomLinkManuallyEdited = false; // Reset manual edit flag
                }
              });
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _showCustomLinkField 
                      ? Icons.keyboard_arrow_up 
                      : Icons.keyboard_arrow_down,
                  size: 18,
                  color: colors.secondaryText,
                ),
                const SizedBox(width: 4),
                Text(
                  _showCustomLinkField 
                      ? "Hide custom invite link" 
                      : "Use custom invite link",
                  style: TextStyle(
                    fontFamily: 'SF Pro Rounded',
                    color: colors.secondaryText,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Custom invite link field (conditional)
        if (_showCustomLinkField) ...[
          const SizedBox(height: 16),
          wrapResponsive(
            StyledInputFieldWidget(
              controller: _customInviteLinkController,
              hintText: "Custom link suffix (optional)",
              onChanged: (text) {
                // Mark as manually edited when user types in this field
                _isCustomLinkManuallyEdited = true;
                
                // Sanitize the text - allow only alphanumeric and hyphens
                if (text.isNotEmpty) {
                  final sanitized = text.replaceAll(RegExp(r'[^a-zA-Z0-9-]'), '');
                  if (sanitized != text) {
                    _customInviteLinkController.value = TextEditingValue(
                      text: sanitized,
                      selection: TextSelection.collapsed(offset: sanitized.length),
                    );
                  }
                }
                setState(() {});
              },
            ),
          ),
          const SizedBox(height: 8),
          wrapResponsive(
            Text(
              _getDynamicLinkCaption(),
              style: TextStyle(
                fontFamily: 'SF Pro Rounded',
                color: colors.secondaryText,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (_customInviteLinkController.text.isNotEmpty && _customInviteLinkController.text.length < 4) ...[
            const SizedBox(height: 4),
            wrapResponsive(
              Text(
                "Custom link should be at least 4 characters",
                style: TextStyle(
                  fontFamily: 'SF Pro Rounded',
                  color: Colors.redAccent,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
        
        const SizedBox(height: 32),
        
        // Confirm button
        wrapResponsive(
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: _isButtonEnabled() ? _createCommunity : null,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: _isButtonEnabled() 
                    ? accentColor
                    : accentColor.withAlpha((255 * 0.4).round()),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: _isButtonEnabled()
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
                    color: _isButtonEnabled()
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

    // Validate custom invite link if visible and non-empty
    if (_showCustomLinkField && 
        _customInviteLinkController.text.isNotEmpty && 
        _customInviteLinkController.text.length < 4) {
      // Don't proceed if custom link is too short
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Pass the custom invite link if it's provided, visible, and valid
    String? customInviteLink;
    if (_showCustomLinkField && 
        _customInviteLinkController.text.isNotEmpty && 
        _customInviteLinkController.text.length >= 4) {
      customInviteLink = _customInviteLinkController.text;
    }

    widget.onCreateCommunity(_communityNameController.text, customInviteLink);
    // No need to set _isLoading back to false as we'll transition to the next screen
  }

  // Check if the button should be enabled based on validation rules
  bool _isButtonEnabled() {
    bool isCommunityNameValid = _communityNameController.text.isNotEmpty;
    
    // If custom link field is shown and has content, it must be valid
    bool isCustomLinkValid = !_showCustomLinkField || 
                            _customInviteLinkController.text.isEmpty || 
                            _customInviteLinkController.text.length >= 4;
    
    return isCommunityNameValid && isCustomLinkValid;
  }

  /// Generates the dynamic link caption based on current state
  String _getDynamicLinkCaption() {
    String linkSuffix;
    
    if (_customInviteLinkController.text.isNotEmpty) {
      // Use the custom link text
      linkSuffix = _customInviteLinkController.text;
    } else if (_communityNameController.text.isNotEmpty) {
      // Use the sanitized community name
      linkSuffix = _sanitizeForUrl(_communityNameController.text);
    } else {
      // Default placeholder
      linkSuffix = "your-custom-link";
    }
    
    return "The link will be holis.is/c/$linkSuffix";
  }
  
  /// Sanitizes a string to be URL-friendly
  /// Converts to lowercase, replaces spaces with hyphens, removes special characters
  String _sanitizeForUrl(String input) {
    if (input.isEmpty) return "";
    
    return input
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'\s+'), '-') // Replace spaces with hyphens
        .replaceAll(RegExp(r'[^a-z0-9-]'), '') // Remove special characters except hyphens
        .replaceAll(RegExp(r'-+'), '-') // Replace multiple hyphens with single hyphen
        .replaceAll(RegExp(r'^-|-$'), ''); // Remove leading/trailing hyphens
  }

  @override
  void dispose() {
    _communityNameController.dispose();
    _customInviteLinkController.dispose();
    super.dispose();
  }
}
