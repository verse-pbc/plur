import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/provider/group_feed_provider.dart';
import 'package:nostrmo/provider/index_provider.dart';
import 'package:nostrmo/provider/list_provider.dart';
import 'package:nostrmo/router/group/communities_feed_widget.dart';
import 'package:nostrmo/router/group/no_communities_widget.dart';
import 'package:nostrmo/component/paste_join_link_button.dart';
// Import Provider package with an alias to avoid conflicts
import 'package:provider/provider.dart' as provider;

import '../../component/shimmer/shimmer.dart';
import '../../util/theme_util.dart';
import 'communities_controller.dart';
import 'communities_grid_widget.dart';

class CommunitiesScreen extends ConsumerStatefulWidget {
  const CommunitiesScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _CommunitiesScreenState();
  }
}

class _CommunitiesScreenState extends ConsumerState<CommunitiesScreen> {
  final subscribeId = StringUtil.rndNameStr(16);
  
  @override
  void dispose() {
    if (_feedProvider != null) {
      _feedProvider!.dispose();
    }
    super.dispose();
  }

  GroupFeedProvider? _feedProvider;

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final appBgColor = themeData.customColors.appBgColor;
    final separatorColor = themeData.customColors.separatorColor;
    final shimmerGradient = LinearGradient(
      colors: [separatorColor, appBgColor, separatorColor],
      stops: const [0.1, 0.3, 0.4],
      begin: const Alignment(-1.0, -0.3),
      end: const Alignment(1.0, 0.3),
      tileMode: TileMode.clamp,
    );
    // Get the view mode from IndexProvider using the aliased provider
    final indexProvider = provider.Provider.of<IndexProvider>(context);
    final viewMode = indexProvider.communityViewMode;
    final listProvider = provider.Provider.of<ListProvider>(context, listen: false);
    
    final controller = ref.watch(communitiesControllerProvider);
    
    return Scaffold(
      body: controller.when(
        data: (groupIds) {
          if (groupIds.isEmpty) {
            return const Center(
              child: NoCommunitiesWidget(),
            );
          }
          
          // Choose content based on view mode
          if (viewMode == CommunityViewMode.feed) {
            // Create and initialize the provider only once
            if (_feedProvider == null) {
              _feedProvider = GroupFeedProvider(listProvider);
              _feedProvider!.subscribe();
              _feedProvider!.doQuery(null);
            }
            return provider.ChangeNotifierProvider.value(
              value: _feedProvider!,
              child: const CommunitiesFeedWidget(),
            );
          } else {
            // Default to grid view
            return Shimmer(
              linearGradient: shimmerGradient,
              child: CommunitiesGridWidget(groupIds: groupIds),
            );
          }
        },
        error: (error, stackTrace) => Center(child: ErrorWidget(error)),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
      // Add toggle view button
      floatingActionButton: controller.maybeWhen(
        data: (groupIds) {
          if (groupIds.isEmpty) {
            // Only show paste link button when there are no groups
            return const PasteJoinLinkButton();
          } else {
            // Show both buttons when there are groups
            return Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Toggle view button
                FloatingActionButton(
                  heroTag: 'toggleView',
                  mini: true,
                  onPressed: () {
                    // Toggle the view mode in IndexProvider
                    indexProvider.setCommunityViewMode(
                      viewMode == CommunityViewMode.grid
                          ? CommunityViewMode.feed
                          : CommunityViewMode.grid
                    );
                  },
                  tooltip: viewMode == CommunityViewMode.grid
                      ? 'Switch to Feed View'
                      : 'Switch to Grid View',
                  child: Icon(
                    viewMode == CommunityViewMode.grid
                        ? Icons.view_list
                        : Icons.grid_view,
                  ),
                ),
                const SizedBox(height: 16),
                // Paste join link button
                const PasteJoinLinkButton(),
              ],
            );
          }
        },
        orElse: () => const PasteJoinLinkButton(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

