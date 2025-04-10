import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nostr_sdk/nostr_sdk.dart';

import '../../data/group_metadata_repository.dart';

/// A controller class that manages the group metadata for a given community.
class CommunityController
    extends AutoDisposeFamilyAsyncNotifier<GroupMetadata?, GroupIdentifier> {
  /// Fetches the group metadata from the cache.
  ///
  /// - Returns: A `Future` that resolves to the group metadata.
  Future<GroupMetadata?> _fetchGroupMetadata(GroupIdentifier id) {
    final repository = ref.watch(groupMetadataRepositoryProvider);
    return repository.fetchGroupMetadata(id, cached: true);
  }

  @override
  Future<GroupMetadata?> build(GroupIdentifier arg) => _fetchGroupMetadata(arg);
}

// A provider that supplies an instance of `CommunityController`
/// for a given group identifier.
final communityControllerProvider = AsyncNotifierProvider.autoDispose
    .family<CommunityController, GroupMetadata?, GroupIdentifier>(
        CommunityController.new);
