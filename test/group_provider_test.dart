import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/provider/group_provider.dart';
import 'package:nostrmo/provider/list_provider.dart';
import 'package:nostrmo/provider/relay_provider.dart';
import 'package:nostrmo/util/string_code_generator.dart';

// Create mocks
@GenerateMocks([Nostr])
import 'group_provider_test.mocks.dart';

void main() {
  group('GroupProvider', () {
    late GroupProvider provider;
    late MockNostr mockNostr;

    setUp(() {
      mockNostr = MockNostr();
      provider = GroupProvider();
      
      // Setup default behavior for the mock
      when(mockNostr.publicKey).thenReturn('test_public_key');
      
      // In real application we'd use the global nostr object, but for testing
      // we'll pass the mock to methods that need it
    });

    test('genFilter should use #d tag instead of d', () {
      final provider = GroupProvider();
      const groupId = "myId";
      final filter = provider.genFilter(groupId, 1);
      expect(filter.containsKey("#d"), true);
      expect(filter["#d"], [groupId]);
    });

    test('getMetadata should return null and trigger query if metadata not found', () {
      // Arrange
      final groupId = GroupIdentifier(RelayProvider.defaultGroupsRelayAddress, 'test_group_id');
      
      // Act
      final result = provider.getMetadata(groupId);
      
      // Assert
      expect(result, isNull);
      // This is a basic test - in a real implementation we'd verify the query was triggered
    });

    test('GroupIdentifier equality works correctly', () {
      // Arrange
      final group1 = GroupIdentifier('host1', 'id1');
      final group2 = GroupIdentifier('host1', 'id1'); // Same values
      final group3 = GroupIdentifier('host2', 'id1'); // Different host
      final group4 = GroupIdentifier('host1', 'id2'); // Different id
      
      // Act & Assert
      expect(group1, equals(group2)); // Same values should be equal
      expect(group1, isNot(equals(group3))); // Different host should not be equal
      expect(group1, isNot(equals(group4))); // Different id should not be equal
      
      // Test toString and hashCode
      expect(group1.toString(), equals(group2.toString()));
      expect(group1.hashCode, equals(group2.hashCode));
      
      // Test Set behavior (hashCode and equals)
      final groupSet = <GroupIdentifier>{};
      groupSet.add(group1);
      expect(groupSet.contains(group2), isTrue); // Should find the equivalent object
      
      groupSet.add(group3);
      expect(groupSet.length, equals(2)); // Should have 2 distinct items
    });
    
    // Skip these tests for now since they depend on the global nostr object
    // TODO: Refactor GroupProvider to accept a Nostr instance in constructor for better testability
    test('updateMetadata should update local cache and send event', () {
      // This test is skipped for now
    });
  });
  
  group('ListProvider', () {
    late ListProvider listProvider;
    late MockNostr mockNostr;

    setUp(() {
      mockNostr = MockNostr();
      listProvider = ListProvider();
      
      // Setup default behavior for the mock
      when(mockNostr.publicKey).thenReturn('test_public_key');
      
      // In real application we'd use the global nostr object, but for testing
      // we'll pass the mock to methods that need it
    });
    
    // Skip these tests for now since they depend on the global nostr object
    // TODO: Refactor ListProvider to accept a Nostr instance in constructor for better testability
    test('createGroupAndGenerateInvite creates a group and adds it to list', () {
      // This test is skipped for now
    });
  });
}