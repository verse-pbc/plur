// A simple test file to manually try event creation
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nostrmo/features/events/models/event_model.dart';
import 'package:nostrmo/features/events/providers/event_provider.dart';
import 'package:nostrmo/features/events/screens/event_creation_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Event Creation Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const EventTestScreen(),
    );
  }
}

class EventTestScreen extends ConsumerWidget {
  const EventTestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Creation Test'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const EventCreationScreen(
                      groupId: 'testgroup123',
                    ),
                  ),
                );
              },
              child: const Text('Open Event Creation Screen'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _testEventCreation(ref, context),
              child: const Text('Test Event Creation Directly'),
            ),
            const SizedBox(height: 20),
            // Display events list
            Expanded(
              child: _buildEventsList(ref),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsList(WidgetRef ref) {
    final eventsAsync = ref.watch(eventProvider);
    
    return eventsAsync.when(
      data: (events) {
        if (events.isEmpty) {
          return const Center(child: Text('No events found'));
        }
        
        return ListView.builder(
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            return ListTile(
              title: Text(event.title),
              subtitle: Text(event.description),
              trailing: Text(event.startAt.toString()),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error: $error'),
      ),
    );
  }

  Future<void> _testEventCreation(WidgetRef ref, BuildContext context) async {
    try {
      // Load events first to initialize state
      await ref.read(eventProvider.notifier).loadEvents();
      
      // Create a test event
      final now = DateTime.now();
      final tomorrow = now.add(const Duration(days: 1));
      
      final event = await ref.read(eventProvider.notifier).createEvent(
        title: 'Test Event ${now.millisecondsSinceEpoch}',
        description: 'This is a test event created at ${now.toString()}',
        startAt: tomorrow,
        groupId: 'testgroup123',
        visibility: EventVisibility.public,
        tags: ['test', 'debugging'],
      );
      
      if (event != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Event created: ${event.title}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create event')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating event: $e')),
      );
    }
  }
}