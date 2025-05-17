import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nostrmo/generated/l10n.dart';
import 'package:nostrmo/features/create_community/create_community_dialog.dart';
import 'package:nostrmo/theme/app_colors.dart';
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
    final colors = context.colors;
    final localization = S.of(context);

    return Center(
      child: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Title and image section
              Text(
                localization.noCommunitiesYet,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: colors.highlightText,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                localization.connectWithOthers,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.secondaryText,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Image section
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.surfaceVariant,
                ),
                child: Center(
                  child: Image.asset(
                    "assets/imgs/welcome_groups.png",
                    width: 120,
                    height: 120,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.group,
                        size: 120,
                        color: colors.dimmed,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Action buttons
              SizedBox(
                width: double.infinity,
                height: 50,
                child: _isCreatingCommunity
                    ? Center(
                        child: CircularProgressIndicator(
                          color: colors.primary,
                        ),
                      )
                    : PrimaryButtonWidget(
                        text: localization.createCommunity,
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
                    side: BorderSide(color: colors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    "Join Holis Test Users",
                    style: TextStyle(
                      color: colors.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'SF Pro Rounded',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Hint text with paste option
              GestureDetector(
                onTap: _pasteJoinLink,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.content_paste_rounded,
                        size: 20,
                        color: colors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        localization.pasteInviteLink,
                        style: TextStyle(
                          fontSize: 14.0,
                          color: colors.primary,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'SF Pro Rounded',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
            SnackBar(
              content: Text(S.of(context).noValidCommunityLink),
              backgroundColor: context.colors.error,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      // Handle clipboard permission errors
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).cannotAccessClipboard),
            backgroundColor: context.colors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
  
  /// Joins the Holis Test Users community group
  void _joinTestUsersGroup() {
    const String testUsersGroupLink = "plur://join-community?group-id=R6PCSLSWB45E&code=Z2PWD5ML";
    
    // Show confirmation dialog first
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        // Get colors from app theme
        final colors = context.colors;
        
        return AlertDialog(
          backgroundColor: colors.modalBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            "Join Holis Test Users Group",
            style: TextStyle(
              color: colors.highlightText,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'SF Pro Rounded',
            ),
          ),
          content: Text(
            "Would you like to join the Holis Test Users community? "
            "This is a public group for testing features and connecting with other users.",
            style: TextStyle(
              color: colors.primaryText,
              fontSize: 16,
              fontFamily: 'SF Pro Rounded',
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
                  fontFamily: 'SF Pro Rounded',
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close dialog
                
                // Show loading indicator
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text("Joining Holis Test Users group..."),
                    duration: const Duration(seconds: 1),
                    backgroundColor: colors.primary.withOpacity(0.9),
                  ),
                );
                
                // Attempt to join the group
                bool success = CommunityJoinUtil.parseAndJoinCommunity(context, testUsersGroupLink);
                
                if (!success && mounted) {
                  // Show error message if joining failed
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text("Failed to join test users group. Please try again later."),
                      backgroundColor: colors.error,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.buttonText,
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
                  fontFamily: 'SF Pro Rounded',
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}