import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/provider/group_provider.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:provider/provider.dart';

import '../../consts/base.dart';

class GroupListItemWidget extends StatefulWidget {
  final GroupIdentifier groupIdentifier;

  const GroupListItemWidget(this.groupIdentifier, {super.key});

  @override
  State<StatefulWidget> createState() {
    return _GroupListItemWidgetState();
  }
}

class _GroupListItemWidgetState extends State<GroupListItemWidget> {
  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);

    List<Widget> list = [];
    list.add(Expanded(
        child: Selector<GroupProvider, GroupMetadata?>(
      builder: (BuildContext context, GroupMetadata? value, Widget? child) {
        String text = widget.groupIdentifier.groupId;
        if (value != null && StringUtil.isNotBlank(value.name)) {
          text = value.name!;
        }

        return Text(text);
      },
      selector: (_, provider) {
        return provider.getMetadata(widget.groupIdentifier);
      },
    )));

    list.add(Selector<GroupProvider, int>(builder: (context, value, child) {
      if (value <= 0) {
        return Container();
      }

      return GestureDetector(
        onTap: editGroupMembers,
        child: Container(
          margin: const EdgeInsets.only(right: Base.basePadding),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [const Icon(Icons.people), Text(" $value")],
          ),
        ),
      );
    }, selector: (_, provider) {
      var admins = provider.getAdmins(widget.groupIdentifier);
      var members = provider.getMembers(widget.groupIdentifier);
      return (admins != null ? admins.users.length : 0) +
          (members != null && members.members != null
              ? members.members!.length
              : 0);
    }));

    list.add(
        Selector<GroupProvider, GroupAdmins?>(builder: (context, admins, child) {
      if (admins == null || !admins.containsUser(nostr!.publicKey)) {
        return const SizedBox.shrink();
      }

      return GestureDetector(
        onTap: editGroupMetadata,
        child: Container(
          margin: const EdgeInsets.only(right: Base.basePadding),
          child: const Icon(Icons.edit),
        ),
      );
    }, selector: (_, provider) {
      return provider.getAdmins(widget.groupIdentifier);
    }));

    list.add(GestureDetector(
      onTap: delGroup,
      child: const Icon(
        Icons.delete,
        color: Colors.red,
      ),
    ));

    return Container(
      padding: const EdgeInsets.only(
        left: Base.basePadding,
        right: Base.basePadding,
        top: Base.basePadding,
        bottom: Base.basePadding,
      ),
      color: themeData.cardColor,
      child: Row(
        children: list,
      ),
    );
  }

  void delGroup() {
    listProvider.leaveGroup(widget.groupIdentifier);
  }

  void editGroupMetadata() {
    RouterUtil.router(context, RouterPath.GROUP_EDIT, widget.groupIdentifier);
  }

  void editGroupMembers() {
    RouterUtil.router(
        context, RouterPath.GROUP_MEMBERS, widget.groupIdentifier);
  }
}
