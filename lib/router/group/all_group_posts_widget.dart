import 'package:flutter/material.dart';
import 'package:nostrmo/component/appbar_bottom_border.dart';
import 'package:nostrmo/component/keep_alive_cust_state.dart';
import 'package:nostrmo/generated/l10n.dart';
import 'package:nostrmo/router/group/communities_feed_widget.dart';
import 'package:nostrmo/router/group/communities_grid_widget.dart';
import 'package:nostrmo/router/group/create_community_dialog.dart';
import 'package:nostrmo/util/theme_util.dart';

/// Widget that provides a tabbed interface for communities:
/// - A grid view of all communities the user has joined
/// - A feed of posts from all communities
class AllGroupPostsWidget extends StatefulWidget {
  const AllGroupPostsWidget({super.key});

  @override
  State<AllGroupPostsWidget> createState() => _AllGroupPostsWidgetState();
}

class _AllGroupPostsWidgetState extends KeepAliveCustState<AllGroupPostsWidget>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }
  
  @override
  Future<void> onReady(BuildContext context) async {
    // Nothing to do on ready
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget doBuild(BuildContext context) {
    final l10n = S.of(context);
    final themeData = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          // App bar with tabs
          Container(
            color: themeData.appBarTheme.backgroundColor,
            child: Column(
              children: [
                // We don't need another title here since it's shown in the main app bar
                AppBar(
                  // No title to avoid repetition
                  centerTitle: true,
                  elevation: 0,
                  automaticallyImplyLeading: false,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      tooltip: l10n.Create_Group,
                      onPressed: _showCreateCommunityDialog,
                    ),
                  ],
                ),
                // Tab bar
                TabBar(
                  controller: _tabController,
                  indicatorColor: themeData.primaryColor,
                  labelColor: themeData.customColors.primaryForegroundColor,
                  unselectedLabelColor: themeData.textTheme.bodyMedium?.color?.withAlpha(179), // 70% opacity
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.grid_view),
                      text: "Grid View",
                    ),
                    Tab(
                      icon: Icon(Icons.view_agenda),
                      text: "Feed View",
                    ),
                  ],
                ),
                const AppBarBottomBorder(),
              ],
            ),
          ),
          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                // Communities Grid View
                CommunitiesGridWidget(),
                // Combined Feed from all communities
                CommunitiesFeedWidget(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateCommunityDialog() {
    CreateCommunityDialog.show(context);
  }
}