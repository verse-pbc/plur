import 'package:flutter/material.dart';
import 'package:nostrmo/generated/l10n.dart';
import 'package:nostrmo/util/theme_util.dart';
import 'package:nostrmo/component/primary_button_widget.dart';

import '../../features/create_community/create_community_dialog.dart';

class NoCommunitiesWidget extends StatefulWidget {
  const NoCommunitiesWidget({super.key});

  @override
  State<NoCommunitiesWidget> createState() => _NoCommunitiesWidgetState();
}

class _NoCommunitiesWidgetState extends State<NoCommunitiesWidget> {
  bool _isCreatingCommunity = false;

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final localization = S.of(context);

    return Center(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.all(30.0),
            child: Card(
              elevation: 4,
              color: themeData.customColors.cardBgColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Title section
                    Text(
                      localization.Communities,
                      style: TextStyle(
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                        color: themeData.customColors.primaryForegroundColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // Image section
                    Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: themeData.customColors.dimmedColor.withOpacity(0.5),
                      ),
                      child: Center(
                        child: ColorFiltered(
                          colorFilter: ColorFilter.mode(
                            themeData.customColors.dimmedColor,
                            BlendMode.srcIn,
                          ),
                          child: Image.asset(
                            "assets/imgs/welcome_groups.png",
                            width: 120,
                            height: 120,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Create community section
                    Text(
                      localization.Start_or_join_a_community,
                      style: TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                        color: themeData.customColors.primaryForegroundColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      localization.Connect_with_others,
                      style: TextStyle(
                        fontSize: 16.0,
                        color: themeData.customColors.primaryForegroundColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Action button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: _isCreatingCommunity
                          ? Center(
                              child: CircularProgressIndicator(
                                color: themeData.customColors.accentColor,
                              ),
                            )
                          : PrimaryButtonWidget(
                              text: localization.Create_Group,
                              borderRadius: 8,
                              onTap: _createCommunity,
                            ),
                    ),
                    const SizedBox(height: 16),

                    // Hint text
                    Text(
                      localization.Have_invite_link,
                      style: TextStyle(
                        fontSize: 14.0,
                        fontStyle: FontStyle.italic,
                        color: themeData.customColors.dimmedColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ),
    );
  }

  void _createCommunity() {
    if (_isCreatingCommunity) return;

    setState(() {
      _isCreatingCommunity = true;
    });

    // Show the dialog
    CreateCommunityDialog.show(context);

    // Reset loading state after a brief delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isCreatingCommunity = false;
        });
      }
    });
  }
}
