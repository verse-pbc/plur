import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../components/component_example.dart';
import '../components/section_header.dart';

/// Typography section of the component library
class TypographySection extends StatelessWidget {
  const TypographySection({super.key});
  
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Headings
        const SectionHeader(
          title: 'Headings',
          subtitle: 'SF Pro Rounded Bold with 120% line height',
        ),
        ComponentExample(
          title: 'H1 - 46pt',
          description: 'Main screen titles',
          example: Text(
            'Bring your people together',
            style: TextStyle(
              fontFamily: 'SF Pro Rounded',
              color: colors.primaryText,
              fontSize: 46,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          code: '''Text(
  'Bring your people together',
  style: TextStyle(
    fontFamily: 'SF Pro Rounded',
    color: colors.primaryText,
    fontSize: 46,
    fontWeight: FontWeight.bold,
    height: 1.2,
  ),
)''',
        ),
        ComponentExample(
          title: 'H2 - 32pt',
          description: 'Section headers',
          example: Text(
            'Component Library',
            style: TextStyle(
              fontFamily: 'SF Pro Rounded',
              color: colors.primaryText,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          code: '''Text(
  'Component Library',
  style: TextStyle(
    fontFamily: 'SF Pro Rounded',
    color: colors.primaryText,
    fontSize: 32,
    fontWeight: FontWeight.bold,
    height: 1.2,
  ),
)''',
        ),
        ComponentExample(
          title: 'H3 - 24pt',
          description: 'Modal titles, subsections',
          example: Text(
            'Login with Nostr',
            style: TextStyle(
              fontFamily: 'SF Pro Rounded',
              color: colors.primaryText,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          code: '''Text(
  'Login with Nostr',
  style: TextStyle(
    fontFamily: 'SF Pro Rounded',
    color: colors.primaryText,
    fontSize: 24,
    fontWeight: FontWeight.bold,
    height: 1.2,
  ),
)''',
        ),
        
        // Body Text
        const SectionHeader(
          title: 'Body Text',
          subtitle: 'SF Pro Rounded Regular with 140% line height',
        ),
        ComponentExample(
          title: 'Body Regular - 17pt',
          description: 'Default body text',
          example: Text(
            'Start meaningful exchanges with people you trust. Holis is communities built for depth, not noise.',
            style: TextStyle(
              fontFamily: 'SF Pro Rounded',
              color: colors.primaryText,
              fontSize: 17,
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
          ),
          code: '''Text(
  'Start meaningful exchanges with people you trust.',
  style: TextStyle(
    fontFamily: 'SF Pro Rounded',
    color: colors.primaryText,
    fontSize: 17,
    fontWeight: FontWeight.w400,
    height: 1.4,
  ),
)''',
        ),
        ComponentExample(
          title: 'Body Secondary - 17pt',
          description: 'Secondary text with muted color',
          example: Text(
            'Enter your nsec private key or nsecBunker URL.',
            style: TextStyle(
              fontFamily: 'SF Pro Rounded',
              color: colors.secondaryText,
              fontSize: 17,
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
          ),
          code: '''Text(
  'Enter your nsec private key or nsecBunker URL.',
  style: TextStyle(
    fontFamily: 'SF Pro Rounded',
    color: colors.secondaryText,
    fontSize: 17,
    fontWeight: FontWeight.w400,
    height: 1.4,
  ),
)''',
        ),
        
        // Button Text
        const SectionHeader(
          title: 'Button Text',
          subtitle: 'SF Pro Rounded Semibold',
        ),
        ComponentExample(
          title: 'Button Large - 18pt',
          description: 'Primary action buttons',
          example: Text(
            'Create a Profile',
            style: TextStyle(
              fontFamily: 'SF Pro Rounded',
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
          code: '''Text(
  'Create a Profile',
  style: TextStyle(
    fontFamily: 'SF Pro Rounded',
    color: Colors.white,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  ),
)''',
        ),
        ComponentExample(
          title: 'Button Regular - 16pt',
          description: 'Secondary buttons',
          example: Text(
            'Login to Account',
            style: TextStyle(
              fontFamily: 'SF Pro Rounded',
              color: colors.primaryText,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          code: '''Text(
  'Login to Account',
  style: TextStyle(
    fontFamily: 'SF Pro Rounded',
    color: colors.primaryText,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  ),
)''',
        ),
        
        // Small Text
        const SectionHeader(
          title: 'Small Text',
          subtitle: 'For captions and metadata',
        ),
        ComponentExample(
          title: 'Caption - 14pt',
          description: 'Helper text, descriptions',
          example: Text(
            'All text styles and typography used throughout the app.',
            style: TextStyle(
              fontFamily: 'SF Pro Rounded',
              color: colors.secondaryText,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          code: '''Text(
  'All text styles and typography used throughout the app.',
  style: TextStyle(
    fontFamily: 'SF Pro Rounded',
    color: colors.secondaryText,
    fontSize: 14,
    height: 1.4,
  ),
)''',
        ),
        
        // Font Weights
        const SectionHeader(
          title: 'Font Weights',
          subtitle: 'Available weights in SF Pro Rounded',
        ),
        ComponentExample(
          title: 'All Weights',
          description: 'Regular (400), Medium (500), Semibold (600), Bold (700)',
          example: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Regular (400)',
                style: TextStyle(
                  fontFamily: 'SF Pro Rounded',
                  color: colors.primaryText,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Medium (500)',
                style: TextStyle(
                  fontFamily: 'SF Pro Rounded',
                  color: colors.primaryText,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Semibold (600)',
                style: TextStyle(
                  fontFamily: 'SF Pro Rounded',
                  color: colors.primaryText,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Bold (700)',
                style: TextStyle(
                  fontFamily: 'SF Pro Rounded',
                  color: colors.primaryText,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}