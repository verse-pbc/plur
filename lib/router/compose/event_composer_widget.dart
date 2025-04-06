import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:nostrmo/component/cust_state.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/generated/l10n.dart';
import 'package:nostrmo/main.dart';
import 'package:nostrmo/router/edit/editor_widget.dart';
import 'package:nostrmo/util/router_util.dart';

class EventComposerWidget extends StatefulWidget {
  final int eventKind;
  final List<dynamic>? customTags;

  const EventComposerWidget({
    Key? key,
    required this.eventKind,
    this.customTags,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _EventComposerWidgetState();
  }
}

class _EventComposerWidgetState extends CustState<EventComposerWidget> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  DateTime _eventDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _eventTime = TimeOfDay.now();
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }
  
  @override
  Future<void> onReady(BuildContext context) async {
    // No initialization needed
  }

  @override
  Widget doBuild(BuildContext context) {
    final localization = S.of(context);
    final themeData = Theme.of(context);
    final textColor = themeData.textTheme.bodyMedium!.color;
    final cardColor = themeData.cardColor;
    final primaryColor = themeData.primaryColor;
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: cardColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            RouterUtil.back(context);
          },
        ),
        title: Text(
          localization.Create_Event,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _createEvent,
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(themeData.colorScheme.primary),
              shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18.0),
                ),
              ),
              padding: MaterialStateProperty.all(
                const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
            child: Text(
              localization.Create,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Title
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: localization.Event_Title,
                hintText: localization.Enter_Event_Title,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              maxLines: 1,
            ),
            const SizedBox(height: 16),
            
            // Event Description
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: localization.Description,
                hintText: localization.Enter_Event_Description,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            
            // Event Location
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: localization.Location,
                hintText: localization.Enter_Event_Location,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              maxLines: 1,
            ),
            const SizedBox(height: 24),
            
            // Event Date & Time
            Text(
              localization.Date_and_Time,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _selectDate,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: localization.Date,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(DateFormat('EEE, MMM d, yyyy').format(_eventDate)),
                          const Icon(Icons.calendar_today, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: _selectTime,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: localization.Time,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_eventTime.format(context)),
                          const Icon(Icons.access_time, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Advanced Options (could be expanded in the future)
            ExpansionTile(
              title: Text(localization.Advanced_Options),
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              children: [
                // Could add more options here like:
                // - Event image
                // - Repeating events
                // - Ticket information
                // - External link
                
                // For now, just a note about event publication
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    localization.Event_Publish_Note,
                    style: TextStyle(
                      color: themeData.hintColor,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _eventDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null && picked != _eventDate) {
      setState(() {
        _eventDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _eventTime,
    );
    if (picked != null && picked != _eventTime) {
      setState(() {
        _eventTime = picked;
      });
    }
  }

  // Method to create and publish the event
  void _createEvent() {
    if (_titleController.text.isEmpty) {
      // Show error for missing title
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).Event_Title_Required)),
      );
      return;
    }

    // Combine date and time
    final eventDateTime = DateTime(
      _eventDate.year,
      _eventDate.month,
      _eventDate.day,
      _eventTime.hour,
      _eventTime.minute,
    );
    
    // Build tags for the event
    List<dynamic> tags = [];
    
    // Add custom tags if they exist
    if (widget.customTags != null) {
      tags.addAll(widget.customTags!);
    }
    
    // Add event-specific tags
    tags.add(["title", _titleController.text]);
    tags.add(["description", _descriptionController.text]);
    tags.add(["start", (eventDateTime.millisecondsSinceEpoch ~/ 1000).toString()]);
    
    if (_locationController.text.isNotEmpty) {
      tags.add(["location", _locationController.text]);
    }
    
    // Optional: Add end time, status, etc.
    
    // Create the content combining the details
    final content = [
      "Event: ${_titleController.text}",
      "",
      _descriptionController.text,
      "",
      "When: ${DateFormat('EEEE, MMMM d, yyyy').format(_eventDate)} at ${_eventTime.format(context)}",
      if (_locationController.text.isNotEmpty) "Where: ${_locationController.text}",
    ].join("\n");
    
    // Create event
    final event = Event(
      nostr!.publicKey,
      widget.eventKind, // Using the event kind from widget
      tags,
      content,
    );
    
    // Sign and send the event
    nostr!.signEvent(event);
    nostr!.sendEvent(event);
    
    // Return to previous screen
    RouterUtil.back(context, event);
  }
}