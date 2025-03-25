import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';

class GroupIdentifierInheritedWidget extends InheritedWidget {
  GroupIdentifier groupIdentifier;

  GroupAdmins? groupAdmins;

  GroupIdentifierInheritedWidget({
    super.key,
    required super.child,
    required this.groupIdentifier,
    this.groupAdmins,
  });

  static GroupIdentifierInheritedWidget? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<GroupIdentifierInheritedWidget>();
  }

  static GroupIdentifier? getGroupIdentifier(BuildContext context) {
    final inheritedWidget = of(context);
    return inheritedWidget?.groupIdentifier;
  }

  static GroupAdmins? getGroupAdmins(BuildContext context) {
    final inheritedWidget = of(context);
    return inheritedWidget?.groupAdmins;
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => false;
}
