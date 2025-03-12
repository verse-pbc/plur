import 'package:flutter/material.dart';
import 'package:nostrmo/nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/provider/badge_definition_provider.dart';
import 'package:nostrmo/provider/badge_provider.dart';
import 'package:provider/provider.dart';

import '../generated/l10n.dart';
import 'badge_detail_widget.dart';

class BadgeAwardWidget extends StatefulWidget {
  Event event;

  BadgeAwardWidget({
    super.key,
    required this.event,
  });

  @override
  State<StatefulWidget> createState() {
    return _BadgeAwardWidgetState();
  }
}

class _BadgeAwardWidgetState extends State<BadgeAwardWidget> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    final localization = S.of(context);
    var badgeId = "";
    for (var tag in widget.event.tags) {
      if (tag is List && tag[0] == "a") {
        badgeId = tag[1];
      }
    }

    if (badgeId == "") {
      return Container();
    }

    var badgeDetailComp = Selector<BadgeDefinitionProvider, BadgeDefinition?>(
        builder: (context, badgeDefinition, child) {
      if (badgeDefinition == null) {
        return Container();
      }

      return BadgeDetailWidget(
        badgeDefinition: badgeDefinition,
      );
    }, selector: (_, provider) {
      return provider.get(badgeId, widget.event.pubkey);
    });

    List<Widget> list = [badgeDetailComp];

    var wearComp = Selector<BadgeProvider, bool>(
      builder: ((context, exist, child) {
        if (exist) {
          return Container();
        }

        return GestureDetector(
          onTap: () {
            String? source;
            if (widget.event.sources.isNotEmpty) {
              source = widget.event.sources[0];
            }
            badgeProvider.wear(badgeId, widget.event.id, relayAddr: source);
          },
          child: Container(
            margin: const EdgeInsets.only(top: Base.BASE_PADDING_HALF),
            padding: const EdgeInsets.only(
              left: Base.basePadding,
              right: Base.basePadding,
            ),
            color: theme.primaryColor,
            width: double.infinity,
            height: 40,
            alignment: Alignment.center,
            child: Text(
              localization.Wear,
              style: const TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        );
      }),
      selector: ((context, badgeProvider) {
        return badgeProvider.containBadge(badgeId);
      }),
    );
    list.add(wearComp);

    return Container(
      padding: const EdgeInsets.only(
        top: Base.BASE_PADDING_HALF,
        left: Base.basePadding,
        right: Base.basePadding,
        bottom: Base.basePadding,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: list,
      ),
    );
  }
}
