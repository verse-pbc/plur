import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../generated/l10n.dart';
import 'sections/typography_section.dart';
import 'sections/colors_section.dart';
import 'sections/buttons_section.dart';

/// Main component library screen
class ComponentLibraryWidget extends StatefulWidget {
  const ComponentLibraryWidget({super.key});

  @override
  State<ComponentLibraryWidget> createState() => _ComponentLibraryWidgetState();
}

class _ComponentLibraryWidgetState extends State<ComponentLibraryWidget> {
  String _selectedSection = 'typography';
  
  final List<Map<String, dynamic>> _sections = [
    {'id': 'typography', 'name': 'Typography', 'icon': Icons.text_fields},
    {'id': 'colors', 'name': 'Colors', 'icon': Icons.palette},
    {'id': 'buttons', 'name': 'Buttons', 'icon': Icons.smart_button},
    {'id': 'forms', 'name': 'Form Elements', 'icon': Icons.input},
    {'id': 'cards', 'name': 'Cards & Containers', 'icon': Icons.dashboard},
    {'id': 'navigation', 'name': 'Navigation', 'icon': Icons.menu},
    {'id': 'feedback', 'name': 'Feedback', 'icon': Icons.feedback},
    {'id': 'modals', 'name': 'Modals & Sheets', 'icon': Icons.open_in_new},
    {'id': 'responsive', 'name': 'Responsive', 'icon': Icons.devices},
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        title: Text(
          'Component Library',
          style: TextStyle(
            fontFamily: 'SF Pro Rounded',
            color: colors.primaryText,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.primaryText),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isDesktop ? _buildDesktopLayout(colors) : _buildMobileLayout(colors),
    );
  }
  
  Widget _buildDesktopLayout(AppColors colors) {
    return Row(
      children: [
        // Sidebar navigation
        Container(
          width: 280,
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border(
              right: BorderSide(
                color: colors.divider,
                width: 1,
              ),
            ),
          ),
          child: _buildSidebar(colors),
        ),
        // Main content area
        Expanded(
          child: _buildContent(colors),
        ),
      ],
    );
  }
  
  Widget _buildMobileLayout(AppColors colors) {
    return Column(
      children: [
        // Horizontal scrollable tabs
        Container(
          height: 60,
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border(
              bottom: BorderSide(
                color: colors.divider,
                width: 1,
              ),
            ),
          ),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _sections.length,
            itemBuilder: (context, index) {
              final section = _sections[index];
              final isSelected = section['id'] == _selectedSection;
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedSection = section['id'];
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  child: Text(
                    section['name'],
                    style: TextStyle(
                      fontFamily: 'SF Pro Rounded',
                      color: isSelected ? colors.accent : colors.secondaryText,
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // Content area
        Expanded(
          child: _buildContent(colors),
        ),
      ],
    );
  }
  
  Widget _buildSidebar(AppColors colors) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 24),
      itemCount: _sections.length,
      itemBuilder: (context, index) {
        final section = _sections[index];
        final isSelected = section['id'] == _selectedSection;
        
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedSection = section['id'];
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? colors.accent.withAlpha((255 * 0.1).round()) : Colors.transparent,
              border: Border(
                left: BorderSide(
                  color: isSelected ? colors.accent : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  section['icon'],
                  color: isSelected ? colors.accent : colors.secondaryText,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  section['name'],
                  style: TextStyle(
                    fontFamily: 'SF Pro Rounded',
                    color: isSelected ? colors.accent : colors.primaryText,
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildContent(AppColors colors) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getSectionTitle(),
              style: TextStyle(
                fontFamily: 'SF Pro Rounded',
                color: colors.highlightText,
                fontSize: 32,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getSectionDescription(),
              style: TextStyle(
                fontFamily: 'SF Pro Rounded',
                color: colors.secondaryText,
                fontSize: 16,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            _buildSectionContent(colors),
          ],
        ),
      ),
    );
  }
  
  String _getSectionTitle() {
    final section = _sections.firstWhere((s) => s['id'] == _selectedSection);
    return section['name'];
  }
  
  String _getSectionDescription() {
    switch (_selectedSection) {
      case 'typography':
        return 'All text styles and typography used throughout the app.';
      case 'colors':
        return 'Complete color palette including light and dark mode variations.';
      case 'buttons':
        return 'Button components in different sizes and states.';
      case 'forms':
        return 'Form elements including inputs, checkboxes, and select boxes.';
      case 'cards':
        return 'Card layouts and container components.';
      case 'navigation':
        return 'Navigation patterns for mobile and desktop.';
      case 'feedback':
        return 'User feedback components like toasts and progress indicators.';
      case 'modals':
        return 'Modal dialogs, bottom sheets, and popovers.';
      case 'responsive':
        return 'Responsive design examples and breakpoints.';
      default:
        return '';
    }
  }
  
  Widget _buildSectionContent(AppColors colors) {
    switch (_selectedSection) {
      case 'typography':
        return _buildTypographySection(colors);
      case 'colors':
        return _buildColorsSection(colors);
      case 'buttons':
        return _buildButtonsSection(colors);
      default:
        return Center(
          child: Text(
            'Section coming soon...',
            style: TextStyle(
              fontFamily: 'SF Pro Rounded',
              color: colors.secondaryText,
              fontSize: 18,
            ),
          ),
        );
    }
  }
  
  Widget _buildTypographySection(AppColors colors) {
    return const TypographySection();
  }
  
  Widget _buildColorsSection(AppColors colors) {
    return const ColorsSection();
  }
  
  Widget _buildButtonsSection(AppColors colors) {
    return const ButtonsSection();
  }
}