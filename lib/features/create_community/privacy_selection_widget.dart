import 'package:flutter/material.dart';

enum CommunityPrivacy {
  discoverable,
  inviteOnly,
}

class PrivacySelectionWidget extends StatelessWidget {
  final CommunityPrivacy? selectedPrivacy;
  final void Function(CommunityPrivacy) onPrivacySelected;

  const PrivacySelectionWidget({
    super.key,
    required this.selectedPrivacy,
    required this.onPrivacySelected,
  });

  @override
  Widget build(BuildContext context) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose Privacy Setting'
        ),
        const SizedBox(height: 20),
        _privacyOption(
          context,
          CommunityPrivacy.discoverable,
          'We want to be discovered',
          'Your community will be visible in search results',
          Icons.search,
        ),
        const SizedBox(height: 20),
        _privacyOption(
          context,
          CommunityPrivacy.inviteOnly,
          'We want to be invite only',
          'Your community will only be accessible through invite links',
          Icons.lock,
        ),
      ],
    );
  }

  Widget _privacyOption(
    BuildContext context,
    CommunityPrivacy privacy,
    String title,
    String description,
    IconData icon,
  ) {
    final themeData = Theme.of(context);
    final isSelected = selectedPrivacy == privacy;

    return InkWell(
      onTap: () => onPrivacySelected(privacy),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? themeData.primaryColor : themeData.dividerColor,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? themeData.primaryColor
                  : themeData.iconTheme.color,
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? themeData.primaryColor
                          : themeData.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: themeData.textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: themeData.primaryColor,
              ),
          ],
        ),
      ),
    );
  }
}
