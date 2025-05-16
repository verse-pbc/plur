import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/features/events/models/event_model.dart';
import 'package:nostrmo/features/events/models/event_rsvp_model.dart';
import 'package:nostrmo/features/events/providers/event_provider.dart';
import 'package:nostrmo/features/events/screens/event_creation_screen.dart';
import 'package:nostrmo/features/events/screens/event_detail_screen.dart';
import 'package:nostrmo/theme/app_colors.dart';
import 'package:nostrmo/util/group_id_util.dart';
import 'package:nostrmo/generated/l10n.dart';
import 'package:nostrmo/main.dart';
import 'package:table_calendar/table_calendar.dart';

/// View modes for events
enum EventViewMode {
  /// List view
  list,
  /// Calendar view
  calendar,
  /// Map view
  map,
}

/// Widget displaying the events tab in a group detail view
class GroupDetailEventsWidget extends ConsumerStatefulWidget {
  /// Group identifier for this widget
  final GroupIdentifier groupIdentifier;

  /// Constructor
  const GroupDetailEventsWidget(this.groupIdentifier, {super.key});

  @override
  ConsumerState<GroupDetailEventsWidget> createState() => _GroupDetailEventsWidgetState();
}

class _GroupDetailEventsWidgetState extends ConsumerState<GroupDetailEventsWidget> 
    with AutomaticKeepAliveClientMixin {
  
  // Current view mode state
  EventViewMode _viewMode = EventViewMode.list;
  
  // Filter state
  bool _showPastEvents = false;
  EventVisibility? _selectedVisibility;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize events for this group after the widget tree is built
    // This prevents "Tried to modify a provider while the widget tree was building" errors
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadEvents();
      }
    });
  }
  
  Future<void> _loadEvents() async {
    try {
      // Format the group ID as "host:id" for the filter
      final groupId = GroupIdUtil.formatForHTag(widget.groupIdentifier);
      
      // Log for debugging
      debugPrint("Loading events for group ID: $groupId");
      
      // Use Future.microtask to delay provider updates until after widget build is complete
      return Future.microtask(() async {
        if (mounted) {
          try {
            // Load events first
            await ref.read(eventProvider.notifier).loadEvents(groupId: groupId);
            
            // Then load RSVPs - catch errors separately to avoid one failure affecting the other
            try {
              await ref.read(eventRSVPProvider.notifier).loadRSVPs(groupId: groupId);
            } catch (rsvpError, rsvpStack) {
              debugPrint("Error loading RSVPs: $rsvpError");
              // Continue without RSVPs if they fail to load
            }
          } catch (error, stack) {
            debugPrint("Error loading events: $error");
            // We'll handle display of errors in the UI, so we don't rethrow
          }
        }
      });
    } catch (e, stack) {
      debugPrint("Fatal error in _loadEvents: $e");
      debugPrint("Stack trace: $stack");
      // Continue without crashing the app
    }
  }
  
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    try {
      final themeData = Theme.of(context);
      final l10n = S.of(context);
      
      // Format the group ID for filtering
      String groupId;
      try {
        groupId = GroupIdUtil.formatForHTag(widget.groupIdentifier);
      } catch (e) {
        // Use a fallback if the group ID can't be formatted
        debugPrint("Error formatting group ID: $e");
        groupId = widget.groupIdentifier.toString();
      }
      
      // Get events data using try-catch to handle potential provider errors
      AsyncValue<List<EventModel>> eventsState;
      try {
        eventsState = ref.watch(eventProvider);
      } catch (e) {
        debugPrint("Error watching event provider: $e");
        // Use loading state as fallback when the provider watch fails
        eventsState = const AsyncValue.loading();
      }
      
      return Stack(
        children: [
          // Main content
          Column(
            children: [
              // View mode and filter toolbar
              _buildToolbar(themeData, l10n),
              
              // Events content based on selected view
              Expanded(
                child: eventsState.when(
                  data: (events) {
                    try {
                      // Filter events based on current filters
                      List<EventModel> filteredEvents;
                      try {
                        filteredEvents = ref.read(eventProvider.notifier).filterEvents(
                          groupId: groupId,
                          visibility: _selectedVisibility,
                          showPastEvents: _showPastEvents,
                        );
                      } catch (filterError) {
                        debugPrint("Error filtering events: $filterError");
                        // Use empty list as fallback if filtering fails
                        filteredEvents = [];
                      }
                      
                      if (filteredEvents.isEmpty) {
                        return _buildEmptyState(themeData, l10n);
                      }
                      
                      // Display events based on current view mode
                      switch (_viewMode) {
                        case EventViewMode.list:
                          return _buildListView(filteredEvents, themeData);
                        case EventViewMode.calendar:
                          return _buildCalendarView(groupId, themeData, l10n);
                        case EventViewMode.map:
                          return _buildMapView(filteredEvents, themeData, l10n);
                      }
                      
                    } catch (e, stack) {
                      debugPrint("Error rendering events: $e");
                      debugPrint("Stack trace: $stack");
                      return _buildErrorState(l10n);
                    }
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (error, stackTrace) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(l10n.errorWhileLoadingEvents),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadEvents,
                          child: Text(l10n.tryAgain),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          // FAB
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'group_detail_create_event_fab',
              onPressed: _createEvent,
              backgroundColor: context.colors.accent,
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
        ],
      );
    } catch (e, stack) {
      // Ultimate fallback - return a simple error widget that won't crash
      debugPrint("Critical error in events build method: $e");
      debugPrint("Stack trace: $stack");
      
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text("There was a problem loading events"),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  try {
                    _loadEvents();
                  } catch (e) {
                    // Ignore errors in the fallback
                  }
                },
                child: const Text("Try Again"),
              ),
            ],
          ),
        ),
      );
    }
  }
  
  Widget _buildErrorState(S l10n) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 36, color: Colors.orange),
          const SizedBox(height: 16),
          Text(l10n.errorWhileLoadingEvents),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadEvents,
            child: Text(l10n.tryAgain),
          ),
        ],
      ),
    );
  }
  
  Widget _buildToolbar(ThemeData themeData, S l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: context.colors.feedBackground,
        border: Border(
          bottom: BorderSide(
            color: context.colors.divider.withAlpha(77),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        children: [
          // View mode selector
          Row(
            children: [
              // List view button
              Expanded(
                child: _buildViewModeButton(
                  themeData,
                  label: l10n.list,
                  icon: Icons.list,
                  isSelected: _viewMode == EventViewMode.list,
                  onTap: () => setState(() => _viewMode = EventViewMode.list),
                ),
              ),
              // Calendar view button
              Expanded(
                child: _buildViewModeButton(
                  themeData,
                  label: l10n.calendar,
                  icon: Icons.calendar_month,
                  isSelected: _viewMode == EventViewMode.calendar,
                  onTap: () => setState(() => _viewMode = EventViewMode.calendar),
                ),
              ),
              // Map view button
              Expanded(
                child: _buildViewModeButton(
                  themeData,
                  label: l10n.map,
                  icon: Icons.map,
                  isSelected: _viewMode == EventViewMode.map,
                  onTap: () => setState(() => _viewMode = EventViewMode.map),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Filter options
          Row(
            children: [
              // Show past events toggle
              FilterChip(
                label: Text(l10n.pastEvents),
                selected: _showPastEvents,
                onSelected: (selected) {
                  setState(() {
                    _showPastEvents = selected;
                  });
                },
                selectedColor: context.colors.accent.withAlpha(51),
                checkmarkColor: context.colors.accent,
              ),
              
              const SizedBox(width: 8),
              
              // Visibility filter
              PopupMenuButton<EventVisibility?>(
                initialValue: _selectedVisibility,
                onSelected: (visibility) {
                  setState(() {
                    _selectedVisibility = visibility;
                  });
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: null,
                    child: Text("All"),
                  ),
                  PopupMenuItem(
                    value: EventVisibility.public,
                    child: Text(l10n.public),
                  ),
                  PopupMenuItem(
                    value: EventVisibility.publicLink,
                    child: Text(l10n.unlisted),
                  ),
                  PopupMenuItem(
                    value: EventVisibility.private,
                    child: Text(l10n.private),
                  ),
                ],
                child: Chip(
                  label: Text(_getVisibilityLabel(l10n)),
                  deleteIcon: const Icon(Icons.arrow_drop_down),
                  onDeleted: () {},
                ),
              ),
              
              const Spacer(),
              
              // Search button
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  // TODO: Implement search for events
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${l10n.search} ${l10n.comingSoon}')),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildViewModeButton(
    ThemeData themeData, {
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? themeData.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected 
                  ? Colors.white 
                  : context.colors.secondaryText,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected 
                    ? Colors.white 
                    : context.colors.secondaryText,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  String _getVisibilityLabel(S l10n) {
    switch (_selectedVisibility) {
      case EventVisibility.public:
        return l10n.public;
      case EventVisibility.publicLink:
        return l10n.unlisted;
      case EventVisibility.private:
        return l10n.private;
      case null:
        return l10n.allVisibility;
    }
  }
  
  Widget _buildEmptyState(ThemeData themeData, S l10n) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.event_available,
            size: 72,
            color: Colors.grey.withAlpha(128), // 0.5 * 255 = 128
          ),
          const SizedBox(height: 16),
          Text(
            _showPastEvents 
                ? l10n.noEventsFound 
                : l10n.noUpcomingEvents,
            style: themeData.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _createEvent,
            icon: const Icon(Icons.add_circle_outline, size: 16),
            label: Text(l10n.createAnEvent),
          ),
        ],
      ),
    );
  }
  
  Widget _buildListView(List<EventModel> events, ThemeData themeData) {
    return RefreshIndicator(
      onRefresh: _loadEvents,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80), // Space for FAB
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          return _buildEventCard(event, themeData);
        },
      ),
    );
  }
  
  Widget _buildCalendarView(String groupId, ThemeData themeData, S l10n) {
    try {
      // TODO: Implement proper calendar view with table_calendar package
      // For now, show a placeholder that won't crash
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.calendarView,
              style: themeData.textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.comingSoon,
              style: themeData.textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _loadEvents(),
              child: Text(l10n.tryAgain),
            ),
          ],
        ),
      );
    } catch (e) {
      // Provide absolute fallback in case of any errors
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_month,
                size: 48,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text("Calendar View Coming Soon"),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _loadEvents(),
                child: Text("Try Again"),
              ),
            ],
          ),
        ),
      );
    }
  }
  
  Widget _buildMapView(List<EventModel> events, ThemeData themeData, S l10n) {
    try {
      // TODO: Implement proper map view in the future
      // For now, show a simple placeholder
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.mapView,
              style: themeData.textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.comingSoon,
              style: themeData.textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadEvents,
              child: Text(l10n.refresh),
            ),
          ],
        ),
      );
    } catch (e) {
      // Provide absolute fallback in case of any errors
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.map,
                size: 48,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text("Map View Coming Soon"),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadEvents,
                child: Text("Refresh"),
              ),
            ],
          ),
        ),
      );
    }
  }
  
  Widget _buildEventCard(EventModel event, ThemeData themeData) {
    final now = DateTime.now();
    final isUpcoming = event.startAt.isAfter(now);
    
    // Format event date and time
    final dateFormat = event.startAt.year == now.year 
        ? '${_getMonthName(event.startAt.month)} ${event.startAt.day}'
        : '${_getMonthName(event.startAt.month)} ${event.startAt.day}, ${event.startAt.year}';
        
    final timeFormat = '${event.startAt.hour.toString().padLeft(2, '0')}:${event.startAt.minute.toString().padLeft(2, '0')}';
    
    // Calculate event status color
    final statusColor = isUpcoming 
        ? context.colors.accent
        : Colors.grey;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: context.colors.divider.withAlpha(77),
          width: 0.5,
        ),
      ),
      elevation: 1,
      child: InkWell(
        onTap: () => _openEventDetails(event),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Event cover image if available
            if (event.coverImageUrl != null && event.coverImageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  event.coverImageUrl!,
                  height: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 120,
                      color: context.colors.accent.withAlpha(26),
                      child: const Center(
                        child: Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                      ),
                    );
                  },
                ),
              ),
            
            // Event details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date and time
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withAlpha(26), // 0.1 * 255 = 26
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.event, size: 16, color: statusColor),
                            const SizedBox(width: 4),
                            Text(
                              dateFormat,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withAlpha(26), // 0.1 * 255 = 26
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.access_time, size: 16, color: statusColor),
                            const SizedBox(width: 4),
                            Text(
                              timeFormat,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const Spacer(),
                      
                      // Visibility indicator
                      _buildVisibilityBadge(event.visibility, themeData),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Event title
                  Text(
                    event.title,
                    style: themeData.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Event description (truncated)
                  Text(
                    event.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: themeData.textTheme.bodyMedium,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Location if available
                  if (event.location != null && event.location!.isNotEmpty)
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: context.colors.secondaryText,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.location!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: context.colors.secondaryText,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                  const SizedBox(height: 8),
                  
                  // RSVP counts
                  _buildRSVPCounts(event.id, themeData),
                ],
              ),
            ),
            
            // RSVP buttons
            _buildRSVPButtons(event, themeData),
          ],
        ),
      ),
    );
  }
  
  Widget _buildVisibilityBadge(EventVisibility visibility, ThemeData themeData) {
    IconData icon;
    String tooltip;
    Color color;
    
    switch (visibility) {
      case EventVisibility.public:
        icon = Icons.public;
        tooltip = 'Public';
        color = Colors.green;
        break;
      case EventVisibility.publicLink:
        icon = Icons.link;
        tooltip = 'Unlisted';
        color = Colors.orange;
        break;
      case EventVisibility.private:
        icon = Icons.lock;
        tooltip = 'Private';
        color = Colors.red;
        break;
    }
    
    return Tooltip(
      message: tooltip,
      child: Icon(
        icon,
        size: 16,
        color: color,
      ),
    );
  }
  
  Widget _buildRSVPCounts(String eventId, ThemeData themeData) {
    // Get RSVP counts from the provider
    final rsvpsState = ref.watch(eventRSVPProvider);
    
    if (!rsvpsState.hasValue) {
      return const SizedBox();
    }
    
    final counts = ref.read(eventRSVPProvider.notifier).getRSVPCountsForEvent(eventId);
    
    return Row(
      children: [
        // Going count
        _buildRSVPCountBadge(
          count: counts[RSVPStatus.going] ?? 0,
          icon: Icons.check_circle_outline,
          color: Colors.green,
        ),
        
        const SizedBox(width: 16),
        
        // Interested count
        _buildRSVPCountBadge(
          count: counts[RSVPStatus.interested] ?? 0,
          icon: Icons.star_outline,
          color: Colors.orange,
        ),
      ],
    );
  }
  
  Widget _buildRSVPCountBadge({
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          count.toString(),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  Widget _buildRSVPButtons(EventModel event, ThemeData themeData) {
    // Current user's RSVP status, if any
    final rsvpsState = ref.watch(eventRSVPProvider);
    RSVPStatus? userStatus;
    
    if (rsvpsState.hasValue) {
      final userRSVP = ref.read(eventRSVPProvider.notifier).getUserRSVPForEvent(event.id);
      if (userRSVP != null) {
        userStatus = userRSVP.status;
      }
    }
    
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: context.colors.divider.withAlpha(77),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Going button
          Expanded(
            child: TextButton.icon(
              onPressed: () => _submitRSVP(event, RSVPStatus.going),
              icon: Icon(
                Icons.check_circle_outline,
                size: 16,
                color: userStatus == RSVPStatus.going
                    ? Colors.green
                    : context.colors.secondaryText,
              ),
              label: Text(
                'Going',
                style: TextStyle(
                  color: userStatus == RSVPStatus.going
                      ? Colors.green
                      : context.colors.secondaryText,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: userStatus == RSVPStatus.going
                    ? Colors.green.withAlpha(26) // 0.1 * 255 = 26
                    : Colors.transparent,
              ),
            ),
          ),
          
          // Vertical divider
          Container(
            height: 24,
            width: 1,
            color: context.colors.divider.withAlpha(128),
          ),
          
          // Interested button
          Expanded(
            child: TextButton.icon(
              onPressed: () => _submitRSVP(event, RSVPStatus.interested),
              icon: Icon(
                Icons.star_outline,
                size: 16,
                color: userStatus == RSVPStatus.interested
                    ? Colors.orange
                    : context.colors.secondaryText,
              ),
              label: Text(
                'Interested',
                style: TextStyle(
                  color: userStatus == RSVPStatus.interested
                      ? Colors.orange
                      : context.colors.secondaryText,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: userStatus == RSVPStatus.interested
                    ? Colors.orange.withAlpha(26) // 0.1 * 255 = 26
                    : Colors.transparent,
              ),
            ),
          ),
          
          // Vertical divider
          Container(
            height: 24,
            width: 1,
            color: context.colors.divider.withAlpha(128),
          ),
          
          // Can't go button
          Expanded(
            child: TextButton.icon(
              onPressed: () => _submitRSVP(event, RSVPStatus.notGoing),
              icon: Icon(
                Icons.cancel_outlined,
                size: 16,
                color: userStatus == RSVPStatus.notGoing
                    ? Colors.red
                    : context.colors.secondaryText,
              ),
              label: Text(
                'Can\'t Go',
                style: TextStyle(
                  color: userStatus == RSVPStatus.notGoing
                      ? Colors.red
                      : context.colors.secondaryText,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: userStatus == RSVPStatus.notGoing
                    ? Colors.red.withAlpha(26) // 0.1 * 255 = 26
                    : Colors.transparent,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _openEventDetails(EventModel event) {
    // Navigate to event details screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EventDetailScreen(
          event: event,
          groupId: GroupIdUtil.formatForHTag(widget.groupIdentifier),
        ),
      ),
    ).then((result) {
      // If event was deleted or updated, refresh the events list
      if (result == true) {
        _loadEvents();
      }
    });
  }
  
  Future<void> _submitRSVP(EventModel event, RSVPStatus status) async {
    try {
      await ref.read(eventRSVPProvider.notifier).submitRSVP(
        eventId: event.id,
        eventDTag: event.d,
        status: status,
        groupId: event.groupId,
        visibility: event.visibility.value,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('RSVP submitted: ${status.value}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting RSVP: $e')),
      );
    }
  }
  
  void _createEvent() async {
    // Check if user is logged in by checking nostr
    if (nostr == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You need to log in to create events')),
      );
      return;
    }
    
    try {
      // Navigate to event creation screen
      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => EventCreationScreen(
            groupId: GroupIdUtil.formatForHTag(widget.groupIdentifier),
          ),
        ),
      );
      
      // If event was created successfully, refresh the events list
      if (result == true) {
        _loadEvents();
      }
    } catch (e) {
      debugPrint('Error navigating to event creation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating event: $e')),
      );
    }
  }
  
  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}