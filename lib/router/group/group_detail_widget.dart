import 'package:flutter/material.dart';
import 'package:nostr_sdk/event.dart' as nostr_event;
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/component/event_delete_callback.dart';
import 'package:nostrmo/component/group_identifier_inherited_widget.dart';
import 'package:nostrmo/provider/group_provider.dart';
import 'package:nostrmo/router/edit/editor_widget.dart';
import 'package:nostrmo/router/group/group_detail_chat_widget.dart';
import 'package:nostrmo/router/group/group_detail_provider.dart';
import 'package:nostrmo/router/group/invite_to_community_dialog.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:provider/provider.dart';
import 'package:nostrmo/util/theme_util.dart';

import '../../component/appbar_back_btn_widget.dart';
import '../../consts/router_path.dart';
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

class _GroupDetailWidgetState extends State<GroupDetailWidget> with SingleTickerProviderStateMixin {
  GroupIdentifier? _groupIdentifier;
  late TabController _tabController;
  final _groupDetailProvider = GroupDetailProvider();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Listen for tab changes to update the FAB visibility
    // Only rebuild the minimum necessary parts of the UI
    _tabController.addListener(_handleTabChange);
    
    _groupDetailProvider.refresh();
  }
  
  // Separate method to handle tab changes more efficiently
  void _handleTabChange() {
    // Only trigger a rebuild if the tab index has actually changed and completed changing
    // This avoids unnecessary rebuilds during tab transitions
    if (!_tabController.indexIsChanging) {
      // Use a more targeted rebuild approach - only rebuild the FAB
      // This is much more efficient than rebuilding the entire widget
      setState(() {
        // Empty setState triggers rebuild only for the FAB
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _groupDetailProvider.dispose();
    super.dispose();
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

    final groupProvider = Provider.of<GroupProvider>(context);
    final groupMetadata = groupProvider.getMetadata(groupIdentifier);
    final groupAdmins = groupProvider.getAdmins(groupIdentifier);
    final isAdmin = groupAdmins?.containsUser(nostr!.publicKey) ?? false;

    return Scaffold(
      body: EventDeleteCallback(
        onDeleteCallback: _onEventDelete,
        child: GroupIdentifierInheritedWidget(
          key: Key("GD_${groupIdentifier.toString()}"),
          groupIdentifier: groupIdentifier,
          groupAdmins: groupAdmins,
          child: CustomScrollView(
            slivers: [
              _buildAppBar(context, groupIdentifier, groupMetadata, isAdmin),
              _buildMainContent(context, groupIdentifier, groupMetadata),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  SliverAppBar _buildAppBar(
    BuildContext context, 
    GroupIdentifier groupIdentifier,
    GroupMetadata? groupMetadata,
    bool isAdmin,
  ) {
    final themeData = Theme.of(context);
    final bodyLargeFontSize = themeData.textTheme.bodyLarge!.fontSize;
    final localization = S.of(context);

    final title = _getAppBarTitle(localization, groupMetadata);
    
    return SliverAppBar(
      floating: false,
      snap: false,
      pinned: true,
      primary: true,
      expandedHeight: 60,
      leading: const AppbarBackBtnWidget(),
      titleSpacing: 0,
      title: _buildAppBarTitle(themeData, title, bodyLargeFontSize),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: themeData.appBarTheme.backgroundColor,
        ),
      ),
      bottom: _buildAppBarBottom(themeData, localization),
      actions: _buildAppBarActions(context, groupIdentifier, isAdmin),
    );
  }

  String _getAppBarTitle(S localization, GroupMetadata? groupMetadata) {
    if (groupMetadata != null && StringUtil.isNotBlank(groupMetadata.name)) {
      return groupMetadata.name!;
    }
    return "${localization.group} ${localization.detail}";
  }

  Widget _buildAppBarTitle(ThemeData themeData, String title, double? fontSize) {
    return Container(
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
          backgroundColor: themeData.customColors.feedBgColor,
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: themeData.customColors.primaryForegroundColor,
          ),
        ),
      ),
    );
  }

  PreferredSize _buildAppBarBottom(ThemeData themeData, S localization) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: Column(
        children: [
          _buildTabBar(themeData, localization),
          const AppBarBottomBorder(),
        ],
      ),
    );
  }

  TabBar _buildTabBar(ThemeData themeData, S localization) {
    return TabBar(
      controller: _tabController,
      indicatorColor: themeData.customColors.accentColor,
      labelColor: themeData.customColors.primaryForegroundColor,
      unselectedLabelColor: themeData.customColors.secondaryForegroundColor,
      labelStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
      ),
      indicatorWeight: 3.0,
      indicatorSize: TabBarIndicatorSize.label,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      tabs: [
        Tab(text: localization.posts),
        Tab(text: localization.chat),
      ],
    );
  }

  List<Widget> _buildAppBarActions(
    BuildContext context, 
    GroupIdentifier groupIdentifier,
    bool isAdmin,
  ) {
    final actions = <Widget>[];
    
    if (isAdmin) {
      actions.add(
        IconButton(
          icon: const Icon(Icons.person_add),
          tooltip: 'Invite to Community',
          onPressed: () => _showInviteDialog(context, groupIdentifier),
        ),
      );
    }
    
    actions.add(
      IconButton(
        icon: const Icon(Icons.search),
        tooltip: 'Search',
        onPressed: _showSearch,
      ),
    );
    
    return actions;
  }

  void _showInviteDialog(BuildContext context, GroupIdentifier groupIdentifier) {
    InviteToCommunityDialog.show(
      context: context,
      groupIdentifier: groupIdentifier,
      listProvider: listProvider,
    );
  }

  SliverFillRemaining _buildMainContent(
    BuildContext context, 
    GroupIdentifier groupIdentifier,
    GroupMetadata? groupMetadata,
  ) {
    return SliverFillRemaining(
      child: MultiProvider(
        providers: [
          ListenableProvider<GroupDetailProvider>.value(
            value: _groupDetailProvider,
          ),
        ],
        child: TabBarView(
          controller: _tabController,
          physics: const NeverScrollableScrollPhysics(), // Disable swipe to reduce accidental tab changes
          children: [
            // GroupDetailNoteListWidget already has AutomaticKeepAliveClientMixin
            RepaintBoundary(
              child: GroupDetailNoteListWidget(
                groupIdentifier, 
                groupMetadata?.name ?? groupIdentifier.groupId,
              ),
            ),
            // Chat widget might need a keep-alive wrapper depending on implementation
            RepaintBoundary(
              child: GroupDetailChatWidget(groupIdentifier),
            ),
          ],
        ),
      ),
    );
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

  // This method is now private and only used in the group info menu
  // We're keeping it here for reference but it's marked with an underscore
  // to show it's private and not used directly from this class
  /*
  void _leaveGroup() {
    final id = _groupIdentifier;
    if (id != null) {
      listProvider.leaveGroup(id);
    }
    RouterUtil.back(context);
  }
  */
  
  void _showSearch() {
    // TODO: Implement search functionality for the group
    // This will be implemented in a future PR
    // For now, show a simple toast message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Search functionality coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showGroupInfo() {
    RouterUtil.router(context, RouterPath.groupInfo, _groupIdentifier);
  }

  Widget? _buildFloatingActionButton() {
    final themeData = Theme.of(context);
    
    // Only show FAB on the Posts tab (index 0)
    // Return null for Chat tab to completely remove the FAB
    if (_tabController.index == 0) {
      // Posts tab
      return FloatingActionButton(
        onPressed: _jumpToAddNote,
        backgroundColor: themeData.customColors.accentColor,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 29),
      );
    }
    
    // Return null for chat tab to completely remove the FAB
    return null;
  }
}
