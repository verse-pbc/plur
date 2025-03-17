import 'package:flutter/material.dart';
import 'package:nostrmo/generated/l10n.dart';
import 'package:nostrmo/nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostrmo/component/styled_popup_menu.dart';

class GroupInfoPopupMenuWidget extends StatelessWidget {
  final GroupIdentifier groupId;

  const GroupInfoPopupMenuWidget({
    super.key,
    required this.groupId,
  });

  @override
  Widget build(BuildContext context) {
    final localization = S.of(context);

    return StyledPopupMenu(
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
      },
    );
  }
}
