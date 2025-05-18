import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nostr_sdk/nostr_sdk.dart';
import '../../theme/app_colors.dart';
import 'age_verification_step.dart';
import 'age_verification_dialog_widget.dart';
import 'name_input_step_widget.dart';
import 'community_intro_step_widget.dart';
import 'discover_communities_step_widget.dart';
import '../../consts/base.dart';
import '../../consts/router_path.dart';
import '../../router/group/no_communities_sheet.dart';
import '../../features/create_community/create_community_dialog.dart';

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
  bool _skipCommunities = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    
    // Initialize steps
    _initializeSteps();
  }
  
  late List<Widget> _steps;
  
  // Initialize steps with callback references
  void _initializeSteps() {
    _steps = [
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
      CommunityIntroStepWidget(
        onContinue: _nextPage,
      ),
      DiscoverCommunitiesStepWidget(
        onJoinCommunities: _onJoinCommunities,
        onCreateCommunity: _onCreateCommunity,
        onSkip: () {
          _skipCommunities = true;
          _completeOnboarding();
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    
    return Scaffold(
      backgroundColor: colors.loginBackground,
      body: SafeArea(
        child: Stack(
          children: [
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

  void _onAgeDenied() async {
    // Show the age verification sheet
    await AgeVerificationDialog.show(context);
    // When the sheet is dismissed, navigate back to the previous screen
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  // Handle joining communities flow
  void _onJoinCommunities() async {
    // First generate the account
    await _generateAccount();
    
    // Return flag for communities
    Map<String, dynamic> result = {
      'privateKey': _generatedPrivateKey,
      'userName': _userName ?? '',
      'joinCommunities': true,
      'skipCommunities': false,
    };
    
    // Return to login screen
    if (mounted) {
      Navigator.of(context).pop(result);
    }
  }
  
  // Handle creating a community flow
  void _onCreateCommunity() async {
    // First generate the account
    await _generateAccount();
    
    // Return flag for creating community
    Map<String, dynamic> result = {
      'privateKey': _generatedPrivateKey,
      'userName': _userName ?? '',
      'joinCommunities': false,
      'createCommunity': true,
      'skipCommunities': false,
    };
    
    // Return to login screen
    if (mounted) {
      Navigator.of(context).pop(result);
    }
  }
  
  // Store generated private key
  String? _generatedPrivateKey;
  
  // Generate account but don't navigate yet
  Future<void> _generateAccount() async {
    setState(() {
      _isLoading = true;
    });
    
    // Import nostr_sdk to generate a private key
    final String privateKey = generatePrivateKey();
    _generatedPrivateKey = privateKey;
    
    // Wait a moment for UI to update
    await Future.delayed(const Duration(milliseconds: 300));
  }

  void _completeOnboarding() {
    setState(() {
      _isLoading = true;
    });
    
    // Import nostr_sdk to generate a private key if not already generated
    if (_generatedPrivateKey == null) {
      _generatedPrivateKey = generatePrivateKey();
    }
    
    // Return the private key, username and skip flag in a map
    Map<String, dynamic> result = {
      'privateKey': _generatedPrivateKey,
      'userName': _userName ?? '',
      'skipCommunities': _skipCommunities,
    };
    
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
}
