import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';

class EventDeleteCallback extends InheritedWidget {
  final Function(Event) onDeleteCallback;

  const EventDeleteCallback({
    super.key,
    required super.child,
    required this.onDeleteCallback,
  });

  static EventDeleteCallback? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<EventDeleteCallback>();
  }

  @override
  bool updateShouldNotify(covariant EventDeleteCallback oldWidget) {
    return false;
  }

  void onDelete(Event event) {
    onDeleteCallback(event);
  }
}
