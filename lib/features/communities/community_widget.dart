import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nostr_sdk/nostr_sdk.dart';

import '../../component/shimmer/shimmer_loading.dart';
import 'community_controller.dart';
import 'community_title_widget.dart';
import 'community_image_widget.dart';

class CommunityWidget extends ConsumerWidget {
  final GroupIdentifier groupIdentifier;

  const CommunityWidget(this.groupIdentifier, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupId = groupIdentifier.groupId;
    final controller = ref.watch(communityControllerProvider(groupIdentifier));
    const imageSize = CommunityImageWidget.imageSize;
    return controller.when(
      data: (value) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CommunityImageWidget(groupId, value),
            const SizedBox(height: 12),
            SizedBox(
              width: imageSize,
              child: SizedBox(
                height: 60,
                child: ShimmerLoading(
                  isLoading: false,
                  child: CommunityTitleWidget(groupId, value),
                ),
              ),
            ),
          ],
        );
      },
      loading: () {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CommunityImageWidget(groupId, null),
            const SizedBox(height: 12),
            SizedBox(
              width: imageSize,
              child: SizedBox(
                height: 60,
                child: ShimmerLoading(
                  isLoading: true,
                  child: CommunityTitleWidget(groupId, null),
                ),
              ),
            ),
          ],
        );
      },
      error: (error, stackTrace) => Center(child: ErrorWidget(error)),
    );
  }
}
