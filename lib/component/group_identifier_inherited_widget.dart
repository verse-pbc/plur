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
    var inheritedWidget = of(context);
    if (inheritedWidget != null) {
      return inheritedWidget.groupIdentifier;
    }

    return null;
  }

  static GroupAdmins? getGroupAdmins(BuildContext context) {
    var inheritedWidget = of(context);
    if (inheritedWidget != null) {
      return inheritedWidget.groupAdmins;
    }

    return null;
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    return false;
  }
}
