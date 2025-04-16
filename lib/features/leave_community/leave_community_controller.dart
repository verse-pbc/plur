import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nostr_sdk/nostr_sdk.dart';

import '../../data/group_identifier_repository.dart';
import '../../data/group_repository.dart';

/// A controller class that manages leaving a community.
class LeaveCommunityController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    return null;
  }

  /// Leaves the specified community.
  ///
  /// Removes the group from the repository and updates the state.
  /// Returns `true` if the operation succeeds, otherwise `false`.
  Future<bool> leaveCommunity(GroupIdentifier groupIdentifier) async {
    state = const AsyncValue.loading();
    try {
      final groupRepository = ref.watch(groupRepositoryProvider);
      final groupIdentifierRepository = ref.watch(groupIdentifierRepositoryProvider);

      await groupRepository.leaveGroup(groupIdentifier);
      await groupIdentifierRepository.removeGroupIdentifier(groupIdentifier);

      state = const AsyncValue.data(null);
      return true;
    } catch (exception, stackTrace) {
      state = AsyncValue.error(exception, stackTrace);
      return false;
    }
  }
}

/// A provider for the `LeaveCommunityController`.
final leaveCommunityControllerProvider =
    AutoDisposeAsyncNotifierProvider<LeaveCommunityController, void>(
        LeaveCommunityController.new);
