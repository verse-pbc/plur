import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/group_metadata_repository.dart';

class CommunityGuidelinesScreenController
    extends StateNotifier<AsyncValue<void>> {
  final GroupMetadataRepository repository;
  CommunityGuidelinesScreenController({required this.repository})
      : super(const AsyncValue<void>.data(null));

  Future<void> save() async {
    state = const AsyncValue<void>.loading();
  }
}
