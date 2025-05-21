import 'package:flutter/material.dart';
import 'package:nostrmo/consts/base.dart';
import 'package:nostrmo/theme/app_colors.dart';

import '../generated/l10n.dart';

class NewNotesUpdatedWidget extends StatelessWidget {
  final int num;
  final Function? onTap;

  const NewNotesUpdatedWidget({super.key, required this.num, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    
    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          onTap!();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 10,
          horizontal: 20,
        ),
        decoration: BoxDecoration(
          color: colors.primary, // Use theme-aware primary color
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: colors.primary.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // New notification icon
            Icon(
              Icons.arrow_upward_rounded,
              color: colors.buttonText,
              size: 16,
            ),
            const SizedBox(width: 8),
            // Text with number of new posts
            Text(
              "$num ${S.of(context).notesUpdated}",
              style: TextStyle(
                fontFamily: 'SF Pro Rounded',
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: colors.buttonText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
