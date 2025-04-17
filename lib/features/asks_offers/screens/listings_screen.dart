import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:nostrmo/util/theme_util.dart';
import '../models/listing_model.dart';
import '../providers/listing_provider.dart';
import '../widgets/listing_card.dart';
import '../screens/create_edit_listing_screen.dart';
import '../screens/listing_detail_screen.dart';

class ListingsScreen extends ConsumerStatefulWidget {
  final String? groupId;

  const ListingsScreen({this.groupId, super.key});

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
    
    // Load listings when screen initializes
    ref.read(listingProvider.notifier).loadListings(groupId: widget.groupId);
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
    return ref.read(listingProvider.notifier).loadListings(groupId: widget.groupId);
  }

  @override
  Widget build(BuildContext context) {
    final listingsState = ref.watch(listingProvider);
    final themeData = Theme.of(context);
    final customColors = themeData.customColors;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Asks & Offers'),
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
                  fillColor: customColors.feedBgColor,
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
                  final filteredListings = ref.read(listingProvider.notifier).filterListings(
                    type: _selectedType,
                    status: _selectedStatus,
                    groupId: widget.groupId,
                    searchQuery: _searchQuery,
                  );

                  if (filteredListings.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.builder(
                    itemCount: filteredListings.length,
                    itemBuilder: (context, index) {
                      return ListingCard(
                        listing: filteredListings[index],
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
                      Text('Error loading listings'),
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
    // Use MaterialPageRoute directly instead of router utility
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreateEditListingScreen(
          groupId: widget.groupId,
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
            color: Colors.grey.withOpacity(0.5),
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