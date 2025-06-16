import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nostrmo/util/locale_util.dart';
import 'package:nostrmo/generated/l10n.dart';

void main() {
  group('LocaleUtil Tests', () {
    test('should detect supported locales correctly', () {
      // Test that English is supported
      expect(LocaleUtil.isLocaleSupported(const Locale('en')), isTrue);
      
      // Test that Spanish is supported
      expect(LocaleUtil.isLocaleSupported(const Locale('es')), isTrue);
      
      // Test that an unsupported language returns false
      expect(LocaleUtil.isLocaleSupported(const Locale('xx')), isFalse);
    });

    test('should get best matching locale correctly', () {
      // Test exact match
      var locale = LocaleUtil.getBestMatchingLocale('en');
      expect(locale?.languageCode, equals('en'));
      
      // Test with country code
      locale = LocaleUtil.getBestMatchingLocale('zh', countryCode: 'TW');
      expect(locale?.languageCode, equals('zh'));
      expect(locale?.countryCode, equals('TW'));
      
      // Test unsupported language
      locale = LocaleUtil.getBestMatchingLocale('xx');
      expect(locale, isNull);
    });

    test('should have correct supported locales', () {
      // Verify we have the expected number of supported locales
      expect(S.supportedLocales.length, greaterThan(20));
      
      // Verify some key languages are supported
      var languageCodes = S.supportedLocales.map((l) => l.languageCode).toSet();
      expect(languageCodes.contains('en'), isTrue);
      expect(languageCodes.contains('es'), isTrue);
      expect(languageCodes.contains('fr'), isTrue);
      expect(languageCodes.contains('de'), isTrue);
      expect(languageCodes.contains('zh'), isTrue);
      expect(languageCodes.contains('ja'), isTrue);
      expect(languageCodes.contains('ko'), isTrue);
    });
  });
}