import 'package:flutter/foundation.dart';
import 'package:nostr_sdk/nostr_sdk.dart';

enum ListingType {
  ask,
  offer,
}

enum ListingStatus {
  active,
  inactive,
  fulfilled,
  expired,
  cancelled,
}

class ListingModel {
  final String id;
  final String pubkey;
  final String d;
  final ListingType type;
  final String title;
  final String content;
  final ListingStatus status;
  final String? groupId; // h tag for group scoping
  final DateTime? expiresAt;
  final String? location;
  final String? price;
  final List<String> imageUrls;
  final String? paymentInfo;
  final DateTime createdAt;

  const ListingModel({
    required this.id,
    required this.pubkey,
    required this.d,
    required this.type,
    required this.title,
    required this.content,
    required this.status,
    this.groupId,
    this.expiresAt,
    this.location,
    this.price,
    this.imageUrls = const [],
    this.paymentInfo,
    required this.createdAt,
  });

  // Create a ListingModel from a Nostr event
  factory ListingModel.fromEvent(Event event) {
    final tags = Map.fromEntries(event.tags.map((tag) => MapEntry(tag[0], tag[1])));
    
    return ListingModel(
      id: event.id,
      pubkey: event.pubkey,
      d: tags['d'] ?? '',
      type: tags['type'] == 'ask' ? ListingType.ask : ListingType.offer,
      title: tags['title'] ?? '',
      content: event.content,
      status: _parseStatus(tags['status']),
      groupId: tags['h'],
      expiresAt: tags['expires'] != null ? DateTime.fromMillisecondsSinceEpoch(int.parse(tags['expires']) * 1000) : null,
      location: tags['location'],
      price: tags['price'],
      imageUrls: event.tags.where((tag) => tag is List && tag.isNotEmpty && tag[0] == 'image')
                    .map((tag) => tag[1].toString()).toList(),
      paymentInfo: tags['payment'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000),
    );
  }

  // Convert ListingModel to a Nostr event
  Event toEvent() {
    final tags = [
      ['d', d],
      ['type', type == ListingType.ask ? 'ask' : 'offer'],
      ['title', title],
      ['status', status.name],
    ];

    if (groupId != null) tags.add(['h', groupId!]);
    if (expiresAt != null) tags.add(['expires', (expiresAt!.millisecondsSinceEpoch ~/ 1000).toString()]);
    if (location != null) tags.add(['location', location!]);
    if (price != null) tags.add(['price', price!]);
    if (paymentInfo != null) tags.add(['payment', paymentInfo!]);
    for (final imageUrl in imageUrls) {
      tags.add(['image', imageUrl]);
    }

    return Event(
      pubkey, 
      31111,
      tags,
      content,
      createdAt: (createdAt.millisecondsSinceEpoch ~/ 1000)
    );
  }

  static ListingStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return ListingStatus.active;
      case 'inactive':
        return ListingStatus.inactive;
      case 'fulfilled':
        return ListingStatus.fulfilled;
      case 'expired':
        return ListingStatus.expired;
      case 'cancelled':
        return ListingStatus.cancelled;
      default:
        return ListingStatus.active;
    }
  }

  // Create a copy of this ListingModel with some fields updated
  ListingModel copyWith({
    String? id,
    String? pubkey,
    String? d,
    ListingType? type,
    String? title,
    String? content,
    ListingStatus? status,
    String? groupId,
    DateTime? expiresAt,
    String? location,
    String? price,
    List<String>? imageUrls,
    String? paymentInfo,
    DateTime? createdAt,
  }) {
    return ListingModel(
      id: id ?? this.id,
      pubkey: pubkey ?? this.pubkey,
      d: d ?? this.d,
      type: type ?? this.type,
      title: title ?? this.title,
      content: content ?? this.content,
      status: status ?? this.status,
      groupId: groupId ?? this.groupId,
      expiresAt: expiresAt ?? this.expiresAt,
      location: location ?? this.location,
      price: price ?? this.price,
      imageUrls: imageUrls ?? this.imageUrls,
      paymentInfo: paymentInfo ?? this.paymentInfo,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ListingModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          pubkey == other.pubkey &&
          d == other.d &&
          type == other.type &&
          title == other.title &&
          content == other.content &&
          status == other.status &&
          groupId == other.groupId &&
          expiresAt == other.expiresAt &&
          location == other.location &&
          price == other.price &&
          listEquals(imageUrls, other.imageUrls) &&
          paymentInfo == other.paymentInfo &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      id.hashCode ^
      pubkey.hashCode ^
      d.hashCode ^
      type.hashCode ^
      title.hashCode ^
      content.hashCode ^
      status.hashCode ^
      groupId.hashCode ^
      expiresAt.hashCode ^
      location.hashCode ^
      price.hashCode ^
      imageUrls.hashCode ^
      paymentInfo.hashCode ^
      createdAt.hashCode;
} 