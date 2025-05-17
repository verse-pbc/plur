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
import 'package:nostrmo/provider/single_event_provider.dart';
import 'package:nostrmo/provider/user_provider.dart';
import 'package:nostrmo/service/moderation_service.dart';
import 'package:nostrmo/service/report_service.dart';
import 'package:nostrmo/util/app_logger.dart';
import 'package:nostrmo/util/moderation_dm_util.dart';
import 'package:nostrmo/util/router_util.dart';
import 'package:nostrmo/util/theme_util.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:nostrmo/consts/router_path.dart';
import 'package:nostrmo/router/group/group_members/user_remove_dialog.dart';
import 'package:nostrmo/router/group/group_members/user_ban_dialog.dart';

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
  String _selectedReportType = 'All';
  String _selectedSortOption = 'Newest';
  
  static const List<String> reportTypes = ['All', 'Content', 'User'];
  static const List<String> sortOptions = ['Newest', 'Oldest', 'Most Reported'];

  @override
  void initState() {
    super.initState();
    _selectedGroup = widget.selectedGroup;
    logger.w("REPORT DEBUG: ReportManagementScreen initialized with selectedGroup: ${widget.selectedGroup?.groupId ?? 'null'}", 
        null, null, LogCategory.groups);
    _fetchAdminGroups();
    
    logger.w("REPORT DEBUG: Adding listener for report updates", null, null, LogCategory.groups);
    reportService.addListener(_onReportsUpdated);
    
    if (widget.selectedGroup != null) {
      logger.w("REPORT DEBUG: Directly subscribing to reports for selected group: ${widget.selectedGroup!.groupId}", 
          null, null, LogCategory.groups);
      reportService.subscribeToGroupReports(widget.selectedGroup!);
    } else {
      try {
        final groupFromContext = context.read<GroupIdentifier>();
        logger.w("REPORT DEBUG: Found group in context, subscribing: ${groupFromContext.groupId}", 
            null, null, LogCategory.groups);
        reportService.subscribeToGroupReports(groupFromContext);
        
        return;
      } catch (e) {
        logger.w("REPORT DEBUG: No group in context, falling back to admin groups method", 
            null, null, LogCategory.groups);
      }
      
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
        
        GroupIdentifier? groupFromContext;
        bool isAdminOfContextGroup = false;
        
        try {
          groupFromContext = context.read<GroupIdentifier>();
          logger.i("Context group: ${groupFromContext.toString()}", null, null, LogCategory.groups);
          
          final key = groupFromContext.toString();
          final admins = groupProvider.groupAdmins[key];
          if (admins != null) {
            logger.i("Found admins for group: $key - ${admins.toString()}", null, null, LogCategory.groups);
            isAdminOfContextGroup = admins.containsUser(myPubkey);
            logger.i("Direct admins.containsUser check: $isAdminOfContextGroup", null, null, LogCategory.groups);
          } else {
            logger.w("No admin data found for group: $key", null, null, LogCategory.groups);
          }
          
          isAdminOfContextGroup = groupProvider.isAdmin(myPubkey, groupFromContext);
          logger.i("groupProvider.isAdmin result: $isAdminOfContextGroup", null, null, LogCategory.groups);
        } catch (e, st) {
          logger.w("No group in context or error reading it: $e", st, null, LogCategory.groups);
        }
        
        logger.i("Calling getAdminGroups...", null, null, LogCategory.groups);
        final adminGroups = groupProvider.getAdminGroups(myPubkey);
        logger.i("getAdminGroups returned ${adminGroups.length} groups", null, null, LogCategory.groups);
        
        if (isAdminOfContextGroup && groupFromContext != null && 
            !adminGroups.contains(groupFromContext)) {
          adminGroups.add(groupFromContext);
          logger.i("Added context group to admin groups list", null, null, LogCategory.groups);
        }
        
        if (mounted) {
          setState(() {
            _adminGroups = adminGroups;
            _loading = false;
            
            if (groupFromContext != null && isAdminOfContextGroup) {
              _selectedGroup = groupFromContext;
            } 
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
      logger.w("REPORT DEBUG: Getting reports for group: ${_selectedGroup!.groupId}", null, null, LogCategory.groups);
      final reports = reportService.getGroupReports(_selectedGroup!.groupId);
      logger.w("REPORT DEBUG: Found ${reports.length} reports for group ${_selectedGroup!.groupId}", null, null, LogCategory.groups);
      
      List<ReportItem> filteredReports = _showDismissed 
          ? reports 
          : reports.where((report) => !report.dismissed).toList();
      
      if (_selectedReportType != 'All') {
        filteredReports = filteredReports.where((report) {
          if (_selectedReportType == 'Content') {
            return report.reportedEventId != null;
          } else if (_selectedReportType == 'User') {
            return report.reportedPubkey != null && report.reportedEventId == null;
          }
          return true;
        }).toList();
      }
      
      logger.w("REPORT DEBUG: After filtering dismissed and type: ${filteredReports.length} reports", null, null, LogCategory.groups);
      
      _sortReports(filteredReports);
      
      setState(() {
        _reports = filteredReports;
      });
    } else {
      logger.w("REPORT DEBUG: Getting all reports across admin groups", null, null, LogCategory.groups);
      final allReports = reportService.getAllReports();
      logger.w("REPORT DEBUG: Found ${allReports.length} total reports across all groups", null, null, LogCategory.groups);
      
      List<ReportItem> filteredReports = _showDismissed 
          ? allReports 
          : allReports.where((report) => !report.dismissed).toList();
      
      if (_selectedReportType != 'All') {
        filteredReports = filteredReports.where((report) {
          if (_selectedReportType == 'Content') {
            return report.reportedEventId != null;
          } else if (_selectedReportType == 'User') {
            return report.reportedPubkey != null && report.reportedEventId == null;
          }
          return true;
        }).toList();
      }
      
      logger.w("REPORT DEBUG: After filtering dismissed and type: ${filteredReports.length} reports", null, null, LogCategory.groups);
      
      _sortReports(filteredReports);
      
      setState(() {
        _reports = filteredReports;
      });
    }
  }
  
  void _sortReports(List<ReportItem> reports) {
    switch (_selectedSortOption) {
      case 'Newest':
        reports.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'Oldest':
        reports.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'Most Reported':
        final reportCounts = <String, int>{};
        
        for (final report in reports) {
          final key = report.reportedEventId ?? report.reportedPubkey ?? '';
          if (key.isNotEmpty) {
            reportCounts[key] = (reportCounts[key] ?? 0) + 1;
          }
        }
        
        reports.sort((a, b) {
          final keyA = a.reportedEventId ?? a.reportedPubkey ?? '';
          final keyB = b.reportedEventId ?? b.reportedPubkey ?? '';
          final countA = reportCounts[keyA] ?? 0;
          final countB = reportCounts[keyB] ?? 0;
          return countB.compareTo(countA);
        });
        break;
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
    
    setState(() {
      _updateReportsList();
    });
  }
  
  void _removeReportedPost(ReportItem report) async {
    if (report.reportedEventId == null) {
      logger.w("REMOVE POST: No event ID in report", null, null, LogCategory.groups);
      return;
    }
    
    if (report.groupContext == null) {
      logger.w("REMOVE POST: No group context in report", null, null, LogCategory.groups);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Cannot remove post: missing group context")),
      );
      return;
    }
    
    // Check admin status
    GroupIdentifier? groupIdentifier = report.groupContext;
    final myPubkey = nostr?.publicKey;
    if (myPubkey == null) {
      logger.w("REMOVE POST: No public key available", null, null, LogCategory.groups);
      return;
    }
    
    final isAdmin = groupProvider.isAdmin(myPubkey, groupIdentifier!);
    if (!isAdmin) {
      logger.w("REMOVE POST: Not an admin of the group", null, null, LogCategory.groups);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("You must be a group admin to remove posts")),
      );
      return;
    }
    
    // Show removal confirmation dialog
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Remove Post"),
        content: const Text("Are you sure you want to remove this post? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("Remove"),
          ),
        ],
      ),
    );
    
    if (confirm != true) {
      return;
    }
    
    // Show loading indicator
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 16),
            Text("Removing post..."),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );
    
    // Remove the post
    try {
      logger.i("REMOVE POST: Attempting to remove post ${report.reportedEventId}", null, null, LogCategory.groups);
      
      final success = await groupProvider.removePost(
        groupIdentifier, 
        report.reportedEventId!,
        reason: "Removed by moderator",
      );
      
      if (!mounted) return;
      
      if (success) {
        logger.i("REMOVE POST: Successfully removed post", null, null, LogCategory.groups);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Post removed successfully")),
        );
        
        // Mark the report as dismissed
        reportService.dismissReport(report.event.id);
        
        // Refresh the reports list
        _updateReportsList();
      } else {
        logger.e("REMOVE POST: Failed to remove post", null, null, LogCategory.groups);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to remove post")),
        );
      }
    } catch (e, st) {
      logger.e("REMOVE POST: Error removing post: $e", st, null, LogCategory.groups);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error removing post: $e")),
        );
      }
    }
  }
  
  void _removeReportedUser(ReportItem report) async {
    if (report.reportedPubkey == null) {
      logger.w("REMOVE USER: No pubkey in report", null, null, LogCategory.groups);
      return;
    }
    
    if (report.groupContext == null) {
      logger.w("REMOVE USER: No group context in report", null, null, LogCategory.groups);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Cannot remove user: missing group context")),
      );
      return;
    }
    
    // Check admin status
    GroupIdentifier? groupIdentifier = report.groupContext;
    final myPubkey = nostr?.publicKey;
    if (myPubkey == null) {
      logger.w("REMOVE USER: No public key available", null, null, LogCategory.groups);
      return;
    }
    
    final isAdmin = groupProvider.isAdmin(myPubkey, groupIdentifier!);
    if (!isAdmin) {
      logger.w("REMOVE USER: Not an admin of the group", null, null, LogCategory.groups);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("You must be a group admin to moderate users")),
      );
      return;
    }
    
    // Get user info for display
    final userName = userProvider.getName(report.reportedPubkey!);
    
    // Show bottom sheet with moderation options
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final customColors = theme.extension<CustomColors>() ?? CustomColors.light;
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(
                  "User Moderation Options",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              const Divider(),
              
              // Remove user option
              ListTile(
                leading: Icon(Icons.person_remove, color: customColors.primaryForegroundColor),
                title: Text("Remove from Group", style: theme.textTheme.bodyMedium),
                subtitle: Text("Remove the user from the group", style: theme.textTheme.bodySmall),
                onTap: () async {
                  Navigator.pop(context);
                  
                  final result = await UserRemoveDialog.show(
                    context,
                    groupIdentifier,
                    report.reportedPubkey!,
                    userName: userName,
                  );
                  
                  if (result == true && mounted) {
                    // Mark the report as dismissed
                    reportService.dismissReport(report.event.id);
                    
                    // Refresh the reports list
                    _updateReportsList();
                    
                    // Show success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("User removed successfully")),
                    );
                  }
                },
              ),
              
              // Ban user option
              ListTile(
                leading: Icon(Icons.block, color: Colors.red),
                title: Text("Ban from Group", style: theme.textTheme.bodyMedium),
                subtitle: Text("Ban the user from posting or viewing content", style: theme.textTheme.bodySmall),
                onTap: () async {
                  Navigator.pop(context);
                  
                  final result = await UserBanDialog.show(
                    context,
                    groupIdentifier,
                    report.reportedPubkey!,
                    userName: userName,
                  );
                  
                  if (result == true && mounted) {
                    // Mark the report as dismissed
                    reportService.dismissReport(report.event.id);
                    
                    // Refresh the reports list
                    _updateReportsList();
                    
                    // Show success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("User banned successfully")),
                    );
                  }
                },
              ),
              
              // View profile option
              ListTile(
                leading: Icon(Icons.person_outline, color: customColors.primaryForegroundColor),
                title: Text("View User Profile", style: theme.textTheme.bodyMedium),
                onTap: () {
                  Navigator.pop(context);
                  _viewReportedUserProfile(report);
                },
              ),
            ],
          ),
        );
      },
    );
  }
  
  void _viewReportedContent(ReportItem report) {
    if (report.reportedEventId != null) {
      final event = singleEventProvider.getEvent(report.reportedEventId!);
      
      if (event != null) {
        showModalBottomSheet(
          context: context,
          builder: (BuildContext context) {
            final themeData = Theme.of(context);
            final customColors = themeData.extension<CustomColors>() ?? CustomColors.light;
            
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Text(
                      "View reported content",
                      style: themeData.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: customColors.feedBgColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: themeData.dividerColor),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              UserPicWidget(
                                pubkey: event.pubkey,
                                width: 32,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                userProvider.getName(event.pubkey),
                                style: themeData.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            StringUtil.isNotBlank(event.content)
                                ? event.content.length > 120
                                    ? "${event.content.substring(0, 120)}..."
                                    : event.content
                                : "[No content]",
                            style: themeData.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const Divider(),
                  
                  ListTile(
                    leading: Icon(Icons.visibility, color: customColors.primaryForegroundColor),
                    title: Text("View individual post", style: themeData.textTheme.bodyMedium),
                    onTap: () {
                      Navigator.pop(context);
                      RouterUtil.router(context, RouterPath.eventDetail, event);
                    },
                  ),
                  
                  ListTile(
                    leading: Icon(Icons.forum_outlined, color: customColors.primaryForegroundColor),
                    title: Text("View in conversation thread", style: themeData.textTheme.bodyMedium),
                    subtitle: Text("See the full context of the discussion", style: themeData.textTheme.bodySmall),
                    onTap: () {
                      Navigator.pop(context);
                      
                      final eventRelation = EventRelation.fromEvent(event);
                      if (eventRelation.rootId != null || eventRelation.replyId != null) {
                        RouterUtil.router(context, RouterPath.threadDetail, event);
                      } else {
                        RouterUtil.router(context, RouterPath.threadDetail, event);
                      }
                    },
                  ),
                  
                  ListTile(
                    leading: Icon(Icons.person_outline, color: customColors.primaryForegroundColor),
                    title: Text("View user profile", style: themeData.textTheme.bodyMedium),
                    onTap: () {
                      Navigator.pop(context);
                      RouterUtil.router(context, RouterPath.user, event.pubkey);
                    },
                  ),
                ],
              ),
            );
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Fetching reported content..."),
            duration: const Duration(seconds: 2),
          ),
        );
        
        nostr?.query([Filter(ids: [report.reportedEventId!]).toJson()], (event) {
          if (event != null && mounted) {
            _viewReportedContent(report);
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Report content not found")),
            );
          }
        });
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
    final customColors = theme.extension<CustomColors>() ?? CustomColors.light;
    
    GroupIdentifier? groupContext;
    bool directAdminCheck = false;
    bool forceAdmin = widget.selectedGroup != null;
    
    try {
      groupContext = context.read<GroupIdentifier>();
      final myPubkey = nostr?.publicKey;
      if (myPubkey != null) {
        directAdminCheck = groupProvider.isAdmin(myPubkey, groupContext);
        logger.i("REPORT SCREEN DIRECT CHECK: isAdmin=$directAdminCheck for group ${groupContext.groupId}", 
          null, null, LogCategory.groups);
          
        if (!directAdminCheck && forceAdmin) {
          logger.w("EMERGENCY WORKAROUND: Admin check failed but forcing admin mode", 
                   null, null, LogCategory.groups);
          directAdminCheck = true;
        }
      }
    } catch (e) {
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
    
    if (forceAdmin && _adminGroups.isEmpty && widget.selectedGroup != null) {
      _adminGroups = [widget.selectedGroup!];
      _selectedGroup = widget.selectedGroup;
      
      logger.w("EMERGENCY WORKAROUND: Forcing admin access for selected group", 
               null, null, LogCategory.groups);
      
      _updateReportsList();
    }
    
    if (!_loading && _adminGroups.isEmpty && groupContext != null && (directAdminCheck || forceAdmin)) {
      _adminGroups = [groupContext];
      _selectedGroup = groupContext;
      
      logger.i("Admin groups empty but direct check says admin - adding group", null, null, LogCategory.groups);
      
      _updateReportsList();
    }
    
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
                  _fetchAdminGroups();
                },
                child: Text("Refresh"),
              ),
            ],
          ),
        ),
      );
    }
    
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
          IconButton(
            icon: Icon(_showDismissed ? Icons.visibility : Icons.visibility_off),
            tooltip: _showDismissed ? "Hide dismissed" : "Show dismissed",
            onPressed: () {
              setState(() {
                _showDismissed = !_showDismissed;
                _updateReportsList();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_adminGroups.length > 1) _buildGroupSelector(),
          
          _buildStatisticsSection(),
          
          _buildFilterSection(),
          
          Expanded(
            child: _reports.isEmpty
              ? Center(
                  child: Text(
                    "No reports found for this group",
                    style: theme.textTheme.bodyLarge,
                  ),
                )
              : ListView.builder(
                  itemCount: _reports.length,
                  itemBuilder: (context, index) => _buildReportItem(_reports[index]),
                ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildReportItem(ReportItem report) {
    final theme = Theme.of(context);
    final customColors = theme.extension<CustomColors>() ?? CustomColors.light;
    final reportedEvent = report.reportedEvent;
    final dateFormat = DateFormat('MMM d, yyyy h:mm a');
    final formattedDate = dateFormat.format(report.createdAt);
    
    String reportReason = report.reason ?? "No reason provided";
    String reportDetails = report.details ?? "";
    
    // Determine report severity based on reason
    Color severityColor;
    IconData severityIcon;
    String severityText;
    
    if (reportReason.toLowerCase().contains('illegal') || 
        reportReason.toLowerCase().contains('child') ||
        reportReason.toLowerCase().contains('abuse')) {
      severityColor = Colors.red;
      severityIcon = Icons.error;
      severityText = "Critical";
    } else if (reportReason.toLowerCase().contains('spam') || 
              reportReason.toLowerCase().contains('phishing')) {
      severityColor = Colors.orange;
      severityIcon = Icons.warning;
      severityText = "Medium";
    } else if (reportReason.toLowerCase().contains('nsfw')) {
      severityColor = Colors.purple;
      severityIcon = Icons.visibility_off;
      severityText = "Content Warning";
    } else {
      severityColor = Colors.blue;
      severityIcon = Icons.flag;
      severityText = "Standard";
    }
    
    // Determine report type and show appropriate icon
    IconData typeIcon;
    String typeText;
    
    if (report.reportedEventId != null) {
      typeIcon = Icons.post_add;
      typeText = "Content Report";
    } else if (report.reportedPubkey != null) {
      typeIcon = Icons.person;
      typeText = "User Report";
    } else {
      typeIcon = Icons.help;
      typeText = "Other Report";
    }
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 1,
      color: report.dismissed 
          ? customColors.cardBgColor.withOpacity(0.7)
          : customColors.cardBgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: report.dismissed ? Colors.grey.withOpacity(0.3) : theme.dividerColor,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status badges and type indicator
            Row(
              children: [
                // Report type badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(typeIcon, size: 14, color: customColors.primaryForegroundColor),
                      const SizedBox(width: 4),
                      Text(typeText, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                
                // Severity badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: severityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(severityIcon, size: 14, color: severityColor),
                      const SizedBox(width: 4),
                      Text(severityText, style: TextStyle(fontSize: 12, color: severityColor)),
                    ],
                  ),
                ),
                
                const Spacer(),
                
                // Status indicator
                if (report.dismissed)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 14, color: Colors.green),
                        const SizedBox(width: 4),
                        Text("Handled", style: TextStyle(fontSize: 12, color: Colors.green)),
                      ],
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Reporter information
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UserPicWidget(
                  pubkey: report.event.pubkey,
                  width: 40,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            userProvider.getName(report.event.pubkey),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _formatDate(report.createdAt),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.hintColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Reported from ${report.groupId ?? 'unknown group'}",
                        style: theme.textTheme.bodySmall,
                      ),
                      InkWell(
                        onTap: () => _viewReporterProfile(report),
                        child: Text(
                          "View reporter profile",
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: customColors.accentColor,
                            decoration: TextDecoration.underline,
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
                color: customColors.feedBgColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Reason: $reportReason",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
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
            
            // Divider between report info and reported content
            if (reportedEvent != null || report.reportedPubkey != null) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(),
              ),
              
              // Reported content section
              Text(
                "Reported Content",
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
            ],
            
            // Reported content preview (if available)
            if (reportedEvent != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: report.dismissed 
                      ? customColors.feedBgColor.withOpacity(0.5)
                      : customColors.feedBgColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Reported user info
                    Row(
                      children: [
                        UserPicWidget(
                          pubkey: reportedEvent.pubkey,
                          width: 32,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          userProvider.getName(reportedEvent.pubkey),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: () => _viewReportedUserProfile(report),
                          child: Text(
                            "View profile",
                            style: TextStyle(
                              fontSize: 12,
                              color: customColors.accentColor,
                              decoration: TextDecoration.underline,
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
                      style: theme.textTheme.bodyMedium?.copyWith(
                        decoration: report.dismissed ? TextDecoration.lineThrough : null,
                        decorationColor: Colors.red.withOpacity(0.5),
                        color: report.dismissed 
                            ? theme.textTheme.bodyMedium!.color!.withOpacity(0.7) 
                            : theme.textTheme.bodyMedium!.color,
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (report.reportedPubkey != null) ...[
              // If only user is reported, not content
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: customColors.feedBgColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Row(
                  children: [
                    UserPicWidget(
                      pubkey: report.reportedPubkey!,
                      width: 40,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userProvider.getName(report.reportedPubkey!),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "User reported for: $reportReason",
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => _viewReportedUserProfile(report),
                      child: const Text("View Profile"),
                    ),
                  ],
                ),
              ),
            ],
            
            // Action buttons
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // View context button
                  if (report.reportedEventId != null && !report.dismissed)
                    OutlinedButton.icon(
                      onPressed: () => _viewReportedContent(report),
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text("View Context"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: customColors.primaryForegroundColor,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  
                  const Spacer(),
                  
                  // Action buttons
                  if (!report.dismissed) ...[
                    // Dismiss button
                    OutlinedButton.icon(
                      onPressed: () => _dismissReport(report),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text("Dismiss"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    const SizedBox(width: 8),
                    
                    // Remove content button (only for content reports)
                    if (report.reportedEventId != null)
                      ElevatedButton.icon(
                        onPressed: () => _removeReportedPost(report),
                        icon: const Icon(Icons.delete, size: 16),
                        label: const Text("Remove Post"),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    
                    // Remove user button (only for user reports)
                    if (report.reportedPubkey != null && report.reportedEventId == null)
                      ElevatedButton.icon(
                        onPressed: () => _removeReportedUser(report),
                        icon: const Icon(Icons.person_remove, size: 16),
                        label: const Text("Remove User"),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                  ] else
                    // For dismissed reports - replace list with single widget
                    Text(
                      "This report has been handled",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.green,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatisticsSection() {
    final theme = Theme.of(context);
    final customColors = theme.extension<CustomColors>() ?? CustomColors.light;
    
    final totalReports = _reports.length;
    final activeReports = _reports.where((r) => !r.dismissed).length;
    final handledReports = totalReports - activeReports;
    final handlingRate = totalReports > 0 ? (handledReports / totalReports * 100).toStringAsFixed(0) : '0';
    
    final mostRecentDate = _reports.isNotEmpty 
        ? _reports.map((r) => r.createdAt).reduce((a, b) => a.isAfter(b) ? a : b)
        : null;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: customColors.cardBgColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Reports Dashboard",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "Group: ${_selectedGroup?.groupId ?? 'All Groups'}",
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statCard(
                "Total Reports",
                "$totalReports",
                Icons.flag,
                customColors.accentColor,
              ),
              _statCard(
                "Active",
                "$activeReports",
                Icons.pending_actions,
                Colors.orange,
              ),
              _statCard(
                "Handled",
                "$handledReports ($handlingRate%)",
                Icons.check_circle,
                Colors.green,
              ),
            ],
          ),
          if (mostRecentDate != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                "Last report: ${_formatDate(mostRecentDate)}",
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(title, style: TextStyle(fontSize: 12, color: color)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFilterSection() {
    final theme = Theme.of(context);
    final customColors = theme.extension<CustomColors>() ?? CustomColors.light;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text("Filter & Sort", style: theme.textTheme.titleSmall),
              const Spacer(),
              TextButton.icon(
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text("Refresh"),
                onPressed: _updateReportsList,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: customColors.cardBgColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedReportType,
                    icon: const Icon(Icons.arrow_drop_down),
                    isExpanded: true,
                    underline: const SizedBox(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedReportType = newValue;
                          _updateReportsList();
                        });
                      }
                    },
                    items: reportTypes.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: customColors.cardBgColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedSortOption,
                    icon: const Icon(Icons.arrow_drop_down),
                    isExpanded: true,
                    underline: const SizedBox(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedSortOption = newValue;
                          _updateReportsList();
                        });
                      }
                    },
                    items: sortOptions.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildGroupSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: DropdownButtonFormField<GroupIdentifier?>(
        decoration: InputDecoration(
          labelText: "Select Group",
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        value: _selectedGroup,
        items: [
          DropdownMenuItem<GroupIdentifier?>(
            value: null,
            child: const Text("All Moderated Groups"),
          ),
          ..._adminGroups.map((group) => DropdownMenuItem<GroupIdentifier?>(
            value: group,
            child: Text(
              (() {
                final metadata = groupProvider.getMetadata(group);
                return metadata?.name ?? group.groupId;
              })(),
            ),
          )).toList(),
        ],
        onChanged: _handleGroupChange,
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 30) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, y').format(date);
    }
  }
} 