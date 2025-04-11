import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/component/event/group_event_list_widget.dart';
import 'package:nostrmo/component/keep_alive_cust_state.dart';
import 'package:nostrmo/component/new_notes_updated_widget.dart';
import 'package:nostrmo/component/paste_join_link_button.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/consts/base_consts.dart';
import 'package:nostrmo/provider/group_feed_provider.dart';
import 'package:nostrmo/provider/group_provider.dart';
import 'package:nostrmo/provider/settings_provider.dart';
import 'package:nostrmo/router/group/no_notes_widget.dart';
import 'package:nostrmo/util/theme_util.dart';
import 'package:provider/provider.dart';

class AllGroupPostsWidget extends StatefulWidget {
  const AllGroupPostsWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return _AllGroupPostsWidgetState();
  }
}

class _AllGroupPostsWidgetState extends KeepAliveCustState<AllGroupPostsWidget> with AutomaticKeepAliveClientMixin {
  final ScrollController scrollController = ScrollController();

  GroupFeedProvider? groupFeedProvider;
  
  // Add cached widgets for improved performance
  static Widget? _cachedContentWidget;
  static List<String>? _cachedEventIds;
  static bool _isInitialized = false;
  
  // Keep track of visible events to avoid unnecessary rebuilds
  final Set<String> _visibleEventIds = {};
  
  @override
  bool get wantKeepAlive => true;
  
  @override
  void initState() {
    super.initState();
    
    // Preload content 
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Preload on init
      _preloadContent();
    });
  }
  
  void _preloadContent() {
    // If we don't have a provider yet, try getting it
    if (groupFeedProvider == null) {
      try {
        groupFeedProvider = Provider.of<GroupFeedProvider>(context, listen: false);
      } catch (_) {
        // Provider not ready yet, will try again later
        return;
      }
    }
    
    // Don't double initialize
    if (!_isInitialized && groupFeedProvider != null) {
      groupFeedProvider!.subscribe();
      groupFeedProvider!.doQuery(null);
      _isInitialized = true;
    }
  }

  @override
  Widget doBuild(BuildContext context) {
    // Must call super for AutomaticKeepAliveClientMixin
    super.build(context);
    
    var settingsProvider = Provider.of<SettingsProvider>(context);
    groupFeedProvider = Provider.of<GroupFeedProvider>(context);
    final themeData = Theme.of(context);
    var eventBox = groupFeedProvider!.notesBox;
    var events = eventBox.all();
    
    // Check if events have changed since last render
    final currentEventIds = events.map((e) => e.id).toList();
    final hasEventsChanged = _cachedEventIds == null || 
                             _cachedEventIds!.length != currentEventIds.length ||
                             !_cachedEventIds!.every(currentEventIds.contains);
    
    // If events haven't changed and we have a cached widget, return it
    if (!hasEventsChanged && _cachedContentWidget != null) {
      // Return cached content
      return Container(
        color: themeData.customColors.feedBgColor,
        child: _cachedContentWidget!,
      );
    }
    
    // Update cached event IDs
    _cachedEventIds = currentEventIds;

    Widget content;
    // Check if there are posts or if we're still loading 
    if (events.isEmpty) {
      // Show loading indicator instead of empty state initially
      if (groupFeedProvider!.isLoading) {
        content = const Center(
          child: CircularProgressIndicator(),
        );
      } else {
        // Only show empty state when we've confirmed there are no events
        content = NoNotesWidget(
          groupName: "your communities",
          onRefresh: onRefresh,
        );
      }
    } else {
      // We have events to show
      var main = RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView.builder(
          padding: EdgeInsets.zero,
          controller: scrollController,
          // Add caching for better performance
          cacheExtent: 500, // Cache more items to reduce rebuilds
          itemBuilder: (context, index) {
            var event = events[index];
            // Track visible events
            _visibleEventIds.add(event.id);
            return RepaintBoundary(
              child: GroupEventListWidget(
                event: event,
                showVideo: settingsProvider.videoPreviewInList != OpenStatus.close,
                key: ValueKey(event.id), // Add key for better recycling
              ),
            );
          },
          itemCount: events.length,
        ),
      );

      var newNotesLength = groupFeedProvider!.newNotesBox.length();
      if (newNotesLength <= 0) {
        content = main;
      } else {
        List<Widget> stackList = [main];
        stackList.add(Positioned(
          top: Base.basePadding,
          child: NewNotesUpdatedWidget(
            num: newNotesLength,
            onTap: () {
              groupFeedProvider!.mergeNewEvent();
              scrollController.jumpTo(0);
            },
          ),
        ));
        content = Stack(
          alignment: Alignment.center,
          children: stackList,
        );
      }
    }
    
    // Cache the content widget for future use
    _cachedContentWidget = content;

    return Container(
      color: themeData.customColors.feedBgColor,
      child: content,
    );
  }

  @override
  Future<void> onReady(BuildContext context) async {
    // Only initialize once
    if (!_isInitialized) {
      groupFeedProvider!.subscribe();
      groupFeedProvider!.doQuery(null);
      _isInitialized = true;
    }
  }

  Future<void> onRefresh() async {
    // Clear content cache when refreshing
    _cachedContentWidget = null;
    _cachedEventIds = null;
    
    // Request fresh data
    groupFeedProvider!.refresh();
  }
  
  @override
  void dispose() {
    // Don't clear the static cache
    super.dispose();
  }
}