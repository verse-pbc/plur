import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/generated/l10n.dart';
import 'package:nostrmo/router/group/join_community_widget.dart';
import 'package:nostrmo/router/group/find_community_widget.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:nostrmo/util/theme_util.dart';
import 'package:nostrmo/router/group/invite_people_widget.dart';
import 'package:nostrmo/provider/list_provider.dart';
import 'package:nostrmo/util/community_join_util.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:nostrmo/consts/router_path.dart';

/// This is a version of InvitePeopleWidget kept for backward compatibility
class OldInvitePeopleWidget extends StatelessWidget {
  final String shareableLink;
  final GroupIdentifier groupIdentifier;
  final bool showCreatePostButton;

  const OldInvitePeopleWidget({
    super.key,
    required this.shareableLink,
    required this.groupIdentifier,
    this.showCreatePostButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customColors = theme.customColors;
    final localization = S.of(context);

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localization.Invite_people_to_join,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: customColors.primaryForegroundColor, 
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: RichText(
                  text: TextSpan(
                    text: shareableLink,
                    style: TextStyle(
                      fontSize: 16,
                      color: customColors.accentColor,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.copy, color: customColors.accentColor),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: shareableLink));
                  BotToast.showText(
                    text: localization.Copy_success,
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 40),
          if (showCreatePostButton)
            Center(
              child: InkWell(
                onTap: () {
                  RouterUtil.back(context);
                  RouterUtil.router(
                      context, RouterPath.groupDetail, groupIdentifier);
                },
                highlightColor: theme.primaryColor.withAlpha(51), // ~0.2 opacity
                child: Container(
                  color: theme.primaryColor,
                  height: 40,
                  alignment: Alignment.center,
                  child: Text(
                    'Create your first post',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: customColors.buttonTextColor,
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

// Track which view is currently active
enum DialogView {
  chooseOption,  // Initial choice screen
  createCommunity, // Create a new community
  joinCommunity,  // Join existing community
  findCommunity,  // Find public communities
  invitePeople  // Show invite people after creation
}

class CreateCommunityDialog extends StatefulWidget {
  const CreateCommunityDialog({super.key});

  static Future<void> show(BuildContext context) async {
    await showDialog<void>(
      context: context,
      useRootNavigator: false,
      builder: (_) {
        return const CreateCommunityDialog();
      },
    );
  }

  @override
  State<CreateCommunityDialog> createState() => _CreateCommunityDialogState();
}

class _CreateCommunityDialogState extends State<CreateCommunityDialog> {
  // We only need to track the current view and loading state
  DialogView _currentView = DialogView.chooseOption;
  bool _isProcessing = false; // Flag to prevent multiple submissions

  // Create a controller here so it persists between rebuilds
  final TextEditingController _communityNameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);

    return AbsorbPointer(
      absorbing: _isProcessing, // Block all input when processing
      child: Scaffold(
        backgroundColor: ThemeUtil.getDialogCoverColor(themeData),
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            GestureDetector(
              onTap: () => RouterUtil.back(context),
              child: Container(color: Colors.black54),
            ),

            Center(
              child: SingleChildScrollView(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: themeData.customColors.cardBgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Align(
                        alignment: Alignment.topRight,
                        child: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            RouterUtil.back(context);
                          },
                        ),
                      ),
                      // Show different content based on current view
                      if (_currentView == DialogView.chooseOption)
                        _buildOptionChoiceView(themeData),
                      if (_currentView == DialogView.createCommunity)
                        _buildCreateCommunityView(themeData),
                      if (_currentView == DialogView.joinCommunity)
                        JoinCommunityWidget(
                            onJoinCommunity: _onJoinCommunity),
                      if (_currentView == DialogView.findCommunity)
                        FindCommunityWidget(
                            onJoinCommunity: _onJoinCommunity),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // New method to build create community view with direct control over the loading state
  Widget _buildCreateCommunityView(ThemeData themeData) {
    final localization = S.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              localization.Create_your_community,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Text(localization.Name_your_community),
            const SizedBox(height: 10),
            TextField(
              controller: _communityNameController,
              decoration: InputDecoration(
                hintText: localization.community_name,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _onCreateCommunity(_communityNameController.text),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: themeData.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                foregroundColor: Colors.white,
              ),
              child: Text(
                localization.Confirm,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build the option choice view with three buttons
  Widget _buildOptionChoiceView(ThemeData themeData) {
    final l10n = S.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          l10n.Communities,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 30),
        // Create new community option
        _buildOptionButton(
          icon: Icons.add_circle_outline,
          title: l10n.Create_Group,
          description: "Start a private community that you'll be the admin of",
          onTap: () {
            setState(() {
              _currentView = DialogView.createCommunity;
            });
          },
          themeData: themeData,
        ),
        const SizedBox(height: 15),
        // Join existing community option
        _buildOptionButton(
          icon: Icons.group_add,
          title: l10n.Join_Group,
          description: "Paste an invitation link to join a community",
          onTap: () {
            setState(() {
              _currentView = DialogView.joinCommunity;
            });
          },
          themeData: themeData,
        ),
        const SizedBox(height: 15),
        // Find community option
        _buildOptionButton(
          icon: Icons.search,
          title: l10n.Find_Group,
          description: l10n.Search_for_public_groups,
          onTap: () {
            setState(() {
              _currentView = DialogView.findCommunity;
            });
          },
          themeData: themeData,
        ),
      ],
    );
  }
  
  // Helper to build consistent option buttons
  Widget _buildOptionButton({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
    required ThemeData themeData,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: themeData.cardColor,
          border: Border.all(color: themeData.dividerColor.withAlpha(128)), // ~0.5 opacity
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 30, color: themeData.primaryColor),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: themeData.textTheme.bodyMedium?.color?.withAlpha(179), // ~0.7 opacity
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: themeData.iconTheme.color?.withAlpha(128), // ~0.5 opacity
            ),
          ],
        ),
      ),
    );
  }

  // Handle creating a new community - SIMPLEST IMPLEMENTATION
  void _onCreateCommunity(String communityName) async {
    if (_isProcessing) return; // Prevent multiple submissions
    if (communityName.trim().isEmpty) return; // No empty names
    
    // Set processing flag immediately to prevent multiple submissions
    setState(() {
      _isProcessing = true;
    });
    
    final listProvider = Provider.of<ListProvider>(context, listen: false);

    try {
      final groupDetails =
          await listProvider.createGroupAndGenerateInvite(communityName);

      if (mounted) {
        // Close this dialog first
        Navigator.of(context).pop();
        
        // Then show the new invite dialog as a full page
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => InvitePeopleWidget(
              shareableLink: groupDetails.$1,
              groupIdentifier: groupDetails.$2,
              showCreatePostButton: true,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false; // Reset only on error
        });
        
        // If an error occurs, we need to show an error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to create community: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  // Handle joining an existing community
  void _onJoinCommunity(String joinLink) async {
    if (_isProcessing) return; // Prevent multiple submissions
    
    setState(() {
      _isProcessing = true;
    });
    
    bool success = CommunityJoinUtil.parseAndJoinCommunity(context, joinLink);
    
    if (success) {
      // Close the dialog
      RouterUtil.back(context);
    } else {
      setState(() {
        _isProcessing = false;
      });
      _showError("Invalid community link format. Please check and try again.");
    }
  }
  
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }
  
  @override
  void dispose() {
    _communityNameController.dispose();
    super.dispose();
  }
}