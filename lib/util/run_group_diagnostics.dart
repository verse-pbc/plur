import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nostrmo/provider/group_feed_provider.dart';
import 'package:nostrmo/provider/group_read_status_provider.dart';
import 'package:nostrmo/provider/list_provider.dart';
import 'package:nostrmo/util/group_feed_diagnostics.dart';

/// A simple widget that runs the group diagnostics and displays the results
class GroupDiagnosticPage extends StatefulWidget {
  const GroupDiagnosticPage({super.key});

  @override
  State<GroupDiagnosticPage> createState() => _GroupDiagnosticPageState();
}

class _GroupDiagnosticPageState extends State<GroupDiagnosticPage> {
  String _diagnosticResults = "No diagnostics run yet.";
  bool _isRunning = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Feed Diagnostics'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _isRunning ? null : _runDiagnostics,
                  child: const Text('Run Diagnostics'),
                ),
                ElevatedButton(
                  onPressed: _isRunning ? null : _forceUpdateCounts,
                  child: const Text('Force Update Counts'),
                ),
                ElevatedButton(
                  onPressed: _isRunning ? null : _refreshFeed,
                  child: const Text('Refresh Feed'),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Results heading
            const Text(
              'Diagnostic Results:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            
            const SizedBox(height: 8),
            
            // Progress indicator when running
            if (_isRunning)
              const Center(
                child: CircularProgressIndicator(),
              ),
            
            // Results output
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: SingleChildScrollView(
                  child: Text(_diagnosticResults),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _runDiagnostics() async {
    // Get the providers
    final listProvider = Provider.of<ListProvider>(context, listen: false);
    final feedProvider = Provider.of<GroupFeedProvider>(context, listen: false);
    
    // The read status provider might not be available directly
    GroupReadStatusProvider? readStatusProvider;
    try {
      readStatusProvider = Provider.of<GroupReadStatusProvider>(context, listen: false);
    } catch (e) {
      setState(() {
        _diagnosticResults = "ERROR: Could not access GroupReadStatusProvider: $e\n\n"
            "This suggests the provider is not properly registered in the widget tree.";
      });
      return;
    }
    
    if (readStatusProvider == null) {
      setState(() {
        _diagnosticResults = "ERROR: GroupReadStatusProvider is null.";
      });
      return;
    }
    
    // Set running state
    setState(() {
      _isRunning = true;
      _diagnosticResults = "Running diagnostics...";
    });
    
    // Use a delayed future to allow the UI to update
    await Future.delayed(const Duration(milliseconds: 100));
    
    try {
      // Redirect logs to a string
      final outputBuffer = StringBuffer();
      outputBuffer.writeln("====== DIAGNOSTIC RESULTS ======");
      outputBuffer.writeln("Time: ${DateTime.now()}");
      outputBuffer.writeln("");
      
      // Run diagnostics (logs will go to the console)
      GroupFeedDiagnostics.diagnoseGroupFeeds(
        feedProvider: feedProvider,
        readStatusProvider: readStatusProvider,
        listProvider: listProvider,
      );
      
      // Add a note that detailed results are in the console
      outputBuffer.writeln("Diagnostic complete. See detailed results in the debug console.");
      
      // Add summary information to the output
      outputBuffer.writeln("\n===== SUMMARY =====");
      outputBuffer.writeln("Groups: ${listProvider.groupIdentifiers.length}");
      outputBuffer.writeln("Posts in main box: ${feedProvider.notesBox.length()}");
      outputBuffer.writeln("Posts in new box: ${feedProvider.newNotesBox.length()}");
      outputBuffer.writeln("Posts in static cache: ${feedProvider.staticEventCache.length}");
      
      // Show unread counts for each group
      outputBuffer.writeln("\n===== GROUP COUNTS =====");
      for (final group in listProvider.groupIdentifiers) {
        final readInfo = readStatusProvider.getReadInfo(group);
        outputBuffer.writeln("${group.groupId}: ${readInfo.postCount} posts, ${readInfo.unreadCount} unread");
      }
      
      // Update the UI
      setState(() {
        _diagnosticResults = outputBuffer.toString();
        _isRunning = false;
      });
    } catch (e, stack) {
      setState(() {
        _diagnosticResults = "ERROR: $e\n\nStack trace:\n$stack";
        _isRunning = false;
      });
    }
  }

  void _forceUpdateCounts() async {
    // Get the providers
    final listProvider = Provider.of<ListProvider>(context, listen: false);
    final feedProvider = Provider.of<GroupFeedProvider>(context, listen: false);
    
    // The read status provider might not be available directly
    GroupReadStatusProvider? readStatusProvider;
    try {
      readStatusProvider = Provider.of<GroupReadStatusProvider>(context, listen: false);
    } catch (e) {
      setState(() {
        _diagnosticResults = "ERROR: Could not access GroupReadStatusProvider: $e";
      });
      return;
    }
    
    if (readStatusProvider == null) {
      setState(() {
        _diagnosticResults = "ERROR: GroupReadStatusProvider is null.";
      });
      return;
    }
    
    // Set running state
    setState(() {
      _isRunning = true;
      _diagnosticResults = "Forcing update of all group read counts...";
    });
    
    // Use a delayed future to allow the UI to update
    await Future.delayed(const Duration(milliseconds: 100));
    
    try {
      // Force update
      feedProvider.updateAllGroupReadCounts();
      
      // Build result output
      final outputBuffer = StringBuffer();
      outputBuffer.writeln("====== UPDATE COMPLETE ======");
      outputBuffer.writeln("Time: ${DateTime.now()}");
      outputBuffer.writeln("");
      
      // Show updated counts for each group
      for (final group in listProvider.groupIdentifiers) {
        final readInfo = readStatusProvider.getReadInfo(group);
        outputBuffer.writeln("${group.groupId}: ${readInfo.postCount} posts, ${readInfo.unreadCount} unread");
      }
      
      // Update the UI
      setState(() {
        _diagnosticResults = outputBuffer.toString();
        _isRunning = false;
      });
    } catch (e, stack) {
      setState(() {
        _diagnosticResults = "ERROR: $e\n\nStack trace:\n$stack";
        _isRunning = false;
      });
    }
  }

  void _refreshFeed() async {
    // Get the feed provider
    final feedProvider = Provider.of<GroupFeedProvider>(context, listen: false);
    
    // Set running state
    setState(() {
      _isRunning = true;
      _diagnosticResults = "Refreshing feed...";
    });
    
    // Use a delayed future to allow the UI to update
    await Future.delayed(const Duration(milliseconds: 100));
    
    try {
      // Call refresh
      feedProvider.refresh();
      
      // Update the UI
      setState(() {
        _diagnosticResults = "Feed refresh initiated at ${DateTime.now()}.\n\n"
            "Check the debug console for more information.\n\n"
            "Run diagnostics after a few seconds to see the results.";
        _isRunning = false;
      });
    } catch (e, stack) {
      setState(() {
        _diagnosticResults = "ERROR: $e\n\nStack trace:\n$stack";
        _isRunning = false;
      });
    }
  }
}