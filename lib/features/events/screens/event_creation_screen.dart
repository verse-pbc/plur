import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nostrmo/features/events/models/event_model.dart';
import 'package:nostrmo/features/events/providers/event_provider.dart';
import 'package:nostrmo/generated/l10n.dart';
import 'package:nostrmo/util/theme_util.dart';
import 'package:nostrmo/util/group_id_util.dart';
import 'package:nostrmo/util/app_logger.dart';

/// Screen for creating or editing an event
class EventCreationScreen extends ConsumerStatefulWidget {
  /// Group context for this event
  final String groupId;
  
  /// Optional existing event to edit
  final EventModel? existingEvent;

  /// Constructor
  const EventCreationScreen({
    required this.groupId, 
    this.existingEvent, 
    super.key,
  });

  @override
  ConsumerState<EventCreationScreen> createState() => _EventCreationScreenState();
}

class _EventCreationScreenState extends ConsumerState<EventCreationScreen> {
  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _coverImageController = TextEditingController();
  final _capacityController = TextEditingController();
  final _costController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  // Event data
  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  DateTime _startTime = DateTime(
    DateTime.now().year, 
    DateTime.now().month,
    DateTime.now().day, 
    18, 0
  ); // Default to 6:00 PM
  
  DateTime? _endDate;
  DateTime? _endTime;
  
  EventVisibility _visibility = EventVisibility.public;
  List<String> _eventTags = [];
  
  // State variables
  bool _isSubmitting = false;
  
  @override
  void initState() {
    super.initState();
    
    // If editing an existing event, populate form fields
    if (widget.existingEvent != null) {
      _populateFormFields();
    }
  }
  
  void _populateFormFields() {
    final event = widget.existingEvent!;
    
    _titleController.text = event.title;
    _descriptionController.text = event.description;
    _locationController.text = event.location ?? '';
    _coverImageController.text = event.coverImageUrl ?? '';
    _capacityController.text = event.capacity?.toString() ?? '';
    _costController.text = event.cost ?? '';
    
    _startDate = DateTime(
      event.startAt.year,
      event.startAt.month,
      event.startAt.day,
    );
    
    _startTime = DateTime(
      event.startAt.year,
      event.startAt.month,
      event.startAt.day,
      event.startAt.hour,
      event.startAt.minute,
    );
    
    if (event.endAt != null) {
      _endDate = DateTime(
        event.endAt!.year,
        event.endAt!.month,
        event.endAt!.day,
      );
      
      _endTime = DateTime(
        event.endAt!.year,
        event.endAt!.month,
        event.endAt!.day,
        event.endAt!.hour,
        event.endAt!.minute,
      );
    }
    
    _visibility = event.visibility;
    _eventTags = List<String>.from(event.tags);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _coverImageController.dispose();
    _capacityController.dispose();
    _costController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final customColors = themeData.customColors;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingEvent != null ? "Edit Event" : "Create an Event"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: customColors.feedBgColor,
        foregroundColor: themeData.primaryColor,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Title
              _buildSectionTitle("Title", themeData),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: "Add a title for your event",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Please enter a title";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              // Description
              _buildSectionTitle("Description", themeData),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  hintText: "Describe what your event is about",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Please enter a description";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              // Date and time
              _buildSectionTitle("Date and Time", themeData),
              
              // Start date and time
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: InkWell(
                      onTap: () => _selectStartDate(context),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: "Start Date",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          DateFormat.yMMMd().format(_startDate),
                          style: themeData.textTheme.bodyLarge,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: InkWell(
                      onTap: () => _selectStartTime(context),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: "Start Time",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          DateFormat.jm().format(_startTime),
                          style: themeData.textTheme.bodyLarge,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // End date and time
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Checkbox(
                    value: _endDate != null,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _endDate = _startDate;
                          _endTime = DateTime(
                            _startDate.year,
                            _startDate.month,
                            _startDate.day,
                            _startTime.hour + 2, // Default to 2 hours after start
                            _startTime.minute,
                          );
                        } else {
                          _endDate = null;
                          _endTime = null;
                        }
                      });
                    },
                    activeColor: customColors.accentColor,
                  ),
                  Text(
                    "Include end date/time",
                    style: themeData.textTheme.bodyMedium,
                  ),
                ],
              ),
              
              if (_endDate != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: InkWell(
                          onTap: () => _selectEndDate(context),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: "End Date",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              DateFormat.yMMMd().format(_endDate!),
                              style: themeData.textTheme.bodyLarge,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: InkWell(
                          onTap: () => _selectEndTime(context),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: "End Time",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              DateFormat.jm().format(_endTime!),
                              style: themeData.textTheme.bodyLarge,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              
              // Location
              _buildSectionTitle("Location", themeData),
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  hintText: "Add a location or virtual meeting link",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Visibility
              _buildSectionTitle("Visibility", themeData),
              DropdownButtonFormField<EventVisibility>(
                value: _visibility,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: [
                  DropdownMenuItem(
                    value: EventVisibility.public,
                    child: Text("Public"),
                  ),
                  DropdownMenuItem(
                    value: EventVisibility.publicLink,
                    child: Text("Unlisted"),
                  ),
                  DropdownMenuItem(
                    value: EventVisibility.private,
                    child: Text("Private"),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _visibility = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 24),
              
              // Additional info section
              ExpansionTile(
                title: Text(
                  "Additional Info",
                  style: themeData.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                children: [
                  // Cover image URL
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: TextFormField(
                      controller: _coverImageController,
                      decoration: InputDecoration(
                        labelText: "Cover Image URL",
                        hintText: 'https://example.com/image.jpg',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  
                  // Capacity
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: TextFormField(
                      controller: _capacityController,
                      decoration: InputDecoration(
                        labelText: "Capacity",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  
                  // Cost
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: TextFormField(
                      controller: _costController,
                      decoration: InputDecoration(
                        labelText: "Cost",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  
                  // Tags (placeholder for now)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: "Event Tags",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Wrap(
                        spacing: 8,
                        children: [
                          if (_eventTags.isEmpty)
                            Text(
                              "No tags added",
                              style: TextStyle(
                                color: customColors.secondaryForegroundColor,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ..._eventTags.map((tag) => Chip(
                            label: Text(tag),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () {
                              setState(() {
                                _eventTags.remove(tag);
                              });
                            },
                          )).toList(),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () => _addTag(context),
                            tooltip: "Add Tag",
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitEvent,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: themeData.primaryColor,
                  ),
                  child: _isSubmitting 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                      widget.existingEvent != null ? "Save Changes" : "Create Event",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSectionTitle(String title, ThemeData themeData) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: themeData.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)), // 2 years in future
    );
    
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
        
        // If end date exists, ensure it's not before start date
        if (_endDate != null && _endDate!.isBefore(_startDate)) {
          _endDate = _startDate;
        }
      });
    }
  }
  
  Future<void> _selectStartTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _startTime.hour, minute: _startTime.minute),
    );
    
    if (picked != null) {
      setState(() {
        _startTime = DateTime(
          _startDate.year,
          _startDate.month,
          _startDate.day,
          picked.hour,
          picked.minute,
        );
        
        // If end time exists on same date, ensure it's not before start time
        if (_endDate != null && _endTime != null && 
            _endDate!.year == _startDate.year && 
            _endDate!.month == _startDate.month && 
            _endDate!.day == _startDate.day && 
            _endTime!.isBefore(_startTime)) {
          _endTime = DateTime(
            _endDate!.year,
            _endDate!.month,
            _endDate!.day,
            _startTime.hour + 2, // Default to 2 hours after start
            _startTime.minute,
          );
        }
      });
    }
  }
  
  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate,
      firstDate: _startDate, // End date must be >= start date
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)), // 2 years in future
    );
    
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }
  
  Future<void> _selectEndTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _endTime != null 
          ? TimeOfDay(hour: _endTime!.hour, minute: _endTime!.minute)
          : TimeOfDay(hour: _startTime.hour + 2, minute: _startTime.minute),
    );
    
    if (picked != null) {
      setState(() {
        _endTime = DateTime(
          _endDate!.year,
          _endDate!.month,
          _endDate!.day,
          picked.hour,
          picked.minute,
        );
        
        // If end date is same as start date, ensure end time is after start time
        if (_endDate!.year == _startDate.year && 
            _endDate!.month == _startDate.month && 
            _endDate!.day == _startDate.day) {
          final startDateTime = DateTime(
            _startDate.year,
            _startDate.month,
            _startDate.day,
            _startTime.hour,
            _startTime.minute,
          );
          
          final endDateTime = DateTime(
            _endDate!.year,
            _endDate!.month,
            _endDate!.day,
            _endTime!.hour,
            _endTime!.minute,
          );
          
          if (endDateTime.isBefore(startDateTime)) {
            _endTime = DateTime(
              _endDate!.year,
              _endDate!.month,
              _endDate!.day,
              _startTime.hour + 2, // Default to 2 hours after start
              _startTime.minute,
            );
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(S.of(context).endTimeMustBeAfterStart)),
            );
          }
        }
      });
    }
  }
  
  void _addTag(BuildContext context) {
    // Show dialog to add a tag
    final textController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Tag"),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            hintText: "Tag Name",
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.none,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              final tag = textController.text.trim();
              if (tag.isNotEmpty && !_eventTags.contains(tag)) {
                setState(() {
                  _eventTags.add(tag);
                });
              }
              Navigator.of(context).pop();
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }
  
  Future<void> _submitEvent() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    try {
      logger.d('Submitting event form...');
      setState(() {
        _isSubmitting = true;
      });
      
      // Combine date and time
      final startDateTime = DateTime(
        _startDate.year,
        _startDate.month,
        _startDate.day,
        _startTime.hour,
        _startTime.minute,
      );
      
      DateTime? endDateTime;
      if (_endDate != null && _endTime != null) {
        endDateTime = DateTime(
          _endDate!.year,
          _endDate!.month,
          _endDate!.day,
          _endTime!.hour,
          _endTime!.minute,
        );
      }
      
      // Create capacity int if provided
      int? capacity;
      if (_capacityController.text.isNotEmpty) {
        try {
          capacity = int.parse(_capacityController.text);
        } catch (e) {
          // Ignore parsing errors
        }
      }
      
      // Process the group ID
      final standardizedGroupId = GroupIdUtil.standardizeGroupIdString(widget.groupId);
      
      // Check if we're creating or updating
      if (widget.existingEvent != null) {
        // Update existing event
        await ref.read(eventProvider.notifier).updateEvent(
          widget.existingEvent!.copyWith(
            title: _titleController.text,
            description: _descriptionController.text,
            coverImageUrl: _coverImageController.text.isEmpty ? null : _coverImageController.text,
            startAt: startDateTime,
            endAt: endDateTime,
            location: _locationController.text.isEmpty ? null : _locationController.text,
            capacity: capacity,
            cost: _costController.text.isEmpty ? null : _costController.text,
            groupId: standardizedGroupId,
            visibility: _visibility,
            tags: _eventTags,
          ),
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Event updated successfully")),
          );
          Navigator.of(context).pop(true); // Return success
        }
      } else {
        // Create new event
        await ref.read(eventProvider.notifier).createEvent(
          title: _titleController.text,
          description: _descriptionController.text,
          coverImageUrl: _coverImageController.text.isEmpty ? null : _coverImageController.text,
          startAt: startDateTime,
          endAt: endDateTime,
          location: _locationController.text.isEmpty ? null : _locationController.text,
          capacity: capacity,
          cost: _costController.text.isEmpty ? null : _costController.text,
          groupId: standardizedGroupId,
          visibility: _visibility,
          tags: _eventTags,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Event created successfully")),
          );
          Navigator.of(context).pop(true); // Return success
        }
      }
    } catch (e, stack) {
      logger.e('Error creating event', e, stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error occurred: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}