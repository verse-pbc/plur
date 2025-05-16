import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../util/router_util.dart';
import '../../theme/app_colors.dart';
import '../../component/primary_button_widget.dart';

/// Dialog to show when user is under 16 years old.
class AgeVerificationDialog extends StatelessWidget {
  final BuildContext parentContext;

  const AgeVerificationDialog({
    super.key,
    required this.parentContext,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: context.colors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(51),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Emoji icon in a container with background
            Container(
              decoration: BoxDecoration(
                color: Colors.amber.withAlpha(26),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(16),
              child: const Text(
                '⚠️',
                style: TextStyle(
                  fontSize: 48,
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Title
            Text(
              'Plur is not for you yet',
              key: const Key('age_dialog_title'),
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                textStyle: TextStyle(
                  color: context.colors.highlightText,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Content
            Text(
              'You must be at least 16 years old to use Plur. '
              'Please come back when you\'re old enough!',
              key: const Key('age_requirement_message'),
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                textStyle: TextStyle(
                  color: context.colors.primaryText,
                  fontSize: 16,
                  height: 1.5,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            const SizedBox(height: 28),
            
            // Button
            PrimaryButtonWidget(
              text: 'Understood',
              height: 52,
              borderRadius: 14,
              onTap: () {
                // Close dialog using dialog's context
                RouterUtil.back(context);
                // Navigate back to login using parent context
                RouterUtil.back(parentContext);
              },
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withAlpha(153),
      builder: (dialogContext) => AgeVerificationDialog(
        parentContext: context,
      ),
    );
  }
}
