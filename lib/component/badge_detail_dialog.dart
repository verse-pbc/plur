import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/util/table_mode_util.dart';

import '../consts/base.dart';
import '../util/router_util.dart';
import '../util/theme_util.dart';
import 'badge_detail_widget.dart';

class BadgeDetailDialog extends StatefulWidget {
  final BadgeDefinition badgeDefinition;

  const BadgeDetailDialog({
    super.key,
    required this.badgeDefinition,
  });

  static Future<bool?> show(
      BuildContext context, BadgeDefinition badgeDefinition) async {
    return await showDialog<bool>(
      context: context,
      useRootNavigator: false,
      builder: (_) {
        return BadgeDetailDialog(
          badgeDefinition: badgeDefinition,
        );
      },
    );
  }

  @override
  State<StatefulWidget> createState() {
    return _BadgeDetailDialog();
  }
}

class _BadgeDetailDialog extends State<BadgeDetailDialog> {
  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);

    Widget main = BadgeDetailWidget(
      badgeDefinition: widget.badgeDefinition,
    );
    if (PlatformUtil.isPC() || TableModeUtil.isTableMode()) {
      main = SizedBox(
        width: mediaDataCache.size.width / 2,
        child: main,
      );
    }

    return Scaffold(
      backgroundColor: ThemeUtil.getDialogCoverColor(themeData),
      body: FocusScope(
        // autofocus: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            RouterUtil.back(context);
          },
          child: Container(
            width: double.infinity,
            height: double.infinity,
            padding: const EdgeInsets.only(
              left: Base.basePadding,
              right: Base.basePadding,
            ),
            alignment: Alignment.center,
            child: GestureDetector(
              onTap: () {},
              child: main,
            ),
          ),
        ),
      ),
    );
  }
}
