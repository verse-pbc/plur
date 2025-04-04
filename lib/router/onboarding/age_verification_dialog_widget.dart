import 'package:flutter/material.dart';
import '../../util/router_util.dart';
import '../../util/theme_util.dart';

/// Temporary dialog to show when user is under 16.
// Todo: Update this dialog when we have a proper under 16 screen designed
class AgeVerificationDialog extends StatelessWidget {
  final BuildContext parentContext;

  const AgeVerificationDialog({
    super.key,
    required this.parentContext,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Go back to School',
        style: TextStyle(
          color: Theme.of(context).customColors.primaryForegroundColor,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: Theme.of(context).customColors.cardBgColor,
      content: const Text(
        'You must be at least 16 years old to use Plur. '
        'Please come back when you\'re old enough!',
        key: Key('age_requirement_message'),
      ),
      actions: [
        TextButton(
          onPressed: () {
            // Close dialog using dialog's context
            RouterUtil.back(context);
            // Navigate back to login using parent context
            RouterUtil.back(parentContext);
          },
          child: const Text('OK'),
        ),
      ],
    );
  }

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AgeVerificationDialog(
        parentContext: context,
      ),
    );
  }
}
