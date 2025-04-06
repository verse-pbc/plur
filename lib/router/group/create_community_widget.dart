import 'package:flutter/material.dart';
import 'package:nostrmo/generated/l10n.dart';

class CreateCommunityWidget extends StatefulWidget {
  final void Function(String) onCreateCommunity;

  const CreateCommunityWidget({super.key, required this.onCreateCommunity});

  @override
  State<CreateCommunityWidget> createState() => _CreateCommunityWidgetState();
}

class _CreateCommunityWidgetState extends State<CreateCommunityWidget> {
  final TextEditingController _communityNameController =
      TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final localization = S.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Header
        Icon(
          Icons.groups_rounded,
          size: 48,
          // Use the theme's icon color
          color: themeData.primaryColor,
        ),
        const SizedBox(height: 16),
        Text(
          "Create your community",
          style: themeData.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ) ?? TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: themeData.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Connect with others in your own shared space",
          style: themeData.textTheme.bodyMedium?.copyWith(
            color: themeData.colorScheme.onSurface.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        
        // Form
        Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Community Name",
                style: themeData.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _communityNameController,
                decoration: InputDecoration(
                  hintText: "Enter a memorable name",
                  hintStyle: TextStyle(
                    color: themeData.hintColor,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: themeData.colorScheme.outline,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      width: 2,
                      color: themeData.primaryColor,
                    ),
                  ),
                  filled: true,
                  fillColor: themeData.cardColor,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                style: themeData.textTheme.bodyLarge,
                onChanged: (text) {
                  setState(() {});
                },
                enabled: !_isLoading,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 8),
              Text(
                "Choose a name that represents your community's purpose",
                style: themeData.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: themeData.hintColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        
        // Button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: themeData.primaryColor,
                  ),
                )
              : ElevatedButton(
                  onPressed: _communityNameController.text.isNotEmpty
                      ? () => _handleCreateCommunity()
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeData.primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: themeData.primaryColor.withOpacity(0.5),
                    disabledForegroundColor: Colors.white.withOpacity(0.5),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: Text(localization.Confirm),
                ),
        ),
      ],
    );
  }

  void _handleCreateCommunity() {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });
    
    widget.onCreateCommunity(_communityNameController.text);
    // No need to set _isLoading back to false as we'll transition to the next screen
  }
}
