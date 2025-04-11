import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nostrmo/generated/l10n.dart';
import 'package:nostrmo/router/group/create_community_dialog.dart';
import 'package:nostrmo/util/theme_util.dart';
import 'package:nostrmo/component/primary_button_widget.dart';
import 'package:nostrmo/util/community_join_util.dart';

class NoCommunitiesWidget extends StatefulWidget {
  const NoCommunitiesWidget({super.key});

  @override
  State<NoCommunitiesWidget> createState() => _NoCommunitiesWidgetState();
}

class _NoCommunitiesWidgetState extends State<NoCommunitiesWidget> {
  bool _isCreatingCommunity = false;

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final localization = S.of(context);

    return Center(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.all(30.0),
            child: Card(
              elevation: 4,
              color: themeData.customColors.cardBgColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Title section
                    Text(
                      localization.Communities,
                      style: TextStyle(
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                        color: themeData.customColors.primaryForegroundColor,
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
                        color: themeData.customColors.dimmedColor.withOpacity(0.5),
                      ),
                      child: Center(
                        child: ColorFiltered(
                          colorFilter: ColorFilter.mode(
                            themeData.customColors.dimmedColor,
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
                                color: themeData.customColors.dimmedColor,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Create community section
                    Text(
                      localization.Start_or_join_a_community,
                      style: TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                        color: themeData.customColors.primaryForegroundColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      localization.Connect_with_others,
                      style: TextStyle(
                        fontSize: 16.0,
                        color: themeData.customColors.primaryForegroundColor,
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
                                color: themeData.customColors.accentColor,
                              ),
                            )
                          : PrimaryButtonWidget(
                              text: localization.Create_Group,
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
                          side: BorderSide(color: themeData.customColors.accentColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          "Join Plur Test Users",
                          style: TextStyle(
                            color: themeData.customColors.accentColor,
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
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            localization.Have_invite_link,
                            style: TextStyle(
                              fontSize: 14.0,
                              fontStyle: FontStyle.italic,
                              color: themeData.customColors.dimmedColor,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.content_paste,
                            size: 16,
                            color: themeData.customColors.accentColor,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
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
      
      if (clipboardText != null) {
        bool success = CommunityJoinUtil.parseAndJoinCommunity(context, clipboardText);
        
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
    const String testUsersGroupLink = "plur://join-community?group-id=R6PCSLSWB45E&code=Z2PWD5ML";
    
    // Show confirmation dialog first
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        // Get colors from Plur theme
        final plurBackground = const Color(0xFF231F32); // PlurColors.cardBackground
        final plurPurple = const Color(0xFF7445FE);     // PlurColors.primaryPurple
        final plurPrimaryText = const Color(0xFFB5A0E1); // PlurColors.primaryText
        final plurHighlightText = const Color(0xFFECE2FD); // PlurColors.highlightText
        final plurSecondaryText = const Color(0xFF63518E); // PlurColors.secondaryText
        
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
                    backgroundColor: plurPurple.withOpacity(0.9),
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