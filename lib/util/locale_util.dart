import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import '../generated/l10n.dart';

class LocaleUtil {
  static String getLocaleKey(Locale l) {
    var key = l.languageCode;
    if (StringUtil.isNotBlank(l.countryCode)) {
      key += "_${l.countryCode!}";
    }
    return key;
  }

  static String? genLocaleKeyFromSring(String? i18n, String? i18nCC) {
    var key = i18n;
    if (StringUtil.isNotBlank(key) && StringUtil.isNotBlank(i18nCC)) {
      key = "${key!}_${i18nCC!}";
    }
    return key;
  }

  /// Detects the device's locale and returns it if we have localization support for it
  /// Returns null if the device locale is not supported
  static Locale? detectSupportedDeviceLocale() {
    try {
      // Get device locale from the platform
      final Locale deviceLocale = ui.PlatformDispatcher.instance.locale;
      
      // Check if we have exact match for language and country code
      for (var supportedLocale in S.supportedLocales) {
        if (supportedLocale.languageCode == deviceLocale.languageCode &&
            supportedLocale.countryCode == deviceLocale.countryCode) {
          return supportedLocale;
        }
      }
      
      // Check if we have match for just the language code
      for (var supportedLocale in S.supportedLocales) {
        if (supportedLocale.languageCode == deviceLocale.languageCode &&
            supportedLocale.countryCode == null) {
          return supportedLocale;
        }
      }
      
      return null;
    } catch (e) {
      // If there's any error in detection, return null to fall back to default
      return null;
    }
  }

  /// Checks if a specific locale is supported by the app
  static bool isLocaleSupported(Locale locale) {
    for (var supportedLocale in S.supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode &&
          supportedLocale.countryCode == locale.countryCode) {
        return true;
      }
    }
    return false;
  }

  /// Gets the best matching locale from supported locales for a given language code
  static Locale? getBestMatchingLocale(String languageCode, {String? countryCode}) {
    // First try exact match with country code
    if (countryCode != null) {
      for (var supportedLocale in S.supportedLocales) {
        if (supportedLocale.languageCode == languageCode &&
            supportedLocale.countryCode == countryCode) {
          return supportedLocale;
        }
      }
    }
    
    // Then try language code only
    for (var supportedLocale in S.supportedLocales) {
      if (supportedLocale.languageCode == languageCode &&
          supportedLocale.countryCode == null) {
        return supportedLocale;
      }
    }
    
    return null;
  }
}
