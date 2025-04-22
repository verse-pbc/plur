import 'package:flutter/foundation.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/util/group_id_util.dart';
import 'package:nostrmo/features/events/nostr_event_kinds.dart';

/// RSVP status options for events
enum RSVPStatus {
  /// User is going to the event
  going,
  
  /// User is interested but not committed
  interested,
  
  /// User is not going to the event
  notGoing,
}

/// Extension to convert RSVPStatus to/from string values used in event tags
extension RSVPStatusExtension on RSVPStatus {
  /// Get string value for Nostr event tag
  String get value {
    switch (this) {
      case RSVPStatus.going:
        return 'going';
      case RSVPStatus.interested:
        return 'interested';
      case RSVPStatus.notGoing:
        return 'not-going';
    }
  }
  
  /// Parse RSVPStatus from string value
  static RSVPStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'going':
        return RSVPStatus.going;
      case 'interested':
        return RSVPStatus.interested;
      case 'not-going':
      case 'notgoing':
      case 'not_going':
        return RSVPStatus.notGoing;
      default:
        return RSVPStatus.interested; // Default to interested
    }
  }
}

/// Model representing an RSVP response to an event
class EventRSVPModel {
  /// Public key of the user who RSVPed
  final String pubkey;
  
  /// ID of the event being RSVPed to
  final String eventId;
  
  /// D-tag value of the event
  final String eventDTag;
  
  /// RSVP status (going, interested, not going)
  final RSVPStatus status;
  
  /// Group ID this event belongs to
  final String? groupId;
  
  /// Visibility level of the RSVP (follows event visibility)
  final String visibility;
  
  /// Timestamp when the RSVP was created/updated
  final DateTime createdAt;
  
  /// Custom fields for RSVP responses
  final Map<String, dynamic>? customResponses;
  
  /// Nostr event ID for this RSVP
  final String? id;
  
  /// Constructor
  EventRSVPModel({
    required this.pubkey,
    required this.eventId,
    required this.eventDTag,
    required this.status,
    this.groupId,
    required this.visibility,
    required this.createdAt,
    this.customResponses,
    this.id,
  });
  
  /// Create a copy of this RSVP with modified fields
  EventRSVPModel copyWith({
    String? pubkey,
    String? eventId,
    String? eventDTag,
    RSVPStatus? status,
    String? groupId,
    String? visibility,
    DateTime? createdAt,
    Map<String, dynamic>? customResponses,
    String? id,
  }) {
    return EventRSVPModel(
      pubkey: pubkey ?? this.pubkey,
      eventId: eventId ?? this.eventId,
      eventDTag: eventDTag ?? this.eventDTag,
      status: status ?? this.status,
      groupId: groupId ?? this.groupId,
      visibility: visibility ?? this.visibility,
      createdAt: createdAt ?? this.createdAt,
      customResponses: customResponses ?? this.customResponses,
      id: id ?? this.id,
    );
  }
  
  /// Convert RSVP to JSON map
  Map<String, dynamic> toJson() {
    return {
      'pubkey': pubkey,
      'eventId': eventId,
      'eventDTag': eventDTag,
      'status': status.value,
      'groupId': groupId,
      'visibility': visibility,
      'createdAt': createdAt.millisecondsSinceEpoch ~/ 1000,
      'customResponses': customResponses,
      'id': id,
    };
  }
  
  /// Create RSVP from JSON map
  factory EventRSVPModel.fromJson(Map<String, dynamic> json) {
    return EventRSVPModel(
      pubkey: json['pubkey'] as String,
      eventId: json['eventId'] as String,
      eventDTag: json['eventDTag'] as String,
      status: RSVPStatusExtension.fromString(json['status'] as String),
      groupId: json['groupId'] as String?,
      visibility: json['visibility'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch((json['createdAt'] as int) * 1000),
      customResponses: json['customResponses'] as Map<String, dynamic>?,
      id: json['id'] as String?,
    );
  }
  
  /// Create a Nostr event from this RSVP model
  Event toEvent() {
    // Create tags for the RSVP
    List<List<String>> tags = [];
    
    // Reference to the original event
    tags.add(['e', eventId, '', 'root']);
    
    // Event d-tag reference
    tags.add(['d', eventDTag]);
    
    // RSVP status
    tags.add(['l', status.value]);
    
    // Group context if provided
    if (groupId != null) {
      final standardGroupId = GroupIdUtil.standardizeGroupIdString(groupId!);
      tags.add(['h', standardGroupId]);
    }
    
    // Visibility (matching the event)
    tags.add(['v', visibility]);
    
    // Create the content for custom responses
    String content = '';
    if (customResponses != null && customResponses!.isNotEmpty) {
      try {
        content = customResponses.toString();
      } catch (e) {
        debugPrint('Error converting custom responses to string: $e');
      }
    }
    
    // Create the Nostr event
    return Event.create(
      kind: EventKindExtension.eventRSVP,
      pubkey: pubkey,
      content: content,
      tags: tags,
      createdAt: createdAt.millisecondsSinceEpoch ~/ 1000,
    );
  }
  
  /// Create an RSVP model from a Nostr event
  factory EventRSVPModel.fromEvent(Event event) {
    try {
      // Event must be kind 31925 (RSVP)
      if (event.kind != EventKindExtension.eventRSVP) {
        throw ArgumentError('Event is not an RSVP event (expected kind 31925)');
      }
      
      // Extract data from event tags
      String? eventId;
      String? eventDTag;
      String? statusStr;
      String? groupId;
      String? visibility;
      
      // Safely convert the dynamic tags to the expected type
      List<List<String>> typedTags = [];
      
      // Convert each tag to a strongly typed List<String>
      for (var tag in event.tags) {
        if (tag is List) {
          List<String> stringTag = [];
          for (var item in tag) {
            stringTag.add(item.toString());
          }
          typedTags.add(stringTag);
        }
      }
      
      // Extract tag values
      for (final tag in typedTags) {
        if (tag.isNotEmpty) {
          switch (tag[0]) {
            case 'e':
              if (tag.length > 1) eventId = tag[1];
              break;
            case 'd':
              if (tag.length > 1) eventDTag = tag[1];
              break;
            case 'l':
              if (tag.length > 1) statusStr = tag[1];
              break;
            case 'h':
              if (tag.length > 1) groupId = tag[1];
              break;
            case 'v':
              if (tag.length > 1) visibility = tag[1];
              break;
          }
        }
      }
    
    // Parse custom responses from content
    Map<String, dynamic>? customResponses;
    if (event.content.isNotEmpty) {
      try {
        customResponses = {
          'responses': event.content,
        };
      } catch (e) {
        debugPrint('Error parsing RSVP custom responses: $e');
      }
    }
    
    // Validate required fields
    if (eventId == null) {
      throw ArgumentError('RSVP event missing event ID (e tag)');
    }
    
    if (eventDTag == null) {
      throw ArgumentError('RSVP event missing event d-tag reference');
    }
    
    // Default status to 'interested' if missing
    final status = statusStr != null 
        ? RSVPStatusExtension.fromString(statusStr)
        : RSVPStatus.interested;
    
    // Default visibility to 'private' if missing
    visibility ??= 'private';
    
    return EventRSVPModel(
      pubkey: event.pubkey,
      eventId: eventId,
      eventDTag: eventDTag,
      status: status,
      groupId: groupId,
      visibility: visibility,
      createdAt: DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000),
      customResponses: customResponses,
      id: event.id,
    );
    } catch (e, stack) {
      debugPrint('Error creating RSVP from Event: $e');
      debugPrint('Stack trace: $stack');
      rethrow;
    }
  }
}