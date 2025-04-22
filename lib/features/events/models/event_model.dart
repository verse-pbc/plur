import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/util/group_id_util.dart';
import 'package:nostrmo/features/events/nostr_event_kinds.dart';

/// Enumeration of event visibility options
enum EventVisibility {
  /// Only visible to group members (encrypted)
  private,
  
  /// Accessible via shareable link but not in public listings (plaintext)
  publicLink,
  
  /// Publicly visible and discoverable (plaintext)
  public,
}

/// Extension to convert EventVisibility to/from string values used in event tags
extension EventVisibilityExtension on EventVisibility {
  /// Get string value for Nostr event tag
  String get value {
    switch (this) {
      case EventVisibility.private:
        return 'private';
      case EventVisibility.publicLink:
        return 'public_link';
      case EventVisibility.public:
        return 'public';
    }
  }
  
  /// Parse EventVisibility from string value
  static EventVisibility fromString(String value) {
    switch (value.toLowerCase()) {
      case 'private':
        return EventVisibility.private;
      case 'public_link':
        return EventVisibility.publicLink;
      case 'public':
        return EventVisibility.public;
      default:
        return EventVisibility.private; // Default to private for safety
    }
  }
}

/// Model representing an event in the system
class EventModel {
  /// Unique identifier of the event (NIP-52 "d" tag value)
  final String id;
  
  /// Public key of the event creator
  final String pubkey;
  
  /// Event unique identifier for duplicate detection (NIP-52 "d" tag)
  final String d;
  
  /// Title of the event
  final String title;
  
  /// Detailed description of the event
  final String description;
  
  /// URL to the event's cover image
  final String? coverImageUrl;
  
  /// Start date and time of the event
  final DateTime startAt;
  
  /// End date and time of the event (optional)
  final DateTime? endAt;
  
  /// Location of the event (physical address or virtual link)
  final String? location;
  
  /// Maximum number of attendees (optional)
  final int? capacity;
  
  /// Cost information (optional)
  final String? cost;
  
  /// Group ID this event belongs to
  final String? groupId;
  
  /// Visibility level of the event
  final EventVisibility visibility;
  
  /// Array of tags for categorization
  final List<String> tags;
  
  /// Original Nostr event ID
  final String? eventId;
  
  /// Timestamp when the event was created
  final DateTime createdAt;
  
  /// List of public keys of event organizers
  final List<String> organizers;
  
  /// Recurrence rule for recurring events (iCalendar RRULE format)
  final String? recurrenceRule;
  
  /// Constructor
  EventModel({
    required this.id,
    required this.pubkey,
    required this.d,
    required this.title,
    required this.description,
    this.coverImageUrl,
    required this.startAt,
    this.endAt,
    this.location,
    this.capacity,
    this.cost,
    this.groupId,
    required this.visibility,
    required this.tags,
    this.eventId,
    required this.createdAt,
    required this.organizers,
    this.recurrenceRule,
  });
  
  /// Create a copy of this event with modified fields
  EventModel copyWith({
    String? id,
    String? pubkey,
    String? d,
    String? title,
    String? description,
    String? coverImageUrl,
    DateTime? startAt,
    DateTime? endAt,
    String? location,
    int? capacity,
    String? cost,
    String? groupId,
    EventVisibility? visibility,
    List<String>? tags,
    String? eventId,
    DateTime? createdAt,
    List<String>? organizers,
    String? recurrenceRule,
  }) {
    return EventModel(
      id: id ?? this.id,
      pubkey: pubkey ?? this.pubkey,
      d: d ?? this.d,
      title: title ?? this.title,
      description: description ?? this.description,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      location: location ?? this.location,
      capacity: capacity ?? this.capacity,
      cost: cost ?? this.cost,
      groupId: groupId ?? this.groupId,
      visibility: visibility ?? this.visibility,
      tags: tags ?? this.tags,
      eventId: eventId ?? this.eventId,
      createdAt: createdAt ?? this.createdAt,
      organizers: organizers ?? this.organizers,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
    );
  }
  
  /// Convert event to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pubkey': pubkey,
      'd': d,
      'title': title,
      'description': description,
      'coverImageUrl': coverImageUrl,
      'startAt': startAt.millisecondsSinceEpoch ~/ 1000,
      'endAt': endAt != null ? endAt!.millisecondsSinceEpoch ~/ 1000 : null,
      'location': location,
      'capacity': capacity,
      'cost': cost,
      'groupId': groupId,
      'visibility': visibility.value,
      'tags': tags,
      'eventId': eventId,
      'createdAt': createdAt.millisecondsSinceEpoch ~/ 1000,
      'organizers': organizers,
      'recurrenceRule': recurrenceRule,
    };
  }
  
  /// Create event from JSON map
  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] as String,
      pubkey: json['pubkey'] as String,
      d: json['d'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      coverImageUrl: json['coverImageUrl'] as String?,
      startAt: DateTime.fromMillisecondsSinceEpoch((json['startAt'] as int) * 1000),
      endAt: json['endAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch((json['endAt'] as int) * 1000)
          : null,
      location: json['location'] as String?,
      capacity: json['capacity'] as int?,
      cost: json['cost'] as String?,
      groupId: json['groupId'] as String?,
      visibility: EventVisibilityExtension.fromString(json['visibility'] as String),
      tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
      eventId: json['eventId'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch((json['createdAt'] as int) * 1000),
      organizers: (json['organizers'] as List<dynamic>).map((e) => e as String).toList(),
      recurrenceRule: json['recurrenceRule'] as String?,
    );
  }
  
  /// Create a Nostr Event object from this model for publishing to relays
  Event toEvent() {
    // Determine if this is a date-based or time-based event per NIP-52
    final int kind = endAt != null ? EventKindExtension.timeBoundedEvent : EventKindExtension.dateBoundedEvent;
    
    // Create tags for the event
    List<List<String>> tags = [];
    
    // Required d-tag for unique ID (ensures we can update this event later)
    tags.add(['d', d]);
    
    // Group identifier tag - required for group events
    if (groupId != null) {
      // Use NIP-29 format for group identification
      final standardGroupId = GroupIdUtil.standardizeGroupIdString(groupId!);
      tags.add(['h', standardGroupId]);
    }
    
    // Visibility tag
    tags.add(['v', visibility.value]);
    
    // Start and end times
    final startTimestamp = startAt.millisecondsSinceEpoch ~/ 1000;
    tags.add(['start', startTimestamp.toString()]);
    
    if (endAt != null) {
      final endTimestamp = endAt!.millisecondsSinceEpoch ~/ 1000;
      tags.add(['end', endTimestamp.toString()]);
    }
    
    // Add title as name
    tags.add(['name', title]);
    
    // Add location if provided
    if (location != null && location!.isNotEmpty) {
      tags.add(['location', location!]);
    }
    
    // Add organizers
    for (final organizer in organizers) {
      tags.add(['p', organizer]);
    }
    
    // Add event tags/categories
    debugPrint('Adding tag categories, tag count: ${this.tags.length}');
    for (final tag in this.tags) {
      debugPrint('Adding tag: $tag');
      tags.add(['t', tag]);
    }
    
    // Add recurrence rule if provided
    if (recurrenceRule != null && recurrenceRule!.isNotEmpty) {
      tags.add(['recurrence', recurrenceRule!]);
    }
    
    // Create the event content
    // For now, just use the description as content
    final content = jsonEncode({
      'description': description,
      'coverImageUrl': coverImageUrl,
      'capacity': capacity,
      'cost': cost,
    });
    
    // Create the Nostr event
    try {
      debugPrint('Creating Event with kind: $kind, tags count: ${tags.length}');
      return Event.create(
        kind: kind,
        pubkey: pubkey,
        content: content,
        tags: tags,
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );
    } catch (e) {
      debugPrint('Error creating Nostr event: $e');
      rethrow;
    }
  }
  
  /// Create an EventModel from a Nostr event
  factory EventModel.fromEvent(Event event) {
    try {
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
      
      // Extract data from event tags
      String? eventId = event.id;
      String? d = _findTagValue(typedTags, 'd');
      String? groupId = _findTagValue(typedTags, 'h');
      String? visibilityStr = _findTagValue(typedTags, 'v');
      String? startStr = _findTagValue(typedTags, 'start');
      String? endStr = _findTagValue(typedTags, 'end');
      String? title = _findTagValue(typedTags, 'name');
      String? location = _findTagValue(typedTags, 'location');
      String? recurrenceRule = _findTagValue(typedTags, 'recurrence');
      
      // Extract organizers (p tags)
      List<String> organizers = _findAllTagValues(typedTags, 'p');
      
      // Extract event tags/categories
      List<String> tags = _findAllTagValues(typedTags, 't');
    
    // Parse content as JSON
    Map<String, dynamic> contentJson = {};
    if (event.content.isNotEmpty) {
      try {
        contentJson = jsonDecode(event.content);
      } catch (e) {
        debugPrint('Error parsing event content as JSON: $e');
        contentJson = {'description': event.content};
      }
    }
    
    // Extract data from content
    String description = contentJson['description'] ?? '';
    String? coverImageUrl = contentJson['coverImageUrl'];
    int? capacity = contentJson['capacity'];
    String? cost = contentJson['cost'];
    
    // Parse timestamps
    DateTime startAt = DateTime.fromMillisecondsSinceEpoch(0);
    DateTime? endAt;
    
    if (startStr != null) {
      try {
        startAt = DateTime.fromMillisecondsSinceEpoch(int.parse(startStr) * 1000);
      } catch (e) {
        debugPrint('Error parsing start timestamp: $e');
      }
    }
    
    if (endStr != null) {
      try {
        endAt = DateTime.fromMillisecondsSinceEpoch(int.parse(endStr) * 1000);
      } catch (e) {
        debugPrint('Error parsing end timestamp: $e');
      }
    }
    
    // Parse visibility
    EventVisibility visibility = EventVisibility.private;
    if (visibilityStr != null) {
      visibility = EventVisibilityExtension.fromString(visibilityStr);
    }
    
    // Default ID if missing
    d = d ?? DateTime.now().millisecondsSinceEpoch.toString();
    
    // Default title if missing
    title = (title == null || title.isEmpty) ? 'Untitled Event' : title;
    
    final String safeEventId = eventId == null ? '' : eventId;
    
    return EventModel(
      id: safeEventId,
      pubkey: event.pubkey,
      d: d,
      title: title,
      description: description,
      coverImageUrl: coverImageUrl,
      startAt: startAt,
      endAt: endAt,
      location: location,
      capacity: capacity,
      cost: cost,
      groupId: groupId,
      visibility: visibility,
      tags: tags,
      eventId: eventId,
      createdAt: DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000),
      organizers: organizers.isEmpty ? [event.pubkey] : organizers,
      recurrenceRule: recurrenceRule,
    );
    } catch (e, stack) {
      debugPrint('Error creating EventModel from Event: $e');
      debugPrint('Stack trace: $stack');
      rethrow;
    }
  }
  
  /// Find the value for a specific tag type
  static String? _findTagValue(List<List<String>> tags, String tagName) {
    for (final tag in tags) {
      if (tag.isNotEmpty && tag[0] == tagName && tag.length > 1) {
        return tag[1];
      }
    }
    return null;
  }
  
  /// Find all values for a specific tag type
  static List<String> _findAllTagValues(List<List<String>> tags, String tagName) {
    List<String> values = [];
    for (final tag in tags) {
      if (tag.isNotEmpty && tag[0] == tagName && tag.length > 1) {
        values.add(tag[1]);
      }
    }
    return values;
  }
}