import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/util/group_id_util.dart';

/// Model representing a chat message in an event discussion
class EventChatModel {
  /// Unique identifier of the chat message
  final String id;
  
  /// Public key of the message creator
  final String pubkey;
  
  /// ID of the event this chat belongs to
  final String eventId;
  
  /// Event d-tag reference value
  final String eventDTag;
  
  /// Message content
  final String content;
  
  /// Optional reference to a parent message (for replies)
  final String? replyTo;
  
  /// Group ID this event belongs to
  final String? groupId;
  
  /// Timestamp when the message was created
  final DateTime createdAt;
  
  /// Constructor
  EventChatModel({
    required this.id,
    required this.pubkey,
    required this.eventId,
    required this.eventDTag,
    required this.content,
    this.replyTo,
    this.groupId,
    required this.createdAt,
  });
  
  /// Create a copy of this message with modified fields
  EventChatModel copyWith({
    String? id,
    String? pubkey,
    String? eventId,
    String? eventDTag,
    String? content,
    String? replyTo,
    String? groupId,
    DateTime? createdAt,
  }) {
    return EventChatModel(
      id: id ?? this.id,
      pubkey: pubkey ?? this.pubkey,
      eventId: eventId ?? this.eventId,
      eventDTag: eventDTag ?? this.eventDTag,
      content: content ?? this.content,
      replyTo: replyTo ?? this.replyTo,
      groupId: groupId ?? this.groupId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
  
  /// Convert chat message to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pubkey': pubkey,
      'eventId': eventId,
      'eventDTag': eventDTag,
      'content': content,
      'replyTo': replyTo,
      'groupId': groupId,
      'createdAt': createdAt.millisecondsSinceEpoch ~/ 1000,
    };
  }
  
  /// Create chat message from JSON map
  factory EventChatModel.fromJson(Map<String, dynamic> json) {
    return EventChatModel(
      id: json['id'] as String,
      pubkey: json['pubkey'] as String,
      eventId: json['eventId'] as String,
      eventDTag: json['eventDTag'] as String,
      content: json['content'] as String,
      replyTo: json['replyTo'] as String?,
      groupId: json['groupId'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch((json['createdAt'] as int) * 1000),
    );
  }
  
  /// Create a Nostr event from this chat model for publishing to relays
  Event toEvent() {
    // Create tags for the message
    List<List<String>> tags = [];
    
    // Reference to the original event
    tags.add(['e', eventId, '', 'root']);
    
    // Event d-tag reference
    tags.add(['d', eventDTag]);
    
    // Reply to a parent message if specified
    if (replyTo != null) {
      tags.add(['e', replyTo!, '', 'reply']);
    }
    
    // Group context if provided
    if (groupId != null) {
      final standardGroupId = GroupIdUtil.standardizeGroupIdString(groupId!);
      tags.add(['h', standardGroupId]);
    }
    
    // Subject tag to identify this as an event chat message
    tags.add(['subject', 'event-chat']);
    
    // Create the Nostr event - using kind 1 for normal notes
    return Event.create(
      kind: 1, // Standard note
      pubkey: pubkey,
      content: content,
      tags: tags,
      createdAt: createdAt.millisecondsSinceEpoch ~/ 1000,
    );
  }
  
  /// Create a chat message model from a Nostr event
  factory EventChatModel.fromEvent(Event event) {
    try {
      // Ensure this is a note with proper tags
      if (event.kind != 1) {
        throw ArgumentError('Event is not a standard note (expected kind 1)');
      }
      
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
      String? eventId;
      String? eventDTag;
      String? replyTo;
      String? groupId;
      String? subject;
      
      for (final tag in typedTags) {
        if (tag.isNotEmpty) {
          switch (tag[0]) {
            case 'e':
              if (tag.length > 1) {
                if (tag.length > 3 && tag[3] == 'root') {
                  eventId = tag[1];
                } else if (tag.length > 3 && tag[3] == 'reply') {
                  replyTo = tag[1];
                } else if (eventId == null) {
                  // Default behavior if no marker is present
                  eventId = tag[1];
                }
              }
              break;
            case 'd':
              if (tag.length > 1) eventDTag = tag[1];
              break;
            case 'h':
              if (tag.length > 1) groupId = tag[1];
              break;
            case 'subject':
              if (tag.length > 1) subject = tag[1];
              break;
          }
        }
      }
      
      // Validate this is an event chat message
      if (subject != 'event-chat') {
        throw ArgumentError('Event is not an event chat message (missing subject tag)');
      }
      
      // Validate required fields
      if (eventId == null) {
        throw ArgumentError('Event chat message missing event ID (e tag with root marker)');
      }
      
      if (eventDTag == null) {
        throw ArgumentError('Event chat message missing event d-tag reference');
      }
      
      return EventChatModel(
        id: event.id,
        pubkey: event.pubkey,
        eventId: eventId,
        eventDTag: eventDTag,
        content: event.content,
        replyTo: replyTo,
        groupId: groupId,
        createdAt: DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000),
      );
    } catch (e, stack) {
      debugPrint('Error creating EventChatModel from Event: $e');
      debugPrint('Stack trace: $stack');
      rethrow;
    }
  }
}