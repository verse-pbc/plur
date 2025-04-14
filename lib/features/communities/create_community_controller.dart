import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nostr_sdk/nostr_sdk.dart';

import '../../data/group_identifier_repository.dart';
import '../../data/group_invite_repository.dart';
import '../../data/group_metadata_repository.dart';
import '../../util/string_code_generator.dart';

typedef AddGroupModel = (GroupIdentifier, String);

/// A controller class that manages the community guidelines for a group.
class AddGroupController extends AutoDisposeAsyncNotifier<AddGroupModel?> {
  @override
  FutureOr<AddGroupModel?> build() async {
    return null;
  }

  Future<bool> createCommunity(String name) async {
    state = const AsyncValue<AddGroupModel?>.loading();
    final groupIdentifier = await _createGroupIdentifier();
    if (groupIdentifier == null) {
      state = const AsyncValue.data(null);
      return false;
    } 
    await _setGroupName(groupIdentifier, name);
    final inviteLink = await _generateInviteLink(groupIdentifier); 
    state = AsyncValue<AddGroupModel?>.data((groupIdentifier, inviteLink));
    return true;
  }

  Future<GroupIdentifier?> _createGroupIdentifier() async {
    final groupId = StringCodeGenerator.generateGroupId();
    final repository = ref.watch(groupIdentifierRepositoryProvider);
    return await repository.createGroupIdentifier(groupId);
  }

  _setGroupName(GroupIdentifier groupIdentifier, String name) async {
    final groupId = groupIdentifier.groupId;
    final host = groupIdentifier.host;
    final groupMetadataProvider = groupMetadataRepositoryProvider;
    final groupMetadataRepository = ref.watch(groupMetadataProvider);
    GroupMetadata groupMetadata = GroupMetadata(groupId, 0, name: name);
    await groupMetadataRepository.setGroupMetadata(groupMetadata, host);
  }

  Future<String> _generateInviteLink(GroupIdentifier groupIdentifier) async {
    // Generate an invite code
    final inviteCode = StringCodeGenerator.generateInviteCode();
    final groupInviteRepository = ref.watch(groupInviteRepositoryProvider);
    return await groupInviteRepository.createInviteLink(
      groupIdentifier,
      inviteCode,
    );
  }
}

final addGroupControllerProvider =
    AsyncNotifierProvider.autoDispose<AddGroupController, AddGroupModel?>(
        AddGroupController.new);
