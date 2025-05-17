import 'package:flutter/material.dart';

class ReportUserDialog extends StatefulWidget {
  const ReportUserDialog({Key? key}) : super(key: key);

  @override
  State<ReportUserDialog> createState() => _ReportUserDialogState();
}

class _ReportUserDialogState extends State<ReportUserDialog> {
  static const List<String> reasons = [
    'Spam',
    'Harassment & Profanity',
    'Impersonation',
    'Bot Account',
    'Scam',
    'Other',
  ];

  String? _selectedReason;
  String _details = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOther = _selectedReason == 'Other';
    return AlertDialog(
      title: const Text('Report User to Community Organizers'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Report this user to community organizers and administrators. Your report helps them moderate the community. Select a reason below:',
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