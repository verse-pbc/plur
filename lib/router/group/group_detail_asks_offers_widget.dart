import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/features/asks_offers/models/listing_model.dart';
import 'package:nostrmo/features/asks_offers/providers/listing_provider.dart';
import 'package:nostrmo/features/asks_offers/widgets/listing_card.dart';
import 'package:nostrmo/features/asks_offers/screens/create_edit_listing_screen.dart';
import 'package:nostrmo/features/asks_offers/screens/listing_detail_screen.dart';
import 'package:nostrmo/util/theme_util.dart';
import 'package:nostrmo/generated/l10n.dart';

class GroupDetailAsksOffersWidget extends ConsumerStatefulWidget {
  final GroupIdentifier groupIdentifier;

  const GroupDetailAsksOffersWidget(this.groupIdentifier, {super.key});

  @override
  ConsumerState<GroupDetailAsksOffersWidget> createState() => _GroupDetailAsksOffersWidgetState();
}

class _GroupDetailAsksOffersWidgetState extends ConsumerState<GroupDetailAsksOffersWidget> with AutomaticKeepAliveClientMixin {
  ListingType? _selectedType;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize listings for this group
    _loadListings();
  }
  
  Future<void> _loadListings() async {
    // Format the group ID as "host:id" - specifically for asks/offers h-tag format
    // This is different from GroupIdentifier.toString() which uses ' as separator
    final groupId = "${widget.groupIdentifier.host}:${widget.groupIdentifier.groupId}";
    
    // Log for debugging
    debugPrint("Loading listings for group ID: $groupId");
    
    // Load listings from provider
    await ref.read(listingProvider.notifier).loadListings(groupId: groupId);
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final themeData = Theme.of(context);
    final customColors = themeData.customColors;
    final l10n = S.of(context);
    
    // Format the group ID as "host:id" - specifically for asks/offers h-tag format
    final groupId = "${widget.groupIdentifier.host}:${widget.groupIdentifier.groupId}";
    
    // Get listings data
    final listingsState = ref.watch(listingProvider);
    
    return Column(
      children: [
        // Tab bar for filtering Ask/Offer
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: customColors.feedBgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildFilterButton(
                  label: "All",
                  isSelected: _selectedType == null,
                  onTap: () => setState(() => _selectedType = null),
                ),
              ),
              Expanded(
                child: _buildFilterButton(
                  label: l10n.asks,
                  isSelected: _selectedType == ListingType.ask,
                  onTap: () => setState(() => _selectedType = ListingType.ask),
                ),
              ),
              Expanded(
                child: _buildFilterButton(
                  label: l10n.offers,
                  isSelected: _selectedType == ListingType.offer,
                  onTap: () => setState(() => _selectedType = ListingType.offer),
                ),
              ),
            ],
          ),
        ),
        
        // Main content
        Expanded(
          child: listingsState.when(
            data: (listings) {
              // Filter listings based on selected type and group
              final allListings = ref.read(listingProvider.notifier).filterListings(
                type: _selectedType,
                showAllGroups: true,
              );
              
              final filteredListings = ref.read(listingProvider.notifier).filterListings(
                type: _selectedType,
                groupId: groupId,
                showAllGroups: false,
              );
              
              // Debug log to see what's happening with listings
              debugPrint("All listings: ${allListings.length}, Group listings for '$groupId': ${filteredListings.length}");
              if (allListings.isNotEmpty && filteredListings.isEmpty) {
                // Debug each listing's groupId to see what's wrong
                for (final listing in allListings) {
                  debugPrint("Listing: ${listing.title}, GroupId: ${listing.groupId}");
                }
              }
              
              if (filteredListings.isEmpty) {
                return _buildEmptyState();
              }
              
              return RefreshIndicator(
                onRefresh: _loadListings,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: filteredListings.length,
                  itemBuilder: (context, index) {
                    return ListingCard(
                      listing: filteredListings[index],
                      showGroupBadge: false, // No need to show group badge in a group view
                      onTap: () {
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
                ),
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (error, stackTrace) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.errorWhileLoadingListings),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadListings,
                    child: Text(l10n.tryAgain),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildFilterButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final themeData = Theme.of(context);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? themeData.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : themeData.customColors.secondaryForegroundColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
  
  Widget _buildEmptyState() {
    final themeData = Theme.of(context);
    final l10n = S.of(context);
    
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _selectedType == ListingType.ask ? Icons.help_outline : 
            _selectedType == ListingType.offer ? Icons.local_offer_outlined : 
            Icons.swap_horiz_outlined,
            size: 72,
            color: Colors.grey.withValues(red: 158, green: 158, blue: 158, alpha: 128),
          ),
          const SizedBox(height: 16),
          Text(
            _buildEmptyStateText(l10n),
            style: themeData.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => _navigateToCreateListing(ListingType.ask),
                icon: const Icon(Icons.help_outline, size: 16),
                label: Text(l10n.postAnAsk),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => _navigateToCreateListing(ListingType.offer),
                icon: const Icon(Icons.local_offer_outlined, size: 16),
                label: Text(l10n.postAnOffer),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  String _buildEmptyStateText(S l10n) {
    if (_selectedType == ListingType.ask) {
      return l10n.noAsksPostedYet;
    } else if (_selectedType == ListingType.offer) {
      return l10n.noOffersPostedYet;
    }
    
    return l10n.noAsksOrOffersPostedYet;
  }
  
  void _navigateToCreateListing(ListingType type) {
    // Format the group ID as "host:id" - specifically for asks/offers h-tag format
    final groupId = "${widget.groupIdentifier.host}:${widget.groupIdentifier.groupId}";
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreateEditListingScreen(
          groupId: groupId,
          type: type,
        ),
      ),
    ).then((_) {
      // Refresh listings when returning from create screen
      _loadListings();
    });
  }
}