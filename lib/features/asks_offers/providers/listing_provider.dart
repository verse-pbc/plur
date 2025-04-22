import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nostr_sdk/nostr_sdk.dart'; // Use nostr_sdk
import 'package:nostrmo/main.dart'; // Import main to access global nostr
import 'package:nostrmo/util/group_id_util.dart';
import '../models/listing_model.dart';

final listingProvider =
    StateNotifierProvider<ListingNotifier, AsyncValue<List<ListingModel>>>((ref) {
  // Pass ref to the notifier
  return ListingNotifier(ref);
});

class ListingNotifier extends StateNotifier<AsyncValue<List<ListingModel>>> {
  final Ref ref;
  String? _subscriptionId;

  ListingNotifier(this.ref) : super(const AsyncValue.loading()) {
    // Initialize with loading state and load initial listings
    loadListings();
  }

  final Map<String, ListingModel> _latestListings =
      {}; // Track latest version by (pubkey, d)

  void _handleSubscriptionEvent(Event event) {
    handleEvent(event);
    // Update state when new events arrive
    state = AsyncValue.data(_latestListings.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  }

  Future<void> loadListings({String? groupId}) async {
    if (nostr == null) {
      state = AsyncValue.error('Nostr client not initialized', StackTrace.current);
      return;
    }
    try {
      debugPrint("Loading listings with groupId: $groupId");
      state = const AsyncValue.loading();
      _latestListings.clear(); // Clear previous listings

      // Create filter for kind 31111 (listing events)
      final filter = Filter(kinds: [31111]);
      // Convert filter to JSON to add custom tags
      final filterJson = filter.toJson();
      
      // Add tag filter if a group ID is specified
      if (groupId != null) {
        // For better querying, we should try multiple formats of the group ID in parallel
        List<String> groupIdFormats = [];
        
        // Add original group ID
        groupIdFormats.add(groupId);
        
        // If the group ID starts with wss://communities.nos.social:, extract the ID part
        if (groupId.startsWith("wss://communities.nos.social:")) {
          final idPart = groupId.split(':').last;
          groupIdFormats.add(idPart);
        }
        
        // Standardize the group ID for h-tag filter
        String standardized = GroupIdUtil.standardizeGroupIdString(groupId);
        if (!groupIdFormats.contains(standardized)) {
          groupIdFormats.add(standardized);
        }
        
        // Extract just the ID part to also search for that
        String idPart = GroupIdUtil.extractIdPart(groupId);
        if (idPart.isNotEmpty && !groupIdFormats.contains(idPart)) {
          groupIdFormats.add(idPart);
        }
        
        // Add all formats to the h-tag filter for maximum compatibility
        filterJson["#h"] = groupIdFormats;
        
        debugPrint("Added h-tag filter: ${filterJson["#h"]}");
        debugPrint("Original groupId: '$groupId', Expanded to multiple formats for search");
      }

      // Cancel previous subscription if exists
      if (_subscriptionId != null) {
        try {
          nostr!.unsubscribe(_subscriptionId!);
        } catch (e) {
          // Ignore errors when unsubscribing
        }
      }

      // Get recent listings
      // Use SDK-provided methods for querying events
      List<Event> initialEvents = [];
      try {
        // Adapting to the nostr_sdk available methods
        initialEvents = await nostr!.queryEvents([filterJson]);
      } catch (e) {
        // Log error but continue with empty list
      }
      for (final event in initialEvents) {
        handleEvent(event);
      }
      // Update state after initial load
      state = AsyncValue.data(_latestListings.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt)));

      // Subscribe to future events using the SDK's event subscription mechanism
      _subscriptionId = "listings_${DateTime.now().millisecondsSinceEpoch}";
      
      // Based on codebase examples, we pass a callback function to handle events
      nostr!.subscribe(
        [filterJson],
        _handleSubscriptionEvent,
        id: _subscriptionId,
      );

    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> createListing({
    // Removed pubkey from arguments, get it from nostr instance
    required ListingType type,
    required String title,
    required String content,
    String? groupId,
    DateTime? expiresAt,
    String? location,
    String? price,
    List<String> imageUrls = const [],
    String? paymentInfo,
  }) async {
     if (nostr == null) {
      throw Exception('Nostr client not initialized');
    }
    try {
      final pubkey = nostr!.publicKey;
      final d = DateTime.now().millisecondsSinceEpoch.toString(); // Unique identifier
      final now = DateTime.now();
      
      // Process the group ID if provided - extract just the ID part for storage in the listing
      String? processedGroupId;
      if (groupId != null) {
        // Extract just the ID part, regardless of input format
        processedGroupId = GroupIdUtil.extractIdPart(groupId);
        debugPrint("Extracted group ID part for listing creation: '$processedGroupId' from '$groupId'");
      }
      
      final listing = ListingModel(
        id: '', // ID will be generated by signing
        pubkey: pubkey,
        d: d,
        type: type,
        title: title,
        content: content,
        status: ListingStatus.active,
        groupId: processedGroupId, // Use the processed group ID
        expiresAt: expiresAt,
        location: location,
        price: price,
        imageUrls: imageUrls,
        paymentInfo: paymentInfo,
        createdAt: now, // Use consistent timestamp
      );

      Event eventToPublish = listing.toEvent();
      // Update createdAt for the event itself before signing
      // SDK doesn't have a copyWith for Event, so we update the timestamp directly
      final updatedCreatedAt = now.millisecondsSinceEpoch ~/ 1000;
      eventToPublish.createdAt = updatedCreatedAt;
      
      // Sign the event
      nostr!.signEvent(eventToPublish);
      
      // Create final model with the actual event ID
      final finalListing = listing.copyWith(id: eventToPublish.id);
      
      // Send the event to relays
      await nostr!.sendEvent(eventToPublish);

      // Update local state immediately
      _updateListing(finalListing);

    } catch (error, stackTrace) {
      // Propagate error or handle it
       if (state is! AsyncError) {
         state = AsyncValue.error(error, stackTrace);
       }
       // Rethrow to signal failure upstream
       rethrow;
    }
  }

  Future<void> updateListing(ListingModel listing) async {
     if (nostr == null) {
      throw Exception('Nostr client not initialized');
    }
    try {
      // Process the group ID if provided - extract just the ID part for storage in the listing
      String? processedGroupId;
      if (listing.groupId != null) {
        // Extract just the ID part, regardless of input format
        processedGroupId = GroupIdUtil.extractIdPart(listing.groupId);
        debugPrint("Extracted group ID part for listing update: '$processedGroupId' from '${listing.groupId}'");
      }
      
      // Ensure the createdAt is newer for the replacement event
      final now = DateTime.now();
      final updatedListing = listing.copyWith(
        createdAt: now,
        groupId: processedGroupId, // Use the processed group ID
      );

      Event eventToPublish = updatedListing.toEvent();
      // Update createdAt for the event itself before signing
      // SDK doesn't have a copyWith for Event, so we update the timestamp directly
      final updatedCreatedAt = now.millisecondsSinceEpoch ~/ 1000;
      eventToPublish.createdAt = updatedCreatedAt;
      
      // Sign the event
      nostr!.signEvent(eventToPublish);

      // Update the ID in the model if needed
      final finalListing = updatedListing.copyWith(id: eventToPublish.id);

      // Send the event to relays
      await nostr!.sendEvent(eventToPublish);
      
      // Update local state
      _updateListing(finalListing);

    } catch (error, stackTrace) {
      if (state is! AsyncError) {
         state = AsyncValue.error(error, stackTrace);
       }
       // Rethrow to signal failure upstream
       rethrow;
    }
  }

  // Process incoming events
  void handleEvent(Event event) {
    if (event.kind == 31111) {
      final listing = ListingModel.fromEvent(event);
      _updateListing(listing);
    }
  }

  void _updateListing(ListingModel listing) {
    final key = '${listing.pubkey}:${listing.d}';
    final currentListing = _latestListings[key];

    // NIP-33 logic: Only update if this is a newer version
    if (currentListing == null ||
        listing.createdAt.isAfter(currentListing.createdAt)) {
      _latestListings[key] = listing;

      // Update state with all current listings, sorted by creation date
      state = AsyncValue.data(_latestListings.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
    }
  }

  List<ListingModel> filterListings({
    ListingType? type,
    ListingStatus? status,
    String? groupId,
    String? searchQuery,
    bool showAllGroups = false,
  }) {
    if (!state.hasValue || state.value == null) return [];
    
    // Log filter parameters for debugging
    debugPrint("Filtering listings: type=${type?.name}, groupId=$groupId, showAllGroups=$showAllGroups");
    
    // If filtering by group ID, log all listings' group IDs for debugging
    if (groupId != null && !showAllGroups) {
      debugPrint("Available listings with group info:");
      for (final listing in state.value!) {
        debugPrint("  Listing: ${listing.title}, GroupId: ${listing.groupId}");
      }
    }

    final results = state.value!.where((listing) {
      // Filter by type
      if (type != null && listing.type != type) return false;
      // Filter by status
      if (status != null && listing.status != status) return false;
      
      // Filter by group ID (if applicable)
      // When showAllGroups is true, we include all listings (from all groups) 
      // Otherwise use the original group filtering behavior
      if (!showAllGroups) {
        if (groupId != null) {
          // Check if listing belongs to the specified group, handling different id formats
          if (listing.groupId == null || !_doesListingMatchGroup(listing, groupId)) {
            return false;
          }
        } else {
          // No group filter specified - only show public listings (no group)
          if (listing.groupId != null) return false;
        }
      }
      
      // Filter by search query
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        return listing.title.toLowerCase().contains(query) ||
               listing.content.toLowerCase().contains(query);
      }
      // If no filters match, include the listing
      return true;
    }).toList();
    
    // Log filtered results
    if (groupId != null && !showAllGroups) {
      debugPrint("Filtered results for groupId=$groupId: ${results.length} listings");
      for (final listing in results) {
        debugPrint("  Matched listing: ${listing.title}, GroupId: ${listing.groupId}");
      }
    }
    
    return results;
  }

  // Helper method to check if a listing matches a group ID, handling different formats
  bool _doesListingMatchGroup(ListingModel listing, String groupIdFilter) {
    if (listing.groupId == null) return false;
    
    // Debug help
    debugPrint("Comparing groupIdFilter: '$groupIdFilter' with listing.groupId: '${listing.groupId}'");
    
    // Check string equality first
    if (listing.groupId == groupIdFilter) {
      debugPrint("✅ EXACT MATCH! groupIdFilter: '$groupIdFilter', listing.groupId: '${listing.groupId}'");
      return true;
    }
    
    // Check for domain-specific matching (wss://communities.nos.social:XXXX)
    if (groupIdFilter.startsWith("wss://communities.nos.social:") && 
        !listing.groupId!.startsWith("wss://")) {
      // Extract the ID part from the filter
      final communityId = groupIdFilter.split(':').last;
      if (listing.groupId == communityId) {
        debugPrint("✅ MATCH after domain extraction! communityId: '$communityId', listing.groupId: '${listing.groupId}'");
        return true;
      }
    }
    
    // Use GroupIdUtil for format-agnostic comparison
    // Extract ID parts separately for detailed debugging
    final filterIdPart = GroupIdUtil.extractIdPart(groupIdFilter);
    final listingIdPart = GroupIdUtil.extractIdPart(listing.groupId);
    
    // Check if ID parts match
    final idPartsMatch = filterIdPart == listingIdPart && filterIdPart.isNotEmpty;
    
    // Detailed debugging
    debugPrint("Filter ID extraction: '$groupIdFilter' → '$filterIdPart'");
    debugPrint("Listing ID extraction: '${listing.groupId}' → '$listingIdPart'");
    
    if (idPartsMatch) {
      debugPrint("✅ ID parts MATCH! filterIdPart: '$filterIdPart', listingIdPart: '$listingIdPart'");
      return true;
    } else {
      debugPrint("❌ ID parts DO NOT match! filterIdPart: '$filterIdPart', listingIdPart: '$listingIdPart'");
      return false;
    }
  }

  @override
  void dispose() {
    if (_subscriptionId != null && nostr != null) {
      try {
        nostr!.unsubscribe(_subscriptionId!);
      } catch (_) {
        // Ignore errors when unsubscribing during dispose
      }
    }
    super.dispose();
  }
} 