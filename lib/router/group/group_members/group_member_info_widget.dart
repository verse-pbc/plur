import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/util/theme_util.dart';

import '../../../component/group/admin_tag_widget.dart';
import '../../../data/user.dart';

/// Displays some info about a group member.
class GroupMemberInfoWidget extends StatelessWidget {
  final String pubkey;
  final User? user;
  final bool isAdmin;

  const GroupMemberInfoWidget({
    super.key,
    required this.pubkey,
    required this.user,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user?.displayName ??
                    user?.name ??
                    Nip19.encodeSimplePubKey(pubkey),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: themeData.textTheme.bodyLarge?.color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                user?.nip05 ?? "",
                style: TextStyle(
                  fontSize: themeData.textTheme.bodySmall!.fontSize,
                  color: themeData.customColors.dimmedColor,
                ),
              ),
            ],
          ),
        ),
        if (isAdmin) const AdminTagWidget(),
      ],
    );
  }
}
