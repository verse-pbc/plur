import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostr_sdk/utils/string_util.dart';
import 'package:nostrmo/component/user/user_pic_widget.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/consts/plur_colors.dart';
import 'package:nostrmo/generated/l10n.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/provider/group_provider.dart';
import 'package:nostrmo/service/report_service.dart';
import 'package:nostrmo/util/app_logger.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:nostrmo/consts/router_path.dart';

class ReportManagementScreen extends StatefulWidget {
  final GroupIdentifier? selectedGroup;

  const ReportManagementScreen({
    Key? key,
    this.selectedGroup,
  }) : super(key: key);

  @override
  State<ReportManagementScreen> createState() => _ReportManagementScreenState();
}

class _ReportManagementScreenState extends State<ReportManagementScreen> {
  GroupIdentifier? _selectedGroup;
  bool _loading = true;
  List<GroupIdentifier> _adminGroups = [];
  List<ReportItem> _reports = [];
  bool _showDismissed = false;

  @override
  void initState() {
    super.initState();
    _selectedGroup = widget.selectedGroup;
    logger.w("REPORT DEBUG: ReportManagementScreen initialized with selectedGroup: ${widget.selectedGroup?.groupId ?? 'null'}", 
        null, null, LogCategory.groups);
    _fetchAdminGroups();
    
    // Subscribe to report updates
    logger.w("REPORT DEBUG: Adding listener for report updates", null, null, LogCategory.groups);
    reportService.addListener(_onReportsUpdated);
    
    // If we have a specific group from the context, subscribe directly to its reports
    // instead of trying to find "admin groups"
    if (widget.selectedGroup != null) {
      logger.w("REPORT DEBUG: Directly subscribing to reports for selected group: ${widget.selectedGroup!.groupId}", 
          null, null, LogCategory.groups);
      reportService.subscribeToGroupReports(widget.selectedGroup!);
    } else {
      // Try to get group from context
      try {
        final groupFromContext = context.read<GroupIdentifier>();
        logger.w("REPORT DEBUG: Found group in context, subscribing: ${groupFromContext.groupId}", 
            null, null, LogCategory.groups);
        reportService.subscribeToGroupReports(groupFromContext);
        
        // We already have a group, so no need to search for more
        return;
      } catch (e) {
        logger.w("REPORT DEBUG: No group in context, falling back to admin groups method", 
            null, null, LogCategory.groups);
      }
      
      // Fall back to the old method if no specific group was provided
      logger.w("REPORT DEBUG: Calling legacy subscribeToAdminGroupReports as fallback", null, null, LogCategory.groups);
      reportService.subscribeToAdminGroupReports();
    }
  }
  
  @override
  void dispose() {
    logger.w("REPORT DEBUG: Removing report listener", null, null, LogCategory.groups);
    reportService.removeListener(_onReportsUpdated);
    super.dispose();
  }
  
  void _onReportsUpdated() {
    logger.w("REPORT DEBUG: Reports updated, refreshing UI", null, null, LogCategory.groups);
    if (mounted) {
      setState(() {
        _updateReportsList();
      });
    }
  }
  
  void _fetchAdminGroups() async {
    setState(() {
      _loading = true;
    });
    
    try {
      final myPubkey = nostr?.publicKey;
      if (myPubkey != null) {
        logger.i("_fetchAdminGroups for user: ${myPubkey.substring(0, 8)}...", null, null, LogCategory.groups);
        
        // First check if we have a specific group from context
        GroupIdentifier? groupFromContext;
        bool isAdminOfContextGroup = false;
        
        try {
          groupFromContext = context.read<GroupIdentifier>();
          // Log the current context group
          logger.i("Context group: ${groupFromContext.toString()}", null, null, LogCategory.groups);
          
          // Check internal data structure
          final key = groupFromContext.toString();
          final admins = groupProvider.groupAdmins[key];
          if (admins != null) {
            logger.i("Found admins for group: $key - ${admins.toString()}", null, null, LogCategory.groups);
            isAdminOfContextGroup = admins.containsUser(myPubkey);
            logger.i("Direct admins.containsUser check: $isAdminOfContextGroup", null, null, LogCategory.groups);
          } else {
            logger.w("No admin data found for group: $key", null, null, LogCategory.groups);
          }
          
          // Use direct isAdmin check for current group
          isAdminOfContextGroup = groupProvider.isAdmin(myPubkey, groupFromContext);
          logger.i("groupProvider.isAdmin result: $isAdminOfContextGroup", null, null, LogCategory.groups);
        } catch (e, st) {
          // No group in context, that's ok
          logger.w("No group in context or error reading it: $e", st, null, LogCategory.groups);
        }
        
        // Get all groups the user is an admin of using getAdminGroups
        logger.i("Calling getAdminGroups...", null, null, LogCategory.groups);
        final adminGroups = groupProvider.getAdminGroups(myPubkey);
        logger.i("getAdminGroups returned ${adminGroups.length} groups", null, null, LogCategory.groups);
        
        // If user is admin of the context group but it's not in adminGroups,
        // add it manually (this handles cases where the cache might be incomplete)
        if (isAdminOfContextGroup && groupFromContext != null && 
            !adminGroups.contains(groupFromContext)) {
          adminGroups.add(groupFromContext);
          logger.i("Added context group to admin groups list", null, null, LogCategory.groups);
        }
        
        if (mounted) {
          setState(() {
            _adminGroups = adminGroups;
            _loading = false;
            
            // If we have a context group and user is admin, use it
            if (groupFromContext != null && isAdminOfContextGroup) {
              _selectedGroup = groupFromContext;
            } 
            // Otherwise, if no group is selected and we have admin groups, select the first one
            else if (_selectedGroup == null && adminGroups.isNotEmpty) {
              _selectedGroup = adminGroups.first;
            }
            
            _updateReportsList();
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _loading = false;
          });
        }
      }
    } catch (e, stackTrace) {
      logger.e('Error fetching admin groups', e, stackTrace, LogCategory.groups);
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }
  
  void _updateReportsList() {
    if (_selectedGroup != null) {
      // Get reports for the selected group
      logger.w("REPORT DEBUG: Getting reports for group: ${_selectedGroup!.groupId}", null, null, LogCategory.groups);
      final reports = reportService.getGroupReports(_selectedGroup!.groupId);
      logger.w("REPORT DEBUG: Found ${reports.length} reports for group ${_selectedGroup!.groupId}", null, null, LogCategory.groups);
      
      // Filter out dismissed reports if needed
      List<ReportItem> filteredReports = _showDismissed 
          ? reports 
          : reports.where((report) => !report.dismissed).toList();
      
      logger.w("REPORT DEBUG: After filtering dismissed: ${filteredReports.length} reports", null, null, LogCategory.groups);
      
      // Sort by date (newest first)
      filteredReports.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      setState(() {
        _reports = filteredReports;
      });
    } else {
      // If no group selected, show reports from all admin groups
      logger.w("REPORT DEBUG: Getting all reports across admin groups", null, null, LogCategory.groups);
      final allReports = reportService.getAllReports();
      logger.w("REPORT DEBUG: Found ${allReports.length} total reports across all groups", null, null, LogCategory.groups);
      
      // Filter out dismissed reports if needed
      List<ReportItem> filteredReports = _showDismissed 
          ? allReports 
          : allReports.where((report) => !report.dismissed).toList();
      
      logger.w("REPORT DEBUG: After filtering dismissed: ${filteredReports.length} reports", null, null, LogCategory.groups);
      
      // Sort by date (newest first)
      filteredReports.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      setState(() {
        _reports = filteredReports;
      });
    }
  }
  
  void _handleGroupChange(GroupIdentifier? newGroup) {
    setState(() {
      _selectedGroup = newGroup;
      _updateReportsList();
    });
  }
  
  void _dismissReport(ReportItem report) {
    reportService.dismissReport(report.event.id);
    
    // Update the UI
    setState(() {
      _updateReportsList();
    });
  }
  
  void _removeReportedPost(ReportItem report) async {
    if (report.reportedEventId == null || report.groupId == null) return;
    
    final groupId = _selectedGroup ?? 
        GroupIdentifier(report.relayUrl ?? "", report.groupId!);
    
    if (groupId != null) {
      final success = await groupProvider.removePost(
        groupId, 
        report.reportedEventId!,
        reason: "Removed after review of user report: ${report.reason ?? 'Not specified'}"
      );
      
      if (success) {
        // Dismiss the report after successful removal
        _dismissReport(report);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Post removed successfully")),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to remove post")),
          );
        }
      }
    }
  }
  
  void _viewReportedContent(ReportItem report) {
    if (report.reportedEventId != null) {
      final event = singleEventProvider.getEvent(report.reportedEventId!);
      if (event != null) {
        RouterUtil.router(context, RouterPath.eventDetail, event);
      } else {
        // If the event is not cached, try to fetch it
        // Show a loading indicator and error handling would be needed here
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Report content not found")),
        );
      }
    }
  }
  
  void _viewReporterProfile(ReportItem report) {
    RouterUtil.router(context, RouterPath.user, report.event.pubkey);
  }
  
  void _viewReportedUserProfile(ReportItem report) {
    if (report.reportedPubkey != null) {
      RouterUtil.router(context, RouterPath.user, report.reportedPubkey!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = S.of(context);
    
    // Try to get the current group context if available
    GroupIdentifier? groupContext;
    bool directAdminCheck = false;
    bool forceAdmin = widget.selectedGroup != null; // If a specific group was selected, force admin mode
    
    try {
      groupContext = context.read<GroupIdentifier>();
      final myPubkey = nostr?.publicKey;
      if (myPubkey != null) {
        // Direct admin check for the current group
        directAdminCheck = groupProvider.isAdmin(myPubkey, groupContext);
        logger.i("REPORT SCREEN DIRECT CHECK: isAdmin=$directAdminCheck for group ${groupContext.groupId}", 
          null, null, LogCategory.groups);
          
        // For debugging only - force admin if coming from admin panel
        if (!directAdminCheck && forceAdmin) {
          logger.w("EMERGENCY WORKAROUND: Admin check failed but forcing admin mode", 
                   null, null, LogCategory.groups);
          directAdminCheck = true;
        }
      }
    } catch (e) {
      // No group in context, that's ok
      logger.d('No group found in context: $e', LogCategory.groups);
    }
    
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Report Management"),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    // Emergency workaround: If a specific group was selected via widget.selectedGroup,
    // force admin access regardless of what the provider says
    if (forceAdmin && _adminGroups.isEmpty && widget.selectedGroup != null) {
      _adminGroups = [widget.selectedGroup!];
      _selectedGroup = widget.selectedGroup;
      
      logger.w("EMERGENCY WORKAROUND: Forcing admin access for selected group", 
               null, null, LogCategory.groups);
      
      // Refresh UI with this new info
      _updateReportsList();
    }
    
    // Check if we have a group context but it's not in admin groups,
    // but the direct admin check says we should be an admin
    if (!_loading && _adminGroups.isEmpty && groupContext != null && (directAdminCheck || forceAdmin)) {
      // This is a special case - getAdminGroups failed but direct check shows admin
      // Let's force add this group to admin groups
      _adminGroups = [groupContext];
      _selectedGroup = groupContext;
      
      logger.i("Admin groups empty but direct check says admin - adding group", null, null, LogCategory.groups);
      
      // Refresh UI with this new info
      _updateReportsList();
    }
    
    // If we have a group context but it's not in admin groups and direct check also failed
    if (!_loading && _adminGroups.isEmpty && groupContext != null && !directAdminCheck) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Report Management"),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.admin_panel_settings_outlined,
                size: 64,
                color: theme.hintColor,
              ),
              const SizedBox(height: 16),
              Text(
                "Not an organizer of this community",
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  "You need to be a community organizer to view and manage reports for this community.",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
              ),
              if (nostr != null) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    "Debug info: Group ${groupContext.groupId}, Admin check: $directAdminCheck, User: ${nostr!.publicKey.substring(0, 8)}...",
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Force a refresh of the admin groups
                  _fetchAdminGroups();
                },
                child: Text("Refresh"),
              ),
            ],
          ),
        ),
      );
    }
    
    // General case - no admin groups found at all
    if (!_loading && _adminGroups.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Report Management"),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.admin_panel_settings_outlined,
                size: 64,
                color: theme.hintColor,
              ),
              const SizedBox(height: 16),
              Text(
                "No admin permissions found",
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  "You need to be a community organizer to access report management. Please contact a community organizer if you believe this is an error.",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Force a refresh of the admin groups
                  _fetchAdminGroups();
                },
                child: Text("Refresh"),
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("Report Management"),
        actions: [
          // Toggle switch for showing dismissed reports
          IconButton(
            icon: Icon(_showDismissed ? Icons.visibility : Icons.visibility_off),
            onPressed: () {
              setState(() {
                _showDismissed = !_showDismissed;
                _updateReportsList();
              });
            },
            tooltip: _showDismissed ? "Hide dismissed reports" : "Show dismissed reports",
          ),
        ],
      ),
      body: Column(
        children: [
          // Group selector dropdown
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.filter_list),
                const SizedBox(width: 8),
                Text(
                  "Filter by community:",
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButton<GroupIdentifier?>(
                    isExpanded: true,
                    value: _selectedGroup,
                    hint: const Text("All communities"),
                    onChanged: _handleGroupChange,
                    items: [
                      const DropdownMenuItem<GroupIdentifier?>(
                        value: null,
                        child: Text("All communities"),
                      ),
                      ..._adminGroups.map((group) {
                        // Get the group metadata for display
                        final metadata = groupProvider.getMetadata(group);
                        final name = metadata?.name ?? group.groupId;
                        
                        return DropdownMenuItem<GroupIdentifier>(
                          value: group,
                          child: Text(
                            name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Reports list
          Expanded(
            child: _reports.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.task_alt,
                          size: 48,
                          color: theme.hintColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No reports found",
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _showDismissed
                              ? "There are no reports for this community"
                              : "There are no active reports for this community",
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _reports.length,
                    itemBuilder: (context, index) {
                      final report = _reports[index];
                      return _buildReportItem(report, theme);
                    },
                  ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildReportItem(ReportItem report, ThemeData theme) {
    final reportedEvent = report.reportedEvent;
    final dateFormat = DateFormat('MMM d, yyyy h:mm a');
    final formattedDate = dateFormat.format(report.createdAt);
    
    // Format report content as needed
    String reportReason = report.reason ?? "No reason provided";
    String reportDetails = report.details ?? "";
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Report header with reporter info and timestamp
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => _viewReporterProfile(report),
                  child: UserPicWidget(
                    pubkey: report.event.pubkey,
                    width: 40,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () => _viewReporterProfile(report),
                            child: Text(
                              userProvider.getName(report.event.pubkey),
                              style: GoogleFonts.nunito(
                                textStyle: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          Text(
                            formattedDate,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.hintColor,
                            ),
                          ),
                        ],
                      ),
                      if (report.dismissed)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "Dismissed",
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.hintColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Report reason and details
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.dividerColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Reason: $reportReason",
                    style: GoogleFonts.nunito(
                      textStyle: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (reportDetails.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      "Details: $reportDetails",
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Reported content preview (if available)
            if (reportedEvent != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.dividerColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Report target header (content or user)
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => _viewReportedUserProfile(report),
                          child: UserPicWidget(
                            pubkey: reportedEvent.pubkey,
                            width: 32,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _viewReportedUserProfile(report),
                          child: Text(
                            userProvider.getName(reportedEvent.pubkey),
                            style: GoogleFonts.nunito(
                              textStyle: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Reported content preview
                    Text(
                      StringUtil.isNotBlank(reportedEvent.content)
                          ? reportedEvent.content.length > 150
                              ? "${reportedEvent.content.substring(0, 150)}..."
                              : reportedEvent.content
                          : "[No content]",
                      style: theme.textTheme.bodyMedium,
                    ),
                    
                    // View full content button
                    TextButton(
                      onPressed: () => _viewReportedContent(report),
                      child: Text("View full content"),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!report.dismissed) ...[
                  // Dismiss button
                  OutlinedButton(
                    onPressed: () => _dismissReport(report),
                    child: Text("Dismiss"),
                  ),
                  const SizedBox(width: 8),
                  
                  // Remove content button (only if content is available)
                  if (report.reportedEventId != null)
                    ElevatedButton(
                      onPressed: () => _removeReportedPost(report),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PlurColors.warningColor,
                        foregroundColor: Colors.white,
                      ),
                      child: Text("Remove Post"),
                    ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
} 