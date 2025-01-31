import 'dart:async';
import 'package:flutter/material.dart';

/// Keeps track of time and updates every minute.
/// Automatically notifies listeners when the time changes.
class TimestampProvider extends ChangeNotifier {
  Timer? _timer;
  DateTime _currentTime = DateTime.now();

  DateTime get currentTime => _currentTime;

  TimestampProvider() {
    // Update every 60 seconds
    _timer = Timer.periodic(const Duration(seconds: 60), (_) {
      _currentTime = DateTime.now();
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
