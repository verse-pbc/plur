import 'package:flutter/material.dart';
import 'package:nostrmo/generated/l10n.dart';
import 'package:nostrmo/features/create_community/create_community_dialog.dart';
import '../../theme/app_colors.dart';
import 'package:nostrmo/util/community_join_util.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Used for logging
import 'dart:developer' as developer;
import 'package:nostrmo/router/group/join_community_widget.dart';

class NoCommunitiesWidget extends StatefulWidget {
  /// If forceShow is true, this dialog will be shown even if the user dismissed it before
  final bool forceShow;
  
  const NoCommunitiesWidget({
    super.key, 
    this.forceShow = false,
  });
  
  /// Checks if the no communities dialog should be shown
  /// Returns true if the dialog should be shown, false otherwise
  static Future<bool> shouldShowDialog() async {
    final prefs = await SharedPreferences.getInstance();
    // If the user has already dismissed the dialog, don't show it again
    final dismissed = prefs.getBool(_NoCommunitiesWidgetState._dismissedDialogKey) ?? false;
    developer.log("shouldShowDialog: dismissed=$dismissed", name: "NoCommunitiesWidget");
    return !dismissed;
  }

  @override
  State<NoCommunitiesWidget> createState() => _NoCommunitiesWidgetState();
}

class _NoCommunitiesWidgetState extends State<NoCommunitiesWidget> {
  bool _isCreatingCommunity = false;
  // Key used to store whether the user has dismissed this dialog
  static const String _dismissedDialogKey = 'community_intro_dismissed';
  

  bool _dialogDismissed = false;
  
  @override
  void initState() {
    super.initState();
    // Check if dialog was previously dismissed
    if (!widget.forceShow) {
      SharedPreferences.getInstance().then((prefs) {
        if (mounted) {
          final dismissed = prefs.getBool(_dismissedDialogKey) ?? false;
          setState(() {
            _dialogDismissed = dismissed;
          });
        }
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final localization = S.of(context);
    
    // If dialog is dismissed and not forced to show, return empty
    if (_dialogDismissed && !widget.forceShow) {
      developer.log("Dialog dismissed, returning empty widget", name: "NoCommunitiesWidget");
      return const SizedBox.shrink();
    }
    
    developer.log("Showing dialog, dismissed=$_dialogDismissed, forceShow=${widget.forceShow}", name: "NoCommunitiesWidget");

    final appColors = Theme.of(context).extension<AppColors>()!;
    
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Welcome title
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Text(
              "Welcome!",
              style: TextStyle(
                fontFamily: 'SF Pro Rounded',
                color: appColors.titleText,
                fontSize: 32,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          // Transparent container with the options
          Container(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                // Create new community option
                _buildOptionItem(
                  context: context,
                  appColors: appColors,
                  icon: Icons.add_circle_outline,
                  title: localization.createGroup,
                  subtitle: "Create a new community for your interests",
                  onTap: _createCommunity,
                ),
                
                Divider(color: appColors.paneSeparator, height: 1),
                
                // Join test community option
                _buildOptionItem(
                  context: context,
                  appColors: appColors,
                  icon: Icons.group_outlined,
                  title: "Join Plur Test Users",
                  subtitle: "Join the official Plur test community",
                  onTap: _joinTestUsersGroup,
                ),
                
                Divider(color: appColors.paneSeparator, height: 1),
                
                // Join with invite link option
                _buildOptionItem(
                  context: context,
                  appColors: appColors,
                  icon: Icons.link,
                  title: localization.joinGroup,
                  subtitle: "Have an invite link? Tap on it to join a community.",
                  onTap: () {
                    // Show JoinCommunityWidget in a bottom sheet or navigate
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => FractionallySizedBox(
                        heightFactor: 0.8,
                        child: Container(
                          decoration: BoxDecoration(
                            color: appColors.modalBackground,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                          ),
                          child: JoinCommunityWidget(
                            onJoinCommunity: (String link) {
                              Navigator.of(context).pop();
                              final success = CommunityJoinUtil.parseAndJoinCommunity(context, link);
                              if (success) {
                                // Optionally close the NoCommunitiesWidget as well
                                if (mounted) setState(() {});
                              }
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
                
                Divider(color: appColors.paneSeparator, height: 1),
                
                // Search for communities
                _buildOptionItem(
                  context: context,
                  appColors: appColors,
                  icon: Icons.search,
                  title: "Find Communities",
                  subtitle: "Search for public communities",
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Public community search coming soon!")),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _createCommunity() {
    if (_isCreatingCommunity) return;

    setState(() {
      _isCreatingCommunity = true;
    });

    // Show the dialog
    CreateCommunityDialog.show(context);

    // Reset loading state after a brief delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isCreatingCommunity = false;
        });
      }
    });
  }
  
  /// Joins the Plur Test Users community group
  void _joinTestUsersGroup() {
    const String testUsersGroupLink = "plur://join-community?group-id=R6PCSLSWB45E&code=Z2PWD5ML";
    
    // Show confirmation dialog first
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        // Get colors from the theme
        final colors = Theme.of(context).extension<AppColors>()!;
        
        return AlertDialog(
          backgroundColor: colors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            "Join Plur Test Users Group",
            style: TextStyle(
              color: colors.primaryText,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            "Would you like to join the Plur Test Users community? "
            "This is a public group for testing features and connecting with other users.",
            style: TextStyle(
              color: colors.primaryText,
              fontSize: 16,
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close dialog
                
                // Show loading indicator
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text("Joining Plur Test Users group..."),
                    duration: const Duration(seconds: 1),
                    backgroundColor: colors.primary.withAlpha((255 * 0.9).round()),
                  ),
                );
                
                // Attempt to join the group
                bool success = CommunityJoinUtil.parseAndJoinCommunity(context, testUsersGroupLink);
                
                if (!success && mounted) {
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
                backgroundColor: colors.primary,
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
  
  Widget _buildOptionItem({
    required BuildContext context,
    required AppColors appColors,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: appColors.primary.withAlpha(26),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: appColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'SF Pro Rounded',
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: appColors.primaryText,
                      height: 1.2,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[  
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'SF Pro Rounded',
                        fontSize: 15,
                        color: appColors.secondaryText,
                        height: 1.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}