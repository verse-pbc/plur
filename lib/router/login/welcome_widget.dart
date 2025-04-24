import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../generated/l10n.dart';
import '../../util/theme_util.dart';
import '../../consts/router_path.dart';
import '../../component/primary_button_widget.dart';

class WelcomeWidget extends ConsumerWidget {
  final VoidCallback onSignupTap;

  const WelcomeWidget({
    super.key,
    required this.onSignupTap,
  });

  void _navigateToNostrLogin(BuildContext context) {
    Navigator.of(context).pushNamed(RouterPath.login);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeData = Theme.of(context);
    final localization = S.of(context);

    return Scaffold(
      backgroundColor: themeData.customColors.appBgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 64),
              Text(
                localization.Welcome_to_plur,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: themeData.customColors.primaryForegroundColor,
                  fontSize: 42,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              PrimaryButtonWidget(
                key: const Key('create_profile_button'),
                onTap: onSignupTap,
                text: localization.Create_a_profile,
                borderRadius: 8,
              ),
              const SizedBox(height: 16),
              PrimaryButtonWidget(
                onTap: () => {},
                text: localization.Login_with_bluesky,
                borderRadius: 8,
                color: themeData.customColors.secondaryForegroundColor,
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _navigateToNostrLogin(context),
                child: Text(
                  localization.Already_a_user,
                  style: TextStyle(
                    color: themeData.customColors.accentColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
