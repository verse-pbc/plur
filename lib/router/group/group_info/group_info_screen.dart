import 'package:flutter/material.dart';
import 'package:nostrmo/nostr_sdk/nostr_sdk.dart';
import 'package:provider/provider.dart';
import 'package:nostrmo/provider/group_provider.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:nostrmo/component/appbar_back_btn_widget.dart';
import 'package:nostrmo/generated/l10n.dart';
import '../../../component/appbar_bottom_border.dart';
import '../../../util/theme_util.dart';
import 'group_info_header_widget.dart';
import 'group_info_menu_widget.dart';
import 'group_info_popupmenu_widget.dart';
import '../../../consts/base.dart';

/// Displays detailed information about a group.
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

    final groupId = argIntf;
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
          GroupInfoPopupMenuWidget(groupId: groupId),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: Base.maxScreenWidth),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                GroupInfoHeaderWidget(
                  metadata: metadata,
                  memberCount: memberCount,
                ),
                if (metadata.about != null) ...[
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      metadata.about!,
                      style: themeData.textTheme.bodyMedium,
                      textAlign: TextAlign.start,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                GroupInfoMenuWidget(groupId: groupId),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
