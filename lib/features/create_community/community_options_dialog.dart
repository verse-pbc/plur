import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nostrmo/features/create_community/create_community_dialog.dart';
import 'package:nostrmo/router/group/join_community_widget.dart';
import 'package:nostrmo/util/community_join_util.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:nostrmo/util/theme_util.dart';

import '../../generated/l10n.dart';

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
    final Color cardColor = themeData.cardColor;
    final textColor = themeData.textTheme.titleMedium?.color ?? Colors.white;
    final accentColor = themeData.primaryColor; 
    final l10n = S.of(context);

    return Scaffold(
      backgroundColor: ThemeUtil.getDialogCoverColor(themeData),
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
                margin: const EdgeInsets.all(24),
                child: Card(
                  elevation: 4,
                  color: cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
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
        onJoinCommunity: (String link) {
          // Attempt to join the community
          final success = CommunityJoinUtil.parseAndJoinCommunity(context, link);
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Close button
        Align(
          alignment: Alignment.topRight,
          child: IconButton(
            icon: Icon(Icons.close, color: textColor.withAlpha(178)), // 0.7 opacity converted to alpha
            onPressed: () {
              RouterUtil.back(context);
            },
            padding: EdgeInsets.zero,
          ),
        ),
        
        // Title
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 24),
          child: Text(
            l10n.communities,
            style: TextStyle(
              color: textColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        
        // Create new community option
        _buildOptionTile(
          context: context,
          icon: Icons.add_circle_outline,
          title: l10n.createGroup,
          subtitle: "Create a new community for your interests",
          color: accentColor,
          onTap: () {
            // First close this dialog
            Navigator.of(context).pop();
            // Then show create community dialog
            CreateCommunityDialog.show(context);
          },
        ),
        
        const Divider(),
        
        // Join test community option
        _buildOptionTile(
          context: context,
          icon: Icons.people_outline,
          title: "Join Plur Test Users",
          subtitle: "Join the official Plur test community",
          color: accentColor,
          onTap: () {
            // Close the current dialog
            Navigator.of(context).pop();
            // Join the test community
            _joinTestUsersGroup(context);
          },
        ),
        
        const Divider(),
        
        // Join with invite link option
        _buildOptionTile(
          context: context,
          icon: Icons.link,
          title: l10n.joinGroup,
          subtitle: l10n.haveInviteLink,
          color: accentColor,
          onTap: () {
            setState(() {
              _currentView = OptionView.join;
            });
          },
        ),
        
        const Divider(),
        
        // Search for communities (placeholder for future implementation)
        _buildOptionTile(
          context: context,
          icon: Icons.search,
          title: "Find Communities",
          subtitle: "Search for public communities",
          color: accentColor.withAlpha(153), // 0.6 opacity converted to alpha
          onTap: () {
            // Placeholder for future implementation
            ScaffoldMessenger.of(context).showSnackBar(
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
    return ListTile(
      leading: Icon(icon, color: color, size: 28),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: Theme.of(context).hintColor,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
  
  /// Joins the Plur Test Users community group
  void _joinTestUsersGroup(BuildContext context) {
    const String testUsersGroupLink = "plur://join-community?group-id=R6PCSLSWB45E&code=Z2PWD5ML";
    
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
            "Join Plur Test Users Group",
            style: TextStyle(
              color: plurHighlightText,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            "Would you like to join the Plur Test Users community? "
            "This is a public group for testing features and connecting with other users.",
            style: TextStyle(
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
                  color: plurSecondaryText,
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close dialog
                
                // Show loading indicator
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text("Joining Plur Test Users group..."),
                    duration: const Duration(seconds: 1),
                    backgroundColor: plurPurple.withAlpha(230), // 0.9 opacity converted to alpha
                  ),
                );
                
                // Attempt to join the group
                bool success = CommunityJoinUtil.parseAndJoinCommunity(context, testUsersGroupLink);
                
                if (!success && context.mounted) {
                  // Show error message if joining failed
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Failed to join test users group. Please try again later."),
                      duration: Duration(seconds: 3),
                    ),
                  );
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