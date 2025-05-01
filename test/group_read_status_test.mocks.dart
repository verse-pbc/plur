// Mock generated manually due to build_runner issues
import 'dart:async';

import 'package:mockito/mockito.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/data/group_read_info_db.dart';
import 'package:nostrmo/provider/list_provider.dart';

// Mock classes
class MockListProvider extends Mock implements ListProvider {
  @override
  List<GroupIdentifier> get groupIdentifiers => super.noSuchMethod(
        Invocation.getter(#groupIdentifiers),
        returnValue: <GroupIdentifier>[],
        returnValueForMissingStub: <GroupIdentifier>[],
      );
}

class MockGroupReadInfoDB extends Mock implements GroupReadInfoDB {}