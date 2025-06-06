import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:modudi/core/cache/cache_service.dart';

import 'package:modudi/core/providers/providers.dart';
import 'package:modudi/features/settings/presentation/providers/app_settings_provider.dart'; // Use proper app settings provider
import 'package:modudi/core/themes/app_color.dart';
import 'package:modudi/core/themes/app_theme.dart'; // Import for AppFontScaling extension
import 'package:modudi/core/l10n/app_localizations_wrapper.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _log = Logger('ProfileScreen');

  // App version info
  final String _appVersion = '1.0.0';
  final String _buildNumber = '1';

  @override
  Widget build(BuildContext context) {
    // Watch the app settings provider state
    final appSettings = ref.watch(appSettingsProvider);
    // Get the notifier to call methods like setThemeMode
    final appSettingsNotifier = ref.read(appSettingsProvider.notifier);
    
    // Get font scale from app settings
    final fontScale = appSettings.fontScale;

    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isSepia = theme.primaryColor == AppColor.primarySepia;
    
    // Theme-specific colors
    final backgroundColor = isDark 
        ? AppColor.backgroundDark 
        : isSepia 
            ? AppColor.backgroundSepia 
            : AppColor.background;
    final textColor = isDark 
        ? AppColor.textPrimaryDark 
        : isSepia 
            ? AppColor.textPrimarySepia 
            : AppColor.textPrimary;
    final secondaryTextColor = isDark 
        ? AppColor.textSecondaryDark 
        : isSepia 
            ? AppColor.textSecondarySepia 
            : AppColor.textSecondary;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: backgroundColor,
        centerTitle: true,
        systemOverlayStyle: isDark
          ? SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: backgroundColor,
            )
          : SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: backgroundColor,
            ),
        title: Text(
          'Profile',
          style: GoogleFonts.playfairDisplay(
            textStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600
            ).withAppFontScale(fontScale), 
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        physics: const BouncingScrollPhysics(),
        children: [
          // Reading preferences section
          _buildSectionHeader('Reading Preferences', textColor, fontScale),
          const SizedBox(height: 16),
          _buildThemeToggle(context, appSettings, appSettingsNotifier, colors, textColor, fontScale),
          const SizedBox(height: 32),
          
          // App settings section
          _buildSectionHeader('App Settings', textColor, fontScale),
          const SizedBox(height: 16),
          _buildLanguageSelector(context, appSettings, appSettingsNotifier, colors, textColor, fontScale),
          const SizedBox(height: 16),
          _buildFontSizeSelector(context, appSettings, appSettingsNotifier, colors, textColor, secondaryTextColor),
          const SizedBox(height: 16),
          _buildSettingCard(
            context,
            'Notifications',
            AppLocalizations.of(context)!.profileScreenManageNotificationsSubtitle,
            Icons.notifications_outlined,
            colors,
            textColor,
            secondaryTextColor,
            fontScale,
            () {
              _log.info('Notifications tapped');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context)!.profileScreenNotificationsNotImplementedSnackbar),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildSettingCard(
            context,
            AppLocalizations.of(context)!.profileScreenCacheManagementTitle,
            AppLocalizations.of(context)!.profileScreenCacheManagementSubtitle,
            Icons.storage_outlined,
            colors,
            textColor,
            secondaryTextColor,
            fontScale,
            () {
              _log.info('Cache Management tapped');
              _showCacheManagementDialog(context, ref);
            },
          ),
          const SizedBox(height: 32),
          
          // Support & info section
          _buildSectionHeader('Support & Info', textColor, fontScale),
          const SizedBox(height: 16),
          _buildSupportInfoSection(context, colors, textColor, secondaryTextColor, fontScale),
          const SizedBox(height: 32),

          // App info section
          _buildSectionHeader(AppLocalizations.of(context)!.profileScreenAppInfoTitle, textColor, fontScale),
          const SizedBox(height: 16),
          _buildAppInfoCard(context, colors, textColor, secondaryTextColor, fontScale),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color textColor, double fontScale) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.playfairDisplay(
          textStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: textColor,
            fontWeight: FontWeight.w600
          ).withAppFontScale(fontScale), 
        ),
      ),
    );
  }

  // Build a card with theme options (Light, Sepia, Dark)
  Widget _buildThemeToggle(
    BuildContext context, 
    AppSettingsState appSettings, 
    AppSettingsNotifier appSettingsNotifier, 
    ColorScheme colors,
    Color textColor,
    double fontScale
  ) {
    final themeMode = appSettings.themeMode;
    final isSepia = appSettings.isSepia;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      elevation: isDark ? 1 : 0.3,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSepia 
              ? AppColor.primarySepia.withValues(alpha: 0.1) 
              : isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.05),
          width: 0.5,
        ),
      ),
      color: isSepia 
          ? AppColor.surfaceSepia.withValues(alpha: 0.5) 
          : isDark
              ? colors.surface.withValues(alpha: 0.5)
              : colors.surface.withValues(alpha: 0.8),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.brightness_4, 
                    color: isSepia ? AppColor.primarySepia : colors.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context)!.profileScreenThemeLabel,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    letterSpacing: 0.1,
                  ).withAppFontScale(fontScale),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildThemeOption(
                  context, 
                  Icons.light_mode, 
                  AppLocalizations.of(context)!.profileScreenThemeLight, 
                  AppThemeMode.light, 
                  themeMode, 
                  appSettingsNotifier,
                  colors,
                  fontScale
                ),
                _buildThemeOption(
                  context, 
                  Icons.menu_book, 
                  AppLocalizations.of(context)!.profileScreenThemeSepia, 
                  AppThemeMode.sepia, 
                  themeMode, 
                  appSettingsNotifier,
                  colors,
                  fontScale
                ),
                _buildThemeOption(
                  context, 
                  Icons.dark_mode, 
                  AppLocalizations.of(context)!.profileScreenThemeDark, 
                  AppThemeMode.dark, 
                  themeMode, 
                  appSettingsNotifier,
                  colors,
                  fontScale
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Build an individual theme option button with icon and label
  Widget _buildThemeOption(
    BuildContext context,
    IconData icon,
    String label,
    AppThemeMode mode,
    AppThemeMode currentMode,
    AppSettingsNotifier appSettingsNotifier,
    ColorScheme colors,
    double fontScale,
  ) {
    final isSelected = mode == currentMode;
    final isSepia = Theme.of(context).primaryColor == AppColor.primarySepia;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return InkWell(
      onTap: () {
        appSettingsNotifier.setThemeMode(mode);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected 
              ? colors.primary.withValues(alpha: 0.9)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? colors.primary 
                : isSepia
                    ? AppColor.primarySepia.withValues(alpha: 0.2)
                    : isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : colors.outline.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon, 
              color: isSelected 
                  ? Colors.white 
                  : isSepia
                      ? AppColor.primarySepia
                      : colors.primary,
              size: 22,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected 
                    ? Colors.white 
                    : isSepia
                        ? AppColor.primarySepia
                        : colors.primary,
              ).withAppFontScale(fontScale),
            ),
          ],
        ),
      ),
    );
  }


  // Build language selector with options
  Widget _buildLanguageSelector(
      BuildContext context,
      AppSettingsState appSettings,
      AppSettingsNotifier appSettingsNotifier,
      ColorScheme colors,
      Color textColor,
      double fontScale
    ) {
    final currentLanguage = appSettings.language;
    final isSepia = appSettings.isSepia;
    final isDark = Theme.of(context).brightness == Brightness.dark;
      
    return Card(
      elevation: isDark ? 1 : 0.3,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSepia 
              ? AppColor.primarySepia.withValues(alpha: 0.1) 
              : isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.05),
          width: 0.5,
        ),
      ),
      color: isSepia 
          ? AppColor.surfaceSepia.withValues(alpha: 0.5) 
          : isDark
              ? colors.surface.withValues(alpha: 0.5)
              : colors.surface.withValues(alpha: 0.8),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.language, 
                    color: isSepia ? AppColor.primarySepia : colors.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context)!.profileScreenLanguageLabel,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    letterSpacing: 0.1,
                  ).withAppFontScale(fontScale),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: AppLanguage.values.map((language) {
                  final isSelected = language == currentLanguage;
                  final backgroundColor = isSelected ? colors.primary : colors.surface.withValues(alpha: 0.7);
                  
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => appSettingsNotifier.setLanguage(language),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            color: backgroundColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? colors.primary : colors.outline.withValues(alpha: 0.2),
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: isSelected ? [
                              BoxShadow(
                                color: colors.primary.withAlpha((255 * 0.2).round()),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ] : null,
                          ),
                          child: Text(
                            language.displayName,
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: isSelected ? Colors.white : colors.onSurfaceVariant,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              letterSpacing: 0.2,
                            ).withAppFontScale(fontScale),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build a setting card with icon, title, and subtitle
  Widget _buildSettingCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    ColorScheme colors,
    Color textColor,
    Color secondaryTextColor,
    double fontScale,
    VoidCallback onTap,
  ) {
    final isSepia = Theme.of(context).primaryColor == AppColor.primarySepia;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      elevation: isDark ? 1 : 0.3,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSepia 
              ? AppColor.primarySepia.withValues(alpha: 0.1) 
              : isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.05),
          width: 0.5,
        ),
      ),
      color: isSepia 
          ? AppColor.surfaceSepia.withValues(alpha: 0.5) 
          : isDark
              ? colors.surface.withValues(alpha: 0.5)
              : colors.surface.withValues(alpha: 0.8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon, 
                  color: isSepia ? AppColor.primarySepia : colors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                        letterSpacing: 0.1,
                      ).withAppFontScale(fontScale),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: secondaryTextColor,
                        letterSpacing: 0.1,
                      ).withAppFontScale(fontScale),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isSepia ? AppColor.primarySepia : colors.primary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Build support card with help and contact options
  Widget _buildSupportInfoSection(BuildContext context, ColorScheme colors, Color textColor, Color secondaryTextColor, double fontScale) {
    return Column(
      children: [
        _buildSettingCard(
          context,
          AppLocalizations.of(context)!.profileScreenHelpFAQTitle,
          AppLocalizations.of(context)!.profileScreenHelpFAQSubtitle,
          Icons.help_outline,
          colors,
          textColor,
          secondaryTextColor,
          fontScale,
          () {
            _log.info('Help & FAQ tapped');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.profileScreenHelpNotImplementedSnackbar),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        _buildSettingCard(
          context,
          AppLocalizations.of(context)!.profileScreenContactUsTitle,
          AppLocalizations.of(context)!.profileScreenContactUsSubtitle,
          Icons.contact_support_outlined,
          colors,
          textColor,
          secondaryTextColor,
          fontScale,
          () {
            _log.info('Contact Us tapped');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.profileScreenContactNotAvailableSnackbar),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
          },
        ),
      ],
    );
  }
  
  // Build app info card with version information
  Widget _buildAppInfoCard(BuildContext context, ColorScheme colors, Color textColor, Color secondaryTextColor, double fontScale) {
    final isSepia = Theme.of(context).primaryColor == AppColor.primarySepia;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      elevation: isDark ? 1 : 0.3,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSepia 
              ? AppColor.primarySepia.withValues(alpha: 0.1) 
              : isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.05),
          width: 0.5,
        ),
      ),
      color: isSepia 
          ? AppColor.surfaceSepia.withValues(alpha: 0.5) 
          : isDark
              ? colors.surface.withValues(alpha: 0.5)
              : colors.surface.withValues(alpha: 0.8),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.info_outline, 
                color: isSepia ? AppColor.primarySepia : colors.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.profileScreenVersionLabel,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                      letterSpacing: 0.1,
                    ).withAppFontScale(fontScale),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$_appVersion ($_buildNumber)',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isSepia ? AppColor.primarySepia : colors.primary,
                        letterSpacing: 0.1,
                      ).withAppFontScale(fontScale),
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

  // Method to show cache management dialog
  void _showCacheManagementDialog(BuildContext context, WidgetRef ref) async {
    _log.info('Showing Cache Management Dialog');
    HapticFeedback.mediumImpact();
    
    // Get cache service instance via provider
    final CacheService cacheService = await ref.read(cacheServiceProvider.future);
    
    // Get current cache sizes
    final String memoryCacheSize = cacheService.getFormattedMemoryCacheSize(); // Removed await
    final String hiveCacheSize = await cacheService.getFormattedPersistentCacheSize();
    final String totalCacheSize = await cacheService.getFormattedTotalCacheSize();
    
    // Show the dialog
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.profileScreenCacheManagementTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total cache size: $totalCacheSize'),
              const SizedBox(height: 16),
              _buildCacheInfoRow(AppLocalizations.of(context)!.profileScreenCacheDialogMemoryCacheLabel, memoryCacheSize),
              _buildCacheInfoRow(AppLocalizations.of(context)!.profileScreenCacheDialogPersistentCacheLabel, hiveCacheSize),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.profileScreenCacheDialogDescription,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.profileScreenCancelButton),
          ),
          ElevatedButton(
            onPressed: () {
              _log.info('Clear Memory Cache button tapped');
              final memoryClearedMessage = AppLocalizations.of(context)!.profileScreenMemoryCacheClearedSnackbar;
              cacheService.clearMemoryCache(); 
              if (!mounted) return;
              Navigator.of(context).pop(); 
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(memoryClearedMessage)),
              );
            },
            child: Text(AppLocalizations.of(context)!.profileScreenClearMemoryCacheButton),
          ),
          ElevatedButton(
            onPressed: () async {
              _log.info('Clear Persistent Cache button tapped');
              final persistentClearedMessage = AppLocalizations.of(context)!.profileScreenPersistentCacheClearedSnackbar;
              await cacheService.clearPersistentCache(); 
              if (!mounted) return;
              Navigator.of(context).pop(); 
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(persistentClearedMessage)),
              );
            },
            child: Text(AppLocalizations.of(context)!.profileScreenClearPersistentCacheButton),
          ),
          ElevatedButton(
            onPressed: () async {
              _log.info('Clear All Cache button tapped');
              final allCachesClearedMessage = AppLocalizations.of(context)!.profileScreenAllCachesClearedSnackbar;
              await cacheService.clearAllCaches(); 
              if (!mounted) return;
              Navigator.of(context).pop();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(allCachesClearedMessage)),
              );
            },
            child: Text(AppLocalizations.of(context)!.profileScreenClearAllCachesButton),
          ),
        ],
      ),
    );
  }
  
  // Helper widget to display cache info with label and value
  Widget _buildCacheInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // Build font size selector
  Widget _buildFontSizeSelector(
    BuildContext context,
    AppSettingsState appSettings,
    AppSettingsNotifier appSettingsNotifier,
    ColorScheme colors,
    Color textColor,
    Color secondaryTextColor
  ) {
         final currentFontSize = appSettings.appFontSize;
    final isSepia = appSettings.isSepia;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      elevation: isDark ? 1 : 0.3,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSepia 
              ? AppColor.primarySepia.withValues(alpha: 0.1) 
              : isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.05),
          width: 0.5,
        ),
      ),
      color: isSepia 
          ? AppColor.surfaceSepia.withValues(alpha: 0.5) 
          : isDark
              ? colors.surface.withValues(alpha: 0.5)
              : colors.surface.withValues(alpha: 0.8),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.text_fields, 
                    color: isSepia ? AppColor.primarySepia : colors.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context)!.profileScreenFontSizeLabel,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    letterSpacing: 0.1,
                  ).withAppFontScale(appSettings.fontScale),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: AppFontSize.values.map((fontSize) {
                  final isSelected = fontSize == currentFontSize;
                  final backgroundColor = isSelected ? colors.primary : colors.surface.withValues(alpha: 0.7);
                  
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                                                 onTap: () => appSettingsNotifier.setAppFontSize(fontSize),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            color: backgroundColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? colors.primary : colors.outline.withValues(alpha: 0.2),
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: isSelected ? [
                              BoxShadow(
                                color: colors.primary.withAlpha((255 * 0.2).round()),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ] : null,
                          ),
                          child: Text(
                            fontSize.displayName,
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: isSelected ? Colors.white : colors.onSurfaceVariant,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
