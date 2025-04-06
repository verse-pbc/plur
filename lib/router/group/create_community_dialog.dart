import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/router/group/create_community_widget.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:nostrmo/util/theme_util.dart';
import 'package:nostrmo/router/group/invite_people_widget.dart';
import 'package:nostrmo/provider/list_provider.dart';
import 'package:provider/provider.dart';

class CreateCommunityDialog extends StatefulWidget {
  const CreateCommunityDialog({super.key});

  static Future<void> show(BuildContext context) async {
    // Force the dialog to use the same brightness as the main app
    final Brightness appBrightness = Theme.of(context).brightness;
    
    // Create a theme that explicitly matches the app's brightness
    final ThemeData forcedTheme = ThemeData(
      brightness: appBrightness,
      // Use primaryColor from the app
      primaryColor: Theme.of(context).primaryColor,
      // Copy other key colors from the app theme
      colorScheme: Theme.of(context).colorScheme,
      // Make sure text is visible on dark backgrounds
      textTheme: appBrightness == Brightness.dark 
          ? ThemeData.dark().textTheme 
          : ThemeData.light().textTheme,
    );
    
    await showDialog<void>(
      context: context,
      useRootNavigator: false,
      barrierDismissible: false, // Prevent accidental dismissal during loading
      builder: (dialogContext) {
        // Force the dialog to use the correct brightness theme
        return Theme(
          data: forcedTheme,
          child: const CreateCommunityDialog(),
        );
      },
    );
  }

  @override
  State<CreateCommunityDialog> createState() => _CreateCommunityDialogState();
}

class _CreateCommunityDialogState extends State<CreateCommunityDialog> {
  bool _showInviteCommunity = false;
  String? _communityInviteLink;
  GroupIdentifier? _groupIdentifier;
  bool _isCreating = false;

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final maxWidth = size.width > 600 ? 500.0 : size.width * 0.9;
    
    // Get the exact brightness mode from theme
    final isDarkMode = themeData.brightness == Brightness.dark;
    
    return PopScope(
      canPop: !_isCreating, // Prevent back button during creation
      child: Scaffold(
        // Force appropriate background color based on theme brightness
        backgroundColor: isDarkMode 
            ? Colors.black.withOpacity(0.9) 
            : ThemeUtil.getDialogCoverColor(themeData),
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            // Background dismiss area (only when not creating)
            GestureDetector(
              onTap: _isCreating ? null : () => RouterUtil.back(context),
              child: Container(
                // Use appropriate background for dialog backdrop
                color: isDarkMode ? Colors.black54 : Colors.black38,
              ),
            ),
            
            // Main content
            Center(
              child: SingleChildScrollView(
                child: Container(
                  width: maxWidth,
                  margin: const EdgeInsets.symmetric(vertical: 40),
                  child: Card(
                    elevation: 8,
                    // Force appropriate background color
                    color: isDarkMode 
                        ? const Color(0xFF1E1E1E) // Dark gray for dark mode
                        : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header with close button
                          if (!_isCreating)
                            Align(
                              alignment: Alignment.topRight,
                              child: IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  RouterUtil.back(context);
                                },
                                tooltip: 'Close',
                                iconSize: 24,
                              ),
                            ),
                            
                          // Content based on state
                          if (!_showInviteCommunity)
                            CreateCommunityWidget(
                              onCreateCommunity: (name) {
                                setState(() {
                                  _isCreating = true;
                                });
                                _onCreateCommunity(name);
                              }
                            ),
                          if (_showInviteCommunity)
                            InvitePeopleWidget(
                              shareableLink: _communityInviteLink ?? '',
                              groupIdentifier: _groupIdentifier!,
                              showCreatePostButton: true,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            // Full-screen loading overlay (optional, for very long operations)
            if (_isCreating && !_showInviteCommunity)
              Container(
                // Force dark overlay regardless of theme for loading screen
                color: Colors.black.withAlpha(150),
                child: Center(
                  child: CircularProgressIndicator(
                    // White progress indicator in dark mode, primary color in light mode
                    color: isDarkMode ? Colors.white : themeData.primaryColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _onCreateCommunity(String communityName) async {
    final listProvider = Provider.of<ListProvider>(context, listen: false);
    
    try {
      final groupDetails =
          await listProvider.createGroupAndGenerateInvite(communityName);

      if (mounted) {
        setState(() {
          _communityInviteLink = groupDetails.$1;
          _groupIdentifier = groupDetails.$2;
          _showInviteCommunity = true;
          _isCreating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
        // Could add error handling here if desired
      }
    }
  }
}
