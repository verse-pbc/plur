import 'package:flutter/material.dart';
import 'package:nostrmo/provider/index_provider.dart';
import 'package:nostrmo/provider/list_provider.dart';
import 'package:nostrmo/router/group/create_community_dialog.dart';
import 'package:nostrmo/router/group/no_communities_widget.dart';
import 'package:provider/provider.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/component/keep_alive_cust_state.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/provider/group_feed_provider.dart';
import 'dart:developer';

import '../../component/shimmer/shimmer.dart';
import '../../features/communities/communities_grid_widget.dart';
import 'communities_feed_widget.dart';
import '../../provider/relay_provider.dart';
import '../../util/time_util.dart';
import '../../util/theme_util.dart';

class CommunitiesWidget extends StatefulWidget {
  const CommunitiesWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return _CommunitiesWidgetState();
  }
}

class _CommunitiesWidgetState extends KeepAliveCustState<CommunitiesWidget>
    with PendingEventsLaterFunction {
  final subscribeId = StringUtil.rndNameStr(16);
  GroupFeedProvider? _feedProvider;

  @override
  Widget doBuild(BuildContext context) {
    print("CommunitiesWidget building...");
    
    final listProvider = Provider.of<ListProvider>(context);
    final indexProvider = Provider.of<IndexProvider>(context);
    final groupIds = listProvider.groupIdentifiers;
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

    // If no communities, show empty state
    if (groupIds.isEmpty) {
      return const Scaffold(
        body: Center(
          child: NoCommunitiesWidget(),
        ),
      );
    }

    // Get view mode from the shared IndexProvider instead of local state
    final viewMode = indexProvider.communityViewMode;
    
    // Create appropriate content based on selected view mode
    Widget content;
    switch (viewMode) {
      case CommunityViewMode.grid:
        content = Shimmer(
          linearGradient: shimmerGradient,
          child: CommunitiesGridWidget(groupIds: groupIds),
        );
        break;
      case CommunityViewMode.feed:
        // Create and initialize the provider only once
        if (_feedProvider == null) {
          _feedProvider = GroupFeedProvider(listProvider);
          _feedProvider!.subscribe();
          _feedProvider!.doQuery(null);
        }
        content = ChangeNotifierProvider.value(
          value: _feedProvider!,
          child: const CommunitiesFeedWidget(),
        );
        break;
    }

    // We don't need an app bar now that the toggle is in the main header
    return Scaffold(
      body: content,
      floatingActionButton: FloatingActionButton(
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
    );
  }

  void showCreateCommunityDialog() {
    CreateCommunityDialog.show(context);
  }

  @override
  Future<void> onReady(BuildContext context) async {
    _subscribe();
  }

  void _subscribe() {
    if (StringUtil.isNotBlank(subscribeId)) {
      _unsubscribe();
    }

    // Get current timestamp to only receive events from now onwards.
    final since = currentUnixTimestamp();
    final filters = [
      {
        // Listen for communities where user is a member
        "kinds": [EventKind.groupMembers],
        "#p": [nostr!.publicKey],
        "since": since,
      },
      {
        // Listen for communities where user is an admin
        "kinds": [EventKind.groupAdmins],
        "#p": [nostr!.publicKey],
        "since": since,
      },
      {
        // Listen for community deletions
        "kinds": [EventKind.groupDeleteGroup],
        "since": since,
      },
      {
        // Listen for community metadata edits
        "kinds": [EventKind.groupEditMetadata],
        "since": since,
      }
    ];

    try {
      nostr!.subscribe(
        filters,
        _handleSubscriptionEvent,
        id: subscribeId,
        relayTypes: [RelayType.temp],
        tempRelays: [RelayProvider.defaultGroupsRelayAddress],
        sendAfterAuth: true,
      );
    } catch (e) {
      log("Error in subscription: $e");
    }
  }

  void _handleSubscriptionEvent(Event event) {
    later(event, (list) {
      final listProvider = Provider.of<ListProvider>(context, listen: false);

      switch (event.kind) {
        case EventKind.groupDeleteGroup:
          listProvider.handleGroupDeleteEvent(event);
        case EventKind.groupMembers || EventKind.groupAdmins:
          listProvider.handleAdminMembershipEvent(event);
        case EventKind.groupEditMetadata:
          listProvider.handleEditMetadataEvent(event);
      }
    }, null);
  }

  Future<void> refresh() async {
    _subscribe();
  }

  void _unsubscribe() {
    try {
      nostr!.unsubscribe(subscribeId);
    } catch (e) {
      log("Error unsubscribing: $e");
    }
  }

  @override
  void dispose() {
    _unsubscribe();
    disposeLater();
    super.dispose();
  }
}
