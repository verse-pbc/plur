import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nostr_sdk/nostr_sdk.dart';

import '../../data/group_identifier_repository.dart';
import '../../data/group_repository.dart';
import '../../data/group_metadata_repository.dart';
import '../../util/string_code_generator.dart';
import 'privacy_selection_widget.dart';

typedef CreateCommunityModel = (GroupIdentifier, String);

/// A controller class that manages group creation.
///
/// This class handles the creation of a new group, saving its identifier,
/// setting its name, and generating an invite link.
class CreateCommunityController
    extends AutoDisposeAsyncNotifier<CreateCommunityModel?> {
  @override
  FutureOr<CreateCommunityModel?> build() async {
    return null;
  }

  /// Creates a new community with the specified [name] and [privacy] setting.
  ///
  /// Returns `true` if the community is successfully created, otherwise `false`.
  Future<bool> createCommunity(String name, CommunityPrivacy privacy) async {
    state = const AsyncValue<CreateCommunityModel?>.loading();
    final groupIdentifier = await _createGroup();
    if (groupIdentifier == null) {
      state = const AsyncValue.data(null);
      return false;
    }
    try {
      await _saveGroupIdentifier(groupIdentifier);
      await _setGroupMetadata(groupIdentifier, name, privacy);
      final inviteLink = await _generateInviteLink(groupIdentifier);
      state = AsyncValue<CreateCommunityModel?>.data((
        groupIdentifier,
        inviteLink,
      ));
      return true;
    } catch (exception) {
      state = const AsyncValue.data(null);
      return false;
    }
  }

  /// Creates a new group and returns its identifier.
  ///
  /// Generates a unique group ID and uses the [GroupRepository] to create
  /// the group. Returns a [GroupIdentifier] if the group is successfully
  /// created, otherwise `null`.
  Future<GroupIdentifier?> _createGroup() async {
    final groupId = StringCodeGenerator.generateGroupId();
    final repository = ref.watch(groupRepositoryProvider);
    return repository.createGroup(groupId);
  }

  /// Saves the group identifier to the repository.
  ///
  /// Adds the [groupIdentifier] to the [GroupIdentifierRepository].
  Future<void> _saveGroupIdentifier(GroupIdentifier groupIdentifier) async {
    final repository = ref.watch(groupIdentifierRepositoryProvider);
    await repository.addGroupIdentifier(groupIdentifier);
  }

  /// Sets the metadata of the group.
  ///
  /// Updates the metadata of the group identified by [groupIdentifier] with
  /// the specified [name] and [privacy] setting.
  Future<void> _setGroupMetadata(GroupIdentifier groupIdentifier, String name,
      CommunityPrivacy privacy) async {
    final groupId = groupIdentifier.groupId;
    final host = groupIdentifier.host;
    final groupMetadataProvider = groupMetadataRepositoryProvider;
    final groupMetadataRepository = ref.watch(groupMetadataProvider);
    GroupMetadata groupMetadata = GroupMetadata(
      groupId,
      0,
      name: name,
      public: privacy == CommunityPrivacy.discoverable,
      open: privacy == CommunityPrivacy.discoverable,
    );
    await groupMetadataRepository.setGroupMetadata(groupMetadata, host);
    // Add delay to give the cache enough time to update the db
    await Future.delayed(const Duration(seconds: 1));
    ref.invalidate(cachedGroupMetadataProvider(groupIdentifier));
  }

  /// Generates an invite link for the group.
  ///
  /// Creates an invite code and uses the [GroupRepository] to generate an
  /// invite link for the group identified by [groupIdentifier]. Returns the
  /// invite link as a string.
  Future<String> _generateInviteLink(GroupIdentifier groupIdentifier) async {
    final inviteCode = StringCodeGenerator.generateInviteCode();
    final groupInviteRepository = ref.watch(groupRepositoryProvider);
    return await groupInviteRepository.createInviteLink(
      groupIdentifier,
      inviteCode,
    );
  }
}

/// A provider for the `CreateCommunityController`.
///
/// This provider creates an instance of [CreateCommunityController] and
/// manages its lifecycle.
final createCommunityControllerProvider = AsyncNotifierProvider.autoDispose<
    CreateCommunityController,
    CreateCommunityModel?>(CreateCommunityController.new);
