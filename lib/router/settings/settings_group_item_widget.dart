import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';

import '../../consts/base.dart';

class SettingsGroupItemWidget extends StatelessWidget {
  final String name;

  final Color? nameColor;

  final String? value;

  final Widget? child;

  final Function? onTap;

  const SettingsGroupItemWidget({super.key,
    required this.name,
    this.nameColor,
    this.value,
    this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    var hintColor = themeData.hintColor;
    var cardColor = themeData.cardColor;
    var fontSize = themeData.textTheme.bodyMedium!.fontSize;

    final Widget resolvedChild;
    if (child != null) {
      resolvedChild = child!;
    } else if (StringUtil.isNotBlank(value)) {
      resolvedChild = Text(
        value!,
        style: TextStyle(
          color: hintColor,
          fontWeight: FontWeight.bold,
          fontSize: fontSize,
        ),
      );
    } else {
      resolvedChild = Container();
    }

    Widget nameWidget = Text(
      name,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: fontSize,
        color: nameColor,
      ),
    );

    return SliverToBoxAdapter(
      child: Container(
        color: cardColor,
        padding: const EdgeInsets.only(
          top: 12,
          left: 20 + Base.basePaddingHalf,
          right: 20 + Base.basePaddingHalf,
        ),
        child: GestureDetector(
          onTap: () {
            if (onTap != null) {
              onTap!();
            }
          },
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              nameWidget,
              Expanded(
                child: Container(),
              ),
              resolvedChild,
            ],
          ),
        ),
      ),
    );
  }
}
