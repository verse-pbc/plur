import 'package:flutter/material.dart';
import 'package:nostrmo/nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/consts/base.dart';

/// Tags that are used to identify the community that the post belongs to.
class CommunityTagWidget extends StatelessWidget {
  final List<dynamic> tags;

  const CommunityTagWidget({
    super.key,
    required this.tags,
  });

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();

    final themeData = Theme.of(context);
    final List<Widget> communityTags = [];

    for (var tag in tags) {
      if (tag.length > 1) {
        var tagName = tag[0];
        var tagValue = tag[1];

        if (tagName == "a") {
          var aid = AId.fromString(tagValue);
          if (aid != null && aid.kind == EventKind.COMMUNITY_DEFINITION) {
            communityTags.add(Container(
              padding: const EdgeInsets.only(
                left: Base.basePadding,
                right: Base.basePadding,
              ),
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.only(right: Base.basePadding),
                    child: Icon(
                      Icons.groups,
                      size: themeData.textTheme.bodyLarge!.fontSize,
                      color: themeData.hintColor,
                    ),
                  ),
                  Text(
                    aid.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ));
          }
        }
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: communityTags,
    );
  }
}
