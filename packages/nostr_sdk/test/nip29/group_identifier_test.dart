import 'package:flutter_test/flutter_test.dart';
import 'package:nostr_sdk/nip29/group_identifier.dart';

void main() {
  group('GroupIdentifier', () {
    test('parses group ID with host and group ID', () {
      final id = GroupIdentifier.parse("wss://communities.nos.social'8237");
      expect(id?.host, equals("wss://communities.nos.social"));
      expect(id?.groupId, equals("8237"));
    });

    test('group ID without host fails to parse', () {
      final id = GroupIdentifier.parse("8971424ALK:A&*^");
      expect(id, isNull);
    });
  });
} 