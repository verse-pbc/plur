import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostr_sdk/nip29/group_identifier.dart';

class InvitePeopleWidget extends StatelessWidget {
  final String shareableLink;
  final GroupIdentifier groupIdentifier;
  final bool showCreatePostButton;

  const InvitePeopleWidget({
    super.key,
    required this.shareableLink,
    required this.groupIdentifier,
    this.showCreatePostButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Invite people to join your community',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
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
                      color: theme.colorScheme.primary,
                      decoration: TextDecoration.underline,
                      decorationColor: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: shareableLink));
                  BotToast.showText(
                    text: 'Link copied to clipboard',
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
                      context, RouterPath.GROUP_DETAIL, groupIdentifier);
                },
                highlightColor: theme.primaryColor.withOpacity(0.2),
                child: Container(
                  color: theme.primaryColor,
                  height: 40,
                  alignment: Alignment.center,
                  child: const Text(
                    'Create your first post',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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
