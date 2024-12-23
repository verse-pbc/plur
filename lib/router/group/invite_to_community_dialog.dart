import 'package:flutter/material.dart';
import 'package:nostr_sdk/nip29/group_identifier.dart';
import 'package:nostrmo/router/group/invite_people_widget.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:nostrmo/util/theme_util.dart';
import 'package:nostrmo/util/string_code_generator.dart';

class InviteToCommunityDialog extends StatelessWidget {
  final GroupIdentifier groupIdentifier;
  final String inviteCode;

  InviteToCommunityDialog({super.key, required this.groupIdentifier})
      : inviteCode = StringCodeGenerator.generateInviteCode();

  static Future<void> show(
      BuildContext context, GroupIdentifier groupIdentifier) async {
    await showDialog<void>(
      context: context,
      useRootNavigator: false,
      builder: (_) {
        return InviteToCommunityDialog(groupIdentifier: groupIdentifier);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    Color cardColor = themeData.cardColor;
    final inviteLink =
        'plur://join-community?group-id=${groupIdentifier.groupId}&code=$inviteCode';

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
                          onPressed: () => RouterUtil.back(context),
                        ),
                      ),
                      InvitePeopleWidget(
                          groupIdentifier: groupIdentifier,
                          shareableLink: inviteLink,
                          showCreatePostButton: false),
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
}
