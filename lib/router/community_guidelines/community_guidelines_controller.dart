import 'dart:async';
import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nostr_sdk/nostr_sdk.dart';

import '../../data/group_metadata_repository.dart';

class CommunityGuidelinesController
    extends AutoDisposeFamilyAsyncNotifier<String, GroupIdentifier> {
  Future<String> _fetchCommunityGuidelines(GroupIdentifier id) async {
    final repository = ref.watch(groupMetadataRepositoryProvider);
    final groupMetadata = await repository.fetchGroupMetadata(id);
    return groupMetadata?.communityGuidelines ?? "";
  }

  @override
  FutureOr<String> build(GroupIdentifier arg) async {
    return _fetchCommunityGuidelines(arg);
  }

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

final communityGuidelinesControllerProvider = AsyncNotifierProvider.autoDispose
    .family<CommunityGuidelinesController, String, GroupIdentifier>(
        CommunityGuidelinesController.new);
