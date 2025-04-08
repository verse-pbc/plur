import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/router/group/create_community_widget.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:nostrmo/util/theme_util.dart';
import 'package:nostrmo/router/group/invite_people_widget.dart';
import 'package:nostrmo/provider/list_provider.dart';
import 'package:provider/provider.dart';

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
  bool _showInviteCommunity = false;
  String? _communityInviteLink;
  GroupIdentifier? _groupIdentifier;
  bool _isCreating = false;

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
                    if (!_showInviteCommunity)
                      CreateCommunityWidget(
                          onCreateCommunity: _onCreateCommunity),
                    if (_showInviteCommunity)
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
          if (_isCreating && !_showInviteCommunity)
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

  void _onCreateCommunity(String communityName) async {
    final listProvider = Provider.of<ListProvider>(context, listen: false);

    try {
      final groupDetails =
          await listProvider.createGroupAndGenerateInvite(communityName);

      if (mounted) {
        setState(() {
          _communityInviteLink = groupDetails.$1;
          _groupIdentifier = groupDetails.$2;
          _showInviteCommunity = true;
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
}
