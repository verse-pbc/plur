import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:provider/provider.dart';
import 'package:nostrmo/provider/group_provider.dart';
import 'package:nostrmo/provider/user_provider.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:nostrmo/component/appbar_back_btn_widget.dart';
import 'package:nostrmo/component/user/user_pic_widget.dart';
import 'package:nostrmo/generated/l10n.dart';
import '../../../component/appbar_bottom_border.dart';
import '../../../util/theme_util.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'group_info_header_widget.dart';
import 'group_info_menu_widget.dart';
import 'group_info_popupmenu_widget.dart';
import '../../../consts/base.dart';
import '../../../data/user.dart';
import '../group_members/member_card_dialog.dart';
import '../group_media_grid_widget.dart';

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
                                        RouterUtil.router(context, RouterPath.inviteToGroup, groupId);
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
                                          RouterUtil.router(context, RouterPath.groupEdit, groupId);
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
                          
                          // Members list section
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      localization.Members,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: customColors.primaryForegroundColor,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        RouterUtil.router(context, RouterPath.groupMembers, groupId);
                                      },
                                      child: Text(
                                        "See All",
                                        style: TextStyle(
                                          color: customColors.accentColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                _buildMembersList(context, groupId),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Media tab - Instagram-style grid
                GroupMediaGridWidget(groupId: groupId),
                
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
  
  Widget _buildMembersList(BuildContext context, GroupIdentifier groupId) {
    final themeData = Theme.of(context);
    final customColors = themeData.customColors;
    final groupProvider = Provider.of<GroupProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    
    // Get member and admin data
    final groupMembers = groupProvider.getMembers(groupId);
    final groupAdmins = groupProvider.getAdmins(groupId);
    
    if (groupMembers == null || groupMembers.members == null || groupMembers.members!.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            "No members found",
            style: TextStyle(color: customColors.secondaryForegroundColor),
          ),
        ),
      );
    }
    
    // Get a limited list of members to show (up to 8 members in a grid)
    final members = groupMembers.members!;
    final displayLimit = 8;
    final displayMembers = members.length > displayLimit 
        ? members.sublist(0, displayLimit) 
        : members;

    // Create a list of member data to sort
    var membersList = displayMembers.map((pubkey) {
      final user = userProvider.getUser(pubkey);
      final isAdmin = groupAdmins?.containsUser(pubkey) ?? false;
      return (pubkey: pubkey, user: user, isAdmin: isAdmin);
    }).toList();

    // Sort the list - admins first, then by display name
    membersList.sort((member1, member2) {
      // First compare by admin status
      if (member1.isAdmin != member2.isAdmin) {
        return member1.isAdmin ? -1 : 1;
      }

      // Then compare by display name
      final member1Name = member1.user?.displayName ??
          member1.user?.name ??
          Nip19.encodeSimplePubKey(member1.pubkey);
      final member2Name = member2.user?.displayName ??
          member2.user?.name ??
          Nip19.encodeSimplePubKey(member2.pubkey);
      return member1Name.compareTo(member2Name);
    });
    
    // Calculate grid parameters
    const int crossAxisCount = 4; // 4 avatars per row
    const double spacing = 12.0;
    const double avatarSize = 60.0;
        
    return Container(
      decoration: BoxDecoration(
        color: customColors.feedBgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          childAspectRatio: 1.0,
        ),
        itemCount: membersList.length,
        itemBuilder: (context, index) {
          final member = membersList[index];
          return _buildMemberGridItem(
            context, 
            pubkey: member.pubkey, 
            user: member.user, 
            isAdmin: member.isAdmin,
            size: avatarSize,
          );
        },
      ),
    );
  }
  
  Widget _buildMemberGridItem(
    BuildContext context, {
    required String pubkey, 
    User? user, 
    bool isAdmin = false,
    required double size,
  }) {
    return GestureDetector(
      onTap: () {
        // Show the member card dialog
        MemberCardDialog.show(
          context,
          pubkey: pubkey,
          groupId: RouterUtil.routerArgs(context) as GroupIdentifier,
          isAdmin: isAdmin,
        );
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Admin indicator - small colored circle border
          Stack(
            alignment: Alignment.center,
            children: [
              // User pic
              UserPicWidget(
                pubkey: pubkey, 
                width: size,
              ),
              
              // Admin indicator
              if (isAdmin)
                Container(
                  width: size + 6,
                  height: size + 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2.5,
                    ),
                  ),
                ),
            ],
          ),
          
          // Username (truncated)
          const SizedBox(height: 4),
          Text(
            _getShortName(user, pubkey),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  String _getShortName(User? user, String pubkey) {
    final displayName = user?.displayName ?? user?.name;
    if (displayName == null || displayName.isEmpty) {
      final npub = Nip19.encodeSimplePubKey(pubkey);
      return npub.substring(0, 8);
    }
    
    // Get first name or handle
    final nameParts = displayName.split(' ');
    return nameParts.first;
  }
}