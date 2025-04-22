import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nostrmo/features/events/models/event_model.dart';
import 'package:nostrmo/features/events/models/event_rsvp_model.dart';
import 'package:nostrmo/features/events/providers/event_provider.dart';
import 'package:nostrmo/features/events/screens/event_creation_screen.dart';
import 'package:nostrmo/generated/l10n.dart';
import 'package:nostrmo/util/theme_util.dart';
import 'package:nostrmo/main.dart';
import 'package:share_plus/share_plus.dart';

/// Screen to display event details
class EventDetailScreen extends ConsumerStatefulWidget {
  /// The event to display
  final EventModel event;
  
  /// Optional group ID for context
  final String? groupId;

  /// Constructor
  const EventDetailScreen({
    required this.event,
    this.groupId,
    super.key,
  });

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> {
  bool _isLoading = false;
  bool _isMounted = false;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    
    // Load RSVPs for this event after the widget tree is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isMounted) {
        _loadRSVPs();
      }
    });
  }
  
  @override
  void dispose() {
    _isMounted = false;
    super.dispose();
  }
  
  Future<void> _loadRSVPs() async {
    if (!_isMounted) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Use Future.microtask to defer provider updates until after widget build is complete
      return Future.microtask(() async {
        if (_isMounted) {
          await ref.read(eventRSVPProvider.notifier).loadRSVPs(eventId: widget.event.id);
        }
      }).then((_) {
        if (_isMounted) {
          setState(() {
            _isLoading = false;
          });
        }
      });
    } catch (e) {
      if (_isMounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final customColors = themeData.customColors;
    final l10n = S.of(context);
    
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return [
              // App bar with cover image if available
              SliverAppBar(
                expandedHeight: widget.event.coverImageUrl != null ? 200 : 120,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: widget.event.coverImageUrl != null
                      ? Image.network(
                          widget.event.coverImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: customColors.accentColor.withOpacity(0.1),
                              child: Center(
                                child: Icon(
                                  Icons.event,
                                  size: 64,
                                  color: customColors.secondaryForegroundColor.withOpacity(0.5),
                                ),
                              ),
                            );
                          },
                        )
                      : Container(
                          color: customColors.accentColor.withOpacity(0.1),
                          child: Center(
                            child: Icon(
                              Icons.event,
                              size: 64,
                              color: customColors.secondaryForegroundColor.withOpacity(0.5),
                            ),
                          ),
                        ),
                  title: Text(
                    widget.event.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  titlePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  expandedTitleScale: 1.0,
                ),
                actions: [
                  // Share button
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: _shareEvent,
                    tooltip: l10n.share,
                  ),
                  
                  // More options menu
                  _buildMoreOptionsMenu(context, l10n),
                ],
                bottom: TabBar(
                  tabs: [
                    Tab(
                      icon: const Icon(Icons.info_outline),
                      text: l10n.description,
                    ),
                    Tab(
                      icon: const Icon(Icons.chat_bubble_outline),
                      text: l10n.responses,
                    ),
                  ],
                  indicatorColor: customColors.accentColor,
                  labelColor: customColors.accentColor,
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [
              // Details tab
              _buildDetailsTab(themeData, customColors, l10n),
              
              // Discussion tab
              _buildDiscussionTab(themeData, customColors, l10n),
            ],
          ),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: OutlinedButton.icon(
                  onPressed: () => _submitRSVP(RSVPStatus.interested),
                  icon: const Icon(Icons.star_outline),
                  label: Text(l10n.interested),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  onPressed: () => _submitRSVP(RSVPStatus.going),
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(l10n.going),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: customColors.accentColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Details tab containing event information and RSVPs
  Widget _buildDetailsTab(ThemeData themeData, CustomColors customColors, S l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date, time and location card
          Card(
            elevation: 1,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Date and time
                  Row(
                    children: [
                      Icon(
                        Icons.event,
                        color: customColors.accentColor,
                        size: 24,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatEventDate(widget.event),
                              style: themeData.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatEventTime(widget.event),
                              style: themeData.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  if (widget.event.location != null && widget.event.location!.isNotEmpty) ...[
                    const Divider(height: 32),
                    
                    // Location
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.location_on,
                          color: customColors.accentColor,
                          size: 24,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.location,
                                style: themeData.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.event.location!,
                                style: themeData.textTheme.bodyMedium,
                              ),
                              if (_isValidUrl(widget.event.location!))
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: InkWell(
                                    onTap: () => _openUrl(widget.event.location!),
                                    child: Text(
                                      l10n.openLink,
                                      style: TextStyle(
                                        color: customColors.accentColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Description section
          Text(
            l10n.description,
            style: themeData.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.event.description,
            style: themeData.textTheme.bodyMedium,
          ),
          
          const SizedBox(height: 24),
          
          // Organizers section
          if (widget.event.organizers.isNotEmpty) ...[
            Text(
              l10n.organizers,
              style: themeData.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ..._buildOrganizersList(widget.event.organizers),
            const SizedBox(height: 24),
          ],
          
          // Additional details section
          if (widget.event.capacity != null || 
              (widget.event.cost != null && widget.event.cost!.isNotEmpty) ||
              widget.event.tags.isNotEmpty) ...[
            Text(
              l10n.additionalInfo,
              style: themeData.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            // Capacity
            if (widget.event.capacity != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.people,
                      size: 16,
                      color: customColors.secondaryForegroundColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${l10n.capacity}: ${widget.event.capacity}',
                      style: themeData.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            
            // Cost
            if (widget.event.cost != null && widget.event.cost!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.monetization_on,
                      size: 16,
                      color: customColors.secondaryForegroundColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${l10n.cost}: ${widget.event.cost}',
                      style: themeData.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            
            // Tags
            if (widget.event.tags.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.tag,
                      size: 16,
                      color: customColors.secondaryForegroundColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Tags:',
                      style: themeData.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.event.tags.map((tag) => Chip(
                  label: Text(tag),
                  backgroundColor: customColors.accentColor.withOpacity(0.1),
                  labelStyle: TextStyle(
                    color: customColors.accentColor,
                  ),
                )).toList(),
              ),
            ],
            
            const SizedBox(height: 24),
          ],
          
          // RSVP summary section with improved UI
          _buildRSVPSummary(themeData, customColors, l10n),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // Widget that shows RSVP summary with direct access to full lists
  Widget _buildRSVPSummary(ThemeData themeData, CustomColors customColors, S l10n) {
    final rsvpsState = ref.watch(eventRSVPProvider);
    
    if (!rsvpsState.hasValue) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    // RSVP counts
    final counts = ref.read(eventRSVPProvider.notifier).getRSVPCountsForEvent(widget.event.id);
    final totalRSVPs = (counts[RSVPStatus.going] ?? 0) + 
                       (counts[RSVPStatus.interested] ?? 0) + 
                       (counts[RSVPStatus.notGoing] ?? 0);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.responses,
              style: themeData.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (totalRSVPs > 0)
              TextButton.icon(
                onPressed: () => _showAllRSVPs(context, themeData),
                icon: const Icon(Icons.people, size: 16),
                label: Text(l10n.viewAll),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        
        // No responses yet
        if (totalRSVPs == 0)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                l10n.noResponsesYet,
                style: TextStyle(
                  color: customColors.secondaryForegroundColor,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
          
        // RSVP status cards
        if (totalRSVPs > 0)
          Row(
            children: [
              // Going
              Expanded(
                child: _buildRSVPStatusCard(
                  themeData,
                  customColors,
                  label: l10n.going,
                  count: counts[RSVPStatus.going] ?? 0,
                  icon: Icons.check_circle_outline,
                  color: Colors.green,
                  onTap: () => _showRSVPsByStatus(context, RSVPStatus.going),
                ),
              ),
              const SizedBox(width: 8),
              
              // Interested
              Expanded(
                child: _buildRSVPStatusCard(
                  themeData,
                  customColors,
                  label: l10n.interested,
                  count: counts[RSVPStatus.interested] ?? 0,
                  icon: Icons.star_outline,
                  color: Colors.orange,
                  onTap: () => _showRSVPsByStatus(context, RSVPStatus.interested),
                ),
              ),
              const SizedBox(width: 8),
              
              // Not Going
              Expanded(
                child: _buildRSVPStatusCard(
                  themeData,
                  customColors,
                  label: l10n.notGoing,
                  count: counts[RSVPStatus.notGoing] ?? 0,
                  icon: Icons.cancel_outlined,
                  color: Colors.red,
                  onTap: () => _showRSVPsByStatus(context, RSVPStatus.notGoing),
                ),
              ),
            ],
          ),
      ],
    );
  }
  
  // RSVP status card with count and tap to view
  Widget _buildRSVPStatusCard(
    ThemeData themeData,
    CustomColors customColors, {
    required String label,
    required int count,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: count > 0 ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              count.toString(),
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Show all RSVPs for all statuses
  void _showAllRSVPs(BuildContext context, ThemeData themeData) {
    final l10n = S.of(context);
    final rsvpsState = ref.read(eventRSVPProvider);
    
    if (!rsvpsState.hasValue) return;
    
    final allRSVPs = rsvpsState.value!.where((rsvp) => rsvp.eventId == widget.event.id).toList();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => DefaultTabController(
          length: 3,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${l10n.responses} (${allRSVPs.length})',
                      style: themeData.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              
              TabBar(
                tabs: [
                  Tab(text: l10n.going),
                  Tab(text: l10n.interested),
                  Tab(text: l10n.notGoing),
                ],
                labelColor: themeData.textTheme.bodyLarge?.color,
              ),
              
              Expanded(
                child: TabBarView(
                  children: [
                    // Going
                    _buildRSVPStatusList(
                      allRSVPs.where((rsvp) => rsvp.status == RSVPStatus.going).toList(),
                      scrollController,
                    ),
                    // Interested
                    _buildRSVPStatusList(
                      allRSVPs.where((rsvp) => rsvp.status == RSVPStatus.interested).toList(),
                      scrollController,
                    ),
                    // Not Going
                    _buildRSVPStatusList(
                      allRSVPs.where((rsvp) => rsvp.status == RSVPStatus.notGoing).toList(),
                      scrollController,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Show RSVPs for a specific status
  void _showRSVPsByStatus(BuildContext context, RSVPStatus status) {
    final l10n = S.of(context);
    final themeData = Theme.of(context);
    final rsvpsState = ref.read(eventRSVPProvider);
    
    if (!rsvpsState.hasValue) return;
    
    final rsvps = rsvpsState.value!
        .where((rsvp) => rsvp.eventId == widget.event.id && rsvp.status == status)
        .toList();
    
    IconData icon;
    Color color;
    String title;
    
    switch (status) {
      case RSVPStatus.going:
        icon = Icons.check_circle_outline;
        color = Colors.green;
        title = l10n.going;
        break;
      case RSVPStatus.interested:
        icon = Icons.star_outline;
        color = Colors.orange;
        title = l10n.interested;
        break;
      case RSVPStatus.notGoing:
        icon = Icons.cancel_outlined;
        color = Colors.red;
        title = l10n.notGoing;
        break;
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.8,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(icon, color: color),
                  const SizedBox(width: 8),
                  Text(
                    '$title (${rsvps.length})',
                    style: themeData.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _buildRSVPStatusList(rsvps, scrollController),
            ),
          ],
        ),
      ),
    );
  }
  
  // Build a list of RSVPs for a status
  Widget _buildRSVPStatusList(List<EventRSVPModel> attendees, ScrollController scrollController) {
    final l10n = S.of(context);
    final themeData = Theme.of(context);
    
    if (attendees.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            l10n.noResponsesYet,
            style: TextStyle(
              color: themeData.customColors.secondaryForegroundColor,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }
    
    return ListView.builder(
      controller: scrollController,
      itemCount: attendees.length,
      itemBuilder: (context, index) {
        final rsvp = attendees[index];
        final shortPubkey = rsvp.pubkey.length > 12 
            ? '${rsvp.pubkey.substring(0, 6)}...${rsvp.pubkey.substring(rsvp.pubkey.length - 6)}'
            : rsvp.pubkey;
        
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: themeData.customColors.accentColor.withOpacity(0.2),
            child: Icon(
              Icons.person,
              color: themeData.customColors.accentColor,
            ),
          ),
          title: Text(shortPubkey),
          subtitle: nostr?.publicKey == rsvp.pubkey ? Text(l10n.you) : null,
          onTap: () {
            Navigator.of(context).pop();
            _viewProfile(rsvp.pubkey);
          },
        );
      },
    );
  }
  
  // Discussion tab for event chat/posts
  Widget _buildDiscussionTab(ThemeData themeData, CustomColors customColors, S l10n) {
    return Column(
      children: [
        Expanded(
          child: _buildEventDiscussionList(themeData, customColors, l10n),
        ),
        _buildEventDiscussionInput(themeData, customColors, l10n),
      ],
    );
  }
  
  // Event discussion message list
  Widget _buildEventDiscussionList(ThemeData themeData, CustomColors customColors, S l10n) {
    // For now, display a placeholder while we implement the actual functionality
    // In the future, we'll use the eventChatProvider here to display real messages
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: customColors.secondaryForegroundColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Event discussion coming soon',
            style: themeData.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'This feature will let you chat about the event with other attendees',
            style: themeData.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Event discussion feature is in development'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Text(l10n.tryAgain),
          ),
        ],
      ),
    );
  }
  
  // Event discussion input field
  Widget _buildEventDiscussionInput(ThemeData themeData, CustomColors customColors, S l10n) {
    final messageController = TextEditingController();
    
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: messageController,
              decoration: InputDecoration(
                hintText: 'Add to the discussion...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: customColors.feedBgColor,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              minLines: 1,
              maxLines: 3,
              enabled: false, // Disabled until we implement the full functionality
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () {
              // When the functionality is implemented, this will send the message
              // For now, show a message that this feature is coming soon
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Event discussion feature is in development'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            borderRadius: BorderRadius.circular(50),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: customColors.accentColor.withOpacity(0.2),
                child: Icon(
                  Icons.send,
                  color: customColors.accentColor.withOpacity(0.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /*
  // IMPLEMENTATION NOTES:
  // The following methods can be used in the future to implement the full
  // event discussion functionality:
  
  // 1. Initialize event chat when entering this screen:
  void _loadEventChat() {
    if (!mounted) return;
    
    ref.read(eventChatProvider.notifier).loadEventChat(
      eventId: widget.event.id,
      eventDTag: widget.event.d,
      groupId: widget.event.groupId,
    );
  }
  
  // 2. Send a new message:
  Future<void> _sendChatMessage(String content) async {
    if (content.trim().isEmpty) return;
    
    try {
      await ref.read(eventChatProvider.notifier).sendMessage(
        eventId: widget.event.id,
        eventDTag: widget.event.d,
        content: content,
        groupId: widget.event.groupId,
      );
      
      // Clear input field
      // messageController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message: $e')),
        );
      }
    }
  }
  
  // 3. Build the actual chat message list:
  Widget _buildChatMessageList() {
    final chatState = ref.watch(eventChatProvider);
    
    return chatState.when(
      data: (messages) {
        final eventMessages = messages.where((m) => m.eventId == widget.event.id).toList();
        
        if (eventMessages.isEmpty) {
          return Center(
            child: Text(
              'No messages yet. Be the first to start the discussion!',
              textAlign: TextAlign.center,
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.only(top: 16, bottom: 80),
          itemCount: eventMessages.length,
          itemBuilder: (context, index) {
            final message = eventMessages[index];
            return _buildChatMessageItem(message);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Error loading discussion: $error'),
            TextButton(
              onPressed: _loadEventChat,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
  
  // 4. Build individual chat message items:
  Widget _buildChatMessageItem(EventChatModel message) {
    final isMyMessage = nostr?.publicKey == message.pubkey;
    final themeData = Theme.of(context);
    final customColors = themeData.customColors;
    
    // Format timestamp
    final now = DateTime.now();
    final messageTime = message.createdAt;
    String formattedTime;
    
    if (now.difference(messageTime).inDays > 0) {
      formattedTime = DateFormat.MMMd().add_jm().format(messageTime);
    } else {
      formattedTime = DateFormat.jm().format(messageTime);
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: isMyMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMyMessage)
            CircleAvatar(
              radius: 16,
              backgroundColor: customColors.accentColor.withOpacity(0.2),
              child: Icon(
                Icons.person,
                size: 16,
                color: customColors.accentColor,
              ),
            ),
          
          const SizedBox(width: 8),
          
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isMyMessage 
                    ? customColors.accentColor.withOpacity(0.2)
                    : customColors.feedBgColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMyMessage)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        message.pubkey.substring(0, 8) + '...',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: customColors.secondaryForegroundColor,
                        ),
                      ),
                    ),
                  
                  Text(message.content),
                  
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        formattedTime,
                        style: TextStyle(
                          fontSize: 10,
                          color: customColors.secondaryForegroundColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          if (isMyMessage)
            const SizedBox(width: 8),
          
          if (isMyMessage)
            CircleAvatar(
              radius: 16,
              backgroundColor: customColors.accentColor.withOpacity(0.2),
              child: Icon(
                Icons.person,
                size: 16,
                color: customColors.accentColor,
              ),
            ),
        ],
      ),
    );
  }
  */
  
  Widget _buildMoreOptionsMenu(BuildContext context, S l10n) {
    final themeData = Theme.of(context);
    final customColors = themeData.customColors;
    
    return PopupMenuButton<String>(
      onSelected: (value) {
        switch (value) {
          case 'edit':
            _editEvent();
            break;
          case 'delete':
            _confirmDeleteEvent();
            break;
          case 'report':
            _reportEvent();
            break;
        }
      },
      itemBuilder: (context) {
        final items = <PopupMenuEntry<String>>[];
        
        // Show edit/delete options if user is the creator or an organizer
        final myPubkey = nostr?.publicKey;
        final isOrganizer = myPubkey != null && 
            (widget.event.pubkey == myPubkey || widget.event.organizers.contains(myPubkey));
        
        if (isOrganizer) {
          items.add(
            PopupMenuItem<String>(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 18, color: customColors.secondaryForegroundColor),
                  const SizedBox(width: 12),
                  Text(l10n.edit),
                ],
              ),
            ),
          );
          
          items.add(
            PopupMenuItem<String>(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 18, color: Colors.red),
                  const SizedBox(width: 12),
                  Text(l10n.delete, style: const TextStyle(color: Colors.red)),
                ],
              ),
            ),
          );
          
          items.add(const PopupMenuDivider());
        }
        
        // Always show report option
        items.add(
          PopupMenuItem<String>(
            value: 'report',
            child: Row(
              children: [
                Icon(Icons.flag, size: 18, color: customColors.secondaryForegroundColor),
                const SizedBox(width: 12),
                Text(l10n.report),
              ],
            ),
          ),
        );
        
        return items;
      },
    );
  }
  
  List<Widget> _buildOrganizersList(List<String> organizers) {
    final themeData = Theme.of(context);
    final l10n = S.of(context);
    
    return organizers.map((pubkey) {
      // Truncate pubkey for display
      final shortPubkey = pubkey.length > 12 
          ? '${pubkey.substring(0, 6)}...${pubkey.substring(pubkey.length - 6)}'
          : pubkey;
      
      return ListTile(
        leading: CircleAvatar(
          backgroundColor: themeData.customColors.accentColor.withOpacity(0.2),
          child: Icon(
            Icons.person,
            color: themeData.customColors.accentColor,
          ),
        ),
        title: Text(shortPubkey),
        subtitle: nostr?.publicKey == pubkey ? Text(l10n.you) : null,
        dense: true,
        contentPadding: EdgeInsets.zero,
        onTap: () => _viewProfile(pubkey),
      );
    }).toList();
  }
  
  // This method remains for backward compatibility but now uses _buildRSVPSummary
  Widget _buildRSVPSection(BuildContext context, S l10n) {
    final themeData = Theme.of(context);
    final customColors = themeData.customColors;
    final rsvpsState = ref.watch(eventRSVPProvider);
    
    if (rsvpsState.isLoading || _isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      );
    } else if (rsvpsState.hasError) {
      return Center(
        child: Column(
          children: [
            Text(l10n.errorLoadingResponses),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _loadRSVPs,
              child: Text(l10n.tryAgain),
            ),
          ],
        ),
      );
    } else {
      return _buildRSVPSummary(themeData, customColors, l10n);
    }
  }
  
  Widget _buildRSVPList(BuildContext context, List<EventRSVPModel> rsvps, S l10n) {
    final themeData = Theme.of(context);
    final customColors = themeData.customColors;
    
    // Filter RSVPs for this event
    final eventRSVPs = rsvps.where((rsvp) => rsvp.eventId == widget.event.id).toList();
    
    if (eventRSVPs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            l10n.noResponsesYet,
            style: TextStyle(
              color: customColors.secondaryForegroundColor,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }
    
    // Group RSVPs by status
    final Map<RSVPStatus, List<EventRSVPModel>> groupedRSVPs = {
      RSVPStatus.going: [],
      RSVPStatus.interested: [],
      RSVPStatus.notGoing: [],
    };
    
    for (final rsvp in eventRSVPs) {
      groupedRSVPs[rsvp.status]!.add(rsvp);
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Going section
        if (groupedRSVPs[RSVPStatus.going]!.isNotEmpty) ...[
          _buildRSVPStatusHeader(
            l10n.going,
            groupedRSVPs[RSVPStatus.going]!.length,
            Icons.check_circle_outline,
            Colors.green,
          ),
          const SizedBox(height: 8),
          _buildAttendeesList(groupedRSVPs[RSVPStatus.going]!),
          const SizedBox(height: 16),
        ],
        
        // Interested section
        if (groupedRSVPs[RSVPStatus.interested]!.isNotEmpty) ...[
          _buildRSVPStatusHeader(
            l10n.interested,
            groupedRSVPs[RSVPStatus.interested]!.length,
            Icons.star_outline,
            Colors.orange,
          ),
          const SizedBox(height: 8),
          _buildAttendeesList(groupedRSVPs[RSVPStatus.interested]!),
          const SizedBox(height: 16),
        ],
        
        // Not going section
        if (groupedRSVPs[RSVPStatus.notGoing]!.isNotEmpty) ...[
          _buildRSVPStatusHeader(
            l10n.notGoing,
            groupedRSVPs[RSVPStatus.notGoing]!.length,
            Icons.cancel_outlined,
            Colors.red,
          ),
          const SizedBox(height: 8),
          _buildAttendeesList(groupedRSVPs[RSVPStatus.notGoing]!),
        ],
      ],
    );
  }
  
  Widget _buildRSVPStatusHeader(String title, int count, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '($count)',
          style: TextStyle(
            color: color,
          ),
        ),
      ],
    );
  }
  
  Widget _buildAttendeesList(List<EventRSVPModel> attendees) {
    final themeData = Theme.of(context);
    final l10n = S.of(context);
    
    // Show just the first 5 attendees if there are more than 5
    final displayedAttendees = attendees.length > 5 ? attendees.sublist(0, 5) : attendees;
    
    return Column(
      children: [
        ...displayedAttendees.map((rsvp) {
          // Truncate pubkey for display
          final shortPubkey = rsvp.pubkey.length > 12 
              ? '${rsvp.pubkey.substring(0, 6)}...${rsvp.pubkey.substring(rsvp.pubkey.length - 6)}'
              : rsvp.pubkey;
          
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: themeData.customColors.accentColor.withOpacity(0.2),
              child: Icon(
                Icons.person,
                color: themeData.customColors.accentColor,
              ),
            ),
            title: Text(shortPubkey),
            subtitle: nostr?.publicKey == rsvp.pubkey ? Text(l10n.you) : null,
            dense: true,
            contentPadding: EdgeInsets.zero,
            onTap: () => _viewProfile(rsvp.pubkey),
          );
        }).toList(),
        
        // Show "View more" button if there are more than 5 attendees
        if (attendees.length > 5)
          TextButton(
            onPressed: () => _viewAllAttendees(attendees),
            child: Text('${l10n.viewAll} (${attendees.length})'),
          ),
      ],
    );
  }
  
  void _viewAllAttendees(List<EventRSVPModel> attendees) {
    final themeData = Theme.of(context);
    final l10n = S.of(context);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.8,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${l10n.attendees} (${attendees.length})',
                    style: themeData.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: attendees.length,
                itemBuilder: (context, index) {
                  final rsvp = attendees[index];
                  final shortPubkey = rsvp.pubkey.length > 12 
                      ? '${rsvp.pubkey.substring(0, 6)}...${rsvp.pubkey.substring(rsvp.pubkey.length - 6)}'
                      : rsvp.pubkey;
                  
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: themeData.customColors.accentColor.withOpacity(0.2),
                      child: Icon(
                        Icons.person,
                        color: themeData.customColors.accentColor,
                      ),
                    ),
                    title: Text(shortPubkey),
                    subtitle: nostr?.publicKey == rsvp.pubkey ? Text(l10n.you) : null,
                    onTap: () {
                      Navigator.of(context).pop();
                      _viewProfile(rsvp.pubkey);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _viewProfile(String pubkey) {
    // TODO: Implement profile view navigation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Viewing profile: $pubkey')),
    );
  }
  
  Future<void> _submitRSVP(RSVPStatus status) async {
    // Get current user's RSVP status
    final rsvpsState = ref.read(eventRSVPProvider);
    final myPubkey = nostr?.publicKey;
    RSVPStatus? previousStatus;
    String? previousRsvpId;
    
    if (rsvpsState.hasValue && myPubkey != null) {
      final userRsvp = rsvpsState.value!.where((rsvp) => 
        rsvp.eventId == widget.event.id && rsvp.pubkey == myPubkey
      ).firstOrNull;
      
      if (userRsvp != null) {
        previousStatus = userRsvp.status;
        previousRsvpId = userRsvp.id;
      }
    }
    
    // Create a temporary RSVP model for optimistic UI update
    if (myPubkey != null) {
      final optimisticRsvp = EventRSVPModel(
        id: previousRsvpId ?? 'temp-${DateTime.now().millisecondsSinceEpoch}',
        pubkey: myPubkey,
        eventId: widget.event.id,
        eventDTag: widget.event.d,
        status: status,
        groupId: widget.event.groupId,
        visibility: widget.event.visibility.value,
        createdAt: DateTime.now(),
      );
      
      // Optimistically update UI
      ref.read(eventRSVPProvider.notifier).updateOptimistically(optimisticRsvp);
    }
    
    try {
      // Perform the actual submission in the background
      await ref.read(eventRSVPProvider.notifier).submitRSVP(
        eventId: widget.event.id,
        eventDTag: widget.event.d,
        status: status,
        groupId: widget.event.groupId,
        visibility: widget.event.visibility.value,
      );
      
      // Note: We don't need to call _loadRSVPs() as the UI already reflects the change
      // Only show a confirmation if needed
      if (mounted) {
        final String statusLabel;
        switch (status) {
          case RSVPStatus.going:
            statusLabel = 'Going';
            break;
          case RSVPStatus.interested:
            statusLabel = 'Interested';
            break;
          case RSVPStatus.notGoing:
            statusLabel = "Can't Go";
            break;
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You are now $statusLabel'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Revert optimistic update on error
        if (previousStatus != null && myPubkey != null) {
          final revertRsvp = EventRSVPModel(
            id: previousRsvpId ?? 'temp-${DateTime.now().millisecondsSinceEpoch}',
            pubkey: myPubkey,
            eventId: widget.event.id,
            eventDTag: widget.event.d,
            status: previousStatus,
            groupId: widget.event.groupId,
            visibility: widget.event.visibility.value,
            createdAt: DateTime.now(),
          );
          
          ref.read(eventRSVPProvider.notifier).updateOptimistically(revertRsvp);
        } else if (myPubkey != null) {
          // If there was no previous status, remove the optimistic RSVP
          ref.read(eventRSVPProvider.notifier).removeOptimisticRSVP(
            myPubkey, 
            widget.event.id
          );
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting RSVP: $e')),
        );
      }
    }
  }
  
  void _editEvent() async {
    // Navigate to event creation/edit screen with existing event data
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EventCreationScreen(
          groupId: widget.groupId ?? widget.event.groupId ?? '',
          existingEvent: widget.event,
        ),
      ),
    );
    
    // If event was updated successfully, reload the page
    if (result == true) {
      // Reload event data
      if (mounted) {
        _loadRSVPs();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Event updated successfully")),
        );
      }
    }
  }
  
  void _confirmDeleteEvent() {
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Event"),
        content: const Text("Are you sure you want to delete this event?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteEvent();
            },
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _deleteEvent() async {
    
    try {
      final success = await ref.read(eventProvider.notifier).deleteEvent(widget.event);
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Event deleted successfully")),
          );
          Navigator.of(context).pop(true); // Return success to previous screen
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Error deleting event")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting event: $e')),
        );
      }
    }
  }
  
  void _reportEvent() {
    // TODO: Implement event reporting
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report feature coming soon')),
    );
  }
  
  void _shareEvent() {
    // Create a shareable message
    final message = '''
${widget.event.title}
${_formatEventDate(widget.event)} ${_formatEventTime(widget.event)}
${widget.event.location != null ? 'Location: ${widget.event.location}' : ''}

${widget.event.description}
''';
    
    Share.share(message, subject: widget.event.title);
  }
  
  bool _isValidUrl(String text) {
    Uri? uri = Uri.tryParse(text);
    return uri != null && 
        (uri.scheme == 'http' || uri.scheme == 'https') && 
        uri.host.isNotEmpty;
  }
  
  void _openUrl(String url) {
    // TODO: Implement URL opening
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening URL: $url')),
    );
  }
  
  String _formatEventDate(EventModel event) {
    final now = DateTime.now();
    final startDate = event.startAt;
    final endDate = event.endAt;
    
    // If event spans multiple days
    if (endDate != null && 
        (endDate.day != startDate.day || 
         endDate.month != startDate.month || 
         endDate.year != startDate.year)) {
      
      // Same month
      if (startDate.month == endDate.month && startDate.year == endDate.year) {
        return '${DateFormat.MMMd().format(startDate)} - ${DateFormat.d().format(endDate)}, ${DateFormat.y().format(endDate)}';
      }
      
      // Different months
      return '${DateFormat.MMMd().format(startDate)} - ${DateFormat.MMMd().format(endDate)}, ${DateFormat.y().format(endDate)}';
    }
    
    // Single day event
    if (startDate.year == now.year) {
      return DateFormat.MMMd().format(startDate);
    } else {
      return DateFormat.yMMMd().format(startDate);
    }
  }
  
  String _formatEventTime(EventModel event) {
    final startTime = DateFormat.jm().format(event.startAt);
    final endDate = event.endAt;
    
    if (endDate != null) {
      final endTime = DateFormat.jm().format(endDate);
      return '$startTime - $endTime';
    }
    
    return startTime;
  }
}