import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/provider/group_provider.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:provider/provider.dart';
import 'package:nostrmo/provider/metadata_provider.dart';
import '../../../component/appbar_back_btn_widget.dart';
import '../../../generated/l10n.dart';
import '../../../component/appbar_bottom_border.dart';
import 'group_member_item_widget.dart';
import '../../../consts/base.dart';

/// Displays a list of members of a group.
class GroupMembersWidget extends StatefulWidget {
  const GroupMembersWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return _GroupMembersWidgetState();
  }
}

class _GroupMembersWidgetState extends State<GroupMembersWidget> {
  GroupIdentifier? groupIdentifier;

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    var bodyLargeFontSize = themeData.textTheme.bodyLarge!.fontSize;
    final localization = S.of(context);
    final metadataProvider = Provider.of<MetadataProvider>(context);

    var arg = RouterUtil.routerArgs(context);
    if (arg == null || arg is! GroupIdentifier) {
      RouterUtil.back(context);
      return Container();
    }
    groupIdentifier = arg;

    var groupProvider = Provider.of<GroupProvider>(context);
    var groupMembers = groupProvider.getMembers(groupIdentifier!);
    var groupAdmins = groupProvider.getAdmins(groupIdentifier!);

    List<Widget> memberList = [];

    if (groupMembers != null && groupMembers.members != null) {
      // Create a list of member data to sort
      var membersList = groupMembers.members!.map((pubkey) {
        final metadata = metadataProvider.getMetadata(pubkey);
        final isAdmin = groupAdmins?.contains(pubkey) != null;
        return (pubkey: pubkey, metadata: metadata, isAdmin: isAdmin);
      }).toList();

      // Sort the list - admins first, then by display name
      membersList.sort((member1, member2) {
        // First compare by admin status
        if (member1.isAdmin != member2.isAdmin) {
          return member1.isAdmin ? -1 : 1;
        }

        // Then compare by display name
        final member1Name = member1.metadata?.displayName ??
            member1.metadata?.name ??
            Nip19.encodeSimplePubKey(member1.pubkey);
        final member2Name = member2.metadata?.displayName ??
            member2.metadata?.name ??
            Nip19.encodeSimplePubKey(member2.pubkey);
        return member1Name.compareTo(member2Name);
      });

      memberList.addAll(membersList.map((member) => GroupMemberItemWidget(
            groupIdentifier: groupIdentifier!,
            pubkey: member.pubkey,
            isAdmin: member.isAdmin,
            metadata: member.metadata,
          )));
    }

    return Scaffold(
      appBar: AppBar(
        leading: const AppbarBackBtnWidget(),
        bottom: const AppBarBottomBorder(),
        title: Text(
          localization.Members,
          style: TextStyle(
            fontSize: bodyLargeFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: Base.maxScreenWidth),
          child: ListView(
            children: memberList,
          ),
        ),
      ),
    );
  }
}
