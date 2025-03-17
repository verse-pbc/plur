import 'package:flutter/material.dart';
import 'package:nostrmo/data/metadata.dart';
import 'package:nostrmo/nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/component/user/user_pic_widget.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/util/theme_util.dart';
import 'group_member_info_widget.dart';

class GroupMemberItemWidget extends StatelessWidget {
  final GroupIdentifier groupIdentifier;
  final String pubkey;
  final Metadata? metadata;
  final bool isAdmin;
  final double userPicWidth = 30;

  const GroupMemberItemWidget({
    super.key,
    required this.groupIdentifier,
    required this.pubkey,
    required this.metadata,
    this.isAdmin = false,
  });

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);

    return GestureDetector(
      onTap: () {
        RouterUtil.router(context, RouterPath.USER, pubkey);
      },
      child: Column(
        children: [
          Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(
              left: Base.basePadding,
              right: Base.basePadding,
              top: Base.basePaddingHalf,
              bottom: Base.basePaddingHalf,
            ),
            color: themeData.customColors.loginBgColor,
            child: Row(
              children: [
                Container(
                  margin: const EdgeInsets.only(right: Base.basePaddingHalf),
                  child: UserPicWidget(pubkey: pubkey, width: userPicWidth),
                ),
                Expanded(
                  child: GroupMemberInfoWidget(
                    pubkey: pubkey,
                    metadata: metadata,
                    isAdmin: isAdmin,
                  ),
                ),
              ],
            ),
          ),
          Container(
            color: themeData.customColors.loginBgColor,
            child: Divider(
              height: 1,
              color: themeData.customColors.feedBgColor,
            ),
          ),
        ],
      ),
    );
  }
}
