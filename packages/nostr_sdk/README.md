# Nostr SDK

A Dart/Flutter package for interacting with the Nostr protocol.

## Features

- Event creation and validation
- Relay connections management
- NIP implementations (NIP02, NIP04, NIP05, NIP07, etc.)
- Cryptographic utilities for Nostr
- Relay pool management
- Group management (NIP29)
- Zaps and Lightning support

## Usage

```dart
import 'package:nostr_sdk/nostr_sdk.dart';

// Create an event
final event = Event.create(
  kind: EventKind.TEXT_NOTE,
  content: "Hello Nostr!",
  tags: [],
  privkey: "your_private_key"
);

// Connect to relays
final relay = Relay("wss://relay.example.com");
await relay.connect();

// Publish event
await relay.publish(event);

// Subscribe to events
final subscription = relay.subscribe([
  Filter(
    kinds: [EventKind.TEXT_NOTE],
    limit: 10,
  )
]);

// Process events
subscription.stream.listen((event) {
  print("Received event: ${event.content}");
});
```

## Additional information

This package is still under development. Use it with caution in production environments.

For more information on the Nostr protocol, visit [nostr.com](https://nostr.com/)