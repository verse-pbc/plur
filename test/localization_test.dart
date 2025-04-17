import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nostrmo/generated/l10n.dart';

void main() {
  testWidgets('Verify localization keys are accessible', (WidgetTester tester) async {
    // Load the localization delegate
    await S.load(const Locale('en'));
    
    // Create an instance of the localization class
    final S localization = S.current;
    
    // Test some basic localization keys to ensure they're accessible
    expect(localization.cancel, 'Cancel');
    expect(localization.confirm, 'Confirm');
    expect(localization.discard, 'Discard');
    expect(localization.settings, 'Settings');
    
    // Test converted keys that were previously in PascalCase
    expect(localization.communityGuidelines, 'Community Guidelines');
    // We've renamed one of the duplicate keys to communityNameHeader
    expect(localization.communityNameHeader, 'Community Name');
    expect(localization.communityName, 'community name');
    expect(localization.enterCommunityName, 'Enter a name for your community');
    expect(localization.continueButton, 'Continue');
    
    // Test keys we've updated in specific components
    expect(localization.hour, 'Hour');
    expect(localization.minute, 'Minute');
    expect(localization.any, 'Any');
    expect(localization.pay, 'Pay');
    expect(localization.lightningInvoice, 'Lightning Invoice');
    
    // Test emoji and editor related keys
    expect(localization.addCustomEmoji, 'Add Custom Emoji');
    expect(localization.customEmoji, 'Custom Emoji');
    expect(localization.emoji, 'Emoji');
    expect(localization.inputCustomEmojiName, 'Input Custom Emoji Name');
  });
}