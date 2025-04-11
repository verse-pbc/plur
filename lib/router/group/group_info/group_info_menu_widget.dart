import 'package:flutter/material.dart';
import 'package:nostrmo/util/theme_util.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:provider/provider.dart';
import 'package:nostrmo/router/group/group_info/group_info_menu_item_widget.dart';
import 'package:nostrmo/generated/l10n.dart';
import 'package:nostrmo/provider/group_provider.dart';
import '../../../main.dart';

enum GroupInfoMenuItem {
  members,
  settings,
  leave;

  String getTitle(BuildContext context) {
    final localization = S.of(context);
    switch (this) {
      case GroupInfoMenuItem.members:
        return localization.Members;
      case GroupInfoMenuItem.settings:
        return localization.Settings;
      case GroupInfoMenuItem.leave:
        return localization.Leave_Group;
    }
  }

  IconData getIcon() {
    switch (this) {
      case GroupInfoMenuItem.members:
        return Icons.people_outline;
      case GroupInfoMenuItem.settings:
        return Icons.settings_outlined;
      case GroupInfoMenuItem.leave:
        return Icons.exit_to_app;
    }
  }
}

/// Displays a scrollable menu in the group info screen with icons and improved styling.
class GroupInfoMenuWidget extends StatelessWidget {
  final GroupIdentifier groupId;

  const GroupInfoMenuWidget({
    super.key,
    required this.groupId,
  });

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final customColors = themeData.customColors;
    final localization = S.of(context);
    final groupProvider = Provider.of<GroupProvider>(context);
    
    // Get available menu items based on user role
    final List<GroupInfoMenuItem> menuItems = _getMenuItems(context, groupProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Text(
            localization.Menu,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: customColors.primaryForegroundColor,
            ),
          ),
          const SizedBox(height: 8),
          // Menu items in a card
          Material(
            color: customColors.feedBgColor,
            clipBehavior: Clip.antiAlias,
            borderRadius: BorderRadius.circular(12),
            elevation: 0,
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: menuItems.length,
              separatorBuilder: (context, index) {
                return Divider(
                  height: 1,
                  indent: 56, // Align divider with text, not icon
                  color: customColors.separatorColor.withOpacity(0.5),
                );
              },
              itemBuilder: (context, index) {
                final item = menuItems[index];
                return GroupInfoMenuItemWidget(
                  title: item.getTitle(context),
                  icon: item.getIcon(),
                  onTap: () => _handleMenuItemTap(context, item),
                  textColor: item == GroupInfoMenuItem.leave 
                    ? Colors.red 
                    : customColors.primaryForegroundColor,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<GroupInfoMenuItem> _getMenuItems(BuildContext context, GroupProvider groupProvider) {
    // Always include Members
    List<GroupInfoMenuItem> items = [GroupInfoMenuItem.members];
    
    // Add Settings only if user is admin
    final groupAdmins = groupProvider.getAdmins(groupId);
    final currentPubKey = nostr?.publicKey;
    final isAdmin = currentPubKey != null && groupAdmins?.containsUser(currentPubKey) == true;
    
    if (isAdmin) {
      items.add(GroupInfoMenuItem.settings);
    }
    
    // Always add Leave option at the end
    items.add(GroupInfoMenuItem.leave);
    
    return items;
  }

  void _handleMenuItemTap(BuildContext context, GroupInfoMenuItem item) {
    switch (item) {
      case GroupInfoMenuItem.members:
        RouterUtil.router(context, RouterPath.groupMembers, groupId);
    }
  }

  void _showLeaveConfirmation(BuildContext context) {
    final themeData = Theme.of(context);
    final customColors = themeData.customColors;
    final localization = S.of(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          localization.Leave_Group_Question,
          style: TextStyle(
            color: customColors.primaryForegroundColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          localization.Leave_Group_Confirmation,
          style: TextStyle(
            color: customColors.primaryForegroundColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              localization.Cancel,
              style: TextStyle(
                color: customColors.primaryForegroundColor,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement leave group functionality
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Return to previous screen
            },
            child: Text(
              localization.Leave,
              style: const TextStyle(
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
