import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/component/main_btn_widget.dart';
import 'package:nostrmo/generated/l10n.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:provider/provider.dart';
import 'package:nostrmo/provider/list_provider.dart';

class InvitePeopleWidget extends StatelessWidget {
  final String? shareableLink;
  final GroupIdentifier? groupIdentifier;
  final bool showCreatePostButton;

  const InvitePeopleWidget({
    super.key,
    this.shareableLink,
    this.groupIdentifier,
    this.showCreatePostButton = false,
  });

  // Helper method to get localized text with a fallback
  String _getText(BuildContext context, String key, String fallback) {
    try {
      // Try to access the localized string dynamically
      switch (key) {
        case 'community_created':
          return S.of(context).Invite_people_to_join;
        case 'next_steps':
          return 'Next steps';
        case 'add_guidelines':
          return 'Add guidelines';
        case 'guidelines_description':
          return 'Set rules and expectations for your community';
        case 'customize_community':
          return 'Customize your community';
        case 'customize_description':
          return 'Add images and details to make your community stand out';
        case 'invite_people':
          return 'Invite people';
        case 'share_invite_link':
          return 'Share the link below to invite others to join';
        case 'invitation_link':
          return 'Invitation link';
        case 'link_copied':
          return S.of(context).Copy_success;
        case 'go_to_community':
          return 'Go to community';
        default:
          return fallback;
      }
    } catch (e) {
      return fallback;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the group identifier
    final groupId = groupIdentifier ?? RouterUtil.routerArgs(context);
    if (groupId == null || groupId is! GroupIdentifier) {
      Navigator.of(context).pop();
      return const SizedBox.shrink();
    }

    // Generate an invite link
    String inviteLink = shareableLink ?? "plur://join-community?group-id=${groupId.groupId}";
    
    if (inviteLink.isEmpty) {
      try {
        final listProvider = Provider.of<ListProvider>(context, listen: false);
        inviteLink = listProvider.createInviteLink(
          groupId, 
          DateTime.now().millisecondsSinceEpoch.toString()
        );
      } catch (e) {
        // Fallback to basic link if provider isn't available
      }
    }
    
    // Get screen dimensions
    final screenSize = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: Container(
            width: screenSize.width * 0.9, // Not full width
            constraints: const BoxConstraints(
              maxWidth: 500, // Maximum width for larger screens
            ),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(26), // ~0.1 opacity
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with back button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _getText(context, 'community_created', 'Community created!'),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Success icon
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.green.withAlpha(26), // ~0.1 opacity
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 40,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Next steps section
                  Text(
                    _getText(context, 'next_steps', 'Next steps'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Setup steps
                  _buildSetupStep(
                    context,
                    icon: Icons.description,
                    title: _getText(context, 'add_guidelines', 'Add guidelines'),
                    description: _getText(context, 'guidelines_description', 'Set rules and expectations for your community'),
                  ),
                  
                  _buildSetupStep(
                    context,
                    icon: Icons.edit,
                    title: _getText(context, 'customize_community', 'Customize your community'),
                    description: _getText(context, 'customize_description', 'Add images and details to make your community stand out'),
                  ),
                  
                  _buildSetupStep(
                    context,
                    icon: Icons.people,
                    title: _getText(context, 'invite_people', 'Invite people'),
                    description: _getText(context, 'share_invite_link', 'Share the link below to invite others to join'),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Invite link section
                  Text(
                    _getText(context, 'invitation_link', 'Invitation link'),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withAlpha(128), // ~0.5 opacity
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            inviteLink,
                            style: theme.textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.copy,
                            color: theme.colorScheme.primary,
                          ),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: inviteLink));
                            BotToast.showText(text: _getText(context, 'link_copied', 'Link copied!'));
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: MainBtnWidget(
                          onTap: () {
                            Navigator.of(context).pop();
                            RouterUtil.router(context, RouterPath.groupDetail, groupId);
                          },
                          text: _getText(context, 'go_to_community', 'Go to community'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildSetupStep(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withAlpha(26), // ~0.1 opacity
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withAlpha(179), // ~0.7 opacity
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}