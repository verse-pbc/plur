import 'package:nostr_sdk/nostr_sdk.dart';

// A class to hold public group information
class PublicGroupInfo {
  final GroupIdentifier identifier;
  final String name;
  final String? about;
  final String? picture;
  final int memberCount;
  final DateTime lastActive;
  
  PublicGroupInfo({
    required this.identifier,
    required this.name,
    this.about,
    this.picture,
    required this.memberCount,
    required this.lastActive,
  });
}