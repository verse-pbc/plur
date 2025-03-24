import 'package:flutter/material.dart';
import 'package:nostrmo/nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/router/group/invite_people_widget.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:nostrmo/util/theme_util.dart';
import 'package:nostrmo/util/string_code_generator.dart';
import 'package:nostrmo/provider/list_provider.dart';

class InviteToCommunityDialog extends StatefulWidget {
  final GroupIdentifier groupIdentifier;
  final ListProvider listProvider;

  const InviteToCommunityDialog({
    super.key,
    required this.groupIdentifier,
    required this.listProvider,
  });

  static Future<void> show(BuildContext context,
      GroupIdentifier groupIdentifier, ListProvider listProvider) async {
    await showDialog<void>(
      context: context,
      useRootNavigator: false,
      builder: (_) {
        return InviteToCommunityDialog(
          groupIdentifier: groupIdentifier,
          listProvider: listProvider,
        );
      },
    );
  }

  @override
  State<InviteToCommunityDialog> createState() =>
      _InviteToCommunityDialogState();
}

class _InviteToCommunityDialogState extends State<InviteToCommunityDialog> {
  late final String inviteCode;
  late final String inviteLink;

  @override
  void initState() {
    super.initState();
    inviteCode = StringCodeGenerator.generateInviteCode();
    inviteLink = widget.listProvider
        .createInviteLink(widget.groupIdentifier, inviteCode);
  }

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
                          groupIdentifier: widget.groupIdentifier,
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
