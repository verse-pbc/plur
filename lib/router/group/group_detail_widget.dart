import 'package:flutter/material.dart';
import 'package:nostr_sdk/event.dart' as nostr_event;
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/component/event_delete_callback.dart';
import 'package:nostrmo/component/group_identifier_inherited_widget.dart';
import 'package:nostrmo/provider/group_feed_provider.dart';
import 'package:nostrmo/provider/group_provider.dart';
import 'package:nostrmo/provider/group_providers.dart';
import 'package:nostrmo/router/edit/editor_widget.dart';
import 'package:nostrmo/router/group/group_detail_asks_offers_widget.dart';
import 'package:nostrmo/router/group/group_detail_chat_widget.dart';
import 'package:nostrmo/router/group/group_detail_events_widget.dart';
import 'package:nostrmo/router/group/group_detail_provider.dart';
import 'package:nostrmo/router/group/invite_to_community_dialog.dart';
import 'package:nostrmo/router/group/invite_debug_dialog.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:provider/provider.dart';
import 'package:nostrmo/theme/app_colors.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

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
    _tabController = TabController(length: 4, vsync: this);
    
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

    // Wrap in GroupProviders to ensure access to read status tracking
    return GroupProviders(
      child: Builder(
        builder: (providerContext) {
          // Schedule marking the group as viewed after the build is complete
          // This avoids the "setState during build" error
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (providerContext.mounted) {
              final feedProvider = Provider.of<GroupFeedProvider>(providerContext, listen: false);
              feedProvider.markGroupViewed(groupIdentifier);
            }
          });
          
          return Scaffold(
            body: EventDeleteCallback(
              onDeleteCallback: _onEventDelete,
              child: GroupIdentifierInheritedWidget(
                key: Key("GD_${groupIdentifier.toString()}"),
                groupIdentifier: groupIdentifier,
                groupAdmins: groupAdmins,
                child: CustomScrollView(
                  slivers: [
                    _buildAppBar(providerContext, groupIdentifier, groupMetadata, isAdmin),
                    _buildMainContent(providerContext, groupIdentifier, groupMetadata),
                  ],
                ),
              ),
            ),
            floatingActionButton: _buildFloatingActionButton(),
          );
        },
      ),
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
          backgroundColor: context.colors.feedBackground,
        ),
        child: Text(
          title,
          style: TextStyle(
            fontFamily: 'SF Pro Rounded',
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: context.colors.primaryText,
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
      indicatorColor: context.colors.accent,
      labelColor: context.colors.primaryText,
      unselectedLabelColor: context.colors.secondaryText,
      labelStyle: const TextStyle(
        fontFamily: 'SF Pro Rounded',
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
      unselectedLabelStyle: const TextStyle(
        fontFamily: 'SF Pro Rounded',
        fontSize: 16,
        fontWeight: FontWeight.normal,
      ),
      indicatorWeight: 3.0,
      indicatorSize: TabBarIndicatorSize.label,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      isScrollable: true, // Allow scrolling for more tabs
      tabs: [
        Tab(text: localization.posts),
        Tab(text: localization.chat),
        Tab(text: localization.asksAndOffers),
        Tab(text: localization.events),
      ],
    );
  }

  List<Widget> _buildAppBarActions(
    BuildContext context, 
    GroupIdentifier groupIdentifier,
    bool isAdmin,
  ) {
    final actions = <Widget>[];
    
    // Add "Mark All as Read" button
    actions.add(
      IconButton(
        icon: const Icon(Icons.mark_email_read),
        tooltip: "Mark All as Read",
        onPressed: () {
          try {
            // Get the GroupFeedProvider and mark all posts as read
            final feedProvider = Provider.of<GroupFeedProvider>(context, listen: false);
            feedProvider.markGroupRead(groupIdentifier);
            
            // Show a confirmation message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Marked all as read"),
                duration: Duration(seconds: 2),
              ),
            );
          } catch (e) {
            // Show error message if there's an issue
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("${S.of(context).error}: $e"),
                duration: const Duration(seconds: 3),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
    
    if (isAdmin) {
      // Create a popup menu for invite options
      actions.add(
        PopupMenuButton<String>(
          icon: const Icon(Icons.person_add),
          tooltip: S.of(context).invite,
          itemBuilder: (context) => [
            PopupMenuItem<String>(
              value: 'link',
              child: Row(
                children: [
                  const Icon(Icons.link),
                  const SizedBox(width: 8),
                  Text(S.of(context).inviteLink),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'name',
              child: Row(
                children: [
                  const Icon(Icons.search),
                  const SizedBox(width: 8),
                  Text(S.of(context).inviteByName),
                ],
              ),
            ),
            // Add debug option in debug mode
            if (kDebugMode)
              PopupMenuItem<String>(
                value: 'debug',
                child: Row(
                  children: [
                    const Icon(Icons.bug_report, color: Colors.orange),
                    const SizedBox(width: 8),
                    Text('Debug Invite Links', style: TextStyle(
                      fontFamily: 'SF Pro Rounded',
                      color: Colors.orange,
                    )),
                  ],
                ),
              ),
          ],
          onSelected: (value) {
            switch (value) {
              case 'link':
                _showInviteDialog(context, groupIdentifier);
                break;
              case 'name':
                _showInviteByNameScreen(context, groupIdentifier);
                break;
              case 'debug':
                InviteDebugDialog.show(context);
                break;
            }
          },
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
  
  void _showInviteByNameScreen(BuildContext context, GroupIdentifier groupIdentifier) {
    RouterUtil.router(context, RouterPath.inviteByName, groupIdentifier);
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
            // Asks/Offers tab
            RepaintBoundary(
              child: GroupDetailAsksOffersWidget(groupIdentifier),
            ),
            // Events tab
            RepaintBoundary(
              child: GroupDetailEventsWidget(groupIdentifier),
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
    final colors = context.colors;
    
    switch (_tabController.index) {
      case 0:
        // Posts tab - show enhanced add note button
        return Container(
          margin: const EdgeInsets.only(bottom: 16, right: 4),
          child: FloatingActionButton.extended(
            heroTag: 'group_detail_add_note_fab',
            onPressed: _jumpToAddNote,
            backgroundColor: colors.accent,
            elevation: 4,
            highlightElevation: 8,
            extendedPadding: const EdgeInsets.symmetric(horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32),
            ),
            label: Row(
              children: [
                const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text(
                  "New Post",
                  style: TextStyle(
                    fontFamily: 'SF Pro Rounded',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            icon: null, // Using custom icon in the label instead
          ),
        );
        
      // Tabs 1 and 2 (Chat and Asks/Offers) don't need FAB
      // The Events tab (index 3) has its own FAB inside its widget
      
      default:
        // Hide FAB for other tabs
        return null;
    }
  }
}
