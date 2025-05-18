import 'package:flutter/material.dart';
import '../../generated/l10n.dart';
import '../../theme/app_colors.dart';
import '../../widget/material_icon_fix.dart';

/// Introduces users to communities and explains how they work.
class CommunityIntroStepWidget extends StatelessWidget {
  final VoidCallback onContinue;

  const CommunityIntroStepWidget({
    super.key,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final localization = S.of(context);
    final colors = context.colors;
    final accentColor = colors.accent;
    final buttonTextColor = colors.buttonText;
    
    // Get screen width for responsive design
    var screenWidth = MediaQuery.of(context).size.width;
    bool isTablet = screenWidth >= 600;
    bool isDesktop = screenWidth >= 900;
    double mainWidth = isDesktop ? 600 : (isTablet ? 600 : double.infinity);
    double buttonMaxWidth = isDesktop ? 400 : (isTablet ? 500 : double.infinity);

    return Stack(
      children: [
        // Back button is not needed here as we don't want users to go back
        // Main content
        Center(
          child: SizedBox(
            width: mainWidth,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Welcome groups icon
                  Image.asset(
                    'assets/imgs/welcome_groups.png',
                    width: 80,
                    height: 80,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback to people icon if image fails to load
                      return Icon(
                        Icons.groups_rounded,
                        size: 80,
                        color: buttonTextColor,
                      );
                    },
                  ),
              
                  const SizedBox(height: 32),
              
                  // Title
                  Text(
                    "Welcome to Communities!",
                    key: const Key('community_intro_title'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'SF Pro Rounded',
                      color: colors.titleText,
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
              
                  const SizedBox(height: 16),
              
                  // Description
                  Text(
                    "Communities are spaces for people to connect around shared interests. You can join existing communities or create your own.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'SF Pro Rounded',
                      color: colors.secondaryText,
                      fontSize: 17,
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Feature points
                  _buildFeaturePoint(
                    context, 
                    Icons.forum_rounded,
                    "Share posts, photos, and chat with others"
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildFeaturePoint(
                    context, 
                    Icons.lock_rounded,
                    "Your data is secure and private"
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildFeaturePoint(
                    context, 
                    Icons.public_rounded,
                    "Connect to the decentralized web"
                  ),
              
                  const SizedBox(height: 48),
              
                  // Continue button
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: buttonMaxWidth),
                      child: SizedBox(
                        width: double.infinity,
                        child: GestureDetector(
                          onTap: onContinue,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            decoration: BoxDecoration(
                              color: accentColor,
                              borderRadius: BorderRadius.circular(32),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              localization.continueButton,
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
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildFeaturePoint(BuildContext context, IconData icon, String text) {
    final colors = context.colors;
    
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: colors.accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(
            icon,
            color: colors.accent,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'SF Pro Rounded',
              color: colors.primaryText,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}