import 'package:flutter/material.dart';
import 'package:nostrmo/util/theme_util.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/router/group/group_info/group_info_menu_item_widget.dart';
import 'package:nostrmo/generated/l10n.dart';

enum GroupInfoMenuItem {
  members;

  String getTitle(BuildContext context) {
    final localization = S.of(context);
    switch (this) {
      case GroupInfoMenuItem.members:
        return localization.Members;
    }
  }
}

/// Displays a scrollable menu in the group info screen.
class GroupInfoMenuWidget extends StatelessWidget {
  final GroupIdentifier groupId;

  const GroupInfoMenuWidget({
    super.key,
    required this.groupId,
  });

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);

    return Material(
      color: themeData.customColors.feedBgColor,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(10),
      child: ListView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _menuItems.length,
        itemBuilder: (context, index) {
          final item = _menuItems[index];
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GroupInfoMenuItemWidget(
                title: item.getTitle(context),
                onTap: () => _navigateToMenuItem(context, item),
              ),
              if (index < _menuItems.length - 1)
                Divider(
                  height: 1,
                  color: themeData.customColors.navBgColor,
                ),
            ],
          );
        },
      ),
    );
  }

  void _navigateToMenuItem(BuildContext context, GroupInfoMenuItem item) {
    switch (item) {
      case GroupInfoMenuItem.members:
        RouterUtil.router(context, RouterPath.GROUP_MEMBERS, groupId);
    }
  }

  List<GroupInfoMenuItem> get _menuItems => GroupInfoMenuItem.values;
}
