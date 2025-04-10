import 'package:nostr_sdk/nostr_sdk.dart';

import '../consts/base_consts.dart';
import '../main.dart';

class TableModeUtil {
  static bool isTableMode() {
    if (settingsProvider.tableMode == OpenStatus.open) {
      return true;
    } else if (settingsProvider.tableMode == OpenStatus.close) {
      return false;
    }
    return PlatformUtil.isTableModeWithoutSetting();
  }
}
