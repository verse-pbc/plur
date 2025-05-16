import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nostr_sdk/nip29/group_identifier.dart';
import 'package:nostrmo/data/group_metadata_repository.dart';
import 'package:nostrmo/theme/app_colors.dart';
import 'package:nostrmo/util/group_id_util.dart';
import '../models/listing_model.dart';
import '../providers/listing_provider.dart';
import '../widgets/listing_card.dart';
import '../screens/create_edit_listing_screen.dart';
import '../screens/listing_detail_screen.dart';

class ListingsScreen extends ConsumerStatefulWidget {
  final String? groupId;
  final bool showAllGroups;

  const ListingsScreen({
    this.groupId, 
    this.showAllGroups = false, 
    super.key
  });

  @override
  ConsumerState<ListingsScreen> createState() => _ListingsScreenState();
}

class _ListingsScreenState extends ConsumerState<ListingsScreen> with SingleTickerProviderStateMixin {
  ListingType? _selectedType;
  ListingStatus? _selectedStatus;
  String _searchQuery = '';
  late TabController _tabController;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    // Initialize tab controller for Ask/Offer tabs
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabSelection);
    
    // Use Future.microtask to delay provider updates until after the widget tree is built
    Future.microtask(() {
      if (mounted) {
        // Load listings from all groups or a specific group
        if (widget.showAllGroups) {
          // Load all listings from all groups
          ref.read(listingProvider.notifier).loadListings(groupId: null);
        } else if (widget.groupId != null) {
          // For loading listings, we need the STANDARDIZED format (with host:id) for h-tag filtering
          String standardizedGroupId = GroupIdUtil.standardizeGroupIdString(widget.groupId!);
          debugPrint("Loading listings for group ID: '$standardizedGroupId' (original: '${widget.groupId}')");
          ref.read(listingProvider.notifier).loadListings(groupId: standardizedGroupId);
        }
      }
    });
  }
  
  // Helper method to format group ID consistently for h-tag use
  String _formatGroupIdForHTag(String rawGroupId) {
    // First standardize the group ID to a common format
    final standardized = GroupIdUtil.standardizeGroupIdString(rawGroupId);
    debugPrint("_formatGroupIdForHTag - Input: '$rawGroupId', Standardized: '$standardized'");
    
    // For filtering purposes, we want just the ID part to match the listing storage format
    final idPart = GroupIdUtil.extractIdPart(standardized);
    debugPrint("_formatGroupIdForHTag - Extracted ID part for filtering: '$idPart'");
    
    // Return just the ID part for filtering
    return idPart;
  }
  
  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }
  
  void _handleTabSelection() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        switch (_tabController.index) {
          case 0: // All
            _selectedType = null;
            break;
          case 1: // Asks
            _selectedType = ListingType.ask;
            break;
          case 2: // Offers
            _selectedType = ListingType.offer;
            break;
        }
      });
    }
  }
  
  Future<void> _refreshListings() async {
    if (widget.showAllGroups) {
      // Refresh listings from all groups
      return ref.read(listingProvider.notifier).loadListings(groupId: null);
    } else if (widget.groupId != null) {
      // For loading listings, we need the STANDARDIZED format (with host:id) for h-tag filtering
      // This is different from local filtering where we just need the ID part
      String standardizedGroupId = GroupIdUtil.standardizeGroupIdString(widget.groupId!);
      debugPrint("Refreshing listings for group ID: '$standardizedGroupId' (original: '${widget.groupId}')");
      return ref.read(listingProvider.notifier).loadListings(groupId: standardizedGroupId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final listingsState = ref.watch(listingProvider);
    final themeData = Theme.of(context);
    
    // Group metadata if we're in a group
    Widget? groupName;
    if (widget.groupId != null && !widget.showAllGroups) {
      groupName = _buildGroupNameWidget();
    } else if (widget.showAllGroups) {
      groupName = Text("All Communities", style: TextStyle(
        fontSize: 14,
        color: context.colors.secondaryText,
      ));
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Asks & Offers'),
            if (groupName != null)
              DefaultTextStyle(
                style: TextStyle(
                  fontSize: 14,
                  color: context.colors.secondaryText,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.arrow_back_ios, size: 12),
                    const SizedBox(width: 4),
                    Flexible(child: groupName),
                  ],
                ),
              ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: context.colors.divider.withAlpha(77),
                  width: 0.5,
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: themeData.primaryColor,
              unselectedLabelColor: context.colors.secondaryText,
              indicatorColor: themeData.primaryColor,
              tabs: const [
                Tab(text: 'ALL'),
                Tab(text: 'ASKS'),
                Tab(text: 'OFFERS'),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterBottomSheet(context);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _refreshListings,
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search asks & offers...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: context.colors.feedBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
            
            // Filter chips
            if (_selectedStatus != null)
              Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 8),
                child: SizedBox(
                  height: 32,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      FilterChip(
                        label: Text(_selectedStatus!.name.toUpperCase()),
                        selected: true,
                        onSelected: (_) {
                          setState(() {
                            _selectedStatus = null;
                          });
                        },
                        avatar: const Icon(Icons.close, size: 16),
                      ),
                    ],
                  ),
                ),
              ),
            
            // Listings
            Expanded(
              child: listingsState.when(
                data: (listings) {
                  // Prepare the group ID with the correct format for filtering
                  String? formattedGroupId;
                  if (!widget.showAllGroups && widget.groupId != null) {
                    // Use our helper method to format the group ID consistently
                    formattedGroupId = _formatGroupIdForHTag(widget.groupId!);
                  }
                  
                  // Enhanced debugging for filtering
                  debugPrint("Filtering listings in ListingsScreen");
                  debugPrint("showAllGroups: ${widget.showAllGroups}");
                  debugPrint("Original groupId: '${widget.groupId}'");
                  debugPrint("Formatted groupId for filtering: '$formattedGroupId'");
                  
                  final filteredListings = ref.read(listingProvider.notifier).filterListings(
                    type: _selectedType,
                    status: _selectedStatus,
                    groupId: widget.showAllGroups ? null : formattedGroupId,
                    searchQuery: _searchQuery,
                    showAllGroups: widget.showAllGroups,
                  );

                  if (filteredListings.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.builder(
                    itemCount: filteredListings.length,
                    itemBuilder: (context, index) {
                      return ListingCard(
                        listing: filteredListings[index],
                        showGroupBadge: widget.showAllGroups, // Show group badge when in all groups mode
                        onTap: () {
                          // Navigate to listing detail screen using direct navigation
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ListingDetailScreen(
                                listing: filteredListings[index],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, stackTrace) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Error loading listings'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          _refreshListings();
                        },
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'createAsk',
            onPressed: () {
              _navigateToCreateListing(ListingType.ask);
            },
            backgroundColor: Colors.blue,
            label: const Text('Post an Ask'),
            icon: const Icon(Icons.help_outline),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.extended(
            heroTag: 'createOffer',
            onPressed: () {
              _navigateToCreateListing(ListingType.offer);
            },
            backgroundColor: Colors.green,
            label: const Text('Post an Offer'),
            icon: const Icon(Icons.local_offer_outlined),
          ),
        ],
      ),
    );
  }
  
  void _navigateToCreateListing(ListingType type) {
    // Format the group ID correctly for h-tag usage in listings
    String? formattedGroupId;
    if (widget.groupId != null) {
      formattedGroupId = _formatGroupIdForHTag(widget.groupId!);
      debugPrint("Creating listing with group ID: '$formattedGroupId' (original: '${widget.groupId}')");
      debugPrint("Group ID part only: '${GroupIdUtil.extractIdPart(formattedGroupId)}'");
    }
    
    // Use MaterialPageRoute directly instead of router utility
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreateEditListingScreen(
          groupId: formattedGroupId,
          type: type,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _selectedType == ListingType.ask ? Icons.help_outline : 
            _selectedType == ListingType.offer ? Icons.local_offer_outlined : 
            Icons.swap_horiz_outlined,
            size: 72,
            color: Colors.grey.withAlpha((0.5 * 255).toInt()),
          ),
          const SizedBox(height: 16),
          Text(
            _buildEmptyStateText(),
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              final typeToCreate = _selectedType ?? ListingType.ask;
              _navigateToCreateListing(typeToCreate);
            },
            icon: Icon(
              _selectedType == ListingType.offer ? Icons.local_offer_outlined : Icons.help_outline,
              size: 16,
            ),
            label: Text('Post a${_selectedType == ListingType.offer ? 'n Offer' : 'n Ask'}'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildGroupNameWidget() {
    if (widget.groupId == null) return const SizedBox.shrink();
    
    // Parse the group ID
    final GroupIdentifier groupIdentifier = GroupIdUtil.parseFromHTag(
      // First standardize the group ID to ensure it's in the correct format
      GroupIdUtil.standardizeGroupIdString(widget.groupId!)
    );
    
    // Extract the formatted part of the group ID for display purposes
    String groupIdFormatted = groupIdentifier.groupId;
    
    // Use the group identifier to fetch metadata
    return Consumer(
      builder: (context, ref, child) {
        final groupMetadataAsync = ref.watch(groupMetadataProvider(groupIdentifier));
        
        return groupMetadataAsync.when(
          data: (metadata) {
            if (metadata == null) {
              return Text('Group: $groupIdFormatted');
            }
            
            return GestureDetector(
              onTap: () {
                // Navigate back to group detail screen
                Navigator.pop(context);
              },
              child: Text(
                metadata.displayName ?? metadata.name ?? 'Group: $groupIdFormatted',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            );
          },
          loading: () => Text('Loading group...'),
          error: (_, __) => Text('Group: $groupIdFormatted'),
        );
      },
    );
  }

  String _buildEmptyStateText() {
    if (_searchQuery.isNotEmpty) {
      return 'No results found for "$_searchQuery"';
    }
    
    if (_selectedType == ListingType.ask) {
      return 'No asks posted yet.\nBe the first to ask for something!';
    } else if (_selectedType == ListingType.offer) {
      return 'No offers posted yet.\nBe the first to offer something!';
    }
    
    return 'No asks or offers posted yet.\nGet started by posting something!';
  }
  
  void _showFilterBottomSheet(BuildContext context) {
    final themeData = Theme.of(context);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.feedBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.4,
              minChildSize: 0.3,
              maxChildSize: 0.8,
              expand: false,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    // Handle
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withAlpha((0.3 * 255).toInt()),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    // Title
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Text(
                            'Filter Listings',
                            style: themeData.textTheme.titleLarge,
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () {
                              setModalState(() {
                                _selectedStatus = null;
                              });
                              setState(() {
                                _selectedStatus = null;
                              });
                            },
                            child: const Text('Reset'),
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                    // Filter options
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16.0),
                        children: [
                          Text(
                            'STATUS',
                            style: themeData.textTheme.labelLarge?.copyWith(
                              color: context.colors.secondaryText,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: ListingStatus.values.map((status) {
                              return FilterChip(
                                label: Text(status.name.toUpperCase()),
                                selected: _selectedStatus == status,
                                onSelected: (selected) {
                                  setModalState(() {
                                    _selectedStatus = selected ? status : null;
                                  });
                                  setState(() {
                                    _selectedStatus = selected ? status : null;
                                  });
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),
                          // Add more filters here as needed (e.g., date ranges, price)
                        ],
                      ),
                    ),
                    // Apply button
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('Apply Filters'),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
} 