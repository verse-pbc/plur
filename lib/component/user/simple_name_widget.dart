import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/data/user.dart';
import 'package:nostrmo/provider/metadata_provider.dart';
import 'package:provider/provider.dart';

class SimpleNameWidget extends StatefulWidget {
  static String getSimpleName(String pubkey, User? user) {
    String? name;
    if (user != null) {
      if (StringUtil.isNotBlank(user.displayName)) {
        name = user.displayName;
      } else if (StringUtil.isNotBlank(user.name)) {
        name = user.name;
      }
    }
    if (StringUtil.isBlank(name)) {
      name = Nip19.encodeSimplePubKey(pubkey);
    }

    return name!;
  }

  String pubkey;

  User? user;

  TextStyle? textStyle;

  int? maxLines;

  TextOverflow? textOverflow;

  SimpleNameWidget({super.key, 
    required this.pubkey,
    this.user,
    this.textStyle,
    this.maxLines,
    this.textOverflow,
  });

  @override
  State<StatefulWidget> createState() {
    return _SimpleNameWidgetState();
  }
}

class _SimpleNameWidgetState extends State<SimpleNameWidget> {
  @override
  Widget build(BuildContext context) {
    if (widget.user != null) {
      return buildWidget(widget.user);
    }

    return Selector<MetadataProvider, User?>(
        builder: (context, user, child) {
      return buildWidget(user);
    }, selector: (_, provider) {
      return provider.getUser(widget.pubkey);
    });
  }

  Widget buildWidget(User? user) {
    var name = SimpleNameWidget.getSimpleName(widget.pubkey, user);
    return Text(
      name,
      style: widget.textStyle,
      maxLines: widget.maxLines,
      overflow: widget.textOverflow,
    );
  }
}
