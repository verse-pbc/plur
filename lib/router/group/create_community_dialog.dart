import 'package:flutter/material.dart';
import 'package:nostr_sdk/event.dart';
import 'package:nostr_sdk/event_kind.dart';
import 'package:nostr_sdk/nip29/group_identifier.dart';
import 'package:nostrmo/router/group/create_community_widget.dart';
import 'package:nostrmo/util/invite_util.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:nostrmo/util/theme_util.dart';
import 'package:nostrmo/router/group/invite_people_widget.dart';
import 'package:nostrmo/main.dart';

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

  void _onCreateCommunity(String communityName) {
    final inviteCode = InviteUtil.generateInviteCode();
    final groupIdentifier =
        GroupIdentifier(communityName, 'wss://communities.nos.social');
    setState(() {
      _communityInviteLink =
          'plur://join-community?group-id=$communityName&code=$inviteCode';
      _showInviteCommunity = true;
    });
    publishCreateInviteEvent(groupIdentifier, inviteCode);
  }

  Future<Event?> publishCreateInviteEvent(
      GroupIdentifier groupIdentifier, String inviteCode,
      {List<String>? roles}) async {
    final tags = [
      ["h", groupIdentifier.groupId],
      ["code", inviteCode],
    ];

    // Add roles if provided, default to "member"
    if (roles != null && roles.isNotEmpty) {
      tags.add(["roles", ...roles]);
    } else {
      tags.add(["roles", "member"]);
    }

    final event = Event(
      nostr!.publicKey,
      EventKind.GROUP_CREATE_INVITE,
      tags,
      "", // Empty content as per example
    );

    // Send to specific relay for the community
    return await nostr!.sendEvent(
      event,
      tempRelays: [groupIdentifier.host],
      targetRelays: [groupIdentifier.host],
    );
  }
}
