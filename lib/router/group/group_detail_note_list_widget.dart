import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/router/group/group_detail_provider.dart';
import 'package:provider/provider.dart';
import 'package:nostrmo/router/group/no_notes_widget.dart';
import 'package:nostrmo/main.dart';
import 'dart:developer';

import '../../component/event/event_list_widget.dart';
import '../../component/keep_alive_cust_state.dart';
import '../../component/new_notes_updated_widget.dart';
import '../../consts/base.dart';
import '../../consts/base_consts.dart';
import '../../provider/settings_provider.dart';
import '../../util/load_more_event.dart';
import '../../util/theme_util.dart';
import '../../util/time_util.dart';
import '../../provider/relay_provider.dart';
import '../../theme/app_colors.dart';

class GroupDetailNoteListWidget extends StatefulWidget {
  final GroupIdentifier groupIdentifier;
  final String groupName;

  const GroupDetailNoteListWidget(this.groupIdentifier, this.groupName,
      {super.key});

  @override
  State<StatefulWidget> createState() {
    return _GroupDetailNoteListWidgetState();
  }
}

class _GroupDetailNoteListWidgetState
    extends KeepAliveCustState<GroupDetailNoteListWidget>
    with LoadMoreEvent, PendingEventsLaterFunction {
  final ScrollController _controller = ScrollController();

  ScrollController scrollController = ScrollController();
  final subscribeId = StringUtil.rndNameStr(16);
  
  // Add cached widgets for improved performance
  static Widget? _cachedContentWidget;
  static List<String>? _cachedEventIds;
  static String? _lastGroupId;

  @override
  void initState() {
    super.initState();
    bindLoadMoreScroll(_controller);
    
    // Check if we're dealing with a new group and reset cache if needed
    if (_lastGroupId != widget.groupIdentifier.groupId) {
      log("New group detected, clearing cache", name: "GroupDetailNoteList");
      _cachedContentWidget = null;
      _cachedEventIds = null;
      _lastGroupId = widget.groupIdentifier.groupId;
    }
    
    // Initialize immediately instead of waiting for onReady
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureSubscription();
    });
  }
  
  // Ensure we're subscribed and have data
  void _ensureSubscription() {
    if (groupDetailProvider == null) {
      try {
        groupDetailProvider = Provider.of<GroupDetailProvider>(context, listen: false);
      } catch (e) {
        log("Error getting provider: $e", name: "GroupDetailNoteList");
        return;
      }
    }
    
    // Make sure we're subscribed
    _subscribe();
    
    // Force a query if we have no data
    if (groupDetailProvider!.notesBox.isEmpty()) {
      log("No notes found, initiating query", name: "GroupDetailNoteList");
      groupDetailProvider!.doQuery(null);
    }
  }

  GroupDetailProvider? groupDetailProvider;

  @override
  Widget doBuild(BuildContext context) {
    var settingsProvider = Provider.of<SettingsProvider>(context);
    groupDetailProvider = Provider.of<GroupDetailProvider>(context);
    final themeData = Theme.of(context);
    var eventBox = groupDetailProvider!.notesBox;
    var events = eventBox.all();
    
    // Check if events have changed since last render
    final currentEventIds = events.map((e) => e.id).toList();
    final hasEventsChanged = _cachedEventIds == null || 
                           _cachedEventIds!.length != currentEventIds.length ||
                           !_cachedEventIds!.every(currentEventIds.contains);
                           
    // If we have a cached widget and events haven't changed, return it
    if (!hasEventsChanged && _cachedContentWidget != null) {
      return Container(
        color: themeData.customColors.feedBgColor,
        child: _cachedContentWidget!,
      );
    }
    
    // Update cached event IDs
    _cachedEventIds = currentEventIds;
    
    // Debug logging
    log("Building group note list for ${widget.groupIdentifier.groupId} with ${events.length} events", 
        name: "GroupDetailNoteList");

    Widget content;
    if (events.isEmpty) {
      // Show loading indicator with improved styling while actively loading
      if (groupDetailProvider!.isLoading) {
        content = Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(context.colors.accent),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Loading posts...",
                style: TextStyle(
                  fontFamily: 'SF Pro Rounded',
                  fontSize: 16,
                  color: context.colors.secondaryText,
                ),
              ),
            ],
          ),
        );
      } else {
        // Show enhanced empty state when confirmed no data
        content = NoNotesWidget(
          groupName: widget.groupName,
          onRefresh: onRefresh,
        );
      }
    } else {
      preBuild();

      // Enhanced list with optimized performance
      var main = RefreshIndicator(
        color: context.colors.accent, // Themed refresh indicator
        backgroundColor: context.colors.surface,
        onRefresh: onRefresh,
        child: ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 16),
          controller: scrollController,
          // Advanced performance optimizations
          cacheExtent: 1000, // Cache even more items for smoother scrolling
          addAutomaticKeepAlives: false, // Helps with memory usage
          addRepaintBoundaries: true, // Each item gets its own repaint boundary
          clipBehavior: Clip.none, // Avoid clipping for better performance
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          itemBuilder: (context, index) {
            var event = events[index];
            // Use RepaintBoundary for each item to isolate repaints
            return RepaintBoundary(
              child: EventListWidget(
                event: event,
                showVideo: settingsProvider.videoPreviewInList != OpenStatus.close,
                key: ValueKey(event.id), // Add key for better recycling
              ),
            );
          },
          itemCount: events.length,
        ),
      );

      // Show new posts indicator with improved styling
      var newNotesLength = groupDetailProvider!.newNotesBox.length();
      if (newNotesLength <= 0) {
        content = main;
      } else {
        List<Widget> stackList = [main];
        stackList.add(Positioned(
          top: Base.basePadding,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(30),
            color: context.colors.primary,
            child: NewNotesUpdatedWidget(
              num: newNotesLength,
              onTap: () {
                groupDetailProvider!.mergeNewEvent();
                // Smooth scroll to top with animation
                scrollController.animateTo(
                  0, 
                  duration: const Duration(milliseconds: 300), 
                  curve: Curves.easeOutCubic
                );
              },
            ),
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

    // Use theme-aware background color from AppColors extension
    return Container(
      color: context.colors.feedBackground,
      child: content,
    );
  }

  // Track if we've already initialized
  bool _hasInitialized = false;
  
  @override
  Future<void> onReady(BuildContext context) async {
    // Only initialize once to avoid expensive operations when switching tabs
    if (!_hasInitialized) {
      _ensureSubscription();
      _hasInitialized = true;
    }
  }

  void _subscribe() {
    if (StringUtil.isNotBlank(subscribeId)) {
      _unsubscribe();
    }

    log("Subscribing to events for group ${widget.groupIdentifier.groupId}", 
        name: "GroupDetailNoteList");
    
    final currentTime = currentUnixTimestamp();
    final filters = [
      {
        // Listen for group notes
        // Use #h tag to match how notes are created
        "kinds": [EventKind.groupNote],
        "#h": [widget.groupIdentifier.groupId],
        "since": currentTime
      },
      {
        // Listen for group note replies
        // Use #h tag to match how notes are created
        "kinds": [EventKind.groupNoteReply],
        "#h": [widget.groupIdentifier.groupId],
        "since": currentTime
      },
      {
        // Listen for group chat messages (NIP-29)
        "kinds": [EventKind.groupChatMessage],
        "#h": [widget.groupIdentifier.groupId],
        "since": currentTime
      },
      {
        // Listen for group chat replies (NIP-29)
        "kinds": [EventKind.groupChatReply],
        "#h": [widget.groupIdentifier.groupId],
        "since": currentTime
      }
    ];

    // Try to subscribe to multiple relays for better reliability
    try {
      // Always subscribe to the default relay
      nostr!.subscribe(
        filters,
        _handleSubscriptionEvent,
        id: subscribeId,
        relayTypes: [RelayType.temp],
        tempRelays: [RelayProvider.defaultGroupsRelayAddress],
        sendAfterAuth: true,
      );
      
      // Also subscribe to the group's specific relay if different
      if (widget.groupIdentifier.host != RelayProvider.defaultGroupsRelayAddress) {
        nostr!.subscribe(
          filters,
          _handleSubscriptionEvent,
          id: "${subscribeId}_specific",
          relayTypes: [RelayType.temp],
          tempRelays: [widget.groupIdentifier.host],
          sendAfterAuth: true,
        );
      }
    } catch (e) {
      log("Error in subscription: $e", name: "GroupDetailNoteList");
    }
  }

  /// Handles events received from group note subscription.
  void _handleSubscriptionEvent(Event event) {
    later(event, (list) {
      bool anyAdded = false;
      
      for (final e in list) {
        // Validate this event belongs to our group
        bool isValidForGroup = false;
        for (var tag in e.tags) {
          if (tag is List && tag.isNotEmpty && tag.length > 1 && 
              tag[0] == "h" && tag[1] == widget.groupIdentifier.groupId) {
            isValidForGroup = true;
            break;
          }
        }
        
        if (isValidForGroup) {
          // Pass to provider
          final wasAdded = groupDetailProvider!.onNewEvent(e);
          if (wasAdded) anyAdded = true;
        }
      }
      
      // If any valid events were added, clear the content cache
      if (anyAdded) {
        _cachedContentWidget = null;
        _cachedEventIds = null;
      }
    }, null);
  }

  Future<void> refresh() async {
    log("Refreshing subscription for group ${widget.groupIdentifier.groupId}", 
        name: "GroupDetailNoteList");
    
    // Clear caches
    _cachedContentWidget = null;
    _cachedEventIds = null;
    
    // Re-subscribe to get fresh data
    _subscribe();
  }

  void _unsubscribe() {
    try {
      nostr!.unsubscribe(subscribeId);
      // Also unsubscribe from the specific relay subscription
      nostr!.unsubscribe("${subscribeId}_specific");
    } catch (e) {
      log("Error unsubscribing: $e", name: "GroupDetailNoteList");
    }
  }

  @override
  void dispose() {
    _unsubscribe();
    disposeLater();
    scrollController.dispose();
    super.dispose();
  }

  @override
  void doQuery() {
    log("Loading more events for group ${widget.groupIdentifier.groupId}", 
        name: "GroupDetailNoteList");
    
    // Clear content cache when loading more
    _cachedContentWidget = null;
    _cachedEventIds = null;
    
    // Query for more data
    preQuery();
    groupDetailProvider!.doQuery(until);
  }

  @override
  EventMemBox getEventBox() {
    return groupDetailProvider!.notesBox;
  }

  Future<void> onRefresh() async {
    log("Manual refresh requested for group ${widget.groupIdentifier.groupId}", 
        name: "GroupDetailNoteList");
    
    // Clear caches
    _cachedContentWidget = null;
    _cachedEventIds = null;
    
    // Refresh data through provider
    groupDetailProvider!.refresh();
  }
}
