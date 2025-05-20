import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nostrmo/component/styled_input_field_widget.dart';
import 'package:nostrmo/consts/colors.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/util/theme_util.dart';
import '../models/listing_model.dart';
import '../models/response_model.dart';
import '../providers/listing_provider.dart';
import '../providers/response_provider.dart';
import '../widgets/listing_card.dart';
import 'create_edit_listing_screen.dart';
import 'listing_detail_screen.dart';

class MyListingsScreen extends ConsumerStatefulWidget {
  const MyListingsScreen({super.key});

  @override
  ConsumerState<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends ConsumerState<MyListingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ListingStatus? _selectedStatus;
  String _searchQuery = '';
  bool _showingResponses = false;
  String? _selectedListingId;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    // Initialize tab controller for Ask/Offer tabs
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabSelection);
    
    // Use Future.microtask to load data after widget tree is built
    Future.microtask(() {
      if (mounted) {
        ref.read(listingProvider.notifier).loadListings();
      }
    });
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
        _showingResponses = false;
        _selectedListingId = null;
      });
    }
  }

  Future<void> _refreshListings() async {
    return ref.read(listingProvider.notifier).loadListings();
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final customColors = themeData.customColors;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Listings'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: customColors.separatorColor.withOpacity(0.3),
                  width: 0.5,
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: themeData.primaryColor,
              unselectedLabelColor: customColors.secondaryForegroundColor,
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
        child: _showingResponses ? _buildResponsesList() : _buildListingsList(),
      ),
      floatingActionButton: !_showingResponses ? Column(
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
      ) : null,
    );
  }
  
  Widget _buildListingsList() {
    final listingsState = ref.watch(listingProvider);
    final themeData = Theme.of(context);
    final customColors = themeData.customColors;
    
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: StyledInputFieldWidget(
            controller: TextEditingController(text: _searchQuery),
            hintText: 'Search your listings...',
            prefixIcon: const Icon(Icons.search),
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
        
        // Listings content
        Expanded(
          child: listingsState.when(
            data: (listings) {
              // Get current user's pubkey
              final currentPubkey = nostr?.publicKey;
              if (currentPubkey == null) {
                return const Center(
                  child: Text('Please sign in to view your listings'),
                );
              }
              
              // Filter listings by the current user
              final myListings = listings.where((listing) => listing.pubkey == currentPubkey).toList();
              
              // Apply additional filters
              final filteredListings = myListings.where((listing) {
                // Filter by type based on tab selection
                if (_tabController.index == 1 && listing.type != ListingType.ask) return false;
                if (_tabController.index == 2 && listing.type != ListingType.offer) return false;
                
                // Filter by status
                if (_selectedStatus != null && listing.status != _selectedStatus) return false;
                
                // Filter by search query
                if (_searchQuery.isNotEmpty) {
                  final query = _searchQuery.toLowerCase();
                  return listing.title.toLowerCase().contains(query) || 
                         listing.content.toLowerCase().contains(query);
                }
                
                return true;
              }).toList();
              
              // Sort by newest first
              filteredListings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
              
              if (filteredListings.isEmpty) {
                return _buildEmptyState();
              }
              
              return ListView.builder(
                itemCount: filteredListings.length,
                itemBuilder: (context, index) {
                  return ListingCard(
                    listing: filteredListings[index],
                    isOwner: true,
                    onTap: () {
                      // Navigate to listing detail
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ListingDetailScreen(
                            listing: filteredListings[index],
                          ),
                        ),
                      );
                    },
                    onViewResponses: () {
                      setState(() {
                        _showingResponses = true;
                        _selectedListingId = filteredListings[index].id;
                      });
                      // Load responses for this listing
                      ref.read(responseProvider.notifier).loadResponses(
                        listingEventId: filteredListings[index].id,
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
                  const Text('Error loading your listings'),
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
    );
  }
  
  Widget _buildResponsesList() {
    final responsesState = ref.watch(responseProvider);
    final themeData = Theme.of(context);
    final customColors = themeData.customColors;
    
    // Find the current listing
    final listingsState = ref.watch(listingProvider);
    ListingModel? selectedListing;
    if (listingsState is AsyncData && _selectedListingId != null) {
      selectedListing = listingsState.value
          ?.firstWhere((listing) => listing.id == _selectedListingId, 
                       orElse: () => throw Exception('Listing not found'));
    }
    
    return Column(
      children: [
        // Header with back button
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: customColors.feedBgColor,
            border: Border(
              bottom: BorderSide(
                color: customColors.separatorColor.withOpacity(0.3),
              ),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _showingResponses = false;
                    _selectedListingId = null;
                  });
                },
              ),
              Expanded(
                child: Text(
                  selectedListing != null ? 'Responses: ${selectedListing.title}' : 'Responses',
                  style: themeData.textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        
        // Response status filter
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
            height: 36,
            decoration: BoxDecoration(
              color: customColors.feedBgColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: ResponseStatus.values.map((status) {
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedStatus = _selectedStatus == status ? null : (status as ListingStatus?);
                      });
                    },
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _selectedStatus == status
                            ? _getColorForResponseStatus(status)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        _getStatusDisplayName(status),
                        style: TextStyle(
                          color: _selectedStatus == status
                              ? Colors.white
                              : customColors.secondaryForegroundColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        
        // Responses content
        Expanded(
          child: responsesState.when(
            data: (responses) {
              // Filter responses based on selected status
              final filteredResponses = responses.where((response) {
                if (_selectedStatus != null && response.status != _selectedStatus) {
                  return false;
                }
                return true;
              }).toList();
              
              if (filteredResponses.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.forum_outlined,
                        size: 48,
                        color: customColors.secondaryForegroundColor.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No responses yet',
                        style: TextStyle(
                          color: customColors.secondaryForegroundColor,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              }
              
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: filteredResponses.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final response = filteredResponses[index];
                  
                  return _buildResponseItem(context, response);
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
                  const Text('Error loading responses'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (_selectedListingId != null) {
                        ref.read(responseProvider.notifier).loadResponses(
                          listingEventId: _selectedListingId!,
                        );
                      }
                    },
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildResponseItem(BuildContext context, ResponseModel response) {
    final themeData = Theme.of(context);
    final customColors = themeData.customColors;
    
    // Get color for response type
    Color getTypeColor() {
      switch (response.responseType) {
        case ResponseType.help:
          return Colors.blue;
        case ResponseType.interest:
          return Colors.green;
        case ResponseType.question:
          return Colors.orange;
        case ResponseType.offer:
          return Colors.purple;
      }
    }
    
    // Get text for response type
    String getTypeText() {
      switch (response.responseType) {
        case ResponseType.help:
          return 'Offered help';
        case ResponseType.interest:
          return 'Expressed interest';
        case ResponseType.question:
          return 'Asked a question';
        case ResponseType.offer:
          return 'Made a counter-offer';
      }
    }
    
    // Get icon for response type
    IconData getTypeIcon() {
      switch (response.responseType) {
        case ResponseType.help:
          return Icons.volunteer_activism;
        case ResponseType.interest:
          return Icons.thumb_up_outlined;
        case ResponseType.question:
          return Icons.help_outline;
        case ResponseType.offer:
          return Icons.local_offer_outlined;
      }
    }
    
    return Card(
      elevation: 0,
      color: customColors.feedBgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: response.status == ResponseStatus.accepted
              ? Colors.green.withOpacity(0.3)
              : response.status == ResponseStatus.declined
                  ? Colors.red.withOpacity(0.3)
                  : customColors.separatorColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Response type
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: getTypeColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        getTypeIcon(),
                        color: getTypeColor(),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        getTypeText(),
                        style: TextStyle(
                          color: getTypeColor(),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Status
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getColorForResponseStatus(response.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getColorForResponseStatus(response.status).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _getStatusDisplayName(response.status),
                    style: TextStyle(
                      color: _getColorForResponseStatus(response.status),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Response content
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: customColors.feedBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                response.content,
                style: themeData.textTheme.bodyMedium,
              ),
            ),
            
            // Additional details if present
            if (response.price != null || 
                response.availability != null || 
                response.location != null) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (response.price != null)
                    _buildDetailChip(
                      Icons.attach_money,
                      response.price!,
                      Colors.green,
                    ),
                  if (response.availability != null)
                    _buildDetailChip(
                      Icons.access_time,
                      response.availability!,
                      Colors.blue,
                    ),
                  if (response.location != null)
                    _buildDetailChip(
                      Icons.location_on,
                      response.location!,
                      Colors.orange,
                    ),
                ],
              ),
            ],
            
            const SizedBox(height: 12),
            
            // Date and action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Date
                Text(
                  _formatRelativeTime(response.createdAt),
                  style: TextStyle(
                    color: customColors.secondaryForegroundColor,
                    fontSize: 12,
                  ),
                ),
                
                // Action buttons (for pending responses)
                if (response.status == ResponseStatus.pending)
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _handleDeclineResponse(response),
                        icon: const Icon(Icons.close, size: 16),
                        label: const Text('Decline', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => _handleAcceptResponse(response),
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Accept', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  void _handleAcceptResponse(ResponseModel response) {
    _showConfirmationDialog(
      context: context,
      title: 'Accept Response',
      message: 'Are you sure you want to accept this response? This will mark it as accepted and notify the sender.',
      confirmButtonText: 'Accept',
      confirmButtonColor: Colors.green,
      onConfirm: () {
        ref.read(responseProvider.notifier).updateResponse(
          response.copyWith(
            status: ResponseStatus.accepted,
          ),
        ).then((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Response accepted'),
              backgroundColor: Colors.green,
            ),
          );
        });
      },
    );
  }

  void _handleDeclineResponse(ResponseModel response) {
    _showConfirmationDialog(
      context: context,
      title: 'Decline Response',
      message: 'Are you sure you want to decline this response? This will mark it as declined and notify the sender.',
      confirmButtonText: 'Decline',
      confirmButtonColor: Colors.red,
      onConfirm: () {
        ref.read(responseProvider.notifier).updateResponse(
          response.copyWith(
            status: ResponseStatus.declined,
          ),
        ).then((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Response declined'),
              backgroundColor: Colors.redAccent,
            ),
          );
        });
      },
    );
  }
  
  // Helper method to show confirmation dialogs
  void _showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String message,
    required String confirmButtonText,
    required Color confirmButtonColor,
    required VoidCallback onConfirm,
  }) {
    final themeData = Theme.of(context);
    final customColors = themeData.customColors;
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: customColors.feedBgColor,
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: TextStyle(color: customColors.secondaryForegroundColor),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              onConfirm();
            },
            child: Text(
              confirmButtonText,
              style: TextStyle(color: confirmButtonColor),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToCreateListing(ListingType type) {
    // Navigate to create listing screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreateEditListingScreen(
          type: type,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final themeData = Theme.of(context);
    final customColors = themeData.customColors;
    
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _tabController.index == 1 ? Icons.help_outline : 
            _tabController.index == 2 ? Icons.local_offer_outlined : 
            Icons.swap_horiz_outlined,
            size: 72,
            color: customColors.secondaryForegroundColor.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            _buildEmptyStateText(),
            style: themeData.textTheme.titleMedium?.copyWith(
              color: customColors.secondaryForegroundColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              final typeToCreate = _tabController.index == 1 ? ListingType.ask : 
                                  _tabController.index == 2 ? ListingType.offer : 
                                  ListingType.ask;
              _navigateToCreateListing(typeToCreate);
            },
            icon: Icon(
              _tabController.index == 2 ? Icons.local_offer_outlined : Icons.help_outline,
              size: 16,
            ),
            label: Text('Post a${_tabController.index == 2 ? 'n Offer' : 'n Ask'}'),
          ),
        ],
      ),
    );
  }

  String _buildEmptyStateText() {
    if (_searchQuery.isNotEmpty) {
      return 'No results found for "$_searchQuery"';
    }
    
    if (_tabController.index == 1) {
      return 'You haven\'t posted any asks yet.\nPost an ask to get started!';
    } else if (_tabController.index == 2) {
      return 'You haven\'t posted any offers yet.\nPost an offer to get started!';
    }
    
    return 'You haven\'t posted any listings yet.\nCreate your first ask or offer!';
  }
  
  void _showFilterBottomSheet(BuildContext context) {
    final themeData = Theme.of(context);
    final customColors = themeData.customColors;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: customColors.feedBgColor,
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
                        color: Colors.grey.withOpacity(0.3),
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
                              color: customColors.secondaryForegroundColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: ListingStatus.values.map((status) {
                              return FilterChip(
                                label: Text(_getStatusDisplayName(status).toUpperCase()),
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
  
  String _formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} ${(difference.inDays / 365).floor() == 1 ? 'year' : 'years'} ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} ${(difference.inDays / 30).floor() == 1 ? 'month' : 'months'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'just now';
    }
  }
  
  Color _getColorForResponseStatus(ResponseStatus status) {
    switch (status) {
      case ResponseStatus.pending:
        return Colors.grey;
      case ResponseStatus.accepted:
        return Colors.green;
      case ResponseStatus.declined:
        return Colors.red;
      case ResponseStatus.withdrawn:
        return Colors.orange;
    }
  }
  
  String _getStatusDisplayName(dynamic status) {
    if (status is ListingStatus) {
      switch (status) {
        case ListingStatus.active:
          return 'Active';
        case ListingStatus.inactive:
          return 'Inactive';
        case ListingStatus.fulfilled:
          return 'Fulfilled';
        case ListingStatus.expired:
          return 'Expired';
        case ListingStatus.cancelled:
          return 'Cancelled';
      }
    } else if (status is ResponseStatus) {
      switch (status) {
        case ResponseStatus.pending:
          return 'Pending';
        case ResponseStatus.accepted:
          return 'Accepted';
        case ResponseStatus.declined:
          return 'Declined';
        case ResponseStatus.withdrawn:
          return 'Withdrawn';
      }
    }
    return 'Unknown';
  }
}