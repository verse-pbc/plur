import 'package:flutter/material.dart';
import '../../util/theme_util.dart';
import 'age_verification_step.dart';
import 'age_verification_dialog_widget.dart';
import '../../consts/base.dart';

/// Manages the onboarding process through multiple steps.
class OnboardingWidget extends StatefulWidget {
  const OnboardingWidget({super.key});

  @override
  State<OnboardingWidget> createState() => _OnboardingWidgetState();
}

class _OnboardingWidgetState extends State<OnboardingWidget> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

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
  ];

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final appBgColor = themeData.customColors.appBgColor;

    return Scaffold(
      backgroundColor: appBgColor,
      body: SafeArea(
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
    Navigator.of(context).pop(true);
  }
}
