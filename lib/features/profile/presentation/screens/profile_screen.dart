import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:modudi/core/cache/cache_service.dart';
import 'package:modudi/core/cache/config/cache_constants.dart';

import 'package:modudi/features/settings/presentation/providers/settings_provider.dart';
import 'package:modudi/core/themes/app_color.dart';
import '../../../../core/l10n/l10n.dart';

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
    // Watch the provider state
    final settingsState = ref.watch(settingsProvider);
    // Get the notifier to call methods like setThemeMode
    final settingsNotifier = ref.read(settingsProvider.notifier);

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
          context.l10n.profile_title,
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w600,
            fontSize: 22,
            color: textColor,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        physics: const BouncingScrollPhysics(),
        children: [
          // Reading preferences section
          _buildSectionHeader(context.l10n.reading_preferences, textColor),
          const SizedBox(height: 16),
          _buildThemeToggle(context, settingsState, settingsNotifier, colors, textColor),
          const SizedBox(height: 16),
          _buildFontSizeSelector(context, settingsState, settingsNotifier, colors, textColor),
          const SizedBox(height: 32),
          
          // App settings section
          _buildSectionHeader(context.l10n.app_settings, textColor),
          const SizedBox(height: 16),
          _buildLanguageSelector(context, settingsState, settingsNotifier, colors, textColor),
          const SizedBox(height: 16),
          _buildSettingCard(
            context,
            context.l10n.notifications,
            'Manage your notification preferences',
            Icons.notifications_outlined,
            colors,
            textColor,
            secondaryTextColor,
            () {
              _log.info('Notifications tapped');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Notification settings not implemented yet.'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildSettingCard(
            context,
            context.l10n.download_settings,
            'Manage your download preferences',
            Icons.download_outlined,
            colors,
            textColor,
            secondaryTextColor,
            () {
              _log.info('Download Settings tapped');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Download settings not implemented yet.'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildSettingCard(
            context,
            'Cache Management',
            'View usage and clear cached content',
            Icons.storage_outlined,
            colors,
            textColor,
            secondaryTextColor,
            () {
              _log.info('Cache Management tapped');
              _showCacheManagementDialog(context);
            },
          ),
          const SizedBox(height: 32),
          
          // Support & info section
          _buildSectionHeader(context.l10n.support_info, textColor),
          const SizedBox(height: 16),
          _buildSupportCard(context, colors, textColor, secondaryTextColor),
          const SizedBox(height: 32),

          // App info section
          _buildSectionHeader('App Info', textColor),
          const SizedBox(height: 16),
          _buildAppInfoCard(context, colors, textColor, secondaryTextColor),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.playfairDisplay(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  // Build a card with theme options (Light, Sepia, Dark)
  Widget _buildThemeToggle(
    BuildContext context, 
    SettingsState settingsState, 
    SettingsNotifier settingsNotifier, 
    ColorScheme colors,
    Color textColor
  ) {
    final themeMode = settingsState.themeMode;
    final isSepia = settingsState.isSepia;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      elevation: isDark ? 1 : 0.3,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSepia 
              ? AppColor.primarySepia.withOpacity(0.1) 
              : isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.05),
          width: 0.5,
        ),
      ),
      color: isSepia 
          ? AppColor.surfaceSepia.withOpacity(0.5) 
          : isDark
              ? colors.surface.withOpacity(0.5)
              : colors.surface.withOpacity(0.8),
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
                    color: colors.primary.withOpacity(0.1),
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
                  'Theme',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    letterSpacing: 0.1,
                  ),
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
                  'Light', 
                  AppThemeMode.light, 
                  themeMode, 
                  settingsNotifier,
                  colors
                ),
                _buildThemeOption(
                  context, 
                  Icons.menu_book, 
                  'Sepia', 
                  AppThemeMode.sepia, 
                  themeMode, 
                  settingsNotifier,
                  colors
                ),
                _buildThemeOption(
                  context, 
                  Icons.dark_mode, 
                  'Dark', 
                  AppThemeMode.dark, 
                  themeMode, 
                  settingsNotifier,
                  colors
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
    SettingsNotifier settingsNotifier,
    ColorScheme colors,
  ) {
    final isSelected = mode == currentMode;
    final isSepia = Theme.of(context).primaryColor == AppColor.primarySepia;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return InkWell(
      onTap: () {
        settingsNotifier.setThemeMode(mode);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected 
              ? colors.primary.withOpacity(0.9)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? colors.primary 
                : isSepia
                    ? AppColor.primarySepia.withOpacity(0.2)
                    : isDark
                        ? Colors.white.withOpacity(0.1)
                        : colors.outline.withOpacity(0.2),
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build font size selector with small, medium, and large options
  Widget _buildFontSizeSelector(
      BuildContext context,
      SettingsState settingsState,
      SettingsNotifier settingsNotifier,
      ColorScheme colors,
      Color textColor
    ) {
    final currentFontSize = settingsState.fontSize;
    final isSepia = settingsState.isSepia;
    final isDark = Theme.of(context).brightness == Brightness.dark;
      
    return Card(
      elevation: isDark ? 1 : 0.3,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSepia 
              ? AppColor.primarySepia.withOpacity(0.1) 
              : isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.05),
          width: 0.5,
        ),
      ),
      color: isSepia 
          ? AppColor.surfaceSepia.withOpacity(0.5) 
          : isDark
              ? colors.surface.withOpacity(0.5)
              : colors.surface.withOpacity(0.8),
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
                    color: colors.primary.withOpacity(0.1),
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
                  'Font Size',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildFontSizeOption(
                  context,
                  'A',
                  'Small',
                  FontSize.small,
                  currentFontSize,
                  settingsNotifier,
                  colors,
                ),
                _buildFontSizeOption(
                  context,
                  'A',
                  'Medium',
                  FontSize.medium,
                  currentFontSize,
                  settingsNotifier,
                  colors,
                ),
                _buildFontSizeOption(
                  context,
                  'A',
                  'Large',
                  FontSize.large,
                  currentFontSize,
                  settingsNotifier,
                  colors,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFontSizeOption(
    BuildContext context,
    String letter,
    String label,
    FontSize size,
    FontSize currentSize,
    SettingsNotifier settingsNotifier,
    ColorScheme colors,
  ) {
    final isSelected = size == currentSize;
    final isSepia = Theme.of(context).primaryColor == AppColor.primarySepia;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Choose font size based on option
    double fontSize = 14.0;
    if (size == FontSize.small) {
      fontSize = 14.0;
    } else if (size == FontSize.medium) {
      fontSize = 18.0;
    } else if (size == FontSize.large) {
      fontSize = 22.0;
    }
    
    return InkWell(
      onTap: () {
        settingsNotifier.setFontSize(size);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected 
              ? colors.primary.withOpacity(0.9)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? colors.primary 
                : isSepia
                    ? AppColor.primarySepia.withOpacity(0.2)
                    : isDark
                        ? Colors.white.withOpacity(0.1)
                        : colors.outline.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              letter,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
                color: isSelected 
                    ? Colors.white 
                    : isSepia
                        ? AppColor.primarySepia
                        : colors.primary,
              ),
            ),
            const SizedBox(height: 4),
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build language selector with options
  Widget _buildLanguageSelector(
      BuildContext context,
      SettingsState settingsState,
      SettingsNotifier settingsNotifier,
      ColorScheme colors,
      Color textColor
    ) {
    final currentLanguage = settingsState.language;
    final isSepia = settingsState.isSepia;
    final isDark = Theme.of(context).brightness == Brightness.dark;
      
    return Card(
      elevation: isDark ? 1 : 0.3,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSepia 
              ? AppColor.primarySepia.withOpacity(0.1) 
              : isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.05),
          width: 0.5,
        ),
      ),
      color: isSepia 
          ? AppColor.surfaceSepia.withOpacity(0.5) 
          : isDark
              ? colors.surface.withOpacity(0.5)
              : colors.surface.withOpacity(0.8),
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
                    color: colors.primary.withOpacity(0.1),
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
                  'Language',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: AppLanguage.values.map((language) {
                  final isSelected = language == currentLanguage;
                  final backgroundColor = isSelected ? colors.primary : colors.surface.withOpacity(0.7);
                  
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => settingsNotifier.setLanguage(language),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            color: backgroundColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? colors.primary : colors.outline.withOpacity(0.2),
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: isSelected ? [
                              BoxShadow(
                                color: colors.primary.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ] : null,
                          ),
                          child: Text(
                            language.displayName,
                            style: TextStyle(
                              fontSize: 14,
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

  // Build a setting card with icon, title, and subtitle
  Widget _buildSettingCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    ColorScheme colors,
    Color textColor,
    Color secondaryTextColor,
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
              ? AppColor.primarySepia.withOpacity(0.1) 
              : isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.05),
          width: 0.5,
        ),
      ),
      color: isSepia 
          ? AppColor.surfaceSepia.withOpacity(0.5) 
          : isDark
              ? colors.surface.withOpacity(0.5)
              : colors.surface.withOpacity(0.8),
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
                  color: colors.primary.withOpacity(0.1),
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
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: secondaryTextColor,
                        letterSpacing: 0.1,
                      ),
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
  Widget _buildSupportCard(BuildContext context, ColorScheme colors, Color textColor, Color secondaryTextColor) {
    return Column(
      children: [
        _buildSettingCard(
          context,
          'Help & FAQ',
          'Get answers to frequently asked questions',
          Icons.help_outline,
          colors,
          textColor,
          secondaryTextColor,
          () {
            _log.info('Help & FAQ tapped');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Help not implemented yet.'),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        _buildSettingCard(
          context,
          'Contact Us',
          'Get in touch with our support team',
          Icons.contact_support_outlined,
          colors,
          textColor,
          secondaryTextColor,
          () {
            _log.info('Contact Us tapped');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Contact info not available yet.'),
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
  Widget _buildAppInfoCard(BuildContext context, ColorScheme colors, Color textColor, Color secondaryTextColor) {
    final isSepia = Theme.of(context).primaryColor == AppColor.primarySepia;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      elevation: isDark ? 1 : 0.3,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSepia 
              ? AppColor.primarySepia.withOpacity(0.1) 
              : isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.05),
          width: 0.5,
        ),
      ),
      color: isSepia 
          ? AppColor.surfaceSepia.withOpacity(0.5) 
          : isDark
              ? colors.surface.withOpacity(0.5)
              : colors.surface.withOpacity(0.8),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colors.primary.withOpacity(0.1),
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
                    'Version',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                      letterSpacing: 0.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: colors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$_appVersion ($_buildNumber)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isSepia ? AppColor.primarySepia : colors.primary,
                        letterSpacing: 0.1,
                      ),
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

  // Cache management dialog that shows cache statistics and provides options to clear cache
  Future<void> _showCacheManagementDialog(BuildContext context) async {
    final cacheService = CacheService();
    await cacheService.initialize();
    
    // Get cache statistics
    final cacheStats = await cacheService.getCacheSizeStats();
    
    // Extract sizes from the stats map
    final booksSize = cacheStats['books'] ?? 0;
    final imagesSize = cacheStats['images'] ?? 0;
    final bookStructuresSize = cacheStats['bookStructures'] ?? 0;
    final chaptersSize = cacheStats['chapters'] ?? 0;
    
    final totalCacheSize = cacheStats['total'] ?? 0;
    final formatSize = (int bytes) {
      if (bytes < 1024) return '$bytes B';
      if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    };
    
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cache Management'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total cache size: ${formatSize(totalCacheSize)}'),
              const SizedBox(height: 16),
              _buildCacheInfoRow('Books', formatSize(booksSize)),
              _buildCacheInfoRow('Images', formatSize(imagesSize)),
              _buildCacheInfoRow('Book structures', formatSize(bookStructuresSize)),
              _buildCacheInfoRow('Chapters', formatSize(chaptersSize)),
              const SizedBox(height: 16),
              const Text(
                'Clearing the cache will free up storage space but may cause slower loading times when you next access content.',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Clear only image cache
              await cacheService.clearBox(CacheConstants.thumbnailMetadataBoxName);
              await cacheService.clearBox(CacheConstants.imageMetadataBoxName);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Image cache cleared')),
                );
                Navigator.of(context).pop();
              }
            },
            child: const Text('Clear Image Cache'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            onPressed: () async {
              // Clear all caches
              await cacheService.clearBox(CacheConstants.booksBoxName);
              await cacheService.clearBox(CacheConstants.volumesBoxName);
              await cacheService.clearBox(CacheConstants.chaptersBoxName);
              await cacheService.clearBox(CacheConstants.headingsBoxName);
              await cacheService.clearBox(CacheConstants.thumbnailMetadataBoxName);
              await cacheService.clearBox(CacheConstants.imageMetadataBoxName);
              await cacheService.clearBox(CacheConstants.bookStructuresBoxName);
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All caches cleared')),
                );
                Navigator.of(context).pop();
              }
            },
            child: const Text('Clear All Caches'),
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
}
