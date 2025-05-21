import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class NoNotesWidget extends StatelessWidget {
  final String groupName;
  final Future<void> Function()? onRefresh;

  const NoNotesWidget({
    Key? key,
    required this.groupName,
    required this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    
    return RefreshIndicator(
      onRefresh: onRefresh ?? () async {},
      child: ListView(
        // Use physics to enable refreshing even when content doesn't overflow
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          // Push content to vertical center with expanded space
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Community icon (placeholder)
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: colors.primaryText.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.groups_rounded,
                    size: 40,
                    color: colors.accent,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Community name
                Text(
                  groupName,
                  style: TextStyle(
                    fontFamily: 'SF Pro Rounded',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: colors.titleText,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                // Welcome message
                Text(
                  'Write a note to welcome your community!',
                  style: TextStyle(
                    fontFamily: 'SF Pro Rounded',
                    fontSize: 17,
                    color: colors.secondaryText,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 32),
                
                // Add note button
                GestureDetector(
                  onTap: () {
                    // Will be handled by the FAB on the main screen
                    // But we add this button for visual clarity
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: colors.accent,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: colors.accent.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.edit_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Write first note',
                          style: const TextStyle(
                            fontFamily: 'SF Pro Rounded',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
