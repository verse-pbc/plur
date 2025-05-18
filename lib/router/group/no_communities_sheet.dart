import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nostrmo/generated/l10n.dart';
import 'package:nostrmo/features/create_community/create_community_dialog.dart';
import '../../theme/app_colors.dart';
import 'package:nostrmo/util/community_join_util.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:nostrmo/data/group_identifier.dart';
import 'package:nostrmo/data/join_group_parameters.dart';
import 'package:nostrmo/provider/list_provider.dart';
import 'package:nostrmo/consts/router_path.dart';

// Used for logging
import 'dart:developer' as developer;

class NoCommunitiesSheet extends StatefulWidget {
  /// If forceShow is true, this dialog will be shown even if the user dismissed it before
  final bool forceShow;
  
  const NoCommunitiesSheet({
    super.key, 
    this.forceShow = false,
  });
  
  /// Checks if the no communities dialog should be shown
  /// Returns true if the dialog should be shown, false otherwise
  static Future<bool> shouldShowDialog() async {
    final prefs = await SharedPreferences.getInstance();
    // If the user has already dismissed the dialog, don't show it again
    final dismissed = prefs.getBool(_NoCommunitiesSheetState._dismissedDialogKey) ?? false;
    developer.log("shouldShowDialog: dismissed=$dismissed", name: "NoCommunitiesSheet");
    
    // The context check can't be performed here reliably
    // Caller should check listProvider.groupIdentifiers.isNotEmpty if needed
    return !dismissed;
  }

  @override
  State<NoCommunitiesSheet> createState() => _NoCommunitiesSheetState();
}

class _NoCommunitiesSheetState extends State<NoCommunitiesSheet> {
  bool _isCreatingCommunity = false;
  // Key used to store whether the user has dismissed this dialog
  static const String _dismissedDialogKey = 'community_intro_dismissed';

  @override
  Widget build(BuildContext context) {
    final localization = S.of(context);
    
    developer.log("Showing NoCommunitiesSheet", name: "NoCommunitiesSheet");

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(24),
        topRight: Radius.circular(24),
      ),
      child: Container(
        color: context.colors.loginBackground,
        child: SafeArea(
          bottom: true,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(40, 32, 40, 48),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Image section first
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.colors.dimmed.withAlpha((255 * 0.1).round()),
                  ),
                  child: Center(
                    child: ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        context.colors.primaryText,
                        BlendMode.srcIn,
                      ),
                      child: Image.asset(
                        "assets/imgs/welcome_groups.png",
                        width: 50,
                        height: 50,
                        errorBuilder: (context, error, stackTrace) {
                          debugPrint("Error loading welcome_groups.png: $error");
                          return Icon(
                            Icons.groups_rounded,
                            size: 50,
                            color: context.colors.primaryText,
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Title section
                Text(
                  localization.communities,
                  style: TextStyle(
                    fontFamily: 'SF Pro Rounded',
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: context.colors.titleText,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Create community section
                Text(
                  localization.startOrJoinACommunity,
                  style: TextStyle(
                    fontFamily: 'SF Pro Rounded',
                    fontSize: 14,
                    color: context.colors.secondaryText,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Action buttons
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Create button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: _isCreatingCommunity
                            ? Center(
                                child: CircularProgressIndicator(
                                  color: context.colors.accent,
                                ),
                              )
                            : ElevatedButton(
                                onPressed: _createCommunity,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: context.colors.primary,
                                  foregroundColor: context.colors.buttonText,
                                  padding: const EdgeInsets.symmetric(horizontal: 40),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  disabledBackgroundColor: context.colors.primary.withAlpha((255 * 0.5).round()),
                                  disabledForegroundColor: context.colors.buttonText.withAlpha((255 * 0.7).round()),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      'assets/imgs/holis-tag.png',
                                      width: 24,
                                      height: 24,
                                      color: context.colors.buttonText,
                                      errorBuilder: (context, error, stackTrace) {
                                        debugPrint("Error loading holis-tag.png: $error");
                                        return Icon(Icons.add_rounded, size: 24, color: context.colors.buttonText);
                                      },
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      localization.createGroup,
                                      style: const TextStyle(
                                        fontFamily: 'SF Pro Rounded',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Join Test Users Group button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton(
                          onPressed: _joinTestUsersGroup,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: context.colors.buttonText,
                              width: 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/imgs/nostrich.png',
                                width: 24,
                                height: 24,
                                color: context.colors.primary,
                                errorBuilder: (context, error, stackTrace) {
                                  debugPrint("Error loading nostrich.png: $error");
                                  return Icon(
                                    Icons.group_add_rounded, 
                                    size: 24,
                                    color: context.colors.primary,
                                  );
                                },
                              ),
                              const SizedBox(width: 12),
                              Text(
                                "Join Plur Test Users",
                                style: TextStyle(
                                  fontFamily: 'SF Pro Rounded',
                                  color: context.colors.primary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Hint text with paste option
                      GestureDetector(
                        onTap: _pasteJoinLink,
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 4,
                          children: [
                            Flexible(
                              child: Text(
                                localization.haveInviteLink,
                                style: TextStyle(
                                  fontFamily: 'SF Pro Rounded',
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                  color: context.colors.dimmed,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Icon(
                              Icons.content_paste_rounded,
                              size: 16,
                              color: context.colors.accent,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
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
  
  Future<void> _pasteJoinLink() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      final clipboardText = clipboardData?.text?.trim();
      
      if (clipboardText != null && mounted) {
        // Make sure to await the async method
        bool success = await CommunityJoinUtil.parseAndJoinCommunity(context, clipboardText);
        
        if (!success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("No valid community link in clipboard"),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      // Handle clipboard permission errors
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Cannot access clipboard. Please interact with the page first or use the 'Join Community' option."),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }
  
  /// Joins the Plur Test Users community group
  void _joinTestUsersGroup() {
    const String testUsersGroupId = "R6PCSLSWB45E";
    const String testUsersGroupLink = "plur://join-community?group-id=R6PCSLSWB45E&code=Z2PWD5ML";
    
    // Check if already a member
    final listProvider = Provider.of<ListProvider>(context, listen: false);
    if (listProvider.isGroupMember(
      JoinGroupParameters("wss://communities.nos.social", testUsersGroupId)
    )) {
      // Already a member, just close the dialog and navigate to the group
      Navigator.of(context).pop(); // Close dialog
      
      // Show message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You're already a member of the Plur Test Users group."),
          duration: Duration(seconds: 2),
        ),
      );
      
      // Navigate to the group
      final groupId = GroupIdentifier("wss://communities.nos.social", testUsersGroupId);
      RouterUtil.router(context, RouterPath.groupDetail, groupId);
      return;
    }
    
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
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close dialog without joining
              },
              child: Text(
                "Cancel",
                style: TextStyle(
                  color: colors.secondaryText,
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
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
                final success = await CommunityJoinUtil.parseAndJoinCommunity(context, testUsersGroupLink);
                
                if (!success && mounted) {
                  // Show error message if joining failed
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Failed to join test users group. Please try again later."),
                      duration: Duration(seconds: 3),
                    ),
                  );
                } else if (mounted) {
                  // Close sheet if we're still open
                  Navigator.of(context).pop();
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
}