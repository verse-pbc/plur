import 'package:flutter/foundation.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/util/app_logger.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/provider/group_provider.dart';

/// A report event with additional metadata
class ReportItem {
  final Event event;
  final String? reason;
  final String? details;
  final String? reportedEventId;
  final String? reportedPubkey;
  final String? groupId;
  final String? relayUrl;
  final DateTime createdAt;
  bool dismissed = false;
  
  ReportItem({
    required this.event,
    this.reason,
    this.details,
    this.reportedEventId,
    this.reportedPubkey,
    this.groupId,
    this.relayUrl,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000);
  
  /// Get the reported content (if available)
  Event? get reportedEvent => reportedEventId != null ? singleEventProvider.getEvent(reportedEventId!) : null;
  
  /// Parse a report item from a Nostr event
  static ReportItem? fromEvent(Event event) {
    if (event.kind != EventKind.reportEvent) return null;
    
    String? reason;
    String? details;
    String? reportedEventId;
    String? reportedPubkey;
    String? groupId;
    String? relayUrl;
    
    for (var tag in event.tags) {
      if (tag.length > 1) {
        final tagName = tag[0] as String;
        final tagValue = tag[1] as String;
        
        switch (tagName) {
          case 'e':
            reportedEventId = tagValue;
            break;
          case 'p':
            reportedPubkey = tagValue;
            break;
          case 'h':
            groupId = tagValue;
            break;
          case 'relay':
            relayUrl = tagValue;
            break;
          case 'reason':
            reason = tagValue;
            break;
          case 'details':
            details = tagValue;
            break;
        }
      }
    }
    
    return ReportItem(
      event: event,
      reason: reason,
      details: details,
      reportedEventId: reportedEventId,
      reportedPubkey: reportedPubkey,
      groupId: groupId,
      relayUrl: relayUrl,
    );
  }
}

/// Service to handle reports for moderation
class ReportService extends ChangeNotifier with LaterFunction {
  // Map of groupId to list of reports
  final Map<String, List<ReportItem>> _reports = {};
  
  // Set of subscription IDs to avoid duplicates
  final Set<String> _activeSubscriptions = {};
  
  // Set of dismissed report IDs
  final Set<String> _dismissedReports = {};
  
  /// Get all reports for a specific group
  List<ReportItem> getGroupReports(String groupId) {
    return _reports[groupId] ?? [];
  }
  
  /// Get all reports for all groups
  List<ReportItem> getAllReports() {
    final allReports = <ReportItem>[];
    _reports.forEach((_, reports) {
      allReports.addAll(reports);
    });
    return allReports;
  }
  
  /// Get count of active (non-dismissed) reports across all groups
  int getActiveReportCount() {
    int count = 0;
    
    _reports.forEach((_, reports) {
      count += reports.where((report) => !report.dismissed).length;
    });
    
    return count;
  }
  
  /// Dismiss a report
  void dismissReport(String reportId) {
    bool updated = false;
    
    _dismissedReports.add(reportId);
    
    _reports.forEach((groupId, reports) {
      for (var report in reports) {
        if (report.event.id == reportId) {
          report.dismissed = true;
          updated = true;
          break;
        }
      }
    });
    
    if (updated) {
      notifyListeners();
    }
  }
  
  /// Subscribe to report events for a specific group
  void subscribeToGroupReports(GroupIdentifier groupId) {
    // Generate a unique subscription ID for this group
    final subscriptionId = 'report_${groupId.groupId}_${DateTime.now().millisecondsSinceEpoch}';
    
    // Skip if already subscribed
    if (_activeSubscriptions.contains(subscriptionId)) {
      return;
    }
    
    logger.i('Subscribing to report events for group ${groupId.groupId}', 
        null, null, LogCategory.groups);
    
    // Add to active subscriptions
    _activeSubscriptions.add(subscriptionId);
    
    // Get the current timestamp
    final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    
    // Define filter for report events (kind 1984)
    final filter = {
      "kinds": [EventKind.reportEvent],
      "#h": [groupId.groupId],
      "since": currentTime - (60 * 60 * 24 * 30) // Include events from the last 30 days
    };
    
    try {
      // Subscribe to report events
      nostr!.subscribe(
        [filter],
        _handleReportEvent,
        id: subscriptionId,
        relayTypes: [RelayType.temp],
        tempRelays: [groupId.host],
        sendAfterAuth: true,
      );
      
      logger.d('Successfully subscribed to report events: $subscriptionId',
          null, null, LogCategory.groups);
    } catch (e, stackTrace) {
      logger.e('Error subscribing to report events: $e', stackTrace, null, 
          LogCategory.groups);
      _activeSubscriptions.remove(subscriptionId);
    }
  }
  
  /// Handle incoming report events
  void _handleReportEvent(Event event) {
    later(() {
      if (event.kind != EventKind.reportEvent) return;
      
      // Process the report event
      final report = ReportItem.fromEvent(event);
      if (report == null || report.groupId == null) return;
      
      // Check if this report is already dismissed
      if (_dismissedReports.contains(event.id)) {
        report.dismissed = true;
      }
      
      // Add the report to the list for this group
      final groupId = report.groupId!;
      if (!_reports.containsKey(groupId)) {
        _reports[groupId] = [];
      }
      
      // Check if we already have this report
      final existingIndex = _reports[groupId]!.indexWhere((r) => r.event.id == event.id);
      
      bool shouldNotify = false;
      if (existingIndex >= 0) {
        // Update existing report if needed (e.g., if it was dismissed)
        if (_reports[groupId]![existingIndex].dismissed != report.dismissed) {
          _reports[groupId]![existingIndex] = report;
          shouldNotify = true;
        }
      } else {
        // Add new report
        _reports[groupId]!.add(report);
        shouldNotify = true;
        
        // Log new report
        logger.i('New report received for group $groupId', null, null, LogCategory.groups);
      }
      
      if (shouldNotify) {
        notifyListeners();
      }
    });
  }
  
  /// Subscribe to reports for all groups the user is an admin of
  void subscribeToAdminGroupReports() {
    final myPubkey = nostr?.publicKey;
    if (myPubkey == null) return;
    
    // Get all groups
    final adminGroups = groupProvider.getAdminGroups(myPubkey);
    
    // Subscribe to reports for each group
    for (var group in adminGroups) {
      subscribeToGroupReports(group);
    }
  }
  
  /// Unsubscribe from all report event subscriptions
  void unsubscribeAll() {
    for (final subId in _activeSubscriptions) {
      try {
        nostr!.unsubscribe(subId);
      } catch (e) {
        logger.e('Error unsubscribing from report events: $e', null, null,
            LogCategory.groups);
      }
    }
    _activeSubscriptions.clear();
  }
  
  @override
  void dispose() {
    unsubscribeAll();
    super.dispose();
  }
} 