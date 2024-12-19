import 'dart:math';

class InviteUtil {
  static String generateInviteCode({int length = 8}) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return List.generate(length, (index) => chars[random.nextInt(chars.length)])
        .join();
  }
}
