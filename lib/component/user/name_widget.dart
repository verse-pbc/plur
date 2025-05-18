import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/component/nip05_valid_widget.dart';
import 'package:nostrmo/data/user.dart';

class NameWidget extends StatefulWidget {
  final String pubkey;

  final User? user;

  final bool showNip05;

  final double? fontSize;

  final Color? fontColor;

  final FontWeight? fontWeight;

  final TextOverflow? textOverflow;

  final int? maxLines;

  final bool showName;

  const NameWidget({
    super.key,
    required this.pubkey,
    this.user,
    this.showNip05 = true,
    this.fontSize,
    this.fontColor,
    this.fontWeight,
    this.textOverflow,
    this.maxLines = 3,
    this.showName = true,
  });
  
  /// Gets a simple display name for a user
  /// If user has a displayName, use that
  /// If not, try using user.name
  /// If neither exists, use the nip19 encoded pubkey
  static String getSimpleName(String pubkey, User? user) {
    if (user != null) {
      if (StringUtil.isNotBlank(user.displayName)) {
        return user.displayName!;
      } else if (StringUtil.isNotBlank(user.name)) {
        return user.name!;
      }
    }
    
    // Fall back to nip19 encoded pubkey
    return Nip19.encodeSimplePubKey(pubkey);
  }

  @override
  State<StatefulWidget> createState() {
    return _NameWidgetState();
  }
}

class _NameWidgetState extends State<NameWidget> {
  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    var textSize = themeData.textTheme.bodyMedium!.fontSize;
    var smallTextSize = themeData.textTheme.bodySmall!.fontSize;
    Color hintColor = themeData.hintColor;
    var user = widget.user;
    String nip19Name = Nip19.encodeSimplePubKey(widget.pubkey);
    String displayName = "";
    String name = "";
    if (widget.fontColor != null) {
      hintColor = widget.fontColor!;
    }

    if (user != null) {
      if (StringUtil.isNotBlank(user.displayName)) {
        displayName = user.displayName!;
        if (StringUtil.isNotBlank(user.name)) {
          name = user.name!;
        }
      } else if (StringUtil.isNotBlank(user.name)) {
        displayName = user.name!;
      }
    }

    List<InlineSpan> nameList = [];

    if (StringUtil.isBlank(displayName)) {
      displayName = nip19Name;
    }
    nameList.add(TextSpan(
      text: StringUtil.breakWord(displayName),
      style: TextStyle(
        fontFamily: 'SF Pro Rounded',
        fontWeight: widget.fontWeight ?? FontWeight.bold,
        fontSize: widget.fontSize ?? textSize,
        color: widget.fontColor,
      ),
    ));
    if (StringUtil.isNotBlank(name) && widget.showName) {
      nameList.add(WidgetSpan(
        child: Container(
          margin: const EdgeInsets.only(left: 2),
          child: Text(
            StringUtil.breakWord("@$name"),
            style: TextStyle(
              fontFamily: 'SF Pro Rounded',
              fontSize: smallTextSize,
              color: hintColor,
            ),
          ),
        ),
      ));
    }

    if (widget.showNip05) {
      var nip05Widget = Container(
        margin: const EdgeInsets.only(left: 3),
        child: Nip05ValidWidget(pubkey: widget.pubkey),
      );

      nameList.add(WidgetSpan(child: nip05Widget));
    }

    return Text.rich(
      TextSpan(children: nameList),
      maxLines: widget.maxLines,
      overflow: widget.textOverflow,
    );
  }
}
