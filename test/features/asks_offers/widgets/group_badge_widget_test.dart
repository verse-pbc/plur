import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:nostrmo/data/group_metadata_repository.dart';
import 'package:nostrmo/features/asks_offers/widgets/group_badge_widget.dart';
import 'package:nostr_sdk/nip29/group_identifier.dart';
import 'package:nostr_sdk/nip29/group_metadata.dart';

// Define a mock class for group metadata provider
class MockRepository extends Mock {
  AsyncValue<GroupMetadata?> getGroupMetadata(GroupIdentifier identifier) {
    return const AsyncValue.loading();
  }
}

void main() {
  group('GroupBadgeWidget', () {
    testWidgets('renders loading state correctly', (WidgetTester tester) async {
      // Create a mock repository
      final mockRepository = MockRepository();
      
      // Return loading state for any group identifier
      when(mockRepository.getGroupMetadata(any)).thenReturn(const AsyncValue.loading());
      
      // Build widget inside a ProviderScope with mocks
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            // Override the provider to use our mock
            groupMetadataProvider.overrideWithProvider((id) => const AsyncValue.loading()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: GroupBadgeWidget(
                groupId: 'relay:test_group',
              ),
            ),
          ),
        ),
      );
      
      // Verify loading state UI
      expect(find.text('Loading...'), findsOneWidget);
      expect(find.byIcon(Icons.group_rounded), findsOneWidget);
    });
    
    testWidgets('renders group name correctly', (WidgetTester tester) async {
      // Create a mock repository
      final mockRepository = MockRepository();
      
      // Create test metadata
      final testMetadata = GroupMetadata(
        name: 'Test Group',
        displayName: 'Display Test Group',
        description: 'A test group',
        picture: null,
      );
      
      // Define an override for the provider
      final testOverride = Provider<AsyncValue<GroupMetadata?>>((ref) {
        return AsyncValue.data(testMetadata);
      });
      
      // Build widget inside a ProviderScope with mocks
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            // Override the provider to return our test data
            groupMetadataProvider.overrideWithProvider((id) => AsyncValue.data(testMetadata)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: GroupBadgeWidget(
                groupId: 'relay:test_group',
              ),
            ),
          ),
        ),
      );
      
      // Let the widget build
      await tester.pump();
      
      // Verify group name is displayed
      expect(find.text('Display Test Group'), findsOneWidget);
      expect(find.byIcon(Icons.group_rounded), findsOneWidget);
    });
    
    testWidgets('responds to tap event', (WidgetTester tester) async {
      // Track tap events
      bool wasTapped = false;
      
      // Build widget with a tap handler
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: GroupBadgeWidget(
                groupId: 'relay:test_group',
                onTap: () {
                  wasTapped = true;
                },
              ),
            ),
          ),
        ),
      );
      
      // Tap the widget
      await tester.tap(find.byType(GroupBadgeWidget));
      
      // Verify the tap was registered
      expect(wasTapped, true);
    });
    
    testWidgets('applies custom styling', (WidgetTester tester) async {
      // Custom style values
      const double testFontSize = 18.0;
      const Color testColor = Colors.purple;
      const Color testBgColor = Colors.amber;
      
      // Build widget with custom styling
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: GroupBadgeWidget(
                groupId: 'relay:test_group',
                fontSize: testFontSize,
                textColor: testColor,
                backgroundColor: testBgColor,
              ),
            ),
          ),
        ),
      );
      
      // Find the container with the background color
      final container = find.ancestor(
        of: find.byIcon(Icons.group_rounded),
        matching: find.byType(Container),
      ).first;
      
      // Verify the styling was applied
      final containerWidget = tester.widget<Container>(container);
      final decoration = containerWidget.decoration as BoxDecoration;
      expect(decoration.color, testBgColor);
      
      // Find the icon to verify its color
      final icon = tester.widget<Icon>(find.byIcon(Icons.group_rounded));
      expect(icon.color, testColor);
      expect(icon.size, testFontSize + 2); // The widget adds 2 to fontSize for the icon
    });
  });
}