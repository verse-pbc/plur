import 'package:flutter/material.dart';
import 'package:nostrmo/generated/l10n.dart';
import 'package:nostrmo/services/analytics_service.dart';

/// Widget that allows users to configure analytics settings.
/// 
/// This widget provides a toggle to opt in or out of analytics
/// and displays information about what data is collected.
class AnalyticsSettingsWidget extends StatefulWidget {
  const AnalyticsSettingsWidget({Key? key}) : super(key: key);

  @override
  State<AnalyticsSettingsWidget> createState() => _AnalyticsSettingsWidgetState();
}

class _AnalyticsSettingsWidgetState extends State<AnalyticsSettingsWidget> {
  final AnalyticsService _analyticsService = AnalyticsService();
  bool _analyticsEnabled = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // Get the current opt-out status
    setState(() {
      _analyticsEnabled = !_analyticsService.isOptedOut;
      _loading = false;
    });
  }

  Future<void> _toggleAnalytics(bool enabled) async {
    setState(() {
      _loading = true;
    });

    try {
      // Update the opt-out preference
      await _analyticsService.setOptOut(!enabled);
      
      setState(() {
        _analyticsEnabled = enabled;
      });
    } catch (e) {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update analytics preference: $e')),
      );
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = S.of(context);
    final themeData = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(localization.Analytics), // Add this string to l10n files
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main toggle for analytics
                SwitchListTile(
                  title: Text(
                    localization.Enable_Analytics, // Add this string to l10n files
                    style: themeData.textTheme.titleMedium,
                  ),
                  subtitle: Text(
                    localization.Help_us_improve_the_app_by_sharing_usage_data, // Add this string to l10n files
                  ),
                  value: _analyticsEnabled,
                  onChanged: _toggleAnalytics,
                ),
                const SizedBox(height: 24),
                
                // Information about what data is collected
                Text(
                  localization.What_We_Collect, // Add this string to l10n files
                  style: themeData.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                _buildInfoCard(
                  icon: Icons.touch_app,
                  title: localization.App_Usage, // Add this string to l10n files
                  description: localization.We_collect_anonymous_data_about_which_features_you_use, // Add this string to l10n files
                ),
                _buildInfoCard(
                  icon: Icons.devices,
                  title: localization.Device_Information, // Add this string to l10n files
                  description: localization.We_collect_basic_device_info_like_OS_version, // Add this string to l10n files
                ),
                _buildInfoCard(
                  icon: Icons.bar_chart,
                  title: localization.Performance_Metrics, // Add this string to l10n files
                  description: localization.We_track_app_performance_to_identify_and_fix_issues, // Add this string to l10n files
                ),
                
                // Information about what data is NOT collected
                const SizedBox(height: 24),
                Text(
                  localization.What_We_Dont_Collect, // Add this string to l10n files
                  style: themeData.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                _buildInfoCard(
                  icon: Icons.message,
                  title: localization.Message_Content, // Add this string to l10n files
                  description: localization.We_NEVER_track_the_content_of_your_messages_or_posts, // Add this string to l10n files
                  isPositive: false,
                ),
                _buildInfoCard(
                  icon: Icons.person,
                  title: localization.Identity_Information, // Add this string to l10n files
                  description: localization.We_NEVER_track_your_nostr_public_key_or_personal_identifiers, // Add this string to l10n files
                  isPositive: false,
                ),
                _buildInfoCard(
                  icon: Icons.group,
                  title: localization.Community_Names, // Add this string to l10n files
                  description: localization.We_NEVER_track_the_names_of_your_communities_or_contacts, // Add this string to l10n files
                  isPositive: false,
                ),
                
                // Privacy policy and data usage
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localization.Privacy_Policy, // Add this string to l10n files
                          style: themeData.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          localization.For_more_information_about_how_we_handle_your_data, // Add this string to l10n files
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: () {
                            // Navigate to privacy policy or open web link
                          },
                          child: Text(localization.View_Privacy_Policy), // Add this string to l10n files
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
    bool isPositive = true,
  }) {
    final themeData = Theme.of(context);
    final iconColor = isPositive 
      ? themeData.colorScheme.primary
      : themeData.colorScheme.error;
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: themeData.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: themeData.textTheme.bodyMedium,
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