import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';

/// Displays the title of a community with an appropiate fallback mechanism.
class CommunityTitleWidget extends StatelessWidget {
  /// Identifier to show when there is no name inside [metadata].
  final String identifier;

  /// Metadata of the community being displayed.
  final GroupMetadata? metadata;

  const CommunityTitleWidget(this.identifier, this.metadata, {super.key});

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    if (metadata == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ],
      );
    } else {
      return Text(
        metadata!.name ?? identifier,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: themeData.textTheme.bodyMedium!.color,
        ),
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        maxLines: 2,
      );
    }
  }
}
