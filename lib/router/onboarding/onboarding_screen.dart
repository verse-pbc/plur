import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import '../../theme/app_colors.dart';
import 'age_verification_step.dart';
import 'age_verification_dialog_widget.dart';
import 'name_input_step_widget.dart';
import '../../consts/base.dart';
import '../../data/join_group_parameters.dart';
import '../../provider/relay_provider.dart';
import '../../main.dart';

/// Manages the onboarding process through multiple steps.
class OnboardingWidget extends StatefulWidget {
  const OnboardingWidget({super.key});

  @override
  State<OnboardingWidget> createState() => _OnboardingWidgetState();
}

class _OnboardingWidgetState extends State<OnboardingWidget> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  String? _userName;
  bool _isLoading = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  late final List<Widget> _steps = [
    AgeVerificationStep(
      onVerified: _nextPage,
      onDenied: _onAgeDenied,
    ),
    NameInputStepWidget(
      onContinue: (name) {
        _userName = name;
        _nextPage();
      },
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Get the current theme mode to adapt colors
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Define theme-adaptive colors
    final backgroundColor = isDarkMode ? context.colors.background : Colors.white;
    final gradientEndColor = isDarkMode ? context.colors.background : Colors.white.withAlpha(245);
    final gradientStartColor = context.colors.primary.withAlpha(isDarkMode ? 64 : 38);
    final logoColor = isDarkMode ? context.colors.highlightText : context.colors.primary;
    final indicatorActiveColor = context.colors.primary;
    final indicatorInactiveColor = isDarkMode 
        ? context.colors.secondaryText.withAlpha(128) 
        : context.colors.secondaryText.withAlpha(102);
    final versionColor = isDarkMode 
        ? context.colors.secondaryText.withAlpha(179) 
        : context.colors.secondaryText;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Background gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    gradientStartColor,
                    gradientEndColor,
                  ],
                  stops: const [0.0, 0.7],
                ),
              ),
            ),
            
            // Logo at the top
            Positioned(
              top: 24,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'plur',
                  style: GoogleFonts.nunito(
                    textStyle: TextStyle(
                      color: logoColor,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            
            // Main content
            Padding(
              padding: const EdgeInsets.only(bottom: 90), // Add bottom padding for version text
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: Base.maxScreenWidth),
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (int page) {
                      setState(() {
                        _currentPage = page;
                      });
                    },
                    children: _steps,
                  ),
                ),
              ),
            ),
            
            // Page indicator and version - moved up to avoid button overlap
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Page indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _steps.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: _currentPage == index
                              ? indicatorActiveColor
                              : indicatorInactiveColor,
                        ),
                      ),
                    ),
                  ),
                  
                  // Version text
                  const SizedBox(height: 8),
                  Text(
                    'v0.1.0',
                    style: GoogleFonts.nunito(
                      textStyle: TextStyle(
                        color: versionColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Loading overlay
            if (_isLoading)
              Container(
                color: context.colors.background.withAlpha(179),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(context.colors.primary),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _nextPage() {
    if (_currentPage < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _onAgeDenied() {
    AgeVerificationDialog.show(context);
  }

  void _completeOnboarding() {
    setState(() {
      _isLoading = true;
    });
    
    // Import nostr_sdk to generate a private key
    final String privateKey = generatePrivateKey();
    
    // Return both the private key and username in a map
    Map<String, String> result = {
      'privateKey': privateKey,
      'userName': _userName ?? '',
    };
    
    // Don't auto-join any groups during onboarding
    // This was causing confusion for new users
    
    // Use a short delay and complete the operation
    Future.delayed(const Duration(milliseconds: 300)).then((_) {
      // Only proceed if still mounted
      if (mounted) {
        Navigator.of(context).pop(result);
      }
    }).catchError((e) {
      // Only handle error if still mounted
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error creating account: ${e.toString()}',
              style: GoogleFonts.nunito(),
            ),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    });
  }
  
  Future<void> _joinTestingGroup() async {
    // The test group ID and invite code as specified
    const String testGroupId = "7C8T22GTBRGW";
    const String testInviteCode = "MEXI77KG";
    const String testGroupHost = RelayProvider.defaultGroupsRelayAddress;
    
    // Create join parameters
    final joinParams = JoinGroupParameters(
      testGroupHost,
      testGroupId,
      code: testInviteCode,
    );
    
    // Join the test group - don't await since it returns void
    listProvider.joinGroup(joinParams);
  }
}
