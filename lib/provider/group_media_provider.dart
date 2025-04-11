import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/main.dart';

/// Provider for fetching and managing media posts from a specific group.
/// Handles loading, caching, and organizing posts with image attachments.
class GroupMediaProvider extends ChangeNotifier with PendingEventsLaterFunction {
  late int _initTime;
  
  /// Holds the posts containing media from the group
  final EventMemBox mediaBox = EventMemBox(sortAfterAdd: false);
  
  /// The group identifier this provider is fetching media for
  final GroupIdentifier groupId;
  
  /// Indicates whether the provider is currently loading
  bool isLoading = true;
  
  /// Stores file metadata mapped by event ID for easy access
  final Map<String, List<FileMetadata>> fileMetadataMap = {};
  
  /// ID for the subscription to group events
  final String subscribeId = StringUtil.rndNameStr(16);
  
  GroupMediaProvider(this.groupId) {
    _initTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    
    // Set a timeout to stop showing the loading indicator after 5 seconds
    // even if no media posts are received
    Future.delayed(const Duration(seconds: 5), () {
      if (isLoading) {
        isLoading = false;
        notifyListeners();
      }
    });
  }
  
  @override
  void dispose() {
    _unsubscribe();
    disposeLater();
    super.dispose();
  }
  
  /// Clears all stored media data
  void clear() {
    mediaBox.clear();
    fileMetadataMap.clear();
    notifyListeners();
  }
  
  /// Fetches media posts from the group relay
  void fetchMedia() {
    if (nostr == null) return;
    
    isLoading = true;
    notifyListeners();
    
    final filter = Filter(
      kinds: [EventKind.groupNote, EventKind.groupNoteReply],
      until: _initTime,
      limit: 100,  // Get a larger number of posts to filter by media
    );
    
    final jsonMap = filter.toJson();
    jsonMap["#h"] = [groupId.groupId];
    
    // Query the specific relay for this group
    nostr!.query(
      [jsonMap],
      onEvent,
      tempRelays: [groupId.host],
      relayTypes: RelayType.onlyTemp,
      sendAfterAuth: true,
    );
    
    // Subscribe to new media posts
    _subscribe();
  }
  
  /// Processes events from the query/subscription
  void onEvent(Event event) {
    later(event, (list) {
      bool mediaAdded = false;
      
      for (var e in list) {
        // Only process group notes and replies
        if (e.kind == EventKind.groupNote || e.kind == EventKind.groupNoteReply) {
          // Check if event has image metadata or contains image URLs
          if (_hasImageContent(e)) {
            if (mediaBox.add(e)) {
              mediaAdded = true;
              _processEventFileMetadata(e);
            }
          }
        }
      }
      
      if (isLoading) {
        isLoading = false;
        if (mediaAdded) {
          mediaBox.sort();
        }
        notifyListeners();
      } else if (mediaAdded) {
        mediaBox.sort();
        notifyListeners();
      }
    }, null);
  }
  
  /// Subscribe to new media posts from the group
  void _subscribe() {
    if (nostr == null) return;
    
    final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    
    final filter = {
      "kinds": [EventKind.groupNote, EventKind.groupNoteReply],
      "#h": [groupId.groupId],
      "since": currentTime
    };
    
    // Subscribe to the group's relay
    try {
      nostr!.subscribe(
        [filter],
        _handleSubscriptionEvent,
        id: subscribeId,
        relayTypes: [RelayType.temp],
        tempRelays: [groupId.host],
        sendAfterAuth: true,
      );
    } catch (e) {
      print("Error in subscription to group relay: $e");
    }
  }
  
  /// Handle events from the subscription
  void _handleSubscriptionEvent(Event event) {
    later(event, (list) {
      for (final e in list) {
        // Process events coming from subscription
        if (_hasImageContent(e)) {
          if (mediaBox.add(e)) {
            _processEventFileMetadata(e);
            mediaBox.sort();
            notifyListeners();
          }
        }
      }
    }, null);
  }
  
  /// Unsubscribe from the group relay
  void _unsubscribe() {
    try {
      if (nostr != null) {
        nostr!.unsubscribe(subscribeId);
      }
    } catch (e) {
      print("Error unsubscribing: $e");
    }
  }
  
  /// Check if an event has image content (either via imeta tags or content URLs)
  bool _hasImageContent(Event event) {
    // Check for imeta tags
    for (var tag in event.tags) {
      if (tag is List && tag.isNotEmpty) {
        if (tag[0] == "imeta") {
          return true;
        }
      }
    }
    
    // Check for image URLs in content
    final content = event.content.toLowerCase();
    return content.contains('.jpg') || 
           content.contains('.jpeg') || 
           content.contains('.png') || 
           content.contains('.gif') ||
           content.contains('.webp');
  }
  
  /// Process file metadata from an event and store it for later use
  void _processEventFileMetadata(Event event) {
    final metadataList = <FileMetadata>[];
    
    // Look for imeta tags
    for (var tag in event.tags) {
      if (tag is List && tag.isNotEmpty && tag[0] == "imeta") {
        final metadata = FileMetadata.fromNIP92Tag(tag);
        if (metadata != null) {
          metadataList.add(metadata);
        }
      }
    }
    
    // If found any metadata, store it by event ID
    if (metadataList.isNotEmpty) {
      fileMetadataMap[event.id] = metadataList;
    }
  }
  
  /// Get file metadata for a specific event
  List<FileMetadata> getFileMetadata(String eventId) {
    return fileMetadataMap[eventId] ?? [];
  }
  
  /// Refresh media posts
  void refresh() {
    _initTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    clear();
    fetchMedia();
  }
}