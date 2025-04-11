import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/generated/l10n.dart';
import 'package:nostrmo/router/group/create_community_widget.dart';
import 'package:nostrmo/router/group/join_community_widget.dart';
import 'package:nostrmo/router/group/find_community_widget.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:nostrmo/util/theme_util.dart';
import 'package:nostrmo/router/group/invite_people_widget.dart';
import 'package:nostrmo/provider/list_provider.dart';
import 'package:nostrmo/data/join_group_parameters.dart';
import 'package:nostrmo/util/community_join_util.dart';
import 'package:provider/provider.dart';

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
  String? _communityInviteLink;
  GroupIdentifier? _groupIdentifier;
  bool _isCreating = false;
  DialogView _currentView = DialogView.chooseOption;

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    Color cardColor = themeData.cardColor;

    return Scaffold(
      backgroundColor: ThemeUtil.getDialogCoverColor(themeData),
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          GestureDetector(
            onTap: () {
              RouterUtil.back(context);
            },
            child: Container(
              color: Colors.black54,
            ),
          ),

          Center(
            child: SingleChildScrollView(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: cardColor,
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
                      CreateCommunityWidget(
                          onCreateCommunity: _onCreateCommunity),
                    if (_currentView == DialogView.joinCommunity)
                      JoinCommunityWidget(
                          onJoinCommunity: _onJoinCommunity),
                    if (_currentView == DialogView.findCommunity)
                      FindCommunityWidget(
                          onJoinCommunity: _onJoinCommunity),
                    if (_currentView == DialogView.invitePeople)
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

          // Full-screen loading overlay (optional, for very long operations)
          if (_isCreating && _currentView != DialogView.invitePeople)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: CircularProgressIndicator(
                  color: themeData.primaryColor,
                ),
              ),
            ),
        ],
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
          border: Border.all(color: themeData.dividerColor.withOpacity(0.5)),
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
                      color: themeData.textTheme.bodyMedium?.color?.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: themeData.iconTheme.color?.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }

  // Handle creating a new community
  void _onCreateCommunity(String communityName) async {
    final listProvider = Provider.of<ListProvider>(context, listen: false);

    setState(() {
      _isCreating = true;
    });

    try {
      final groupDetails =
          await listProvider.createGroupAndGenerateInvite(communityName);

      if (mounted) {
        setState(() {
          _communityInviteLink = groupDetails.$1;
          _groupIdentifier = groupDetails.$2;
          _currentView = DialogView.invitePeople;
          _isCreating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }
  
  // Handle joining an existing community
  void _onJoinCommunity(String joinLink) async {
    bool success = CommunityJoinUtil.parseAndJoinCommunity(context, joinLink);
    
    if (success) {
      // Close the dialog
      RouterUtil.back(context);
    } else {
      _showError("Invalid community link format. Please check and try again.");
    }
  }
  
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }
}
