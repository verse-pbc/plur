import 'package:flutter/foundation.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/util/app_logger.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/provider/group_provider.dart';

/// A report event with additional metadata
class ReportItem {
  final Event event;
  final String? groupId;
  final String? reportedEventId;
  final String? reportedPubkey;
  final String? reason;
  final String? details;
  final DateTime createdAt;
  final bool dismissed;
  final Event? reportedEvent;
  
  // Added properties
  final GroupIdentifier? groupContext;
  final String id; // ID field to identify this report
  
  ReportItem({
    required this.event,
    this.groupId,
    this.reportedEventId,
    this.reportedPubkey,
    this.reason,
    this.details,
    required this.createdAt,
    this.dismissed = false,
    this.reportedEvent,
    this.groupContext,
    String? id, // Optional ID parameter
  }) : id = id ?? event.id; // Use event ID as fallback
  
  /// Parse a report item from a Nostr event
  static ReportItem? fromEvent(Event event) {
    if (event.kind != EventKind.reportEvent) return null;
    
    String? reason;
    String? details;
    String? reportedEventId;
    String? reportedPubkey;
    String? groupId;
    
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
          case 'reason':
            reason = tagValue;
            break;
          case 'details':
            details = tagValue;
            break;
        }
      }
    }
    
    // Ensure we create the DateTime from the event's createdAt timestamp
    final createdAtDateTime = DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000);
    
    return ReportItem(
      event: event,
      reason: reason,
      details: details,
      reportedEventId: reportedEventId,
      reportedPubkey: reportedPubkey,
      groupId: groupId,
      createdAt: createdAtDateTime,
    );
  }
}

/// Service to handle reports for moderation
class ReportService extends ChangeNotifier with LaterFunction {
  // Map of groupId to list of reports
  final Map<String, List<ReportItem>> _reports = {};
  
  // Map of groupId to subscription ID
  final Map<String, String> _groupSubscriptions = {};
  
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
  
  /// Dismiss a report by ID
  /// This marks a report as handled
  void dismissReport(String reportId) {
    // Find the report by ID
    for (var groupId in _reports.keys) {
      var reportList = _reports[groupId];
      if (reportList != null) {
        for (int i = 0; i < reportList.length; i++) {
          if (reportList[i].id == reportId) {
            // Create a new report with dismissed = true
            var updatedReport = ReportItem(
              event: reportList[i].event,
              reportedEventId: reportList[i].reportedEventId,
              reportedPubkey: reportList[i].reportedPubkey,
              reason: reportList[i].reason,
              details: reportList[i].details,
              groupId: reportList[i].groupId,
              createdAt: reportList[i].createdAt,
              dismissed: true,
              reportedEvent: reportList[i].reportedEvent,
              groupContext: reportList[i].groupContext,
              id: reportId,
            );
            
            // Replace the old report with the updated one
            reportList[i] = updatedReport;
            
            // Also add to dismissed reports set for backward compatibility
            _dismissedReports.add(reportId);
            
            logger.i('Dismissed report $reportId', null, null, LogCategory.groups);
            notifyListeners();
            return;
          }
        }
      }
    }
    
    logger.w('Report $reportId not found for dismissal', null, null, LogCategory.groups);
  }
  
  /// Subscribe to reports for a specific group
  void subscribeToGroupReports(GroupIdentifier groupId) {
    if (nostr == null || groupId.groupId.isEmpty) return;
    
    logger.w("REPORT DEBUG: Subscribing to reports for group ${groupId.groupId}", null, null, LogCategory.groups);
    
    final subscriptionId = "report_${groupId.groupId}";
    _groupSubscriptions[groupId.groupId] = subscriptionId;
    
    // Get current time
    final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    
    // Define filter for report events (kind 1984)
    // Corrected filter format: "#h" should be a string key in the json object
    final filter = Filter(
      kinds: [EventKind.reportEvent],
      since: currentTime - (60 * 60 * 24 * 30) // Include events from the last 30 days
    );
    
    // Explicitly add the #h tag after creating the filter
    final filterMap = filter.toJson();
    filterMap["#h"] = [groupId.groupId];
    
    logger.w("REPORT DEBUG: Filter: $filterMap", null, null, LogCategory.groups);
    logger.w("REPORT DEBUG: Subscription ID: $subscriptionId", null, null, LogCategory.groups);
    logger.w("REPORT DEBUG: Group ID: ${groupId.groupId}, Host: ${groupId.host}", null, null, LogCategory.groups);
    logger.w("REPORT DEBUG: EventKind.reportEvent = ${EventKind.reportEvent}", null, null, LogCategory.groups);
    
    // Make sure we have this group in our reports map
    if (!_reports.containsKey(groupId.groupId)) {
      _reports[groupId.groupId] = [];
    }
    
    // Subscribe to report events - use the relay from the group ID
    final relaySub = [groupId.host];
    
    logger.w("REPORT DEBUG: Using relays: $relaySub", null, null, LogCategory.groups);
    
    try {
      nostr!.subscribe(
        [filterMap],
        _handleReportEvent,
        id: subscriptionId,
        relayTypes: [RelayType.temp],
        tempRelays: relaySub,
        sendAfterAuth: true,
      );
      
      logger.w("REPORT DEBUG: Subscription sent with ID: $subscriptionId", null, null, LogCategory.groups);
    } catch (e, st) {
      logger.e("REPORT DEBUG: Error subscribing to reports: $e", e, st, LogCategory.groups);
    }
  }
  
  /// Handle a received report event
  void _handleReportEvent(Event event) {
    // Debug logging - always log received report events
    logger.i("REPORT DEBUG: Received event with kind: ${event.kind}, ID: ${event.id.substring(0, 8)}...", null, null, LogCategory.groups);
    
    // Extract tags for debugging
    String tagsInfo = "";
    for (var tag in event.tags) {
      if (tag.length > 1) {
        tagsInfo += "[${tag[0]}: ${tag[1]}] ";
      }
    }
    logger.i("REPORT DEBUG: Event tags: $tagsInfo", null, null, LogCategory.groups);
    
    // Use later to avoid setState during build
    later(() {
      if (event.kind != EventKind.reportEvent) {
        logger.d("Received non-report event in report handler: ${event.kind}", null, null, LogCategory.groups);
        return;
      }
      
      logger.i("Received report event: ${event.id.substring(0, 8)}...", null, null, LogCategory.groups);
      
      // Parse the event into a report item
      final report = ReportItem.fromEvent(event);
      if (report == null) {
        logger.w("Failed to parse report event: ${event.id.substring(0, 8)}...", null, null, LogCategory.groups);
        return;
      }
      
      if (report.groupId == null) {
        logger.w("Report event has no group ID: ${event.id.substring(0, 8)}...", null, null, LogCategory.groups);
        return;
      }
      
      // Debug log complete report details
      logger.i("REPORT DEBUG: Parsed report - Group: ${report.groupId}, " +
               "Event: ${report.reportedEventId?.substring(0, 8) ?? 'none'}, " +
               "User: ${report.reportedPubkey?.substring(0, 8) ?? 'none'}, " +
               "Reason: ${report.reason ?? 'none'}", 
               null, null, LogCategory.groups);
      
      // Create a new report with dismissed flag if this report is already in dismissed reports set
      ReportItem finalReport = report;
      if (_dismissedReports.contains(event.id)) {
        logger.d("Report ${event.id.substring(0, 8)}... is already dismissed", null, null, LogCategory.groups);
        
        // Create new report with dismissed set to true
        finalReport = ReportItem(
          event: report.event,
          reportedEventId: report.reportedEventId,
          reportedPubkey: report.reportedPubkey,
          reason: report.reason,
          details: report.details,
          groupId: report.groupId,
          createdAt: report.createdAt,
          dismissed: true,
          reportedEvent: report.reportedEvent,
          groupContext: report.groupContext,
          id: report.id,
        );
      }
      
      // Get the group ID and ensure we have a list for it
      final groupId = finalReport.groupId!;
      if (!_reports.containsKey(groupId)) {
        logger.i("Creating report list for group $groupId", null, null, LogCategory.groups);
        _reports[groupId] = [];
      }
      
      // Check if we already have this report
      final existingIndex = _reports[groupId]!.indexWhere((r) => r.event.id == event.id);
      
      bool shouldNotify = false;
      if (existingIndex >= 0) {
        // Update existing report if needed
        if (_reports[groupId]![existingIndex].dismissed != finalReport.dismissed) {
          logger.d("Updating existing report ${event.id.substring(0, 8)}...", null, null, LogCategory.groups);
          _reports[groupId]![existingIndex] = finalReport;
          shouldNotify = true;
        }
      } else {
        // Add new report
        logger.i("Adding new report for group $groupId: ${event.id.substring(0, 8)}...", null, null, LogCategory.groups);
        _reports[groupId]!.add(finalReport);
        shouldNotify = true;
      }
      
      // Log report content
      if (shouldNotify) {
        logger.i("Report details - Event ID: ${finalReport.reportedEventId?.substring(0, 8) ?? 'none'}, " +
                "User: ${finalReport.reportedPubkey?.substring(0, 8) ?? 'none'}, " +
                "Reason: ${finalReport.reason ?? 'none'}", 
                null, null, LogCategory.groups);
        
        // Notify listeners about the change
        notifyListeners();
        
        // Debug notification
        logger.i("REPORT DEBUG: Notified listeners about report update/addition", null, null, LogCategory.groups);
      }
    });
  }
  
  /// Subscribe to reports for all groups the user is an admin of
  void subscribeToAdminGroupReports() {
    final myPubkey = nostr?.publicKey;
    if (myPubkey == null) return;
    
    logger.w("REPORT DEBUG: Subscribing to admin group reports for user ${myPubkey.substring(0, 8)}...", 
             null, null, LogCategory.groups);
    
    // Get all groups
    final adminGroups = groupProvider.getAdminGroups(myPubkey);
    
    // Log number of admin groups found
    logger.w("REPORT DEBUG: Found ${adminGroups.length} admin groups for subscription", 
             null, null, LogCategory.groups);
    
    if (adminGroups.isEmpty) {
      logger.w("REPORT DEBUG: No admin groups found, trying to check if direct admin check would work...", 
               null, null, LogCategory.groups);
    } else {
      // Log each admin group
      for (var group in adminGroups) {
        logger.w("REPORT DEBUG: Admin group: ${group.groupId} @ ${group.host}", 
                 null, null, LogCategory.groups);
      }
    }
    
    // Subscribe to reports for each group
    for (var group in adminGroups) {
      logger.w("REPORT DEBUG: Subscribing to reports for group ${group.groupId}", 
               null, null, LogCategory.groups);
      subscribeToGroupReports(group);
    }
    
    // If we didn't subscribe to any groups, log that too
    if (adminGroups.isEmpty) {
      logger.w("REPORT DEBUG: No groups to subscribe for reports - check GroupProvider.getAdminGroups", 
               null, null, LogCategory.groups);
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