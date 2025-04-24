import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/main.dart';
import 'dart:developer';

final emergencyAlertControllerProvider = Provider((ref) {
  return EmergencyAlertController(ref);
});

class EmergencyAlertController {
  final Ref _ref;

  EmergencyAlertController(this._ref);

  Future<Event> sendEmergencyAlert(
      String message, GroupIdentifier groupIdentifier) async {
    final event = Event(
      nostr!.publicKey,
      EventKind.groupNote,
      [
        ["h", groupIdentifier.groupId],
        ["broadcast"]
      ],
      message,
    );

    final groupRelays = [groupIdentifier.host];
    final sentEvent = await nostr!.sendEvent(
      event,
      targetRelays: groupRelays,
      tempRelays: groupRelays,
    );
    if (sentEvent == null) {
      throw Exception('Failed to send emergency alert');
    }
    log('Publishing emergency alert: ${sentEvent.toJson()}');
    return sentEvent;
  }
}
