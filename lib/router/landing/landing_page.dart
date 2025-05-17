import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../consts/base.dart';
import '../login/login_widget.dart';

/// A wrapper for the landing page that handles layout and styling
/// This ensures the initial screen has the proper styling
class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    
    // Check screen size for responsive design
    var screenWidth = MediaQuery.of(context).size.width;
    bool isTablet = screenWidth >= 600;
    bool isDesktop = screenWidth >= 900;
    
    // For desktop sizes, we'll add background decorations
    return Scaffold(
      backgroundColor: colors.loginBackground,
      body: Stack(
        children: [
          // Background decoration for larger screens
          if (isDesktop || isTablet)
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  color: colors.primary.withAlpha((255 * 0.05).round()),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          
          if (isDesktop || isTablet)
            Positioned(
              bottom: -120,
              left: -50,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  color: colors.primary.withAlpha((255 * 0.07).round()),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            
          // Main content
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: Base.maxScreenWidth),
                child: const LoginSignupWidget(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}