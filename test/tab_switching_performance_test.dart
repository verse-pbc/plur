import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/provider/index_provider.dart';
import 'package:nostrmo/provider/list_provider.dart';
import 'package:nostrmo/provider/settings_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide ChangeNotifierProvider;

import 'tab_switching_performance_test.mocks.dart';

@GenerateMocks([ListProvider, SettingsProvider])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Tab Switching Performance', () {
    late MockListProvider mockListProvider;
    late MockSettingsProvider mockSettingsProvider;
    late IndexProvider indexProvider;

    setUp(() {
      mockListProvider = MockListProvider();
      mockSettingsProvider = MockSettingsProvider();
      indexProvider = IndexProvider();
      
      // Configure mocks
      when(mockListProvider.groupIdentifiers).thenReturn([]);
      
      // Mock SettingsProvider properties
      when(mockSettingsProvider.defaultTab).thenReturn(null);
      when(mockSettingsProvider.defaultIndex).thenReturn(0);
      when(mockSettingsProvider.lockOpen).thenReturn(0); // OpenStatus.close
      when(mockSettingsProvider.fontFamily).thenReturn('Nunito');
      when(mockSettingsProvider.fontSize).thenReturn(16.0);
      
      // Set up the mock as the global instance
      SettingsProvider.setTestInstance(mockSettingsProvider);
    });

    tearDown(() {
      // Clean up the static test instance
      SettingsProvider.clearTestInstance();
    });
    
    test('IndexProvider should handle rapid tab switching with throttling', () {
      // First switch
      indexProvider.setCurrentTap(1);
      expect(indexProvider.currentTap, 1);
      
      // Rapid second switch - should be throttled
      indexProvider.setCurrentTap(2);
      
      // Current tab should still be 1 due to throttling
      expect(indexProvider.currentTap, 1);
    });
  });
}