import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/component/styled_input_field_widget.dart';
import 'package:nostrmo/features/create_community/create_community_dialog.dart';
import 'package:nostrmo/util/community_join_util.dart';
import 'package:nostrmo/theme/app_colors.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/provider/user_provider.dart';
import 'package:nostrmo/generated/l10n.dart';
import 'package:provider/provider.dart';
import '../../data/user.dart';

/// A widget that displays options when no communities are available
/// Provides options to create or join communities
class EmptyCommunitiesWidget extends StatelessWidget {
  const EmptyCommunitiesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final pubkey = nostr!.publicKey;
    
    return Container(
      color: colors.background,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Title at the top
          Padding(
            padding: const EdgeInsets.fromLTRB(40, 60, 40, 0),
            child: Center(
              child: Selector<UserProvider, User?>(
                builder: (context, user, child) {
                  String displayName = "";
                  
                  if (user != null) {
                    if (user.displayName != null && user.displayName!.isNotEmpty) {
                      displayName = user.displayName!;
                    } else if (user.name != null && user.name!.isNotEmpty) {
                      displayName = user.name!;
                    }
                  }
                  
                  if (displayName.isEmpty) {
                    displayName = Nip19.encodeSimplePubKey(pubkey);
                  }
                  
                  return Text(
                    "Welcome, $displayName!",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: colors.primaryText,
                    ),
                  );
                },
                selector: (_, provider) {
                  return provider.getUser(pubkey);
                },
              ),
            ),
          ),
          
          // Option tiles at the bottom
          Padding(
            padding: const EdgeInsets.only(bottom: 48),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: _buildOptionTile(
                    context: context,
                    icon: 'assets/imgs/create-community.png',
                    title: "Create a Community",
                    subtitle: "Start your own community around a topic or activity you care about.",
                    onTap: () {
                      CreateCommunityDialog.show(context);
                    },
                  ),
                ),
                
                const SizedBox(height: 24),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: _buildOptionTile(
                    context: context,
                    icon: 'assets/imgs/join-community.png',
                    title: "Join Holis Community",
                    subtitle: "Be part of our official test group and help us shape the future of Holis.",
                    onTap: () {
                      _joinTestUsersGroup(context);
                    },
                  ),
                ),
                
                const SizedBox(height: 24),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: _buildOptionTile(
                    context: context,
                    icon: 'assets/imgs/icon-link.png',
                    title: "Join with an Invite",
                    subtitle: "Got an invite link? Use it here to join a private group instantly.",
                    onTap: () {
                      _showJoinWithInviteSheet(context);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Helper to build a consistent option tile
  Widget _buildOptionTile({
    required BuildContext context,
    required dynamic icon, // Can be IconData or String (asset path)
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    final colors = context.colors;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final color = enabled ? colors.accent : colors.secondaryText.withAlpha(153);
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E2936) : null,
        border: Border.all(
          color: colors.paneSeparator,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Show image if icon is a String (asset path), otherwise show Icon
              icon is String
                ? Image.asset(
                    icon,
                    width: 28,
                    height: 28,
                    // Removed the color tinting to show original image colors
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.error_outline, color: color, size: 28);
                    },
                  )
                : Icon(icon, color: color, size: 28),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: enabled ? colors.primaryText : colors.secondaryText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: colors.secondaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Joins the Plur Test Users community group
  void _joinTestUsersGroup(BuildContext context) {
    const String testUsersGroupLink = "plur://join-community?group-id=R6PCSLSWB45E&code=Z2PWD5ML";
    
    // Show join community sheet (similar to login sheet)
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withAlpha((255 * 0.5).round()),
      enableDrag: true,
      isDismissible: true,
      builder: (BuildContext context) {
        // Get responsive width values
        var screenWidth = MediaQuery.of(context).size.width;
        bool isTablet = screenWidth >= 600;
        bool isDesktop = screenWidth >= 900;
        double sheetMaxWidth = isDesktop ? 600 : (isTablet ? 600 : double.infinity);
        
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
              },
              child: Container(
                color: Colors.transparent,
                height: 100,  // Touch area above sheet
              ),
            ),
            AnimatedPadding(
              padding: MediaQuery.of(context).viewInsets,
              duration: const Duration(milliseconds: 100),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: sheetMaxWidth),
                  child: Container(
                    decoration: BoxDecoration(
                      color: context.colors.loginBackground,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: SafeArea(
                      top: false,
                      bottom: true,
                      child: _buildJoinHolisSheet(context, testUsersGroupLink),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
  
  // Shows the join with invite sheet (similar to login sheet)
  void _showJoinWithInviteSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withAlpha((255 * 0.5).round()),
      enableDrag: true,
      isDismissible: true,
      builder: (BuildContext context) {
        // Get responsive width values
        var screenWidth = MediaQuery.of(context).size.width;
        bool isTablet = screenWidth >= 600;
        bool isDesktop = screenWidth >= 900;
        double sheetMaxWidth = isDesktop ? 600 : (isTablet ? 600 : double.infinity);
        
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
              },
              child: Container(
                color: Colors.transparent,
                height: 100,  // Touch area above sheet
              ),
            ),
            AnimatedPadding(
              padding: MediaQuery.of(context).viewInsets,
              duration: const Duration(milliseconds: 100),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: sheetMaxWidth),
                  child: Container(
                    decoration: BoxDecoration(
                      color: context.colors.loginBackground,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: const SafeArea(
                      top: false,
                      bottom: true,
                      child: _JoinWithInviteSheetContent(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
  
  // Builds the join Holis community sheet content (similar to login sheet)
  Widget _buildJoinHolisSheet(BuildContext context, String testUsersGroupLink) {
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
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 32, 40, 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Close button
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: buttonTextColor.withAlpha((255 * 0.1).round()),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  color: buttonTextColor,
                  size: 20,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Community join icon above title
          Center(
            child: Image.asset(
              'assets/imgs/join-community.png',
              width: 80,
              height: 80,
              // No color tinting to show the original image
              errorBuilder: (context, error, stackTrace) {
                // Fallback icon if image fails to load
                return Icon(
                  Icons.people_rounded,
                  size: 80,
                  color: buttonTextColor,
                );
              },
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Title
          wrapResponsive(
            Center(
              child: Text(
                "Join Holis Community",
                style: TextStyle(
                  fontFamily: 'SF Pro Rounded',
                  color: buttonTextColor,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Description
          wrapResponsive(
            Text(
              "Would you like to join the Holis Community? This is our official test group where you can help us shape the future of Holis.",
              style: TextStyle(
                fontFamily: 'SF Pro Rounded',
                color: colors.secondaryText,
                fontSize: 16,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Cancel button
          wrapResponsive(
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    border: Border.all(
                      color: colors.secondaryText.withAlpha((255 * 0.3).round()),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    "Cancel",
                    style: TextStyle(
                      fontFamily: 'SF Pro Rounded',
                      color: buttonTextColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Join Group button
          wrapResponsive(
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                  
                  // Show loading indicator
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text("Joining Holis Community..."),
                      duration: const Duration(seconds: 1),
                      backgroundColor: colors.primary.withAlpha(230),
                    ),
                  );
                  
                  // Attempt to join the group
                  bool success = CommunityJoinUtil.parseAndJoinCommunity(context, testUsersGroupLink);
                  
                  if (!success && context.mounted) {
                    // Show error message if joining failed
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Failed to join Holis Community. Please try again later."),
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withAlpha(77),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    "Join Group",
                    style: TextStyle(
                      fontFamily: 'SF Pro Rounded',
                      color: buttonTextColor,
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
      ),
    );
  }
}

// A stateful widget for the join with invite sheet content
class _JoinWithInviteSheetContent extends StatefulWidget {
  const _JoinWithInviteSheetContent();

  @override
  State<_JoinWithInviteSheetContent> createState() => _JoinWithInviteSheetContentState();
}

class _JoinWithInviteSheetContentState extends State<_JoinWithInviteSheetContent> {
  final TextEditingController _linkController = TextEditingController();
  bool _hasValidFormat = false;

  @override
  void initState() {
    super.initState();
    
    // Check clipboard on initialization
    _checkClipboard();
  }
  
  Future<void> _checkClipboard() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      final clipboardText = clipboardData?.text?.trim();
      
      // If clipboard contains what looks like a community link, pre-fill it
      if (clipboardText != null && 
          (clipboardText.startsWith('plur://join-community') || clipboardText.startsWith('plur:join-community')) &&
          clipboardText.contains('group-id=')) {
        _linkController.text = clipboardText;
        _validateLink(clipboardText);
      }
    } catch (e) {
      // Silently handle clipboard permission errors
      // In web contexts, we'll need user interaction first
      debugPrint("Clipboard access error: $e");
    }
  }
  
  void _validateLink(String text) {
    setState(() {
      // Basic validation - we'll do more thorough validation when processing
      final trimmedText = text.trim();
      _hasValidFormat = (trimmedText.startsWith('plur://join-community') || 
                         trimmedText.startsWith('plur:join-community')) && 
                        trimmedText.contains('group-id=');
    });
  }
  
  // Helper method to paste from clipboard, addressing use_build_context_synchronously
  Future<void> _pasteFromClipboard(BuildContext context) async {
    // Grab the context before the async operation
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data?.text != null && mounted) {
        _linkController.text = data!.text!.trim();
        _validateLink(_linkController.text);
      }
    } catch (e) {
      // Handle clipboard permission errors using the captured scaffoldMessenger
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text("Cannot access clipboard. Please interact with the page first or enter the link manually."),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final colors = context.colors;
    final accentColor = colors.accent;
    final buttonTextColor = colors.buttonText;
    
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
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 32, 40, 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Close button
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: buttonTextColor.withAlpha((255 * 0.1).round()),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  color: buttonTextColor,
                  size: 20,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Community join icon above title
          Center(
            child: Image.asset(
              'assets/imgs/icon-link.png',
              width: 80,
              height: 80,
              // No color tinting to show the original image
              errorBuilder: (context, error, stackTrace) {
                // Fallback icon if image fails to load
                return Icon(
                  Icons.link_rounded,
                  size: 80,
                  color: buttonTextColor,
                );
              },
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Title
          wrapResponsive(
            Center(
              child: Text(
                l10n.joinGroup,
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
          
          const SizedBox(height: 16),
          
          // Subtitle
          wrapResponsive(
            Text(
              "Paste a community invitation link",
              style: TextStyle(
                fontFamily: 'SF Pro Rounded',
                color: colors.secondaryText,
                fontSize: 16,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Example of what a link looks like
          wrapResponsive(
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colors.secondaryText.withAlpha((255 * 0.1).round()),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "Example: plur://join-community?group-id=ABC123&code=XYZ789",
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  color: colors.secondaryText,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Link input field
          wrapResponsive(
            SizedBox(
              height: 120, // Set a height for multiline input
              child: StyledInputFieldWidget(
                controller: _linkController,
                hintText: l10n.pleaseInput,
                autofocus: true,
                suffixIcon: _linkController.text.isNotEmpty 
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _linkController.clear();
                          _hasValidFormat = false;
                        });
                      },
                    )
                  : null,
                onChanged: _validateLink,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Paste button
          wrapResponsive(
            Center(
              child: TextButton.icon(
                onPressed: () {
                  _pasteFromClipboard(context);
                },
                icon: Icon(
                  Icons.content_paste,
                  color: accentColor,
                ),
                label: Text(
                  "Paste from clipboard",
                  style: TextStyle(
                    color: accentColor,
                    fontFamily: 'SF Pro Rounded',
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Join button
          wrapResponsive(
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: _hasValidFormat ? () {
                  Navigator.of(context).pop();
                  
                  // Attempt to join the group
                  final success = CommunityJoinUtil.parseAndJoinCommunity(
                    context, 
                    _linkController.text
                  );
                  
                  if (!success && context.mounted) {
                    // Show error message if joining failed
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Failed to join community. Please try again later."),
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                } : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: _hasValidFormat 
                      ? accentColor
                      : accentColor.withAlpha((255 * 0.4).round()),
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: _hasValidFormat ? [
                      BoxShadow(
                        color: accentColor.withAlpha(77),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ] : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    l10n.joinGroup,
                    style: TextStyle(
                      fontFamily: 'SF Pro Rounded',
                      color: _hasValidFormat
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
      ),
    );
  }
  
  @override
  void dispose() {
    _linkController.dispose();
    super.dispose();
  }
}