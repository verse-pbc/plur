import 'dart:async';

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

}

final communityGuidelinesControllerProvider = AsyncNotifierProvider.autoDispose
    .family<CommunityGuidelinesController, String, GroupIdentifier>(
        CommunityGuidelinesController.new);
