import 'package:flutter/material.dart';
import 'package:nostrmo/generated/l10n.dart';
import 'package:nostrmo/router/group/create_community_dialog.dart';

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
            // Use theme-appropriate colors
            color: themeData.dialogBackgroundColor,
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
                      fontFamily: 'Roboto',
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                      color: themeData.primaryColor,
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
                      color: themeData.primaryColor.withAlpha(25),
                    ),
                    child: Center(
                      child: ColorFiltered(
                        colorFilter: ColorFilter.mode(
                          themeData.primaryColor,
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
                    'Start or join a community',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                      color: themeData.colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Connect with others by creating your own community or joining an existing one with an invite link.',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 16.0,
                      color: themeData.colorScheme.onSurface.withAlpha(204), // ~0.8 opacity
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
                              color: themeData.primaryColor,
                            ),
                          )
                        : ElevatedButton.icon(
                            onPressed: _handleCreateCommunity,
                            icon: const Icon(Icons.add_circle_outline),
                            label: Text(localization.Create_Group),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: themeData.primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 16, 
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Hint text
                  Text(
                    'Have an invite link? Tap on it to join a community.',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 14.0,
                      fontStyle: FontStyle.italic,
                      color: themeData.colorScheme.onSurface.withAlpha(153), // ~0.6 opacity
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

  void _handleCreateCommunity() {
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
