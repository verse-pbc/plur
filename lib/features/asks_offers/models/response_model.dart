import 'package:nostr_sdk/nostr_sdk.dart';

enum ResponseType {
  interest,
  help,
  question,
  offer
}

enum ResponseStatus {
  pending,
  accepted,
  declined,
  withdrawn
}

class ResponseModel {
  final String id;
  final String pubkey;
  final String d;
  final String listingEventId;
  final String listingPubkey;
  final String listingD;
  final ResponseType responseType;
  final ResponseStatus status;
  final String content;
  final DateTime createdAt;
  final String? price;
  final String? availability;
  final String? location;
  final String? paymentInfo;

  const ResponseModel({
    required this.id,
    required this.pubkey,
    required this.d,
    required this.listingEventId,
    required this.listingPubkey,
    required this.listingD,
    required this.responseType,
    required this.status,
    required this.content,
    required this.createdAt,
    this.price,
    this.availability,
    this.location,
    this.paymentInfo,
  });

  // Create a ResponseModel from a Nostr event
  factory ResponseModel.fromEvent(Event event) {
    final tags = Map.fromEntries(event.tags.map((tag) => MapEntry(tag[0], tag[1])));
    
    return ResponseModel(
      id: event.id,
      pubkey: event.pubkey,
      d: tags['d'] ?? '',
      listingEventId: tags['e'] ?? '',
      listingPubkey: tags['p'] ?? '',
      listingD: tags['listing_d'] ?? '',
      responseType: _parseResponseType(tags['response_type']),
      status: _parseStatus(tags['status']),
      content: event.content,
      createdAt: DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000),
      price: tags['price'],
      availability: tags['availability'],
      location: tags['location'],
      paymentInfo: tags['payment'],
    );
  }

  // Convert ResponseModel to a Nostr event
  Event toEvent() {
    final tags = [
      ['d', d],
      ['e', listingEventId],
      ['p', listingPubkey],
      ['listing_d', listingD],
      ['response_type', responseType.name],
      ['status', status.name],
    ];

    if (price != null) tags.add(['price', price!]);
    if (availability != null) tags.add(['availability', availability!]);
    if (location != null) tags.add(['location', location!]);
    if (paymentInfo != null) tags.add(['payment', paymentInfo!]);

    return Event(
      pubkey, 
      31112, // Response event kind
      tags,
      content,
      createdAt: (createdAt.millisecondsSinceEpoch ~/ 1000)
    );
  }

  static ResponseType _parseResponseType(String? type) {
    switch (type?.toLowerCase()) {
      case 'interest':
        return ResponseType.interest;
      case 'help':
        return ResponseType.help;
      case 'question':
        return ResponseType.question;
      case 'offer':
        return ResponseType.offer;
      default:
        return ResponseType.interest;
    }
  }

  static ResponseStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return ResponseStatus.pending;
      case 'accepted':
        return ResponseStatus.accepted;
      case 'declined':
        return ResponseStatus.declined;
      case 'withdrawn':
        return ResponseStatus.withdrawn;
      default:
        return ResponseStatus.pending;
    }
  }

  // Create a copy of this ResponseModel with some fields updated
  ResponseModel copyWith({
    String? id,
    String? pubkey,
    String? d,
    String? listingEventId,
    String? listingPubkey,
    String? listingD,
    ResponseType? responseType,
    ResponseStatus? status,
    String? content,
    DateTime? createdAt,
    String? price,
    String? availability,
    String? location,
    String? paymentInfo,
  }) {
    return ResponseModel(
      id: id ?? this.id,
      pubkey: pubkey ?? this.pubkey,
      d: d ?? this.d,
      listingEventId: listingEventId ?? this.listingEventId,
      listingPubkey: listingPubkey ?? this.listingPubkey, 
      listingD: listingD ?? this.listingD,
      responseType: responseType ?? this.responseType,
      status: status ?? this.status,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      price: price ?? this.price,
      availability: availability ?? this.availability,
      location: location ?? this.location,
      paymentInfo: paymentInfo ?? this.paymentInfo,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResponseModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          pubkey == other.pubkey &&
          d == other.d &&
          listingEventId == other.listingEventId &&
          listingPubkey == other.listingPubkey &&
          listingD == other.listingD &&
          responseType == other.responseType &&
          status == other.status &&
          content == other.content &&
          createdAt == other.createdAt &&
          price == other.price &&
          availability == other.availability &&
          location == other.location &&
          paymentInfo == other.paymentInfo;

  @override
  int get hashCode =>
      id.hashCode ^
      pubkey.hashCode ^
      d.hashCode ^
      listingEventId.hashCode ^
      listingPubkey.hashCode ^
      listingD.hashCode ^
      responseType.hashCode ^
      status.hashCode ^
      content.hashCode ^
      createdAt.hashCode ^
      price.hashCode ^
      availability.hashCode ^
      location.hashCode ^
      paymentInfo.hashCode;
}