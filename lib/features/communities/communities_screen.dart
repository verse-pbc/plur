import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nostrmo/router/group/create_community_dialog.dart';
import 'package:nostrmo/router/group/no_communities_widget.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/main.dart';
import 'dart:developer';

import '../../component/shimmer/shimmer.dart';
import '../../router/group/communities_grid_widget.dart';
import '../../util/time_util.dart';
import '../../util/theme_util.dart';
import 'communities_controller.dart';

class CommunitiesScreen extends ConsumerStatefulWidget {
  const CommunitiesScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _CommunitiesScreenState();
  }
}

class _CommunitiesScreenState extends ConsumerState<CommunitiesScreen> {
  final subscribeId = StringUtil.rndNameStr(16);

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final appBgColor = themeData.customColors.appBgColor;
    final separatorColor = themeData.customColors.separatorColor;
    final shimmerGradient = LinearGradient(
      colors: [separatorColor, appBgColor, separatorColor],
      stops: const [0.1, 0.3, 0.4],
      begin: const Alignment(-1.0, -0.3),
      end: const Alignment(1.0, 0.3),
      tileMode: TileMode.clamp,
    );
    final controller = ref.watch(communitiesControllerProvider);
    return Scaffold(
      body: controller.when(
        data: (value) {
          if (value.isEmpty) {
            return const Center(
              child: NoCommunitiesWidget(),
            );
          }
          return Shimmer(
            linearGradient: shimmerGradient,
            child: CommunitiesGridWidget(groupIds: value),
          );
        },
        error: (error, stackTrace) => Center(child: ErrorWidget(error)),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

