import 'package:flutter/material.dart';
import '../../generated/l10n.dart';
import '../../theme/app_colors.dart';
import '../../widget/material_icon_fix.dart';
import '../../consts/plur_colors.dart';
import '../../consts/base.dart';

/// Helps users discover and join their first communities.
class DiscoverCommunitiesStepWidget extends StatelessWidget {
  final VoidCallback onJoinCommunities;
  final VoidCallback onCreateCommunity;
  final VoidCallback onSkip;

  const DiscoverCommunitiesStepWidget({
    super.key,
    required this.onJoinCommunities,
    required this.onCreateCommunity,
    required this.onSkip,
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
        // Main content
        Center(
          child: SizedBox(
            width: mainWidth,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Friends icon
                  Image.asset(
                    'assets/imgs/welcome_groups.png',
                    width: 80,
                    height: 80,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback to people icon if image fails to load
                      return Icon(
                        Icons.diversity_3_rounded,
                        size: 80,
                        color: buttonTextColor,
                      );
                    },
                  ),
              
                  const SizedBox(height: 32),
              
                  // Title
                  Text(
                    "Find Your Communities",
                    key: const Key('discover_communities_title'),
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
                    "Join public communities around your interests, or create your own community to invite others.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'SF Pro Rounded',
                      color: colors.secondaryText,
                      fontSize: 17,
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                    ),
                  ),
              
                  const SizedBox(height: 48),
              
                  // Browse Communities button (primary action)
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: buttonMaxWidth),
                      child: SizedBox(
                        width: double.infinity,
                        child: GestureDetector(
                          onTap: onJoinCommunities,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            decoration: BoxDecoration(
                              color: AppColorPalette.accentTeal,
                              borderRadius: BorderRadius.circular(32),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColorPalette.accentTeal.withAlpha(77),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.search_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      "Browse Communities",
                                      style: TextStyle(
                                        fontFamily: 'SF Pro Rounded',
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.2,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Create Community button (secondary action)
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: buttonMaxWidth),
                      child: SizedBox(
                        width: double.infinity,
                        child: GestureDetector(
                          onTap: onCreateCommunity,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            decoration: BoxDecoration(
                              color: colors.accent,
                              borderRadius: BorderRadius.circular(32),
                            ),
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.add_circle_outline_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      "Create Community",
                                      style: TextStyle(
                                        fontFamily: 'SF Pro Rounded',
                                        color: buttonTextColor,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.2,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Skip for now link
                  GestureDetector(
                    onTap: onSkip,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        "Skip for now",
                        style: TextStyle(
                          fontFamily: 'SF Pro Rounded',
                          color: colors.secondaryText,
                          fontSize: 16,
                          decoration: TextDecoration.underline,
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
}