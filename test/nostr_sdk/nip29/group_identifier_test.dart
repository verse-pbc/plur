import 'package:flutter_test/flutter_test.dart';
import '../../../lib/nostr_sdk/nip29/group_identifier.dart';

void main() {
  group('GroupIdentifier', () {
    test('parses group ID with host and group ID', () {
      final id = GroupIdentifier.parse("wss://communities.nos.social'8237");
      expect(id?.host, equals("wss://communities.nos.social"));
      expect(id?.groupId, equals("8237"));
    });

    test('parses group ID without host', () {
      final id = GroupIdentifier.parse("8971424ALK:A&*^");
      expect(id?.host, "");
      expect(id?.groupId, equals("8971424ALK:A&*^"));
    });

    test('parses group ID with single quote', () {
      final id = GroupIdentifier.parse("1'2");
      expect(id?.host, equals("1"));
      expect(id?.groupId, equals("2"));
    });
  });
} 