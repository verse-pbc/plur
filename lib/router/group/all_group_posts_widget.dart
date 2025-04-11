import 'package:flutter/material.dart';
import 'package:nostrmo/component/appbar_bottom_border.dart';
import 'package:nostrmo/component/keep_alive_cust_state.dart';
import 'package:nostrmo/component/paste_join_link_button.dart';
import 'package:nostrmo/router/group/communities_feed_widget.dart';
import 'package:nostrmo/router/group/communities_grid_widget.dart';
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
    final themeData = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          // App bar with tabs
          Container(
            color: themeData.appBarTheme.backgroundColor,
            child: Column(
              children: [
                // Minimal app bar - no title or buttons needed since they're in the main app bar
                AppBar(
                  automaticallyImplyLeading: false,
                  elevation: 0,
                  toolbarHeight: 8, // Minimal height
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
      // Add the paste link button that appears when clipboard has a join link
      floatingActionButton: const PasteJoinLinkButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

}