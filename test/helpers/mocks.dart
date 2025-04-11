import 'package:flutter/material.dart';
import 'package:nostrmo/generated/l10n.dart';

/// A mock implementation of NoCommunitiesWidget for testing
class MockNoCommunitiesWidget extends StatelessWidget {
  const MockNoCommunitiesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Start or join a community',
              key: const Key('community_widget_text'),
            ),
            FilledButton(
              onPressed: () {},
              child: const Text('Create Group'),
            ),
          ],
        ),
      ),
    );
  }
}

/// A mock implementation of CommunitiesScreen that always shows our mock NoCommunitiesWidget
class MockCommunitiesScreen extends StatelessWidget {
  const MockCommunitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: MockNoCommunitiesWidget(),
      ),
    );
  }
}

/// A simplified mock of the login screen that just needs the signup button
class MockLoginWidget extends StatelessWidget {
  const MockLoginWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FilledButton(
              key: const Key('signup_button'),
              onPressed: () {
                // Navigate to the onboarding screen
                Navigator.of(context).pushNamed('/onboarding');
              },
              child: const Text('Signup'),
            ),
          ],
        ),
      ),
    );
  }
}

/// A mock implementation of the onboarding flow for testing
class MockOnboardingWidget extends StatefulWidget {
  const MockOnboardingWidget({super.key});

  @override
  State<MockOnboardingWidget> createState() => _MockOnboardingWidgetState();
}

class _MockOnboardingWidgetState extends State<MockOnboardingWidget> {
  bool showAgeVerification = true;
  bool showNameInput = false;
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (showAgeVerification) ...[
              Text(
                'Are you at least 13 years old?',
                key: const Key('age_verification_title'),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton(
                    onPressed: () {
                      setState(() {
                        showAgeVerification = false;
                        showNameInput = true;
                      });
                    },
                    child: const Text('Yes'),
                  ),
                  const SizedBox(width: 20),
                  FilledButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text(
                            'Age Verification',
                            key: Key('age_dialog_title'),
                          ),
                          content: const Text(
                            'You must be at least 13 years old to use this app.',
                            key: Key('age_requirement_message'),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                Navigator.of(context).pop();
                              },
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Text('No'),
                  ),
                ],
              ),
            ],
            if (showNameInput) ...[
              Text(
                'What should we call you?',
                key: const Key('name_input_title'),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: TextField(
                  key: const Key('input'),
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'Enter your name',
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  // Complete onboarding and show the NoCommunitiesWidget directly
                  Navigator.of(context).pop();
                  // Add the MockCommunitiesScreen directly to the widget tree
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const MockCommunitiesScreen()
                    ),
                  );
                },
                child: const Text('Continue'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}