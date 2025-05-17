import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../component/primary_button_widget.dart';
import '../components/component_example.dart';
import '../components/section_header.dart';

/// Buttons section of the component library
class ButtonsSection extends StatefulWidget {
  const ButtonsSection({super.key});

  @override
  State<ButtonsSection> createState() => _ButtonsSectionState();
}

class _ButtonsSectionState extends State<ButtonsSection> {
  bool _isHoveredPrimary = false;
  bool _isHoveredSecondary = false;
  bool _isHoveredText = false;
  
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Primary Button
        const SectionHeader(
          title: 'Primary Button',
          subtitle: 'Filled button for primary actions',
        ),
        
        ComponentExample(
          title: 'States',
          description: 'Normal, Hover, Active, and Disabled states',
          example: Row(
            children: [
              // Normal
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Normal',
                      style: TextStyle(
                        fontFamily: 'SF Pro Rounded',
                        color: colors.secondaryText,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    PrimaryButtonWidget(
                      text: 'Create a Profile',
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Hover
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Hover',
                      style: TextStyle(
                        fontFamily: 'SF Pro Rounded',
                        color: colors.secondaryText,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    MouseRegion(
                      onEnter: (_) => setState(() => _isHoveredPrimary = true),
                      onExit: (_) => setState(() => _isHoveredPrimary = false),
                      child: Transform.scale(
                        scale: _isHoveredPrimary ? 1.02 : 1.0,
                        child: PrimaryButtonWidget(
                          text: 'Create a Profile',
                          onTap: () {},
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Disabled
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Disabled',
                      style: TextStyle(
                        fontFamily: 'SF Pro Rounded',
                        color: colors.secondaryText,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const PrimaryButtonWidget(
                      text: 'Create a Profile',
                      enabled: false,
                    ),
                  ],
                ),
              ),
            ],
          ),
          code: '''PrimaryButtonWidget(
  text: 'Create a Profile',
  onTap: () {},
  enabled: true, // or false for disabled state
)''',
        ),
        
        ComponentExample(
          title: 'Sizes',
          description: 'Different button sizes',
          example: Column(
            children: [
              // Large
              Row(
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(
                      'Large (18pt)',
                      style: TextStyle(
                        fontFamily: 'SF Pro Rounded',
                        color: colors.secondaryText,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _PrimaryButton(
                      text: 'Create a Profile',
                      fontSize: 18,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Regular
              Row(
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(
                      'Regular (16pt)',
                      style: TextStyle(
                        fontFamily: 'SF Pro Rounded',
                        color: colors.secondaryText,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Expanded(
                    child: PrimaryButtonWidget(
                      text: 'Login to Account',
                      onTap: () {},
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Small
              Row(
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(
                      'Small (14pt)',
                      style: TextStyle(
                        fontFamily: 'SF Pro Rounded',
                        color: colors.secondaryText,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _PrimaryButton(
                      text: 'Continue',
                      fontSize: 14,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Secondary Button
        const SectionHeader(
          title: 'Secondary Button',
          subtitle: 'Outlined button for secondary actions',
        ),
        
        ComponentExample(
          title: 'States',
          description: 'Normal, Hover, Active, and Disabled states',
          example: Row(
            children: [
              // Normal
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Normal',
                      style: TextStyle(
                        fontFamily: 'SF Pro Rounded',
                        color: colors.secondaryText,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _SecondaryButton(
                      text: 'Login with Nostr',
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Hover
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Hover',
                      style: TextStyle(
                        fontFamily: 'SF Pro Rounded',
                        color: colors.secondaryText,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    MouseRegion(
                      onEnter: (_) => setState(() => _isHoveredSecondary = true),
                      onExit: (_) => setState(() => _isHoveredSecondary = false),
                      child: _SecondaryButton(
                        text: 'Login with Nostr',
                        onTap: () {},
                        isHovered: _isHoveredSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Disabled
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Disabled',
                      style: TextStyle(
                        fontFamily: 'SF Pro Rounded',
                        color: colors.secondaryText,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _SecondaryButton(
                      text: 'Login with Nostr',
                      enabled: false,
                    ),
                  ],
                ),
              ),
            ],
          ),
          code: '''GestureDetector(
  onTap: onTap,
  child: Container(
    padding: const EdgeInsets.symmetric(vertical: 18),
    decoration: BoxDecoration(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(32),
      border: Border.all(
        color: buttonTextColor.withAlpha((255 * 0.3).round()),
        width: 2,
      ),
    ),
    alignment: Alignment.center,
    child: Text(
      'Login with Nostr',
      style: TextStyle(
        fontFamily: 'SF Pro Rounded',
        color: buttonTextColor,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    ),
  ),
)''',
        ),
        
        // Text Button
        const SectionHeader(
          title: 'Text Button',
          subtitle: 'Minimal button for less prominent actions',
        ),
        
        ComponentExample(
          title: 'States',
          description: 'Text buttons with different states',
          example: Row(
            children: [
              // Normal
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Normal',
                      style: TextStyle(
                        fontFamily: 'SF Pro Rounded',
                        color: colors.secondaryText,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontFamily: 'SF Pro Rounded',
                          color: colors.accent,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Hover
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Hover',
                      style: TextStyle(
                        fontFamily: 'SF Pro Rounded',
                        color: colors.secondaryText,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    MouseRegion(
                      onEnter: (_) => setState(() => _isHoveredText = true),
                      onExit: (_) => setState(() => _isHoveredText = false),
                      child: TextButton(
                        onPressed: () {},
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontFamily: 'SF Pro Rounded',
                            color: _isHoveredText 
                              ? colors.accent.withAlpha((255 * 0.8).round())
                              : colors.accent,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Disabled
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Disabled',
                      style: TextStyle(
                        fontFamily: 'SF Pro Rounded',
                        color: colors.secondaryText,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: null,
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontFamily: 'SF Pro Rounded',
                          color: colors.secondaryText.withAlpha((255 * 0.5).round()),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Icon Button
        const SectionHeader(
          title: 'Icon Button',
          subtitle: 'Circular button with icon',
        ),
        
        ComponentExample(
          title: 'Variants',
          description: 'Different icon button styles',
          example: Row(
            children: [
              // With background
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'With Background',
                      style: TextStyle(
                        fontFamily: 'SF Pro Rounded',
                        color: colors.secondaryText,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: colors.buttonText.withAlpha((255 * 0.1).round()),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          color: colors.buttonText,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Without background
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'No Background',
                      style: TextStyle(
                        fontFamily: 'SF Pro Rounded',
                        color: colors.secondaryText,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    IconButton(
                      onPressed: () {},
                      icon: Icon(
                        Icons.visibility,
                        color: colors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Primary color
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Primary Color',
                      style: TextStyle(
                        fontFamily: 'SF Pro Rounded',
                        color: colors.secondaryText,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: colors.accent,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Custom primary button widget for size variations
class _PrimaryButton extends StatelessWidget {
  final String text;
  final double fontSize;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final bool enabled;
  
  const _PrimaryButton({
    required this.text,
    required this.fontSize,
    required this.padding,
    this.onTap,
    this.enabled = true,
  });
  
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: enabled ? colors.accent : colors.accent.withAlpha((255 * 0.4).round()),
          borderRadius: BorderRadius.circular(32),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'SF Pro Rounded',
            color: enabled ? colors.buttonText : colors.buttonText.withAlpha((255 * 0.4).round()),
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

// Custom secondary button widget
class _SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final bool enabled;
  final bool isHovered;
  
  const _SecondaryButton({
    required this.text,
    this.onTap,
    this.enabled = true,
    this.isHovered = false,
  });
  
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final buttonTextColor = colors.buttonText;
    
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: isHovered ? colors.accent.withAlpha((255 * 0.1).round()) : Colors.transparent,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: isHovered 
              ? colors.accent
              : enabled 
                ? buttonTextColor.withAlpha((255 * 0.3).round())
                : buttonTextColor.withAlpha((255 * 0.15).round()),
            width: 2,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'SF Pro Rounded',
            color: isHovered
              ? colors.accent
              : enabled
                ? buttonTextColor
                : buttonTextColor.withAlpha((255 * 0.4).round()),
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}