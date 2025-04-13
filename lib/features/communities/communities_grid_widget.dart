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
    // Log that this widget is being built/displayed
    debugPrint("🔍 SCREEN DISPLAYED: CommunitiesGridWidget (Communities grid)");
    
    return GridView.builder(
      padding: const EdgeInsets.only(top: 52, bottom: 80), // Increased bottom padding
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 0.0,
        mainAxisSpacing: 40.0, // Increased to give more vertical space
        childAspectRatio: 0.9, // Adjusted to make cells taller than they are wide
      ),
      itemCount: groupIds.length,
      itemBuilder: (context, index) {
        final groupIdentifier = groupIds[index];
        return InkWell(
          onTap: () {
            RouterUtil.router(
                context, RouterPath.groupDetail, groupIdentifier);
          },
          child: CommunityWidget(groupIdentifier),
        );
      },
    );
  }
}
