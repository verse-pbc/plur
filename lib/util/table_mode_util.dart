import 'package:nostr_sdk/nostr_sdk.dart';

import '../consts/base_consts.dart';
import '../main.dart';

class TableModeUtil {
  static bool isTableMode() {
    if (settingProvider.tableMode == OpenStatus.OPEN) {
      return true;
    } else if (settingProvider.tableMode == OpenStatus.CLOSE) {
      return false;
    }
    return PlatformUtil.isTableModeWithoutSetting();
  }
}
