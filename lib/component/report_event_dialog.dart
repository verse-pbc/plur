import 'package:flutter/material.dart';

class ReportEventDialog extends StatefulWidget {
  const ReportEventDialog({Key? key}) : super(key: key);

  @override
  State<ReportEventDialog> createState() => _ReportEventDialogState();
}

class _ReportEventDialogState extends State<ReportEventDialog> {
  static const List<String> reasons = [
    'Spam',
    'Harassment & Profanity',
    'NSFW',
    'Illegal',
    'Impersonation',
    'Other',
  ];

  String? _selectedReason;
  String _details = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOther = _selectedReason == 'Other';
    return AlertDialog(
      title: const Text('Report to Community Organizers'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Report this content to community organizers and administrators. Your report helps them moderate the community. Select a reason below:',
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
            if (isOther)
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Additional details',
                ),
                minLines: 1,
                maxLines: 3,
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
          onPressed: _selectedReason == null
              ? null
              : () {
                  Navigator.of(context).pop({
                    'reason': _selectedReason,
                    'details': _details,
                  });
                },
          child: const Text('Submit'),
        ),
      ],
    );
  }
} 