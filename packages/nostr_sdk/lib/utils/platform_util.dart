import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class PlatformUtil {
  static BaseDeviceInfo? deviceInfo;

  static bool _isTable = false;

  static Future<void> init(BuildContext context) async {
    final size = MediaQuery.of(context).size;

    if (deviceInfo == null) {
      var deviceInfoPlus = DeviceInfoPlugin();
      deviceInfo = await deviceInfoPlus.deviceInfo;
    }

    if (!isWeb() &&
        Platform.isIOS &&
        deviceInfo != null &&
        deviceInfo!.data["systemName"] == "iPadOS") {
      _isTable = true;
    } else {
      if (size.shortestSide > 600) {
        _isTable = true;
      }
    }

    // double ratio = size.width / size.height;
    // if ((ratio >= 0.74) && (ratio < 1.5)) {
    //   _isTable = true;
    // }
  }

  static bool isAndroid() {
    if (isWeb()) {
      return false;
    }

    return Platform.isAndroid;
  }

  static bool isIOS() {
    if (isWeb()) {
      return false;
    }

    return Platform.isIOS;
  }

  static bool isWeb() {
    return kIsWeb;
  }

  static bool isTableModeWithoutSetting() {
    if (isPC()) {
      return true;
    }

    return _isTable;
  }

  static bool isWindowsOrLinux() {
    if (isWeb()) {
      return false;
    }
    return Platform.isWindows || Platform.isLinux;
  }

  static bool isPC() {
    if (isWeb()) {
      return false;
    }
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }
}
