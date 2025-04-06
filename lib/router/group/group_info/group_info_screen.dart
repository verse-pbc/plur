import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:provider/provider.dart';
import 'package:nostrmo/provider/group_provider.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:nostrmo/component/appbar_back_btn_widget.dart';
import 'package:nostrmo/generated/l10n.dart';
import '../../../component/appbar_bottom_border.dart';
import '../../../util/theme_util.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'group_info_header_widget.dart';
import 'group_info_menu_widget.dart';
import 'group_info_popupmenu_widget.dart';
import '../../../consts/base.dart';

import '../../../main.dart';

/// Displays detailed information about a group with member actions.
class GroupInfoWidget extends StatefulWidget {
  const GroupInfoWidget({Key? key}) : super(key: key);

  @override
  State<GroupInfoWidget> createState() => _GroupInfoWidgetState();
}

class _GroupInfoWidgetState extends State<GroupInfoWidget> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Debug logging
    print("GroupInfoWidget building...");
    
    final groupProvider = Provider.of<GroupProvider>(context);
    final themeData = Theme.of(context);
    final customColors = themeData.customColors;
    final localization = S.of(context);

    final argIntf = RouterUtil.routerArgs(context);
    print("GroupInfoWidget argument: $argIntf");
    
    if (argIntf == null || argIntf is! GroupIdentifier) {
      print("GroupInfoWidget error: Invalid arguments, returning to previous screen");
      RouterUtil.back(context);
      return Container();
    }

    final groupId = argIntf;
    print("GroupInfoWidget groupId: ${groupId.toString()}");
    
    final metadata = groupProvider.getMetadata(groupId);
    print("GroupInfoWidget metadata: ${metadata?.toString() ?? 'null'}");
    
    final memberCount = groupProvider.getMemberCount(groupId);
    print("GroupInfoWidget memberCount: $memberCount");
    
    final groupAdmins = groupProvider.getAdmins(groupId);
    print("GroupInfoWidget groupAdmins: ${groupAdmins?.toString() ?? 'null'}");
    
    final isAdmin = groupAdmins?.containsUser(nostr!.publicKey) ?? false;
    print("GroupInfoWidget isAdmin: $isAdmin");

    if (metadata == null) {
      print("GroupInfoWidget showing loading indicator (metadata is null)");
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        leading: const AppbarBackBtnWidget(),
        title: Text(
          localization.Group_Info,
          style: TextStyle(
            color: customColors.primaryForegroundColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: const AppBarBottomBorder(),
        actions: [
          GroupInfoPopupMenuWidget(groupId: groupId),
        ],
      ),
      body: Column(
        children: [
          // Main scrollable section
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Members tab
                SingleChildScrollView(
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: Base.maxScreenWidth),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GroupInfoHeaderWidget(
                            metadata: metadata,
                            memberCount: memberCount,
                          ),
                          if (metadata.about != null && metadata.about!.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),
                                  Text(
                                    localization.About,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: customColors.primaryForegroundColor,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    metadata.about!,
                                    style: themeData.textTheme.bodyMedium,
                                    textAlign: TextAlign.start,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                          
                          // Action buttons
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  localization.Actions,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: customColors.primaryForegroundColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    _buildActionButton(
                                      context: context,
                                      icon: Icons.person_add_outlined,
                                      label: localization.Invite,
                                      onTap: () {
                                        RouterUtil.router(context, RouterPath.INVITE_TO_GROUP, groupId);
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    _buildActionButton(
                                      context: context,
                                      icon: Icons.share_outlined,
                                      label: localization.Share,
                                      onTap: () {
                                        // TODO: Implement share functionality
                                      },
                                    ),
                                    if (isAdmin) ...[
                                      const SizedBox(width: 8),
                                      _buildActionButton(
                                        context: context,
                                        icon: Icons.edit_outlined,
                                        label: localization.Edit,
                                        onTap: () {
                                          RouterUtil.router(context, RouterPath.GROUP_EDIT, groupId);
                                        },
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Menu section
                          GroupInfoMenuWidget(groupId: groupId),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Media tab
                _buildEmptyTabContent(context, localization.Media),
                
                // Links tab
                _buildEmptyTabContent(context, localization.Links),
                
                // Places tab
                _buildEmptyTabContent(context, localization.Places),
                
                // Events tab
                _buildEmptyTabContent(context, localization.Events),
              ],
            ),
          ),
          
          // Tab bar at bottom
          Container(
            decoration: BoxDecoration(
              color: customColors.navBgColor,
              border: Border(
                top: BorderSide(
                  color: customColors.separatorColor,
                  width: 0.5,
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: customColors.accentColor,
              labelColor: customColors.accentColor,
              unselectedLabelColor: customColors.secondaryForegroundColor,
              tabs: [
                Tab(
                  text: localization.Members,
                  icon: const Icon(Icons.people_outline, size: 20),
                ),
                Tab(
                  text: localization.Media,
                  icon: const Icon(Icons.photo_library_outlined, size: 20),
                ),
                Tab(
                  text: localization.Links,
                  icon: const Icon(Icons.link, size: 20),
                ),
                Tab(
                  text: localization.Places,
                  icon: const Icon(Icons.place_outlined, size: 20),
                ),
                Tab(
                  text: localization.Events,
                  icon: const Icon(Icons.event_outlined, size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final themeData = Theme.of(context);
    final customColors = themeData.customColors;
    
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: customColors.feedBgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: customColors.accentColor,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: customColors.primaryForegroundColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildEmptyTabContent(BuildContext context, String tabName) {
    final themeData = Theme.of(context);
    final customColors = themeData.customColors;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 48,
            color: customColors.dimmedColor,
          ),
          const SizedBox(height: 16),
          Text(
            "No $tabName found",
            style: TextStyle(
              color: customColors.secondaryForegroundColor,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}