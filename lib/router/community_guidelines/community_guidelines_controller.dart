import 'dart:async';
import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nostr_sdk/nostr_sdk.dart';

import '../../data/group_metadata_repository.dart';

/// A controller class that manages the community guidelines for a group.
class CommunityGuidelinesController
    extends AutoDisposeFamilyAsyncNotifier<String, GroupIdentifier> {
  /// Fetches the community guidelines for a given group identifier.
  ///
  /// This function retrieves the group metadata from the repository and
  /// returns the community guidelines. If no guidelines are found, an empty
  /// string is returned.
  ///
  /// - Parameters:
  ///   - id: The identifier of the group for which community guidelines are
  ///   to be fetched.
  /// - Returns: A `Future` that resolves to the community guidelines of the
  /// specified group.
  Future<String> _fetchCommunityGuidelines(GroupIdentifier id) async {
    final repository = ref.watch(groupMetadataRepositoryProvider);
    final groupMetadata = await repository.fetchGroupMetadata(id);
    return groupMetadata?.communityGuidelines ?? "";
  }

  @override
  FutureOr<String> build(GroupIdentifier arg) async {
    return _fetchCommunityGuidelines(arg);
  }

  /// Saves the community guidelines for a group.
  ///
  /// This function updates the community guidelines of the specified group
  /// in the repository. If the new guidelines are the same as the current
  /// ones, the function returns `true` immediately. Otherwise, it updates
  /// the state and saves the new guidelines.
  ///
  /// - Parameters:
  ///   - communityGuidelines: The new community guidelines to be saved.
  /// - Returns: A `Future` that resolves to `true` if the guidelines were
  /// successfully saved, otherwise `false`.
  Future<bool> save(String communityGuidelines) async {
    GroupIdentifier id = arg;
    if (state.hasValue && state.value == communityGuidelines) {
      return true;
    }
    final repository = ref.watch(groupMetadataRepositoryProvider);
    state = AsyncValue<String>.loading();
    var metadata = await repository.fetchGroupMetadata(id);
    if (metadata == null) {
      state = AsyncValue<String>.data(state.value ?? "");
      return false;
    }
    metadata.communityGuidelines = communityGuidelines;
    final result = await repository.setGroupMetadata(metadata, id.host);
    if (result) {
      state = AsyncValue<String>.data(communityGuidelines);
    } else {
      state = AsyncValue<String>.data(state.value ?? "");
    }
    return result;
  }
}

/// A provider that supplies an instance of `CommunityGuidelinesController`
/// for a given group identifier.
final communityGuidelinesControllerProvider = AsyncNotifierProvider.autoDispose
    .family<CommunityGuidelinesController, String, GroupIdentifier>(
        CommunityGuidelinesController.new);
