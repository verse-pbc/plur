import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../theme/app_colors.dart';

/// Wrapper for displaying component examples
class ComponentExample extends StatelessWidget {
  final String title;
  final String? description;
  final Widget example;
  final String? code;
  final bool showBorder;
  
  const ComponentExample({
    super.key,
    required this.title,
    this.description,
    required this.example,
    this.code,
    this.showBorder = true,
  });
  
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'SF Pro Rounded',
              color: colors.primaryText,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (description != null) ...[
            const SizedBox(height: 8),
            Text(
              description!,
              style: TextStyle(
                fontFamily: 'SF Pro Rounded',
                color: colors.secondaryText,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(12),
              border: showBorder ? Border.all(
                color: colors.divider,
                width: 1,
              ) : null,
            ),
            child: example,
          ),
          if (code != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: code!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Code copied to clipboard',
                          style: TextStyle(
                            fontFamily: 'SF Pro Rounded',
                            color: Colors.white,
                          ),
                        ),
                        backgroundColor: colors.success,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: Icon(Icons.copy, size: 16, color: colors.accent),
                  label: Text(
                    'Copy code',
                    style: TextStyle(
                      fontFamily: 'SF Pro Rounded',
                      color: colors.accent,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}