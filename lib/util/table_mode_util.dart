import 'package:nostrmo/nostr_sdk/nostr_sdk.dart';

import '../consts/base_consts.dart';
import '../main.dart';

class TableModeUtil {
  static bool isTableMode() {
    if (settingsProvider.tableMode == OpenStatus.OPEN) {
      return true;
    } else if (settingsProvider.tableMode == OpenStatus.CLOSE) {
      return false;
    }
    return PlatformUtil.isTableModeWithoutSetting();
  }
}
