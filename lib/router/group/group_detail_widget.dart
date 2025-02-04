import 'package:flutter/material.dart';
import 'package:nostr_sdk/event.dart' as nostr_event;
import 'package:nostr_sdk/event_kind.dart';
import 'package:nostr_sdk/nip29/group_identifier.dart';
import 'package:nostr_sdk/utils/string_util.dart';
import 'package:nostrmo/component/event_delete_callback.dart';
import 'package:nostrmo/component/group_identifier_inherited_widget.dart';
import 'package:nostrmo/provider/group_provider.dart';
import 'package:nostrmo/router/edit/editor_widget.dart';
import 'package:nostrmo/router/group/group_detail_provider.dart';
import 'package:nostrmo/router/group/invite_to_community_dialog.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:provider/provider.dart';
import 'package:super_tooltip/super_tooltip.dart';

import '../../component/appbar_back_btn_widget.dart';
import '../../consts/router_path.dart';
import '../../consts/colors.dart';
import '../../generated/l10n.dart';
import '../../main.dart';
import 'group_detail_note_list_widget.dart';

class GroupDetailWidget extends StatefulWidget {
  static bool showTooltipOnGroupCreation = false;
  const GroupDetailWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return _GroupDetailWidgetState();
  }
}

class _GroupDetailWidgetState extends State<GroupDetailWidget> {
  GroupIdentifier? groupIdentifier;
  final _tooltipController = SuperTooltipController();

  GroupDetailProvider groupDetailProvider = GroupDetailProvider();

  @override
  void initState() {
    super.initState();
    if (GroupDetailWidget.showTooltipOnGroupCreation) {
      GroupDetailWidget.showTooltipOnGroupCreation = false;
      _showTooltipAfterDelay();
    }
    groupDetailProvider.refresh();
  }

  @override
  void dispose() {
    super.dispose();
    groupDetailProvider.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final bodyLargeFontSize = themeData.textTheme.bodyLarge!.fontSize;
    final localization = S.of(context);

    final argIntf = RouterUtil.routerArgs(context);
    if (argIntf == null || argIntf is! GroupIdentifier) {
      RouterUtil.back(context);
      return Container();
    }
    groupIdentifier = argIntf as GroupIdentifier?;
    groupDetailProvider.updateGroupIdentifier(groupIdentifier!);

    final groupProvider = Provider.of<GroupProvider>(context);
    final groupMetadata = groupProvider.getMetadata(groupIdentifier!);
    final groupAdmins = groupProvider.getAdmins(groupIdentifier!);
    final isAdmin = groupAdmins?.contains(nostr!.publicKey) != null;

    String title = "${localization.Group} ${localization.Detail}";
    Widget flexBackground = Container(
      color: themeData.hintColor.withOpacity(0.3),
    );
    if (groupMetadata != null) {
      if (StringUtil.isNotBlank(groupMetadata.name)) {
        title = groupMetadata.name!;
      }
    }

    var appbar = SliverAppBar(
      floating: false,
      snap: false,
      pinned: true,
      primary: true,
      expandedHeight: 60,
      leading: const AppbarBackBtnWidget(),
      title: Text(
        title,
        style: TextStyle(
          fontSize: bodyLargeFontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: flexBackground,
      ),
      actions: [
        if (isAdmin)
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Invite to Community',
            onPressed: () {
              InviteToCommunityDialog.show(context, groupIdentifier!);
            },
          ),
        IconButton(
          icon: const Icon(Icons.edit_outlined),
          onPressed: _editGroup,
        ),
        IconButton(
          icon: const Icon(Icons.group_remove_outlined),
          onPressed: _leaveGroup,
        ),
      ],
    );

    var main = SliverFillRemaining(
      child: MultiProvider(
        providers: [
          ListenableProvider<GroupDetailProvider>.value(
            value: groupDetailProvider,
          ),
        ],
        child: GroupDetailNoteListWidget(
            groupIdentifier!, groupMetadata?.name ?? groupIdentifier!.groupId),
      ),
    );

    return Scaffold(
      body: EventDeleteCallback(
        onDeleteCallback: _onEventDelete,
        child: GroupIdentifierInheritedWidget(
          key: Key("GD_${groupIdentifier.toString()}"),
          groupIdentifier: groupIdentifier!,
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
          backgroundColor: ColorList.accent,
          child: const Icon(Icons.add, color: Colors.white, size: 29),
          shape: CircleBorder()
      )
    );
  }

  void _jumpToAddNote() {
    _hideTooltip();
    List<dynamic> tags = [];
    var previousTag = ["previous", ...groupDetailProvider.notesPrevious()];
    tags.add(previousTag);
    EditorWidget.open(
      context,
      groupIdentifier: groupIdentifier,
      groupEventKind: EventKind.GROUP_NOTE,
      tagsAddedWhenSend: tags,
    ).then((event) {
      if (event != null && groupDetailProvider.isGroupNote(event)) {
        groupDetailProvider.handleDirectEvent(event);
      }
    });
  }

  void _onEventDelete(nostr_event.Event e) {
    groupDetailProvider.deleteEvent(e);
  }

  void _leaveGroup() {
    final id = groupIdentifier;
    if (id != null) {
      listProvider.leaveGroup(id);
    }
    RouterUtil.back(context);
  }

  void _editGroup() {
    RouterUtil.router(context, RouterPath.GROUP_EDIT, groupIdentifier);
  }

  void _makeTooltip() {
    _tooltipController.showTooltip();
  }

  void _hideTooltip() {
    _tooltipController.hideTooltip();
  }

  Future<void> _showTooltipAfterDelay() async {
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      _makeTooltip();
    }
  }
}
