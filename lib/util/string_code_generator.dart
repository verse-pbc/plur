import 'dart:math';

class StringCodeGenerator {
  static String generateInviteCode({int length = 8}) {
    return _generateRandomString(length, 'ABCDEFGHIJKLMNPQRSTUVWXYZ23456789');
  }

  static String generateGroupId({int length = 12}) {
    return _generateRandomString(length, 'ABCDEFGHIJKLMNPQRSTUVWXYZ23456789');
  }

  static String _generateRandomString(int length, String chars) {
    final random = Random();
    return List.generate(length, (index) => chars[random.nextInt(chars.length)])
        .join();
  }
}
