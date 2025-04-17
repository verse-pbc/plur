import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/data/join_group_parameters.dart';
import 'package:nostrmo/provider/list_provider.dart';

// Mock NostrClient to simulate responses
class MockNostrClient {
  String publicKey = 'mock_public_key';
  
  // Mock sending events
  Future<Event?> sendEvent(Event event, {List<String>? tempRelays, List<String>? targetRelays}) async {
    // Simulate successful event sending
    return event;
  }
  
  // Mock query method
  void query(
    List<Map<String, dynamic>> filters,
    Function(Event) onEvent,
    {List<String>? tempRelays, 
    RelayType? relayTypes,
    bool sendAfterAuth = true,
    Function? onComplete}
  ) {
    // Simulate response with a group members event that includes our public key
    final membersEvent = Event.fromJson({
      'id': 'members_event_id',
      'pubkey': 'admin_key',
      'created_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'kind': EventKind.groupMembers,
      'tags': [
        ['d', 'test_group_id'],
        ['p', 'mock_public_key'] // This is our public key
      ],
      'content': '',
      'sig': 'mock_signature',
    });
    
    // Call the onEvent handler with our mock event
    onEvent(membersEvent);
    
    // Call onComplete if provided
    if (onComplete != null) {
      onComplete();
    }
  }
  
  // Mock unsubscribe method (no-op for tests)
  void unsubscribe(String id) {}
}

// Test implementation of ListProvider that exposes protected methods
class TestableListProvider extends ListProvider {
  // Expose the _processJoinRequest method for testing
  Future<(GroupIdentifier, bool)> testProcessJoinRequest(JoinGroupParameters request) async {
    return _processJoinRequest(request);
  }
  
  // Expose the _verifyMembership method for testing
  Future<bool> testVerifyMembership(JoinGroupParameters request) async {
    return _verifyMembership(request);
  }
  
  // Expose the group identifiers for testing
  Set<GroupIdentifier> get testGroupIdentifiers => _groupIdentifiers;
  
  // Expose _addGroupIdentifier for testing
  void testAddGroupIdentifier(GroupIdentifier groupId) {
    _addGroupIdentifier(groupId);
  }
}

// Main test function
void main() {
  group('Group Joining Process Tests', () {
    late TestableListProvider listProvider;
    late MockNostrClient mockNostrClient;
    
    setUp(() {
      mockNostrClient = MockNostrClient();
      // Set the global nostr instance to our mock
      nostr = mockNostrClient;
      
      // Create a testable list provider
      listProvider = TestableListProvider();
    });
    
    test('Creating a join event with invite code', () {
      // Create a test join request with an invite code
      final request = JoinGroupParameters(
        'wss://test.relay',
        'test_group_id',
        code: 'test_invite_code'
      );
      
      // Create the join event using the method we want to test
      final joinEvent = listProvider._createJoinEvent(request);
      
      // Verify the event has the correct structure
      expect(joinEvent.kind, equals(EventKind.groupJoin));
      expect(joinEvent.pubkey, equals('mock_public_key'));
      
      // Verify the tags
      bool hasGroupTag = false;
      bool hasCodeTag = false;
      
      for (var tag in joinEvent.tags) {
        if (tag is List && tag.isNotEmpty) {
          if (tag[0] == 'h' && tag.length > 1 && tag[1] == 'test_group_id') {
            hasGroupTag = true;
          }
          if (tag[0] == 'code' && tag.length > 1 && tag[1] == 'test_invite_code') {
            hasCodeTag = true;
          }
        }
      }
      
      expect(hasGroupTag, isTrue, reason: 'Join event should contain an h tag with the group ID');
      expect(hasCodeTag, isTrue, reason: 'Join event should contain a code tag with the invite code');
    });
    
    test('Processing join request adds group to identifiers', () async {
      // Create a test join request
      final request = JoinGroupParameters(
        'wss://test.relay',
        'test_group_id',
        code: 'test_invite_code'
      );
      
      // Process the join request
      final result = await listProvider.testProcessJoinRequest(request);
      
      // Verify the result
      expect(result.$2, isTrue, reason: 'Join request should succeed');
      expect(result.$1.groupId, equals('test_group_id'));
      expect(result.$1.host, equals('wss://test.relay'));
    });
    
    test('Adding group identifier updates list and triggers metadata query', () {
      // Create test group ID
      final groupId = GroupIdentifier('wss://test.relay', 'test_group_id');
      
      // Verify group isn't in list yet
      expect(listProvider.testGroupIdentifiers.contains(groupId), isFalse);
      
      // Add group identifier
      listProvider.testAddGroupIdentifier(groupId);
      
      // Verify group was added
      expect(listProvider.testGroupIdentifiers.contains(groupId), isTrue);
      expect(listProvider.groupIdentifiers.length, equals(1));
      expect(listProvider.groupIdentifiers[0].groupId, equals('test_group_id'));
    });
    
    test('Group membership verification returns true for valid membership', () async {
      // Create a test join request
      final request = JoinGroupParameters(
        'wss://test.relay',
        'test_group_id',
        code: 'test_invite_code'
      );
      
      // Verify membership (using our mock NostrClient which adds our pubkey to the members)
      final isMember = await listProvider.testVerifyMembership(request);
      
      // Membership should be verified
      expect(isMember, isTrue);
    });
    
    test('Full join process adds group to identifiers', () async {
      // Create a test join request
      final request = JoinGroupParameters(
        'wss://test.relay',
        'test_group_id',
        code: 'test_invite_code'
      );
      
      // Initial state should have no groups
      expect(listProvider.groupIdentifiers.isEmpty, isTrue);
      
      // Process the join request
      final result = await listProvider.testProcessJoinRequest(request);
      expect(result.$2, isTrue);
      
      // Handle the results manually
      listProvider._handleJoinResults([result.$1], null, [request]);
      
      // Verify the group was added
      expect(listProvider.groupIdentifiers.isNotEmpty, isTrue);
      expect(listProvider.groupIdentifiers[0].groupId, equals('test_group_id'));
    });
  });
}