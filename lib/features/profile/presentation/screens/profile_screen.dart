import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
// import 'package:go_router/go_router.dart'; // Not used directly here yet

import '../../../../core/providers/settings_provider.dart';
import '../../../../core/themes/app_color.dart'; // Used indirectly via theme
import '../../../../l10n/l10n.dart'; // Import localization extension

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _log = Logger('ProfileScreen');

  // TODO: Fetch version dynamically
  final String _appVersion = '1.0.0';
  final String _buildNumber = '1';

  @override
  Widget build(BuildContext context) {
    // Watch the provider state
    final settingsState = ref.watch(settingsProvider);
    // Get the notifier to call methods like setThemeMode
    final settingsNotifier = ref.read(settingsProvider.notifier);

    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;

    // Using a Scaffold for structure, including AppBar
    return Scaffold(
       appBar: AppBar(
          title: Text(context.l10n.profile_title),
          backgroundColor: theme.appBarTheme.backgroundColor, // Use theme color
          foregroundColor: theme.appBarTheme.foregroundColor,
          elevation: 0, // Keep AppBar flat
          automaticallyImplyLeading: false, // No back button needed on main tabs
          actions: const [], // No actions for now
       ),
      backgroundColor: theme.scaffoldBackgroundColor, // Use theme background
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Section: Reading Preferences
          _buildSectionHeader(context, context.l10n.reading_preferences),
          _buildThemeToggle(context, settingsState, settingsNotifier, colors),
          _buildFontSizeSelector(context, settingsState, settingsNotifier, colors),
          const Divider(height: 1, thickness: 0.5),

          // Section: App Settings
          const SizedBox(height: 16),
          _buildSectionHeader(context, context.l10n.app_settings),
          _buildLanguageSelector(context, settingsState, settingsNotifier, colors),
          _buildSettingsItem(context, context.l10n.notifications, Icons.notifications_outlined, () {
            // TODO: Navigate to Notification Settings Screen
            _log.info('Notifications tapped');
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notification settings not implemented yet.')));
          }),
          _buildSettingsItem(context, context.l10n.download_settings, Icons.download_outlined, () {
            // TODO: Navigate to Download Settings Screen
            _log.info('Download Settings tapped');
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Download settings not implemented yet.')));
          }),
          const Divider(height: 1, thickness: 0.5),

          // Section: Support & Info
          const SizedBox(height: 16),
          _buildSectionHeader(context, context.l10n.support_info),
          _buildSettingsItem(context, context.l10n.help_faq, Icons.help_outline, () {
            // TODO: Navigate to Help Screen or open URL
            _log.info('Help & FAQ tapped');
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Help not implemented yet.')));
          }),
          _buildSettingsItem(context, context.l10n.contact_us, Icons.contact_support_outlined, () {
            // TODO: Navigate to Contact Screen or show contact info
            _log.info('Contact Us tapped');
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contact info not available yet.')));
          }),
          _buildSettingsItem(context, context.l10n.privacy_policy, Icons.privacy_tip_outlined, () {
            // TODO: Navigate to Privacy Policy Screen or open URL
            _log.info('Privacy Policy tapped');
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Privacy Policy not available yet.')));
          }),
          const Divider(height: 1, thickness: 0.5),

          // Section: App Details
          const SizedBox(height: 16),
          _buildSectionHeader(context, context.l10n.app_details),
          _buildInfoItem(context, context.l10n.app_version, _appVersion),
          _buildInfoItem(context, context.l10n.build_number, _buildNumber),
          const Divider(height: 1, thickness: 0.5),

          // Section: Logout (Optional - Add if auth implemented)
          // const SizedBox(height: 24),
          // Center(
          //   child: TextButton.icon(
          //     icon: Icon(Icons.logout, color: theme.colorScheme.error),
          //     label: Text('Logout', style: TextStyle(color: theme.colorScheme.error)),
          //     onPressed: () { /* TODO: Implement Logout */ },
          //   ),
          // ),
        ],
      ),
    );
  }

  // --- Helper Widgets --- 

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 16.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary, // Use primary color for headers
        ),
      ),
    );
  }

  Widget _buildThemeToggle(
      BuildContext context,
      SettingsState settingsState,
      SettingsNotifier settingsNotifier,
      ColorScheme colors
    ) {
    final theme = Theme.of(context);
    
    // Check which theme is selected
    final isLightMode = settingsState.themeMode == AppThemeMode.light;
    final isDarkMode = settingsState.themeMode == AppThemeMode.dark;
    final isSystemMode = settingsState.themeMode == AppThemeMode.system;
    final isSepiaMode = settingsState.themeMode == AppThemeMode.sepia;

    // Icons for the toggle buttons
    const lightIcon = Icons.wb_sunny_outlined;
    const systemIcon = Icons.brightness_auto_outlined;
    const darkIcon = Icons.nightlight_outlined;
    const sepiaIcon = Icons.color_lens_outlined;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.brightness_6_outlined, color: theme.iconTheme.color?.withOpacity(0.7)),
              const SizedBox(width: 16),
              Text(context.l10n.appearance, style: theme.textTheme.bodyLarge),
            ],
          ),
          ToggleButtons(
            isSelected: [isLightMode, isSystemMode, isDarkMode, isSepiaMode],
            onPressed: (index) {
              AppThemeMode newMode;
              switch (index) {
                case 0:
                  newMode = AppThemeMode.light;
                  break;
                case 1:
                  newMode = AppThemeMode.system;
                  break;
                case 2:
                  newMode = AppThemeMode.dark;
                  break;
                case 3:
                  newMode = AppThemeMode.sepia;
                  break;
                default:
                  newMode = AppThemeMode.system;
              }
              settingsNotifier.setThemeMode(newMode);
            },
            borderRadius: BorderRadius.circular(8.0),
            selectedColor: colors.onPrimary,
            color: theme.iconTheme.color?.withOpacity(0.7),
            fillColor: colors.primary, 
            constraints: const BoxConstraints(minHeight: 36.0, minWidth: 40.0),
            children: const [
              Icon(lightIcon, size: 16),
              Icon(systemIcon, size: 16),
              Icon(darkIcon, size: 16),
              Icon(sepiaIcon, size: 16),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFontSizeSelector(
      BuildContext context,
      SettingsState settingsState,
      SettingsNotifier settingsNotifier,
      ColorScheme colors
    ) {
    final theme = Theme.of(context);
    
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.format_size, color: theme.iconTheme.color?.withOpacity(0.7)),
      title: Text(context.l10n.font_size, style: theme.textTheme.bodyLarge),
      trailing: SegmentedButton<FontSize>(
        segments: [
          ButtonSegment<FontSize>(
            value: FontSize.small,
            label: Text(context.l10n.small, style: TextStyle(fontSize: 12)),
          ),
          ButtonSegment<FontSize>(
            value: FontSize.medium,
            label: Text(context.l10n.medium, style: TextStyle(fontSize: 14)),
          ),
          ButtonSegment<FontSize>(
            value: FontSize.large,
            label: Text(context.l10n.large, style: TextStyle(fontSize: 16)),
          ),
        ],
        selected: {settingsState.fontSize},
        onSelectionChanged: (newSelection) {
          settingsNotifier.setFontSize(newSelection.first);
        },
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
  
  Widget _buildLanguageSelector(
      BuildContext context,
      SettingsState settingsState,
      SettingsNotifier settingsNotifier,
      ColorScheme colors
    ) {
    final theme = Theme.of(context);
    
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.language, color: theme.iconTheme.color?.withOpacity(0.7)),
      title: Text(context.l10n.language, style: theme.textTheme.bodyLarge),
      trailing: DropdownButtonHideUnderline(
        child: DropdownButton<AppLanguage>(
          value: settingsState.language,
          items: AppLanguage.values.map((AppLanguage value) {
            return DropdownMenuItem<AppLanguage>(
              value: value,
              child: Text(value.displayName, style: theme.textTheme.bodyMedium),
            );
          }).toList(),
          onChanged: (newValue) {
            if (newValue != null) {
              settingsNotifier.setLanguage(newValue);
            }
          },
          style: theme.textTheme.bodyLarge, // Ensure dropdown text style matches
          icon: Icon(Icons.arrow_drop_down, color: theme.iconTheme.color?.withOpacity(0.7)),
        ),
      ),
    );
  }

  Widget _buildSettingsItem(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: theme.iconTheme.color?.withOpacity(0.7)),
      title: Text(title, style: theme.textTheme.bodyLarge),
      trailing: Icon(Icons.chevron_right, color: theme.iconTheme.color?.withOpacity(0.7)),
      onTap: onTap,
    );
  }

  Widget _buildInfoItem(BuildContext context, String title, String value) {
     final theme = Theme.of(context);
     return Padding(
       padding: const EdgeInsets.symmetric(vertical: 12.0),
       child: Row(
         mainAxisAlignment: MainAxisAlignment.spaceBetween,
         children: [
           Text(title, style: theme.textTheme.bodyLarge),
           Text(value, style: theme.textTheme.bodyMedium?.copyWith(
             color: theme.textTheme.bodySmall?.color // Use secondary text color
           )),
         ],
       ),
     );
  }
}
