import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/data/user.dart';
import 'package:nostrmo/provider/user_provider.dart';
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

  final String pubkey;

  final User? user;

  final TextStyle? textStyle;

  final int? maxLines;

  final TextOverflow? textOverflow;

  const SimpleNameWidget({super.key,
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
  void initState() {
    super.initState();
    // If we're not given a user, try to fetch one from reliable relays
    // but use microtask to avoid modifying providers during build
    if (widget.user == null) {
      Future.microtask(() {
        if (mounted) {
          final provider = Provider.of<UserProvider>(context, listen: false);
          provider.fetchUserProfileFromReliableRelays(widget.pubkey);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.user != null) {
      return buildWidget(widget.user);
    }

    return Selector<UserProvider, User?>(
        builder: (context, user, child) {
      return buildWidget(user);
    }, selector: (_, provider) {
      // This will not update the provider, just access its data
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
