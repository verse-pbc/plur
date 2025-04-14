import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nostr_sdk/nostr_sdk.dart';

import '../../data/group_metadata_repository.dart';
import '../data/group_identifier_repository.dart';
import '../util/string_code_generator.dart';

typedef AddGroupModel = (GroupIdentifier, String);

/// A controller class that manages the community guidelines for a group.
class AddGroupController extends AutoDisposeAsyncNotifier<AddGroupModel?> {
  @override
  FutureOr<AddGroupModel?> build() async {
    return null;
  }

  Future<bool> createCommunity(String name) async {
    state = const AsyncValue<AddGroupModel?>.loading();
    final repository = ref.watch(groupIdentifierRepositoryProvider);
    final result = await repository.createCommunity();
    if (result != null) {
      final groupMetadataProvider = groupMetadataRepositoryProvider;
      final groupMetadataRepository = ref.watch(groupMetadataProvider);
      GroupMetadata groupMetadata = GroupMetadata(
        result.groupId,
        0,
        name: name,
      );
      final didEdit = await groupMetadataRepository.setGroupMetadata(groupMetadata, result.host);
      
      // Generate an invite code
      final inviteCode = StringCodeGenerator.generateInviteCode();
      inviteLink = createInviteLink(result.groupId, inviteCode);
    }
    String? inviteLink;
    
      
    // final listProvider = Provider.of<ListProvider>(context, listen: false);
    // final groupDetails =
    //     await listProvider.createGroupAndGenerateInvite(communityName);

    // setState(() {
    //   _communityInviteLink = groupDetails.$1;
    //   _groupIdentifier = groupDetails.$2;
    //   _showInviteCommunity = true;
    // });
    return false;
  }
}

final addGroupControllerProvider =
    AsyncNotifierProvider.autoDispose<AddGroupController, AddGroupModel?>(
        AddGroupController.new);
