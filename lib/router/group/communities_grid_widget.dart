import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';

import '../../consts/router_path.dart';
import '../../util/router_util.dart';
import 'community_widget.dart';

/// A widget that displays a grid of communities.
class CommunitiesGridWidget extends StatelessWidget {
  /// List of group identifiers to be displayed in the grid.
  final List<GroupIdentifier> groupIds;

  const CommunitiesGridWidget({super.key, required this.groupIds});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(vertical: 52),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 0.0,
        mainAxisSpacing: 32.0,
        childAspectRatio: 1,
      ),
      itemCount: groupIds.length,
      itemBuilder: (context, index) {
        final groupIdentifier = groupIds[index];
        return InkWell(
          onTap: () {
            RouterUtil.router(
                context, RouterPath.GROUP_DETAIL, groupIdentifier);
          },
          child: CommunityWidget(groupIdentifier),
        );
      },
    );
  }
}
