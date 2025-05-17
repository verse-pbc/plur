import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Sheet to show when user is under 16 years old.
class AgeVerificationDialog extends StatelessWidget {
  const AgeVerificationDialog({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accentColor = colors.accent;
    final buttonTextColor = colors.buttonText;
    
    return SafeArea(
      bottom: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(40, 32, 40, 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Close button
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: buttonTextColor.withAlpha((255 * 0.1).round()),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    color: buttonTextColor,
                    size: 20,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Thumbs down icon
            Image.asset(
              'assets/imgs/thumbs-down.png',
              width: 80,
              height: 80,
              errorBuilder: (context, error, stackTrace) {
                // Fallback icon if image fails to load
                return Icon(
                  Icons.thumb_down_rounded,
                  size: 80,
                  color: buttonTextColor,
                );
              },
            ),
            
            const SizedBox(height: 24),
            
            // Title
            Text(
              'Plur is not for you yet',
              key: const Key('age_dialog_title'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'SF Pro Rounded',
                color: colors.titleText,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Content
            Text(
              'You must be at least 16 years old to use Plur. Please come back when you\'re old enough!',
              key: const Key('age_requirement_message'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'SF Pro Rounded',
                color: colors.secondaryText,
                fontSize: 17,
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Understood button
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(32),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Understood',
                    style: TextStyle(
                      fontFamily: 'SF Pro Rounded',
                      color: buttonTextColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
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
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withAlpha((255 * 0.5).round()),
      enableDrag: true,
      isDismissible: true,
      builder: (BuildContext context) {
        // Get responsive width values
        var screenWidth = MediaQuery.of(context).size.width;
        bool isTablet = screenWidth >= 600;
        bool isDesktop = screenWidth >= 900;
        double sheetMaxWidth = isDesktop ? 600 : (isTablet ? 600 : double.infinity);
        
        return GestureDetector(
          onTap: () {
            // Dismiss the sheet when tapping outside
            Navigator.of(context).pop();
          },
          child: Container(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: () {}, // Prevent dismissal when tapping on the sheet itself
              child: AnimatedPadding(
                padding: MediaQuery.of(context).viewInsets,
                duration: const Duration(milliseconds: 100),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: sheetMaxWidth),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                      child: Container(
                        color: context.colors.loginBackground,
                        child: const IntrinsicHeight(
                          child: AgeVerificationDialog(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
