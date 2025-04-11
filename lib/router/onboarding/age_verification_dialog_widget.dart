import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../util/router_util.dart';
import '../../consts/plur_colors.dart';

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
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: PlurColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Emoji icon
            const Text(
              '⚠️',
              style: TextStyle(
                fontSize: 48,
              ),
            ),
            const SizedBox(height: 16),
            
            // Title
            Text(
              'Plur is not for you yet',
              key: const Key('age_dialog_title'),
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                textStyle: const TextStyle(
                  color: PlurColors.highlightText,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
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
                textStyle: const TextStyle(
                  color: PlurColors.primaryText,
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Button
            GestureDetector(
              onTap: () {
                // Close dialog using dialog's context
                RouterUtil.back(context);
                // Navigate back to login using parent context
                RouterUtil.back(parentContext);
              },
              child: Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  color: PlurColors.buttonBackground,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: PlurColors.buttonBackground.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  'OK',
                  style: GoogleFonts.nunito(
                    textStyle: const TextStyle(
                      color: PlurColors.buttonText,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
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
      builder: (dialogContext) => AgeVerificationDialog(
        parentContext: context,
      ),
    );
  }
}
