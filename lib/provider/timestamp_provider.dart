import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'timestamp_provider.g.dart';

/// Keeps track of time and updates every minute.
/// Automatically notifies listeners when the time changes.
@riverpod
class Timestamp extends _$Timestamp {
  Timer? _timer;

  @override
  DateTime build() {
    ref.onDispose(() {
      _timer?.cancel();
    });

    // Start the timer and update state every minute
    _timer = Timer.periodic(const Duration(seconds: 60), (_) {
      state = DateTime.now();
    });

    // Return the initial value
    return DateTime.now();
  }
}