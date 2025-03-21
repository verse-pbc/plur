import 'package:flutter_test/flutter_test.dart';
import 'package:nostrmo/provider/group_provider.dart';

void main() {
  test('genFilter should use #d tag instead of d', () {
    final provider = GroupProvider();
    const groupId = "myId";
    final filter = provider.genFilter(groupId, 1);
    expect(filter.containsKey("#d"), true);
    expect(filter["#d"], [groupId]);
  });
}
