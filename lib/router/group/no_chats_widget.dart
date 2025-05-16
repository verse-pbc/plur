import 'package:flutter/material.dart';
import '../../consts/base.dart';
import '../../theme/app_colors.dart';
import '../../generated/l10n.dart';

/// Widget displayed when there are no chat messages in a group yet
class NoChatsWidget extends StatelessWidget {
  final String groupName;
  final Function() onRefresh;

  const NoChatsWidget({
    super.key,
    required this.groupName,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final localization = S.of(context);
    
    return RefreshIndicator(
      onRefresh: () async {
        onRefresh();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: 400,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 64,
                  color: context.colors.dimmed,
                ),
                const SizedBox(height: 20),
                Text(
                  "No Chat Messages Yet",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: context.colors.primaryText,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Base.basePadding * 2,
                  ),
                  child: Text(
                    "Be the first to start a conversation in this community!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: context.colors.dimmed,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text("Refresh"),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: context.colors.buttonText,
                    backgroundColor: context.colors.accent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}