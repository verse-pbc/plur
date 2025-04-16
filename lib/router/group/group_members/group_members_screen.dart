import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/provider/group_provider.dart';
import 'package:provider/provider.dart';
import 'package:nostrmo/provider/user_provider.dart';
import '../../../component/appbar_back_btn_widget.dart';
import '../../../component/appbar_bottom_border.dart';
import '../../../generated/l10n.dart';
import 'group_member_item_widget.dart';
import '../../../consts/base.dart';

class GroupMembersScreen extends StatelessWidget {
  const GroupMembersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final bodyLargeFontSize = themeData.textTheme.bodyLarge!.fontSize;
    final localization = S.of(context);
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
      body: const SingleChildScrollView(child: GroupMembersWidget()),
    );
  }
}

/// Displays a list of members of a group.
class GroupMembersWidget extends StatelessWidget {
  const GroupMembersWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    final groupIdentifier = context.read<GroupIdentifier>();

    final groupProvider = Provider.of<GroupProvider>(context);
    final groupMembers = groupProvider.getMembers(groupIdentifier)?.members;
    final groupAdmins = groupProvider.getAdmins(groupIdentifier);
    if ((groupMembers == null || groupMembers.isEmpty) &&
        (groupAdmins?.users == null || groupAdmins!.users.isEmpty)) {
      return const CircularProgressIndicator();
    }

    // Create a list of member data to sort
    var membersList = groupMembers?.map((pubkey) {
          final user = userProvider.getUser(pubkey);
          final isAdmin = groupAdmins?.containsUser(pubkey) ?? false;
          return (pubkey: pubkey, user: user, isAdmin: isAdmin);
        }).toList() ??
        [];

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

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: Base.maxScreenWidth),
        child: ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: groupMembers?.length ?? 0,
          itemBuilder: (context, index) {
            final member = membersList[index];
            return GroupMemberItemWidget(
              groupIdentifier: groupIdentifier,
              pubkey: member.pubkey,
              isAdmin: member.isAdmin,
              user: member.user,
            );
          },
        ),
      ),
    );
  }
}
