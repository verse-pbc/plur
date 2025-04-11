import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import '../../consts/plur_colors.dart';
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
    return Scaffold(
      backgroundColor: PlurColors.appBackground,
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
                    PlurColors.primaryPurple.withAlpha(64),
                    PlurColors.appBackground,
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
                    textStyle: const TextStyle(
                      color: PlurColors.highlightText,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            
            // Main content
            Center(
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
            
            // Page indicator
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                              ? PlurColors.primaryPurple
                              : PlurColors.secondaryText.withAlpha(128),
                        ),
                      ),
                    ),
                  ),
                  
                  // Version text
                  const SizedBox(height: 16),
                  Text(
                    'v0.1.0',
                    style: GoogleFonts.nunito(
                      textStyle: TextStyle(
                        color: PlurColors.secondaryText.withAlpha(179),
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
                color: PlurColors.appBackground.withAlpha(179),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(PlurColors.primaryPurple),
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
    
    // For local/development builds, auto-join the testing group
    _joinTestingGroup();
    
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
