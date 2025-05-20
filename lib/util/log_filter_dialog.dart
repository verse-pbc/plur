import 'package:flutter/material.dart';
import 'package:nostrmo/component/styled_input_field_widget.dart';
import 'package:nostrmo/util/app_logger.dart';

/// A dialog that allows runtime configuration of logging filters
class LogFilterDialog extends StatefulWidget {
  /// Constructor
  const LogFilterDialog({Key? key}) : super(key: key);

  /// Show the log filter dialog
  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => const LogFilterDialog(),
    );
  }

  @override
  State<LogFilterDialog> createState() => _LogFilterDialogState();
}

class _LogFilterDialogState extends State<LogFilterDialog> {
  // Track which categories are active
  final Map<LogCategory, bool> _categoryStates = {};
  
  // New tag to add
  final _tagController = TextEditingController();
  
  // List of excluded tags
  late List<String> _excludedTags;
  
  // Debug override state
  late bool _debugOverride;

  @override
  void initState() {
    super.initState();
    
    // Initialize category states
    for (final category in LogCategory.values) {
      _categoryStates[category] = logger.isCategoryActive(category);
    }
    
    // Get excluded tags
    _excludedTags = logger.getExcludedTags();
    
    // Debug override is initially false
    _debugOverride = false;
  }

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }

  void _updateCategories() {
    final activeCategories = _categoryStates.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
    
    logger.filterByCategories(activeCategories);
  }

  void _addExcludedTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_excludedTags.contains(tag)) {
      setState(() {
        logger.addExcludedTag(tag);
        _excludedTags = logger.getExcludedTags();
        _tagController.clear();
      });
    }
  }

  void _removeExcludedTag(String tag) {
    setState(() {
      logger.removeExcludedTag(tag);
      _excludedTags = logger.getExcludedTags();
    });
  }

  void _toggleDebugOverride(bool value) {
    setState(() {
      _debugOverride = value;
      logger.enableDebugOverride(value);
    });
  }

  void _resetAllFilters() {
    setState(() {
      logger.clearCategoryFilters();
      _excludedTags.forEach(logger.removeExcludedTag);
      _excludedTags = [];
      _debugOverride = false;
      logger.enableDebugOverride(false);
      
      // Reset category states
      for (final category in LogCategory.values) {
        _categoryStates[category] = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(16.0),
        constraints: const BoxConstraints(
          maxWidth: 500,
          maxHeight: 600,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Log Filter Settings',
                  style: theme.textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(),
            
            // Debug override
            SwitchListTile(
              title: const Text('Debug Override (Show All Logs)'),
              subtitle: const Text('Bypasses all filters - use carefully!'),
              value: _debugOverride,
              onChanged: _toggleDebugOverride,
            ),
            
            const Divider(),
            
            // Log categories
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                'Log Categories',
                style: theme.textTheme.titleMedium,
              ),
            ),
            
            Expanded(
              child: ListView(
                children: LogCategory.values.map((category) {
                  return CheckboxListTile(
                    title: Text(category.name),
                    value: _categoryStates[category] ?? true,
                    onChanged: (value) {
                      setState(() {
                        _categoryStates[category] = value ?? false;
                        _updateCategories();
                      });
                    },
                  );
                }).toList(),
              ),
            ),
            
            const Divider(),
            
            // Excluded tags
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                'Excluded Tags',
                style: theme.textTheme.titleMedium,
              ),
            ),
            
            Row(
              children: [
                Expanded(
                  child: StyledInputFieldWidget(
                    controller: _tagController,
                    hintText: 'Enter tag to exclude',
                    onSubmitted: (_) => _addExcludedTag(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addExcludedTag,
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _excludedTags.map((tag) {
                return Chip(
                  label: Text(tag),
                  onDeleted: () => _removeExcludedTag(tag),
                );
              }).toList(),
            ),
            
            const Divider(),
            
            // Reset button
            Center(
              child: ElevatedButton(
                onPressed: _resetAllFilters,
                child: const Text('Reset All Filters'),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 