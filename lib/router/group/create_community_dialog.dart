import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/router/group/create_community_widget.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:nostrmo/util/theme_util.dart';
import 'package:provider/provider.dart';
import 'package:nostrmo/provider/list_provider.dart';
import 'package:flutter/services.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:nostrmo/generated/l10n.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostrmo/provider/relay_provider.dart';

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
                  // GroupDetailWidget.showTooltipOnGroupCreation = true;
                  RouterUtil.router(
                      context, RouterPath.GROUP_DETAIL, groupIdentifier);
                },
                highlightColor: theme.primaryColor.withOpacity(0.2),
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

  bool _showInviteCommunity = false;

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);

    return Scaffold(
      backgroundColor: ThemeUtil.getDialogCoverColor(themeData),
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          GestureDetector(
            onTap: () => RouterUtil.back(context),
            child: Container(color: Colors.black54),
          ),
          SingleChildScrollView(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              alignment: Alignment.center,
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.all(20),
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
                          onPressed: () => RouterUtil.back(context),
                        ),
                      ),
                      if (!_showInviteCommunity)
                        CreateCommunityWidget(
                            onCreateCommunity: _onCreateCommunity),
                      if (_showInviteCommunity)
                        OldInvitePeopleWidget(
                          shareableLink: _communityInviteLink ?? '',
                          groupIdentifier: _groupIdentifier!,
                          showCreatePostButton: true,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onCreateCommunity(String communityName) async {
    final listProvider = Provider.of<ListProvider>(context, listen: false);
    
    // Show a loading indicator
    final cancelLoading = BotToast.showLoading();
    
    try {
      // Create an actual group and get the invite link
      print("Creating community: $communityName");
      final (inviteLink, groupId) = await listProvider.createGroupAndGenerateInvite(communityName);
      
      if (inviteLink != null && groupId != null) {
        print("Group created: $groupId");
        print("Invite link: $inviteLink");
        
        setState(() {
          _communityInviteLink = inviteLink;
          _groupIdentifier = groupId;
          _showInviteCommunity = true;
        });
      } else {
        print("Failed to create group - null values returned");
        BotToast.showText(text: "Failed to create community. Please try again.");
      }
    } catch (e) {
      print("Error creating community: $e");
      BotToast.showText(text: "Error creating community: $e");
    } finally {
      // Hide the loading indicator
      cancelLoading();
    }
  }
}