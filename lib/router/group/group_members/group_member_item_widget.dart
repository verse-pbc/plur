import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/component/user/user_pic_widget.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostrmo/generated/l10n.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/provider/group_provider.dart';
import 'package:nostrmo/router/group/group_members/member_card_dialog.dart';
import 'package:nostrmo/router/group/group_members/user_ban_dialog.dart';
import 'package:nostrmo/router/group/group_members/user_remove_dialog.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:nostrmo/util/theme_util.dart';
import 'package:provider/provider.dart';
import 'package:bot_toast/bot_toast.dart';

import '../../../data/user.dart';
import 'group_member_info_widget.dart';

/// Displays a member of a group in a list.
class GroupMemberItemWidget extends StatelessWidget {
  final GroupIdentifier groupIdentifier;
  final String pubkey;
  final User? user;
  final bool isAdmin;
  final double userPicWidth = 30;

  const GroupMemberItemWidget({
    super.key,
    required this.groupIdentifier,
    required this.pubkey,
    required this.user,
    this.isAdmin = false,
  });

  // Check if the current user is looking at their own profile
  bool get _isCurrentUser => nostr != null && pubkey == nostr!.publicKey;

  // Check if the current user is an admin of this group
  bool _isCurrentUserAdmin(BuildContext context) {
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    return nostr != null && groupProvider.isAdmin(nostr!.publicKey, groupIdentifier);
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final localization = S.of(context);
    final currentUserIsAdmin = _isCurrentUserAdmin(context);
    final displayName = user?.displayName ?? user?.name ?? Nip19.encodeSimplePubKey(pubkey);

    // Only show admin controls if current user is admin and not looking at themselves
    final canShowAdminControls = currentUserIsAdmin && !_isCurrentUser;

    return Column(
      children: [
        Container(
          color: themeData.customColors.loginBgColor,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: Base.basePadding,
              vertical: Base.basePaddingHalf,
            ),
            leading: UserPicWidget(pubkey: pubkey, width: userPicWidth),
            title: Text(
              displayName,
              style: themeData.textTheme.titleMedium,
            ),
            subtitle: isAdmin 
                ? Text(localization.groupAdmin, 
                    style: themeData.textTheme.bodySmall?.copyWith(color: Colors.blue))
                : null,
            trailing: canShowAdminControls 
                ? PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) => _handleAction(context, value),
                    itemBuilder: (context) => [
                      PopupMenuItem<String>(
                        value: 'remove',
                        child: Row(
                          children: [
                            const Icon(Icons.person_remove, color: Colors.red, size: 20),
                            const SizedBox(width: 8),
                            Text(localization.removeUser, style: const TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'ban',
                        child: Row(
                          children: [
                            const Icon(Icons.block, color: Colors.red, size: 20),
                            const SizedBox(width: 8),
                            Text(localization.banUser, style: const TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  )
                : null,
            onTap: () => MemberCardDialog.show(
              context,
              pubkey: pubkey,
              groupId: groupIdentifier,
              isAdmin: isAdmin,
            ),
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
    );
  }

  void _handleAction(BuildContext context, String action) {
    switch (action) {
      case 'remove':
        _showRemoveDialog(context);
        break;
      case 'ban':
        _showBanDialog(context);
        break;
    }
  }

  void _showRemoveDialog(BuildContext context) async {
    final result = await UserRemoveDialog.show(
      context,
      groupIdentifier,
      pubkey,
      userName: user?.name,
    );
    
    if (result == true) {
      // Refresh the group data
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      groupProvider.refreshGroup(groupIdentifier);
      
      // Show success message
      BotToast.showText(text: "User removed successfully");
    }
  }
  
  void _showBanDialog(BuildContext context) async {
    final result = await UserBanDialog.show(
      context,
      groupIdentifier,
      pubkey,
      userName: user?.name,
    );
    
    if (result == true) {
      // Refresh the group data
      final groupProvider = Provider.of<GroupProvider>(context, listen: false);
      groupProvider.refreshGroup(groupIdentifier);
      
      // Show success message
      BotToast.showText(text: "User banned successfully");
    }
  }
}
