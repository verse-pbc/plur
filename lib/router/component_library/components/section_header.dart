import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

/// Section header for organizing components
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
  });
  
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 24, top: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: colors.divider,
                  width: 2,
                ),
              ),
            ),
            child: Row(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'SF Pro Rounded',
                    color: colors.primaryText,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: TextStyle(
                fontFamily: 'SF Pro Rounded',
                color: colors.secondaryText,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}