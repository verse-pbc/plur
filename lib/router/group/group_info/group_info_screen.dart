import 'dart:math';

import 'package:bot_toast/bot_toast.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:provider/provider.dart';
import 'package:nostrmo/provider/group_provider.dart';
import 'package:nostrmo/provider/list_provider.dart';
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

import '../../../main.dart';

/// Class to store member data in a consistent format
class MemberInfo {
  final String pubkey;
  final User? user;
  final bool isAdmin;
  final bool isPending;
  final String inviteCode;
  final List<String> roles;
  // Add invite label for better display of pending invites
  final String inviteLabel;
  // Add field for tracking who an invite is for (when known)
  final String invitee;
  
  MemberInfo({
    required this.pubkey,
    this.user,
    required this.isAdmin,
    required this.isPending,
    this.inviteCode = '',
    this.roles = const <String>[],
    this.inviteLabel = '',
    this.invitee = '',
  });
}

/// Displays detailed information about a group with member actions.
class GroupInfoWidget extends StatefulWidget {
  const GroupInfoWidget({Key? key}) : super(key: key);

  @override
  State<GroupInfoWidget> createState() => _GroupInfoWidgetState();
}

class _GroupInfoWidgetState extends State<GroupInfoWidget> {
  // Tab selection: 0 = Members, 1 = Invites
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
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
          localization.groupInfo,
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
      body: SingleChildScrollView(
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
                          localization.about,
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
                        localization.actions,
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
                            label: localization.invite,
                            onTap: () {
                              RouterUtil.router(context, RouterPath.inviteToGroup, groupId);
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildActionButton(
                            context: context,
                            icon: Icons.share_outlined,
                            label: localization.share,
                            isDisabled: true,
                            onTap: () {
                              // Feature not yet implemented
                            },
                          ),
                          if (isAdmin) ...[
                            const SizedBox(width: 8),
                            _buildActionButton(
                              context: context,
                              icon: Icons.edit_outlined,
                              label: localization.edit,
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
                
                // Members & Invites section with tabs
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            localization.members,
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
                      _buildMembersWithTabs(context, groupId),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDisabled = false,
  }) {
    final themeData = Theme.of(context);
    final customColors = themeData.customColors;
    
    return Expanded(
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: customColors.feedBgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isDisabled ? customColors.dimmedColor : customColors.accentColor,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: isDisabled ? customColors.dimmedColor : customColors.primaryForegroundColor,
                ),
              ),
              if (isDisabled)
                Text(
                  "Coming soon",
                  style: TextStyle(
                    fontSize: 9,
                    color: customColors.dimmedColor,
                    fontStyle: FontStyle.italic,
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
            Icons.construction_outlined,
            size: 48,
            color: customColors.dimmedColor,
          ),
          const SizedBox(height: 16),
          Text(
            "Coming Soon",
            style: TextStyle(
              color: customColors.secondaryForegroundColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "$tabName feature is under development",
            style: TextStyle(
              color: customColors.secondaryForegroundColor,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMembersWithTabs(BuildContext context, GroupIdentifier groupId) {
    final themeData = Theme.of(context);
    final customColors = themeData.customColors;
    final groupProvider = Provider.of<GroupProvider>(context);
    final localization = S.of(context);
    
    // Get pending invites
    final pendingInvites = groupProvider.getPendingInvites(groupId);
    final hasPendingInvites = pendingInvites.isNotEmpty;
    
    // Tab design and content
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tab selector
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: customColors.feedBgColor.withAlpha((255 * 0.5).round()),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              // Members tab
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedTab = 0;
                    });
                  },
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _selectedTab == 0 
                          ? customColors.feedBgColor 
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      localization.members,
                      style: TextStyle(
                        color: _selectedTab == 0
                            ? customColors.primaryForegroundColor
                            : customColors.secondaryForegroundColor,
                        fontWeight: _selectedTab == 0 
                            ? FontWeight.bold 
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
              // Invites tab
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedTab = 1;
                    });
                  },
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _selectedTab == 1 
                          ? customColors.feedBgColor 
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          "Invites", // Use a hardcoded string for now since localization.invites isn't available
                          style: TextStyle(
                            color: _selectedTab == 1
                                ? customColors.primaryForegroundColor
                                : customColors.secondaryForegroundColor,
                            fontWeight: _selectedTab == 1 
                                ? FontWeight.bold 
                                : FontWeight.normal,
                          ),
                        ),
                        // Removed notification dot
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Tab content
        if (_selectedTab == 0)
          _buildMembersTabContent(context, groupId)
        else
          _buildInvitesTabContent(context, groupId),
      ],
    );
  }
  
  Widget _buildMembersTabContent(BuildContext context, GroupIdentifier groupId) {
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
    
    // Get members to show
    final members = groupMembers.members ?? [];
    
    // Limit to 8 members for the preview
    final displayCount = min(members.length, 8);
    final displayMembers = members.sublist(0, displayCount);
    
    // Create a list of member info
    var membersList = displayMembers.map((pubkey) {
      final user = userProvider.getUser(pubkey);
      final isAdmin = groupAdmins?.containsUser(pubkey) ?? false;
      return MemberInfo(
        pubkey: pubkey, 
        user: user, 
        isAdmin: isAdmin, 
        isPending: false,
      );
    }).toList();
    
    // Sort members - admins first, then by name
    membersList.sort((MemberInfo member1, MemberInfo member2) {
      // Admin status takes precedence
      if (member1.isAdmin != member2.isAdmin) {
        return member1.isAdmin ? -1 : 1;
      }
      
      // Then sort by name
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
    const double spacing = 16.0;
    const double avatarSize = 56.0;
    
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
          mainAxisSpacing: spacing + 16,
          childAspectRatio: 0.65,
        ),
        itemCount: membersList.length,
        itemBuilder: (context, index) {
          final MemberInfo member = membersList[index];
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
  
  Widget _buildInvitesTabContent(BuildContext context, GroupIdentifier groupId) {
    final themeData = Theme.of(context);
    final customColors = themeData.customColors;
    final groupProvider = Provider.of<GroupProvider>(context);
    
    // Get pending invites
    final pendingInvites = groupProvider.getPendingInvites(groupId);
    
    if (pendingInvites.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            "No pending invites",
            style: TextStyle(color: customColors.secondaryForegroundColor),
          ),
        ),
      );
    }
    
    // Prepare invite info list
    var invitesList = <MemberInfo>[];
    
    for (var inviteEvent in pendingInvites) {
      final (inviteCode, List<String> roles) = groupProvider.getInviteDetails(inviteEvent);
      final isAdminInvite = roles.contains("admin");
      
      // Try to extract meaningful information from the invite
      String inviteLabel = "Invite";
      String invitee = "";
      
      for (var tag in inviteEvent.tags) {
        if (tag is List && tag.length > 1) {
          if (tag[0] == "description" || tag[0] == "desc" || tag[0] == "name") {
            inviteLabel = tag[1].toString();
          } else if (tag[0] == "invitee" || tag[0] == "for" || tag[0] == "recipient") {
            invitee = tag[1].toString();
          }
        }
      }
      
      // Create a better label based on available information
      if (invitee.isNotEmpty) {
        inviteLabel = "For $invitee";
      } else if (inviteLabel == "Invite" && inviteCode.isNotEmpty) {
        inviteLabel = "Invite ${inviteCode.substring(0, min(4, inviteCode.length))}";
      }
      
      invitesList.add(MemberInfo(
        pubkey: "", 
        user: null, 
        isAdmin: isAdminInvite,
        isPending: true,
        inviteCode: inviteCode,
        roles: roles,
        inviteLabel: inviteLabel,
        invitee: invitee,
      ));
    }
    
    // Sort invites - admin invites first
    invitesList.sort((MemberInfo invite1, MemberInfo invite2) {
      if (invite1.isAdmin != invite2.isAdmin) {
        return invite1.isAdmin ? -1 : 1;
      }
      return invite1.inviteLabel.compareTo(invite2.inviteLabel);
    });
    
    // Calculate grid parameters
    const int crossAxisCount = 4;
    const double spacing = 16.0;
    const double avatarSize = 56.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
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
              mainAxisSpacing: spacing + 16,
              childAspectRatio: 0.65,
            ),
            itemCount: invitesList.length,
            itemBuilder: (context, index) {
              final MemberInfo invite = invitesList[index];
              return _buildPendingInvitePlaceholder(
                context,
                inviteCode: invite.inviteCode,
                roles: invite.roles,
                isAdmin: invite.isAdmin,
                size: avatarSize,
                inviteLabel: invite.invitee.isNotEmpty 
                  ? invite.invitee 
                  : invite.inviteLabel,
              );
            },
          ),
        ),
        
        // Explanation about dotted borders
        Padding(
          padding: const EdgeInsets.only(top: 8.0, left: 4.0),
          child: Text(
            "Dotted border = pending invites",
            style: TextStyle(
              fontSize: 12,
              color: customColors.secondaryForegroundColor,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildMembersList(BuildContext context, GroupIdentifier groupId) {
    final themeData = Theme.of(context);
    final customColors = themeData.customColors;
    final groupProvider = Provider.of<GroupProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final localization = S.of(context);
    
    // Get member and admin data
    final groupMembers = groupProvider.getMembers(groupId);
    final groupAdmins = groupProvider.getAdmins(groupId);
    
    // Get pending invites
    final pendingInvites = groupProvider.getPendingInvites(groupId);
    final hasPendingInvites = pendingInvites.isNotEmpty;
    
    if ((groupMembers == null || groupMembers.members == null || groupMembers.members!.isEmpty) && 
        !hasPendingInvites) {
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
    
    // Get a limited list of members to show
    final members = groupMembers?.members ?? [];
    
    // Determine how many regular members we can show if we have pending invites
    // We'll show up to 8 items total (members + pending invites)
    const totalDisplayLimit = 8;
    int pendingDisplayCount = hasPendingInvites ? min(pendingInvites.length, 3) : 0; // Show max 3 pending invites
    int memberDisplayLimit = totalDisplayLimit - pendingDisplayCount;
    
    final displayMembers = members.length > memberDisplayLimit 
        ? members.sublist(0, memberDisplayLimit) 
        : members;

    // Create a list of member data to sort
    
    var membersList = displayMembers.map((pubkey) {
      final user = userProvider.getUser(pubkey);
      final isAdmin = groupAdmins?.containsUser(pubkey) ?? false;
      return MemberInfo(
        pubkey: pubkey, 
        user: user, 
        isAdmin: isAdmin, 
        isPending: false,
      );
    }).toList();
    
    // Add pending invites if we have any
    if (hasPendingInvites) {
      final displayInvites = pendingInvites.length > pendingDisplayCount
          ? pendingInvites.sublist(0, pendingDisplayCount)
          : pendingInvites;
          
      for (var inviteEvent in displayInvites) {
        final (inviteCode, List<String> roles) = groupProvider.getInviteDetails(inviteEvent);
        final isAdminInvite = roles.contains("admin");
        
        // Generate a friendly label for this invite
        String inviteLabel = "Invite";
        String invitee = "";
        
        // Try to extract a meaningful label and invitee from the invite event tags
        for (var tag in inviteEvent.tags) {
          if (tag is List && tag.length > 1) {
            // Check for description/name tags
            if (tag[0] == "description" || tag[0] == "desc" || tag[0] == "name") {
              inviteLabel = tag[1].toString();
            }
            // Check for invitee tag
            else if (tag[0] == "invitee" || tag[0] == "for" || tag[0] == "recipient") {
              invitee = tag[1].toString();
            }
          }
        }
        
        // Create a better label based on available information
        if (invitee.isNotEmpty) {
          // If we know who it's for, prioritize that
          inviteLabel = "For $invitee";
        } else if (inviteLabel == "Invite" && inviteCode.isNotEmpty) {
          // If no description or invitee but we have a code, use that
          inviteLabel = "Invite ${inviteCode.substring(0, min(4, inviteCode.length))}";
        }
        
        // We don't know the pubkey of the invitee (it's just a link)
        // so we'll use a placeholder here
        membersList.add(MemberInfo(
          pubkey: "", 
          user: null, 
          isAdmin: isAdminInvite,
          isPending: true,
          inviteCode: inviteCode,
          roles: roles,
          inviteLabel: inviteLabel,
          invitee: invitee,
        ));
      }
    }

    // Sort the list - admins first, then members, with pending and normal interspersed
    membersList.sort((MemberInfo member1, MemberInfo member2) {
      // First compare by admin status
      if (member1.isAdmin != member2.isAdmin) {
        return member1.isAdmin ? -1 : 1;
      }
      
      // For regular members, sort by isPending status within their role group
      // so that regular members come first, then regular pending invites
      if (!member1.isAdmin && !member2.isAdmin) {
        if (member1.isPending != member2.isPending) {
          return member1.isPending ? 1 : -1;
        }
      }
      
      // For admin members, also sort by isPending within role group
      // so admin members come first, then admin pending invites
      if (member1.isAdmin && member2.isAdmin) {
        if (member1.isPending != member2.isPending) {
          return member1.isPending ? 1 : -1;
        }
      }

      // Then compare by display name for normal members
      if (!member1.isPending && !member2.isPending) {
        final member1Name = member1.user?.displayName ??
            member1.user?.name ??
            Nip19.encodeSimplePubKey(member1.pubkey);
        final member2Name = member2.user?.displayName ??
            member2.user?.name ??
            Nip19.encodeSimplePubKey(member2.pubkey);
        return member1Name.compareTo(member2Name);
      }
      
      // For pending invites, sort by invite code
      if (member1.isPending && member2.isPending) {
        return member1.inviteCode.compareTo(member2.inviteCode);
      }
      
      return 0;
    });
    
    // Calculate grid parameters
    const int crossAxisCount = 4; // 4 avatars per row
    const double spacing = 16.0; // More spacing to avoid crowding
    const double avatarSize = 56.0; // Slightly smaller avatars to fit better
    
    // Calculate the number of rows needed
    final int rowCount = (membersList.length / crossAxisCount).ceil();
        
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: customColors.feedBgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16),
          // Removing maxHeight constraint to allow the grid to expand naturally
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing + 16, // More vertical spacing for text
              // Adjust childAspectRatio to make sure items fit correctly
              childAspectRatio: 0.65, // Even taller to fit both avatar and text
            ),
            itemCount: membersList.length,
            itemBuilder: (context, index) {
              final MemberInfo member = membersList[index];
              if (member.isPending) {
                // For invites, show a special pending invite UI
                return _buildPendingInvitePlaceholder(
                  context,
                  inviteCode: member.inviteCode,
                  roles: member.roles,
                  isAdmin: member.isAdmin,
                  size: avatarSize,
                  inviteLabel: member.invitee.isNotEmpty 
                    ? member.invitee  // Use the direct invitee name if available
                    : member.inviteLabel,
                );
              } else {
                // Return regular member widget
                return _buildMemberGridItem(
                  context, 
                  pubkey: member.pubkey, 
                  user: member.user, 
                  isAdmin: member.isAdmin,
                  size: avatarSize,
                );
              }
            },
          ),
        ),
        
        // Show pending invites explanation if needed
        if (hasPendingInvites)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 4.0),
            child: Text(
              "Dotted border = pending invites",
              style: TextStyle(
                fontSize: 12,
                color: customColors.secondaryForegroundColor,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }
  
  /// Widget to display a pending invite placeholder in the members grid
  Widget _buildPendingInvitePlaceholder(
    BuildContext context, {
    required String inviteCode,
    required List<String> roles,
    bool isAdmin = false,
    required double size,
    String inviteLabel = 'Invite',
  }) {
    final themeData = Theme.of(context);
    final customColors = themeData.customColors;
    
    return GestureDetector(
      onTap: () {
        // Show invite details in a simpler dialog
        _showSimpleInviteDialog(context, inviteCode, roles, isAdmin, invitee: inviteLabel.startsWith("For ") ? inviteLabel.substring(4) : "");
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Stack to show the avatar with dotted border and admin indicator if needed
          Stack(
            alignment: Alignment.center,
            children: [
              // Dotted border circle for indicating pending status
              DottedBorder(
                borderType: BorderType.Circle,
                color: customColors.accentColor.withAlpha(180),
                strokeWidth: 1.5,
                dashPattern: const [3, 3],
                padding: const EdgeInsets.all(2),
                child: Container(
                  width: size - 4,  // Adjust size to account for the border
                  height: size - 4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: themeData.cardColor,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.person_add_alt,
                      size: size * 0.4,
                      color: isAdmin 
                          ? themeData.colorScheme.primary 
                          : themeData.hintColor,
                    ),
                  ),
                ),
              ),
              
              // Admin indicator (outer circle)
              if (isAdmin)
                Container(
                  width: size + 6,
                  height: size + 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: themeData.colorScheme.primary,
                      width: 2.0,
                    ),
                  ),
                ),
            ],
          ),
          
          // Role text
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              inviteLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: themeData.hintColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
          
          // Role & Status text
          Container(
            margin: const EdgeInsets.only(top: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isAdmin ? "Admin" : "Member",
                  style: TextStyle(
                    fontSize: 10,
                    color: isAdmin 
                        ? themeData.colorScheme.primary 
                        : themeData.hintColor,
                    fontWeight: isAdmin ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                Text(
                  " • ",
                  style: TextStyle(
                    fontSize: 10,
                    color: themeData.hintColor,
                  ),
                ),
                Text(
                  "Pending",
                  style: TextStyle(
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                    color: themeData.hintColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  void _showInviteDetailsDialog(
    BuildContext context, 
    Event inviteEvent, 
    String inviteCode, 
    List<String> roles
  ) {
    final themeData = Theme.of(context);
    final customColors = themeData.customColors;
    final groupId = RouterUtil.routerArgs(context) as GroupIdentifier;
    final listProvider = Provider.of<ListProvider>(context, listen: false);
    
    // Generate invite link (will use direct protocol URL by default)
    final inviteLink = listProvider.createInviteLink(groupId, inviteCode);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Pending Invite", 
          style: TextStyle(color: customColors.primaryForegroundColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "This is a pending invite for a ${roles.contains('admin') ? 'Admin' : 'Member'}.",
              style: TextStyle(color: customColors.primaryForegroundColor),
            ),
            const SizedBox(height: 12),
            
            // Display invite link with copy button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: customColors.feedBgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      inviteLink,
                      style: TextStyle(
                        fontSize: 12,
                        color: customColors.primaryForegroundColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.copy,
                      color: customColors.accentColor,
                      size: 16,
                    ),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: inviteLink));
                      BotToast.showText(text: S.of(context).copySuccess);
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 8),
            Text(
              "Created: ${_formatTimestamp(inviteEvent.createdAt)}",
              style: TextStyle(
                fontSize: 12,
                color: customColors.secondaryForegroundColor,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              "Close", 
              style: TextStyle(color: customColors.accentColor),
            ),
          ),
        ],
        backgroundColor: customColors.feedBgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
  
  /// Show a dialog with invite details (no event required)
  void _showSimpleInviteDialog(
    BuildContext context, 
    String inviteCode, 
    List<String> roles,
    bool isAdmin,
    {String invitee = ''}
  ) {
    final themeData = Theme.of(context);
    final customColors = themeData.customColors;
    final groupId = RouterUtil.routerArgs(context) as GroupIdentifier;
    final listProvider = Provider.of<ListProvider>(context, listen: false);
    
    // Generate invite link (will use direct protocol URL by default)
    final inviteLink = listProvider.createInviteLink(groupId, inviteCode);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Pending Invite", 
          style: TextStyle(color: customColors.primaryForegroundColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              invitee.isNotEmpty 
                ? "This is a pending invite for $invitee (${isAdmin ? 'Admin' : 'Member'})."
                : "This is a pending invite for a ${isAdmin ? 'Admin' : 'Member'}.",
              style: TextStyle(color: customColors.primaryForegroundColor),
            ),
            const SizedBox(height: 12),
            
            // Display invite link with copy button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: customColors.feedBgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      inviteLink,
                      style: TextStyle(
                        fontSize: 12,
                        color: customColors.primaryForegroundColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.copy,
                      color: customColors.accentColor,
                      size: 16,
                    ),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: inviteLink));
                      BotToast.showText(text: S.of(context).copySuccess);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              "Close", 
              style: TextStyle(color: customColors.accentColor),
            ),
          ),
        ],
        backgroundColor: customColors.feedBgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
  
  /// Format a Unix timestamp date
  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }
  
  /// Format a Unix timestamp date with more detail
  String _formatTimestamp(int timestamp) {
    return _formatDate(timestamp);
  }
  
  Widget _buildMemberGridItem(
    BuildContext context, {
    required String pubkey, 
    User? user, 
    bool isAdmin = false,
    required double size,
    bool isPendingInvite = false,
  }) {
    return GestureDetector(
      onTap: () {
        if (!isPendingInvite) {
          // Show the member card dialog for actual members
          MemberCardDialog.show(
            context,
            pubkey: pubkey,
            groupId: RouterUtil.routerArgs(context) as GroupIdentifier,
            isAdmin: isAdmin,
          );
        } else {
          // For pending invites, show a different dialog or action
          _showPendingInviteInfo(context, pubkey);
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Ensure we fit within available space by using constraints
          return Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Avatar with appropriate border
              Center(
                child: isPendingInvite 
                    ? _buildPendingInviteAvatar(context, pubkey, user, size)
                    : _buildMemberAvatar(context, pubkey, user, isAdmin, size),
              ),
              
              // Username (truncated)
              const SizedBox(height: 8),
              Container(
                width: double.infinity, // Full width for text container
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  _getShortName(user, pubkey),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isPendingInvite 
                        ? Theme.of(context).hintColor 
                        : Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
              
              // Status indicator for pending invites
              if (isPendingInvite)
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  child: Text(
                    "Pending",
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).hintColor,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          );
        }
      ),
    );
  }
  
  // Helper to build member avatar with admin indicator if needed
  Widget _buildMemberAvatar(
    BuildContext context, 
    String pubkey, 
    User? user, 
    bool isAdmin, 
    double size
  ) {
    final themeData = Theme.of(context);
    
    return SizedBox(
      // Ensure consistent sizing
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background color to ensure avatar is properly contained
          Container(
            width: size - 4,
            height: size - 4,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: themeData.cardColor,
            ),
          ),
          
          // Error-resistant avatar display
          ClipOval(
            child: SizedBox(
              width: size - 4,
              height: size - 4,
              child: _buildAvatarWithErrorHandling(context, pubkey, user, size: size - 4),
            ),
          ),
          
          // Admin indicator
          if (isAdmin)
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: themeData.colorScheme.primary,
                  width: 2.0,
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  // Helper to build pending invite avatar with dotted border
  Widget _buildPendingInviteAvatar(
    BuildContext context, 
    String pubkey, 
    User? user, 
    double size
  ) {
    final customColors = Theme.of(context).customColors;
    
    return DottedBorder(
      borderType: BorderType.Circle,
      color: customColors.accentColor.withAlpha(180),
      strokeWidth: 1.5,
      dashPattern: const [3, 3],
      padding: const EdgeInsets.all(2),
      child: SizedBox(
        width: size - 4,
        height: size - 4,
        child: _buildAvatarWithErrorHandling(context, pubkey, user, size: size - 6),
      ),
    );
  }
  
  // Helper to build avatar with proper error handling
  Widget _buildAvatarWithErrorHandling(
    BuildContext context, 
    String pubkey, 
    User? user, 
    {required double size}
  ) {
    // Use UserPicWidget which should handle errors internally
    return UserPicWidget(
      pubkey: pubkey,
      width: size,
      user: user,
    );
  }
  
  void _showPendingInviteInfo(BuildContext context, String inviteePubkey) {
    final themeData = Theme.of(context);
    final customColors = themeData.customColors;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Pending Invite", style: TextStyle(color: customColors.primaryForegroundColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "This user has been invited but hasn't accepted yet.",
              style: TextStyle(color: customColors.primaryForegroundColor),
            ),
            const SizedBox(height: 8),
            Text(
              "You can remind them about the invitation or send a new invite link.",
              style: TextStyle(color: customColors.secondaryForegroundColor, fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("Close", style: TextStyle(color: customColors.accentColor)),
          ),
        ],
        backgroundColor: customColors.feedBgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
  
  String _getShortName(User? user, String pubkey) {
    // First try to get a meaningful name from the user object
    final displayName = user?.displayName ?? user?.name;
    if (displayName != null && displayName.isNotEmpty) {
      // Get first name or handle
      final nameParts = displayName.split(' ');
      return nameParts.first;
    }
    
    // Fall back to shortened pubkey if no name is available
    try {
      if (pubkey.isEmpty) {
        return "Invite";
      }
      final npub = Nip19.encodeSimplePubKey(pubkey);
      return npub.substring(0, min(8, npub.length));
    } catch (e) {
      // Handle any encoding errors safely
      return pubkey.isNotEmpty ? pubkey.substring(0, min(6, pubkey.length)) : "User";
    }
  }
  
}