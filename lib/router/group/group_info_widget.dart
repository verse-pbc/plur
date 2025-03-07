import 'package:flutter/material.dart';
import 'package:nostrmo/nostr_sdk/nostr_sdk.dart';
import 'package:provider/provider.dart';
import 'package:nostrmo/provider/group_provider.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:nostrmo/component/appbar_back_btn_widget.dart';
import 'package:nostrmo/generated/l10n.dart';
import '../../consts/router_path.dart';
import '../../component/appbar_bottom_border.dart';
import '../../util/theme_util.dart';
import '../../component/styled_popup_menu.dart';

import '../../component/group/group_avatar_widget.dart';

/// A widget that displays detailed information about a group.
///
/// This widget expects a [GroupIdentifier] as a route argument and displays
/// the group's avatar, name, member count, status, and description.
class GroupInfoWidget extends StatelessWidget {
  const GroupInfoWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final groupProvider = Provider.of<GroupProvider>(context);
    final themeData = Theme.of(context);
    final localization = S.of(context);

    final argIntf = RouterUtil.routerArgs(context);
    if (argIntf == null || argIntf is! GroupIdentifier) {
      RouterUtil.back(context);
      return Container();
    }

    final groupId = argIntf as GroupIdentifier;
    final metadata = groupProvider.getMetadata(groupId);
    final memberCount = groupProvider.getMemberCount(groupId);

    if (metadata == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        leading: const AppbarBackBtnWidget(),
        title: Text(
          localization.Group_Info,
          style: TextStyle(
            color: themeData.customColors.primaryForegroundColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: const AppBarBottomBorder(),
        actions: [
          StyledPopupMenu(
              items: [
                StyledPopupItem(
                  value: "edit",
                  text: localization.Edit,
                  icon: Icons.edit_outlined,
                ),
              ],
              onSelected: (value) {
                switch (value) {
                  case "edit":
                    RouterUtil.router(context, RouterPath.GROUP_EDIT, groupId);
                }
              }),
        ],
      ),
      body: SingleChildScrollView(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              // Centered content
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // Group Avatar
                    GroupAvatar(imageUrl: metadata.picture),
                    const SizedBox(height: 16),
                    // Group Name
                    Text(
                      metadata.name ?? metadata.groupId,
                      style: themeData.textTheme.headlineSmall?.copyWith(
                        color: themeData.customColors.primaryForegroundColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Group Status and Member Count
                    Text(
                      _groupStatusText(metadata, memberCount, localization),
                      style: themeData.textTheme.bodyMedium?.copyWith(
                        color: themeData.customColors.dimmedColor,
                      ),
                    ),
                    const SizedBox(height: 25),
                  ],
                ),
              ),
              // Group Description (not centered)
              if (metadata.about != null)
                SizedBox(
                  width: double.infinity,
                  child: Text(
                    metadata.about!,
                    style: themeData.textTheme.bodyMedium,
                    textAlign: TextAlign.start,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _groupStatusText(
          GroupMetadata metadata, int memberCount, S localization) =>
      '${metadata.open ?? false ? localization.Opened : localization.Closed} '
      '${localization.group} • $memberCount ${memberCount == 1 ? localization.Member : localization.Members}';
}
