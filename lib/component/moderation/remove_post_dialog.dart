import 'package:flutter/material.dart';

/// Dialog for confirming post removal by community organizers
class RemovePostDialog extends StatefulWidget {
  const RemovePostDialog({Key? key}) : super(key: key);

  @override
  State<RemovePostDialog> createState() => _RemovePostDialogState();
}

class _RemovePostDialogState extends State<RemovePostDialog> {
  static const List<String> reasons = [
    'Spam',
    'Harassment & Profanity',
    'Inappropriate Content',
    'Off-topic',
    'Misinformation',
    'Violates Community Guidelines',
    'Other',
  ];

  String? _selectedReason;
  String _details = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOther = _selectedReason == 'Other';
    
    return AlertDialog(
      title: const Text('Remove Post'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This post will be hidden from all community members. This action cannot be undone. '
              'Please select a reason for removing this post:',
            ),
            const SizedBox(height: 16),
            ...reasons.map((reason) => RadioListTile<String>(
                  title: Text(reason),
                  value: reason,
                  groupValue: _selectedReason,
                  onChanged: (value) {
                    setState(() {
                      _selectedReason = value;
                    });
                  },
                )),
            if (isOther || _selectedReason != null)
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Additional details (optional)',
                  hintText: 'Provide more information about why this post is being removed',
                ),
                minLines: 2,
                maxLines: 4,
                onChanged: (value) {
                  setState(() {
                    _details = value;
                  });
                },
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          onPressed: _selectedReason == null
              ? null
              : () {
                  Navigator.of(context).pop({
                    'reason': _selectedReason,
                    'details': _details,
                  });
                },
          child: const Text('Remove Post'),
        ),
      ],
    );
  }
} 