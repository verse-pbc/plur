import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../provider/timestamp_provider.dart';

enum TimeUnit { seconds, minutes, hours, days, older }

/// A widget that displays a relative timestamp that updates every 60 seconds.
///
/// This widget takes a Unix timestamp (in seconds) and displays it in a human-readable
/// format
///
/// The display automatically updates every 60 seconds.
/// Only this widget rebuilds on updates, not its parent.
class RelativeDateWidget extends ConsumerWidget {
  /// Unix timestamp in seconds
  final int date;

  const RelativeDateWidget(this.date, {super.key});

  /// Formats a timestamp into a human-readable relative date string.
  ///
  /// Takes the current [DateTime] as [now] to calculate the relative difference
  /// from [date]. Returns a formatted string that represents the time difference.
  String _formatRelativeDate(DateTime now) {
    // Convert Unix timestamp to local DateTime.
    final timestamp =
        DateTime.fromMillisecondsSinceEpoch(date * 1000, isUtc: false);
    final difference = now.difference(timestamp);

    // Handle negative time difference.
    if (difference.isNegative) {
      return 'just now';
    }

    final unit = difference.inDays >= 31
        ? TimeUnit.older
        : difference.inHours >= 24
            ? TimeUnit.days
            : difference.inMinutes >= 60
                ? TimeUnit.hours
                : difference.inSeconds >= 60
                    ? TimeUnit.minutes
                    : TimeUnit.seconds;

    String timeStr;
    switch (unit) {
      case TimeUnit.seconds:
        if (difference.inSeconds == 0) return 'just now';
        timeStr = '${difference.inSeconds}s';
        break;
      case TimeUnit.minutes:
        timeStr = '${difference.inMinutes}m';
        break;
      case TimeUnit.hours:
        timeStr = '${difference.inHours}h';
        break;
      case TimeUnit.days:
        timeStr = '${difference.inDays}d';
        break;
      case TimeUnit.older:
        return DateFormat('dd MMM, yyyy').format(timestamp);
    }

    return '$timeStr ago';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeData = Theme.of(context);
    final currentTime = ref.watch(timestampProvider);
    return Text(
      _formatRelativeDate(currentTime),
      style: TextStyle(
        color: themeData.hintColor,
        fontSize: themeData.textTheme.bodySmall!.fontSize,
      ),
    );
  }
}
