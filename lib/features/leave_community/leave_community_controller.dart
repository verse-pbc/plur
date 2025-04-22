import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nostr_sdk/nostr_sdk.dart';

import '../../data/group_identifier_repository.dart';
import '../../data/group_repository.dart';

/// A controller class that manages leaving a community.
class LeaveCommunityController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {
    return;
  }

  /// Leaves the specified community.
  ///
  /// Removes the group from the repository and updates the state.
  /// Returns `true` if the operation succeeds, otherwise `false`.
  Future<bool> leaveCommunity(GroupIdentifier groupIdentifier) async {
    state = const AsyncValue.loading();

    var success = false;

    state = await AsyncValue.guard(() async {
      final groupRepository = ref.read(groupRepositoryProvider);
      final groupIdentifierRepository = ref.read(groupIdentifierRepositoryProvider);
      await groupRepository.leaveGroup(groupIdentifier);
      await groupIdentifierRepository.removeGroupIdentifier(groupIdentifier);

      success = true;
    });

    return success;
  }
}

/// A provider for the `LeaveCommunityController`.
final leaveCommunityControllerProvider =
    AutoDisposeAsyncNotifierProvider<LeaveCommunityController, void>(
        LeaveCommunityController.new);
