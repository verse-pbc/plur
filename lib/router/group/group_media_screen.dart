import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:provider/provider.dart';
import 'package:nostrmo/provider/group_provider.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:nostrmo/component/appbar_back_btn_widget.dart';
import 'package:nostrmo/generated/l10n.dart';
import '../../component/appbar_bottom_border.dart';
import '../../theme/app_colors.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'group_info/group_info_header_widget.dart';
import 'group_info/group_info_popupmenu_widget.dart';
import '../../consts/base.dart';
import 'group_media_grid_widget.dart';

/// Displays media content from a group with consistent navigation
class GroupMediaScreen extends StatefulWidget {
  const GroupMediaScreen({Key? key}) : super(key: key);

  @override
  State<GroupMediaScreen> createState() => _GroupMediaScreenState();
}

class _GroupMediaScreenState extends State<GroupMediaScreen> {
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
          localization.media,
          style: TextStyle(
            color: context.colors.primaryText,
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
          // Group header
          GroupInfoHeaderWidget(
            metadata: metadata,
            memberCount: memberCount,
          ),
          
          // Media section title
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Text(
                  localization.media,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.colors.primaryText,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    Icons.refresh,
                    color: context.colors.accent,
                  ),
                  onPressed: () {
                    // Refresh media
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
          
          // Media grid (takes remaining space)
          Expanded(
            child: GroupMediaGridWidget(groupId: groupId),
          ),
        ],
      ),
    );
  }
}