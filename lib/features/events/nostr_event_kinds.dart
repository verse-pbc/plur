import 'package:nostr_sdk/nostr_sdk.dart';

/// Extension to add calendar-related event kinds to the Nostr SDK's EventKind enum
extension EventKindExtension on EventKind {
  /// Date-bounded event (NIP-52) - Kind 31922
  static const int dateBoundedEvent = 31922;
  
  /// Time-bounded event (NIP-52) - Kind 31923
  static const int timeBoundedEvent = 31923;
  
  /// Event RSVP (NIP-52) - Kind 31925
  static const int eventRSVP = 31925;
  
  /// Regular note (NIP-01) - Kind 1
  /// Used for event chat messages with subject tag "event-chat"
  static const int standardNote = 1;
}