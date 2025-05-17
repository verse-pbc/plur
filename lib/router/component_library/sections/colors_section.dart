import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../components/component_example.dart';
import '../components/section_header.dart';

/// Colors section of the component library
class ColorsSection extends StatelessWidget {
  const ColorsSection({super.key});
  
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Brand Colors
        const SectionHeader(
          title: 'Brand Colors',
          subtitle: 'Primary brand colors used throughout the app',
        ),
        ComponentExample(
          title: 'Primary & Accent',
          example: Row(
            children: [
              _ColorSwatch(
                name: 'Primary Purple',
                color: const Color(0xFF7445FE),
                hex: '#7445FE',
              ),
              const SizedBox(width: 16),
              _ColorSwatch(
                name: 'Accent Teal',
                color: const Color(0xFF009994),
                hex: '#009994',
              ),
            ],
          ),
        ),
        
        // Text Colors
        const SectionHeader(
          title: 'Text Colors',
          subtitle: 'Colors for different text elements',
        ),
        ComponentExample(
          title: isDarkMode ? 'Dark Mode Text' : 'Light Mode Text',
          example: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _ColorSwatch(
                    name: 'Primary Text',
                    color: colors.primaryText,
                    hex: isDarkMode ? '#B6A0E1' : '#4B3997',
                  ),
                  const SizedBox(width: 16),
                  _ColorSwatch(
                    name: 'Secondary Text',
                    color: colors.secondaryText,
                    hex: isDarkMode ? '#93A5B7' : '#837AA0',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _ColorSwatch(
                    name: 'Button Text',
                    color: colors.buttonText,
                    hex: '#FFFFFF',
                  ),
                  const SizedBox(width: 16),
                  _ColorSwatch(
                    name: 'Highlight Text',
                    color: colors.highlightText,
                    hex: isDarkMode ? '#ECE2FD' : '#231F32',
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Background Colors
        const SectionHeader(
          title: 'Background Colors',
          subtitle: 'Colors for surfaces and backgrounds',
        ),
        ComponentExample(
          title: isDarkMode ? 'Dark Mode Backgrounds' : 'Light Mode Backgrounds',
          example: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _ColorSwatch(
                    name: 'Background',
                    color: colors.background,
                    hex: isDarkMode ? '#150F23' : '#FFFFFF',
                  ),
                  const SizedBox(width: 16),
                  _ColorSwatch(
                    name: 'Surface',
                    color: colors.surface,
                    hex: isDarkMode ? '#190F28' : '#F5F2FF',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _ColorSwatch(
                    name: 'Login Background',
                    color: colors.loginBackground,
                    hex: '#150F23',
                  ),
                  const SizedBox(width: 16),
                  _ColorSwatch(
                    name: 'Card Background',
                    color: colors.cardBackground,
                    hex: isDarkMode ? '#231F32' : '#FFFFFF',
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Special Colors
        const SectionHeader(
          title: 'Special Colors',
          subtitle: 'Colors for specific UI elements',
        ),
        ComponentExample(
          title: 'UI Elements',
          example: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _ColorSwatch(
                    name: 'Input Background',
                    color: const Color(0xFF11171F),
                    hex: '#11171F',
                  ),
                  const SizedBox(width: 16),
                  _ColorSwatch(
                    name: 'Input Border',
                    color: const Color(0xFF2E4052),
                    hex: '#2E4052',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _ColorSwatch(
                    name: 'Divider',
                    color: colors.divider,
                    hex: isDarkMode ? '#27193D' : '#E5DBFF',
                  ),
                  const SizedBox(width: 16),
                  _ColorSwatch(
                    name: 'Shadow',
                    color: colors.shadow,
                    hex: '#000000',
                    opacity: 0.1,
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // State Colors
        const SectionHeader(
          title: 'State Colors',
          subtitle: 'Colors for different states and feedback',
        ),
        ComponentExample(
          title: 'States',
          example: Row(
            children: [
              _ColorSwatch(
                name: 'Error',
                color: colors.error,
                hex: '#FF4B4B',
              ),
              const SizedBox(width: 16),
              _ColorSwatch(
                name: 'Success',
                color: colors.success,
                hex: '#00BFA5',
              ),
              const SizedBox(width: 16),
              _ColorSwatch(
                name: 'Warning',
                color: colors.warning,
                hex: '#FFB74D',
              ),
            ],
          ),
        ),
        
        // Opacity Examples
        const SectionHeader(
          title: 'Opacity Levels',
          subtitle: 'Common opacity values used',
        ),
        ComponentExample(
          title: 'Accent Color Opacity',
          example: Row(
            children: [
              _ColorSwatch(
                name: '100%',
                color: colors.accent,
                hex: '#009994',
              ),
              const SizedBox(width: 16),
              _ColorSwatch(
                name: '70%',
                color: colors.accent.withAlpha((255 * 0.7).round()),
                hex: '#009994',
                opacity: 0.7,
              ),
              const SizedBox(width: 16),
              _ColorSwatch(
                name: '40%',
                color: colors.accent.withAlpha((255 * 0.4).round()),
                hex: '#009994',
                opacity: 0.4,
              ),
              const SizedBox(width: 16),
              _ColorSwatch(
                name: '15%',
                color: colors.accent.withAlpha((255 * 0.15).round()),
                hex: '#009994',
                opacity: 0.15,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Color swatch widget for displaying colors
class _ColorSwatch extends StatelessWidget {
  final String name;
  final Color color;
  final String hex;
  final double opacity;
  
  const _ColorSwatch({
    required this.name,
    required this.color,
    required this.hex,
    this.opacity = 1.0,
  });
  
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: colors.divider,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 80,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(7),
                  topRight: Radius.circular(7),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontFamily: 'SF Pro Rounded',
                      color: colors.primaryText,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    opacity < 1.0 ? '$hex ${(opacity * 100).round()}%' : hex,
                    style: TextStyle(
                      fontFamily: 'SF Pro Rounded',
                      color: colors.secondaryText,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}