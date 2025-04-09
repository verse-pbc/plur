import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/group_identifier_provider.dart';

/// A controller class that manages the group of communities.
class CommunitiesController extends StreamNotifier<GroupIdentifiers> {
  /// Fetches the list of current group identifiers.
  ///
  /// This function retrieves group identifiers from the repository and
  /// returns them.
  ///
  /// - Returns: A `Future` that resolves to the group identifiers list.
  Stream<GroupIdentifiers> _watchGroupIdentifiers() {
    final repository = ref.watch(groupIdentifierRepositoryProvider);
    return repository.watchGroupIdentifierList();
  }

  @override
  Stream<GroupIdentifiers> build() => _watchGroupIdentifiers();
}

// A provider that supplies an instance of `CommunityGuidelinesController`
/// for a given group identifier.
final communitiesControllerProvider =
    StreamNotifierProvider<CommunitiesController, GroupIdentifiers>(
  CommunitiesController.new,
);
