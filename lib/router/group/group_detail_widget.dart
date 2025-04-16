import 'package:flutter/material.dart';
import 'package:nostr_sdk/event.dart' as nostr_event;
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/component/event_delete_callback.dart';
import 'package:nostrmo/component/group_identifier_inherited_widget.dart';
import 'package:nostrmo/provider/group_provider.dart';
import 'package:nostrmo/router/edit/editor_widget.dart';
import 'package:nostrmo/router/group/group_detail_provider.dart';
import 'package:nostrmo/router/group/invite_to_community_dialog.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:provider/provider.dart';
import 'package:nostrmo/util/theme_util.dart';

import '../../component/appbar_back_btn_widget.dart';
import '../../consts/router_path.dart';
import '../../features/leave_community/leave_community_button.dart';
import '../../generated/l10n.dart';
import '../../main.dart';
import 'group_detail_note_list_widget.dart';
import '../../component/appbar_bottom_border.dart';

class GroupDetailWidget extends StatefulWidget {
  static bool showTooltipOnGroupCreation = false;
  const GroupDetailWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return _GroupDetailWidgetState();
  }
}

class _GroupDetailWidgetState extends State<GroupDetailWidget> {
  GroupIdentifier? _groupIdentifier;

  final _groupDetailProvider = GroupDetailProvider();

  @override
  void initState() {
    super.initState();
    _groupDetailProvider.refresh();
  }

  @override
  void dispose() {
    super.dispose();
    _groupDetailProvider.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupIdentifier = RouterUtil.routerArgs(context);
    if (groupIdentifier == null || groupIdentifier is! GroupIdentifier) {
      RouterUtil.back(context);
      return Container();
    }

    _groupIdentifier ??= groupIdentifier;
    _groupDetailProvider.updateGroupIdentifier(groupIdentifier);

    final themeData = Theme.of(context);
    final bodyLargeFontSize = themeData.textTheme.bodyLarge!.fontSize;
    final localization = S.of(context);

    final groupProvider = Provider.of<GroupProvider>(context);
    final groupMetadata = groupProvider.getMetadata(groupIdentifier);
    final groupAdmins = groupProvider.getAdmins(groupIdentifier);
    final isAdmin = groupAdmins?.containsUser(nostr!.publicKey) ?? false;

    String title = "${localization.Community} ${localization.Detail}";
    Widget flexBackground = Container(
      color: themeData.appBarTheme.backgroundColor,
    );
    if (groupMetadata != null && StringUtil.isNotBlank(groupMetadata.name)) {
      title = groupMetadata.name!;
    }

    var appbar = SliverAppBar(
      floating: false,
      snap: false,
      pinned: true,
      primary: true,
      expandedHeight: 60,
      leading: const AppbarBackBtnWidget(),
      titleSpacing: 0,
      title: Container(
        width: double.infinity,
        height: 45,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: ElevatedButton(
          onPressed: _showGroupInfo,
          style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: EdgeInsets.zero,
              backgroundColor: themeData.customColors.feedBgColor),
          child: Text(
            title,
            style: TextStyle(
                fontSize: bodyLargeFontSize,
                fontWeight: FontWeight.bold,
                color: themeData.customColors.primaryForegroundColor),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: flexBackground,
      ),
      bottom: const AppBarBottomBorder(),
      actions: [
        if (isAdmin)
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Invite to Community',
            onPressed: () {
              InviteToCommunityDialog.show(
                context: context,
                groupIdentifier: groupIdentifier,
                listProvider: listProvider,
              );
            },
          ),
        LeaveCommunityButton(
          groupIdentifier,
          onLeft: () => RouterUtil.back(context),
        ),
      ],
    );

    var main = SliverFillRemaining(
      child: MultiProvider(
        providers: [
          ListenableProvider<GroupDetailProvider>.value(
            value: _groupDetailProvider,
          ),
        ],
        child: GroupDetailNoteListWidget(
            groupIdentifier, groupMetadata?.name ?? groupIdentifier.groupId),
      ),
    );

    return Scaffold(
        body: EventDeleteCallback(
          onDeleteCallback: _onEventDelete,
          child: GroupIdentifierInheritedWidget(
            key: Key("GD_${groupIdentifier.toString()}"),
            groupIdentifier: groupIdentifier,
            groupAdmins: groupAdmins,
            child: CustomScrollView(
              slivers: [
                appbar,
                main,
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _jumpToAddNote,
          backgroundColor: themeData.customColors.accentColor,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, color: Colors.white, size: 29),
        ));
  }

  void _jumpToAddNote() {
    List<dynamic> tags = [];
    var previousTag = ["previous", ..._groupDetailProvider.notesPrevious()];
    tags.add(previousTag);
    EditorWidget.open(
      context,
      groupIdentifier: _groupIdentifier,
      groupEventKind: EventKind.groupNote,
      tagsAddedWhenSend: tags,
    ).then((event) {
      if (event != null && _groupDetailProvider.isGroupNote(event)) {
        _groupDetailProvider.handleDirectEvent(event);
      }
    });
  }

  void _onEventDelete(nostr_event.Event e) {
    _groupDetailProvider.deleteEvent(e);
  }

  void _showGroupInfo() {
    RouterUtil.router(context, RouterPath.groupInfo, _groupIdentifier);
  }
}
