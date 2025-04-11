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
                    PlurColors.primaryPurple.withOpacity(0.2),
                    PlurColors.appBackground,
                  ],
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
                      fontSize: 32,
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _steps.length,
                  (index) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentPage == index
                          ? PlurColors.primaryPurple
                          : PlurColors.secondaryText.withOpacity(0.5),
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

  void _nextPage() async {
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
    // Import nostr_sdk to generate a private key
    final String privateKey = generatePrivateKey();
    
    // Return both the private key and username in a map
    Map<String, String> result = {
      'privateKey': privateKey,
      'userName': _userName ?? '',
    };
    
    // For local/development builds, auto-join the testing group
    _joinTestingGroup();
    
    Navigator.of(context).pop(result);
  }
  
  void _joinTestingGroup() {
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
    
    // Join the test group
    listProvider.joinGroup(joinParams);
  }
}
