import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nostrmo/features/create_community/create_community_dialog.dart';
import 'package:nostrmo/router/group/join_community_widget.dart';
import 'package:nostrmo/util/community_join_util.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:nostrmo/util/theme_util.dart';

import '../../generated/l10n.dart';
import '../../theme/app_colors.dart';

/// A dialog that provides multiple options for community engagement:
/// 1. Create a new community
/// 2. Search for public communities
/// 3. Join the test community
/// 4. Join with an invite link
class CommunityOptionsDialog extends ConsumerStatefulWidget {
  const CommunityOptionsDialog({super.key});

  /// Shows the community options dialog
  static Future<void> show(BuildContext context) async {
    await showDialog<void>(
      context: context,
      useRootNavigator: false,
      builder: (_) {
        return const CommunityOptionsDialog();
      },
    );
  }

  @override
  ConsumerState<CommunityOptionsDialog> createState() {
    return _CommunityOptionsDialogState();
  }
}

// Define enum outside the class
enum OptionView {
  main,    // Main options menu
  join,    // Join by invite link
}

class _CommunityOptionsDialogState extends ConsumerState<CommunityOptionsDialog> {
  // Track the current view state
  OptionView _currentView = OptionView.main;

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final appColors = themeData.extension<AppColors>()!;
    final textColor = appColors.titleText;
    final accentColor = appColors.primary; 
    final l10n = S.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Backdrop - dismisses dialog when tapped
          GestureDetector(
            onTap: () {
              RouterUtil.back(context);
            },
            child: Container(
              color: Colors.black54,
            ),
          ),
          
          // Dialog content
          Center(
            child: SingleChildScrollView(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 40),
                child: Container(
                  decoration: BoxDecoration(
                    color: appColors.modalBackground,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _buildCurrentView(context, textColor, accentColor, l10n),
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
  
  // Returns the appropriate view based on current state
  Widget _buildCurrentView(BuildContext context, Color textColor, Color accentColor, S l10n) {
    // Since we have a complete enum with only two cases, we can simplify this
    if (_currentView == OptionView.main) {
      return _buildMainOptionsView(context, textColor, accentColor, l10n);
    } else {
      return JoinCommunityWidget(
        onJoinCommunity: (String link) async {
          // Attempt to join the community
          final success = await CommunityJoinUtil.parseAndJoinCommunity(context, link);
          if (success) {
            // Close the dialog on success
            RouterUtil.back(context);
          }
        },
      );
    }
  }
  
  // Builds the main options menu
  Widget _buildMainOptionsView(BuildContext context, Color textColor, Color accentColor, S l10n) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Close button
        Align(
          alignment: Alignment.topRight,
          child: GestureDetector(
            onTap: () => RouterUtil.back(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: appColors.secondaryText.withAlpha(26), // Very light background
              ),
              child: Icon(
                Icons.close,
                color: appColors.secondaryText,
                size: 20,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Title
        Text(
          l10n.communities,
          style: TextStyle(
            fontFamily: 'SF Pro Rounded',
            color: textColor,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 40),
        
        // Create new community option
        _buildOptionTile(
          context: context,
          icon: Icons.add,
          title: l10n.createGroup,
          subtitle: "",
          color: accentColor,
          onTap: () {
            // First close this dialog
            Navigator.of(context).pop();
            // Then show create community dialog
            CreateCommunityDialog.show(context);
          },
        ),
        
        // Join test community option
        _buildOptionTile(
          context: context,
          icon: Icons.groups,
          title: "Join Holis Test Users",
          subtitle: "",
          color: accentColor,
          onTap: () {
            // Close the current dialog
            Navigator.of(context).pop();
            // Join the test community
            _joinTestUsersGroup(context);
          },
        ),
        
        // Join with invite link option
        _buildOptionTile(
          context: context,
          icon: Icons.link,
          title: l10n.joinGroup,
          subtitle: "",
          color: accentColor,
          onTap: () {
            setState(() {
              _currentView = OptionView.join;
            });
          },
        ),
        
        // Search for communities (placeholder for future implementation)
        _buildOptionTile(
          context: context,
          icon: Icons.search,
          title: "Find Communities",
          subtitle: "",
          color: accentColor,
          onTap: () {
            // Placeholder for future implementation
            // Capture scaffold messenger to avoid potential widget deactivation issues
            final scaffoldMessenger = ScaffoldMessenger.of(context);
            scaffoldMessenger.showSnackBar(
              const SnackBar(content: Text("Public community search coming soon!")),
            );
          },
        ),
      ],
    );
  }
  
  // Helper to build a consistent option tile
  Widget _buildOptionTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: appColors.surface.withAlpha(77), // Semi-transparent background
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: color,
                size: 32,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'SF Pro Rounded',
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  color: appColors.titleText,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Joins the Holis Test Users community group
  void _joinTestUsersGroup(BuildContext context) {
    const String testUsersGroupLink = "holis://join-community?group-id=R6PCSLSWB45E&code=Z2PWD5ML";
    
    // Show confirmation dialog first
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        // Get colors from Plur theme
        final themeData = Theme.of(context);
        final plurBackground = themeData.cardColor;
        final plurPurple = themeData.primaryColor;
        final plurPrimaryText = themeData.textTheme.titleMedium?.color;
        final plurHighlightText = themeData.textTheme.titleLarge?.color;
        final plurSecondaryText = themeData.hintColor;
        
        return AlertDialog(
          backgroundColor: plurBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            "Join Holis Test Users Group",
            style: TextStyle(
              fontFamily: 'SF Pro Rounded',
              color: plurHighlightText,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            "Would you like to join the Holis Test Users community? "
            "This is a public group for testing features and connecting with other users.",
            style: TextStyle(
              fontFamily: 'SF Pro Rounded',
              color: plurPrimaryText,
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close dialog without joining
              },
              child: Text(
                "Cancel",
                style: TextStyle(
                  fontFamily: 'SF Pro Rounded',
                  color: plurSecondaryText,
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Close dialog
                
                // Capture scaffold messenger before closing dialog
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                
                // Show loading indicator after ensuring we have a valid reference
                if (context.mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: const Text("Joining Holis Test Users group..."),
                      duration: const Duration(seconds: 3),
                      backgroundColor: plurPurple.withAlpha(230), // 0.9 opacity converted to alpha
                    ),
                  );
                }
                
                try {
                  // Attempt to join the group
                  bool success = await CommunityJoinUtil.parseAndJoinCommunity(context, testUsersGroupLink);
                  
                  if (!success && context.mounted) {
                    // Show error message if joining failed
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(
                        content: Text("Failed to join test users group. Please try again later."),
                        duration: Duration(seconds: 3),
                      ),
                    );
                  } else if (success && context.mounted) {
                    // Show success message
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: const Text("Successfully joined Holis Test Users group!"),
                        duration: const Duration(seconds: 2),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text("Error joining group: $e"),
                        duration: const Duration(seconds: 3),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: plurPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                "Join Group",
                style: TextStyle(
                  fontFamily: 'SF Pro Rounded',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}