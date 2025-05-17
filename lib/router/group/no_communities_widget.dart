import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nostrmo/generated/l10n.dart';
import 'package:nostrmo/router/group/create_community_dialog.dart';
import 'package:nostrmo/util/theme_util.dart';
import 'package:nostrmo/util/community_join_util.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:nostrmo/provider/list_provider.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:nostrmo/data/join_group_parameters.dart';
import 'package:nostrmo/model/group_identifier.dart';
import 'package:nostrmo/consts/router_path.dart';

// Used for logging
import 'dart:developer' as developer;

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
  
  // Method to save state when user dismisses the dialog
  Future<void> _dismissDialog() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dismissedDialogKey, true);
    
    // Pop the dialog if in a dialog, otherwise just hide this widget
    if (mounted) {
      Navigator.of(context).canPop() 
          ? Navigator.of(context).pop() 
          : setState(() {}); // Force refresh
    }
  }

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

    return Center(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.all(30.0),
            child: Card(
              elevation: 4,
              color: context.colors.cardBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  // Close button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: Icon(
                        Icons.close,
                        color: context.colors.secondaryText,
                      ),
                      onPressed: _dismissDialog,
                    ),
                  ),
                  // Main content
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Title section
                        Text(
                          localization.communities,
                          style: TextStyle(
                            fontSize: 24.0,
                            fontWeight: FontWeight.bold,
                            color: context.colors.primaryText,
                          ),
                          textAlign: TextAlign.center,
                        ),
                    const SizedBox(height: 24),

                    // Image section
                    Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: context.colors.dimmed.withAlpha((255 * 0.5).round()),
                      ),
                      child: Center(
                        child: ColorFiltered(
                          colorFilter: ColorFilter.mode(
                            context.colors.dimmed,
                            BlendMode.srcIn,
                          ),
                          child: Image.asset(
                            "assets/imgs/welcome_groups.png",
                            width: 120,
                            height: 120,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.group,
                                size: 120,
                                color: context.colors.dimmed,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Create community section
                    Text(
                      localization.startOrJoinACommunity,
                      style: TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                        color: context.colors.primaryText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      localization.connectWithOthers,
                      style: TextStyle(
                        fontSize: 16.0,
                        color: context.colors.primaryText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Action buttons
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: _isCreatingCommunity
                          ? Center(
                              child: CircularProgressIndicator(
                                color: context.colors.accent,
                              ),
                            )
                          : PrimaryButtonWidget(
                              text: localization.createGroup,
                              borderRadius: 8,
                              onTap: _createCommunity,
                            ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Join Test Users Group button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: _joinTestUsersGroup,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: context.colors.accent),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          "Join Plur Test Users",
                          style: TextStyle(
                            color: context.colors.accent,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Hint text with paste option
                    GestureDetector(
                      onTap: _pasteJoinLink,
                      child: Wrap( // Replace Row with Wrap to prevent overflow
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 4, // Horizontal spacing between items
                        children: [
                          Flexible(
                            child: Text(
                              localization.haveInviteLink,
                              style: TextStyle(
                                fontSize: 14.0,
                                fontStyle: FontStyle.italic,
                                color: context.colors.dimmed,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.content_paste,
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
    // Capture BuildContext before async operation
    final BuildContext currentContext = context;
    final bool contextMounted = mounted;
    
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      final clipboardText = clipboardData?.text?.trim();
      
      if (clipboardText != null) {
        if (!contextMounted) return; // Check if widget is still mounted
        
        bool success = CommunityJoinUtil.parseAndJoinCommunity(currentContext, clipboardText);
        
        if (!success && mounted) {
          ScaffoldMessenger.of(currentContext).showSnackBar(
            SnackBar(
              content: Text(S.of(currentContext).noValidCommunityLink),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      // Handle clipboard permission errors
      if (contextMounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(
            content: Text(S.of(currentContext).cannotAccessClipboard),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
  
  /// Joins the Plur Test Users community group
  void _joinTestUsersGroup() {
    const String testUsersGroupId = "R6PCSLSWB45E";
    const String testUsersGroupLink = "plur://join-community?group-id=R6PCSLSWB45E&code=Z2PWD5ML";
    
    developer.log("_joinTestUsersGroup: Getting ListProvider to check membership", name: "NoCommunitiesWidget");
    
    // Check if already a member
    final listProvider = Provider.of<ListProvider>(context, listen: false);
    
    // Create join parameters with correct host and groupId
    final joinParams = JoinGroupParameters("wss://communities.nos.social", testUsersGroupId);
    
    developer.log("_joinTestUsersGroup: Created JoinGroupParameters with host=${joinParams.host}, groupId=${joinParams.groupId}", name: "NoCommunitiesWidget");
    
    // Control whether to check membership or always show dialog
    const bool alwaysShowJoinDialog = true; // Set to false to enable the membership check
    
    // Check if user is already a member of the test group
    bool isMember = alwaysShowJoinDialog ? false : listProvider.isGroupMember(joinParams);
    
    developer.log("_joinTestUsersGroup: isMember result: $isMember (always show dialog: $alwaysShowJoinDialog)", name: "NoCommunitiesWidget");
    
    if (isMember) {
      // Already a member, just navigate to the group
      developer.log("User is already a member of the Plur Test Users group, navigating to detail view", name: "NoCommunitiesWidget");
      
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
    
    developer.log("User is not a member of the Plur Test Users group (or dialog forced), showing join dialog", name: "NoCommunitiesWidget");
    
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
                developer.log("Join dialog: Cancel button pressed", name: "NoCommunitiesWidget");
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
              onPressed: () {
                developer.log("Join dialog: Join Group button pressed", name: "NoCommunitiesWidget");
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
                developer.log("Attempting to join group using CommunityJoinUtil.parseAndJoinCommunity", name: "NoCommunitiesWidget");
                bool success = CommunityJoinUtil.parseAndJoinCommunity(context, testUsersGroupLink);
                developer.log("Join result: $success", name: "NoCommunitiesWidget");
                
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
}