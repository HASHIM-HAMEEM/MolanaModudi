import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart'; // Import for DragStartBehavior

import '../../../settings/presentation/providers/app_settings_provider.dart';
import '../providers/reading_settings_provider.dart';
import '../screens/reading/widgets/reading_header.dart'; // Import to access settingsPanelVisibilityProvider

/// A minimalistic, Airbnb-style bottom sheet for reading settings
class ReaderSettingsBottomSheet extends ConsumerStatefulWidget {
  const ReaderSettingsBottomSheet({super.key});

  @override
  ConsumerState<ReaderSettingsBottomSheet> createState() => _ReaderSettingsBottomSheetState();
}

class _ReaderSettingsBottomSheetState extends ConsumerState<ReaderSettingsBottomSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appSettings = ref.watch(appSettingsProvider);
    final appSettingsNotifier = ref.read(appSettingsProvider.notifier);
    final readingSettings = ref.watch(readingSettingsProvider);
    final readingSettingsNotifier = ref.read(readingSettingsProvider.notifier);
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Container(
      height: size.height * 0.75,
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          // Minimalistic handle bar
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 20),
            decoration: BoxDecoration(
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Clean header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
            children: [
              Text(
                  'Reading Settings',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: -0.5,
              ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    ref.read(settingsPanelVisibilityProvider.notifier).state = false;
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ),
              ),
            ],
          ),
          ),

          const SizedBox(height: 32),

          // Minimalistic tab bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: theme.colorScheme.onSurface,
              unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
              dividerColor: Colors.transparent,
              labelStyle: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              tabs: const [
                Tab(text: 'Appearance'),
                Tab(text: 'Typography'),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(), // Prevents swipe between tabs, good for slider interaction
              children: [
                _buildAppearanceTab(theme, appSettings, appSettingsNotifier),
                _buildTypographyTab(theme, readingSettings, readingSettingsNotifier),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppearanceTab(ThemeData theme, AppSettingsState appSettings, AppSettingsNotifier appSettingsNotifier) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      dragStartBehavior: DragStartBehavior.down,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Theme selection
            Text(
            'Theme',
            style: GoogleFonts.inter(
              fontSize: 18,
                fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            
          // Minimalistic theme grid
            GridView.count(
              crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.8,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
              _buildMinimalisticThemeCard(
                  'Light',
                Icons.light_mode_outlined,
                Colors.white,
                Colors.grey[900]!,
                  appSettings.themeMode == AppThemeMode.light,
                () {
                  HapticFeedback.selectionClick();
                  appSettingsNotifier.setThemeMode(AppThemeMode.light);
                  // Auto-dismiss after theme change
                  _autoDismissPanel();
                },
                theme,
                ),
              _buildMinimalisticThemeCard(
                  'Dark',
                Icons.dark_mode_outlined,
                Colors.grey[900]!,
                Colors.white,
                  appSettings.themeMode == AppThemeMode.dark,
                () {
                  HapticFeedback.selectionClick();
                  appSettingsNotifier.setThemeMode(AppThemeMode.dark);
                  // Auto-dismiss after theme change
                  _autoDismissPanel();
                },
                theme,
                ),
              _buildMinimalisticThemeCard(
                  'Sepia',
                Icons.auto_stories_outlined,
                const Color(0xFFF4F1E8),
                const Color(0xFF5C4B37),
                  appSettings.themeMode == AppThemeMode.sepia,
                () {
                  HapticFeedback.selectionClick();
                  appSettingsNotifier.setThemeMode(AppThemeMode.sepia);
                  // Auto-dismiss after theme change
                  _autoDismissPanel();
                },
                theme,
                ),
              _buildMinimalisticThemeCard(
                  'Auto',
                Icons.brightness_auto_outlined,
                theme.colorScheme.surface,
                theme.colorScheme.onSurface,
                  appSettings.themeMode == AppThemeMode.system,
                () {
                  HapticFeedback.selectionClick();
                  appSettingsNotifier.setThemeMode(AppThemeMode.system);
                  // Auto-dismiss after theme change
                  _autoDismissPanel();
                },
                theme,
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Reading tips with better design
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.lightbulb_outline_rounded,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Reading Tips',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '• Tap screen to toggle controls\n• Swipe to navigate pages\n• Use edge taps for quick navigation',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          ],
      ),
    );
  }

  /// Auto-dismiss the panel after a short delay
  void _autoDismissPanel() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        ProviderScope.containerOf(context).read(settingsPanelVisibilityProvider.notifier).state = false;
      }
    });
  }

  Widget _buildMinimalisticThemeCard(
    String title,
    IconData icon,
    Color bgColor,
    Color textColor,
    bool isSelected,
    VoidCallback onTap,
    ThemeData theme,
  ) {
    return GestureDetector(
      // Complete gesture isolation for theme cards
      onTap: () {
        onTap(); // Execute the actual theme change
      },
      // Absorb other gestures
      onPanDown: (_) {},
      onPanStart: (_) {},
      onPanUpdate: (_) {},
      onPanEnd: (_) {},
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isSelected 
            ? theme.colorScheme.primary.withValues(alpha: 0.1)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
              ? theme.colorScheme.primary
              : theme.colorScheme.outline.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
      child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
          children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: textColor,
              ),
            ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected 
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle_rounded,
                  size: 20,
                  color: theme.colorScheme.primary,
            ),
          ],
            ),
        ),
      ),
    );
  }

  Widget _buildTypographyTab(ThemeData theme, ReadingSettingsState readingSettings, ReadingSettingsNotifier readingSettingsNotifier) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      dragStartBehavior: DragStartBehavior.down,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Font family section
            Text(
              'Font Family',
            style: GoogleFonts.inter(
              fontSize: 18,
                fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            
          _buildReadingFontSelection(theme, readingSettings, readingSettingsNotifier),
          
          const SizedBox(height: 32),
          
          // Font size section
          _buildReadingFontSizeSlider(theme, readingSettings, readingSettingsNotifier),
          
          const SizedBox(height: 32),
          
          // Line spacing section
          _buildReadingLineSpacingSlider(theme, readingSettings, readingSettingsNotifier),
          
          const SizedBox(height: 32),
          
          // Preview section
          _buildReadingTextPreview(theme, readingSettings),
          
          const SizedBox(height: 32),
          ],
      ),
    );
  }

  Widget _buildReadingFontSelection(ThemeData theme, ReadingSettingsState readingSettings, ReadingSettingsNotifier readingSettingsNotifier) {
    final fonts = [
      // Arabic/Urdu fonts
      {
        'name': 'Jameel Noori Nastaleeq',
        'family': ReadingFontFamily.jameelNoori,
        'preview': 'جمیل نوری نستعلیق',
        'description': 'Traditional Urdu'
      },
      {
        'name': 'Noto Nastaliq Urdu',
        'family': ReadingFontFamily.notoNastaliq,
        'preview': 'نوٹو نستعلیق اردو',
        'description': 'Modern Urdu'
      },
      {
        'name': 'Noto Naskh Arabic',
        'family': ReadingFontFamily.notoNaskh,
        'preview': 'نوتو نسخ العربية',
        'description': 'Arabic Script'
      },
      {
        'name': 'Amiri Quran',
        'family': ReadingFontFamily.amiriQuran,
        'preview': 'أميري قرآن',
        'description': 'Quranic Style'
      },
      {
        'name': 'Scheherazade New',
        'family': ReadingFontFamily.scheherazade,
        'preview': 'شهرزاد جديد',
        'description': 'Academic Arabic'
      },
      // English fonts
      {
        'name': 'Roboto',
        'family': ReadingFontFamily.roboto,
        'preview': 'The quick brown fox',
        'description': 'Modern Sans'
      },
      {
        'name': 'Open Sans',
        'family': ReadingFontFamily.openSans,
        'preview': 'The quick brown fox',
        'description': 'Humanist Sans'
      },
      {
        'name': 'Lato',
        'family': ReadingFontFamily.lato,
        'preview': 'The quick brown fox',
        'description': 'Friendly Sans'
      },
      {
        'name': 'Serif',
        'family': ReadingFontFamily.serif,
        'preview': 'The quick brown fox',
        'description': 'Classic Serif'
      },
    ];

    return Column(
      children: fonts.map((font) => 
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: _buildFontCard(
            font['name']! as String,
            (font['family']! as ReadingFontFamily).fontFamily,
            font['preview']! as String,
            font['description']! as String,
            readingSettings.fontFamily == font['family']!,
            () {
              HapticFeedback.selectionClick();
              readingSettingsNotifier.setFontFamily(font['family']! as ReadingFontFamily);
              // Show brief feedback
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Font changed to ${font['name']}'),
                  duration: const Duration(milliseconds: 1200),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.only(bottom: 100),
                ),
              );
            },
            theme,
          ),
        ),
      ).toList(),
    );
  }

  Widget _buildFontCard(
    String name,
    String family,
    String preview,
    String description,
    bool isSelected,
    VoidCallback onTap,
    ThemeData theme,
  ) {
    return GestureDetector(
      // Complete gesture isolation for font cards
      onTap: () {
        onTap(); // Execute the actual font change
      },
      // Absorb other gestures
      onPanDown: (_) {},
      onPanStart: (_) {},
      onPanUpdate: (_) {},
      onPanEnd: (_) {},
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected 
            ? theme.colorScheme.primary.withValues(alpha: 0.08)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
              ? theme.colorScheme.primary
              : theme.colorScheme.outline.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isSelected 
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          description,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
            ),
            const SizedBox(height: 8),
            Text(
                    preview,
              style: TextStyle(
                      fontFamily: family,
                      fontSize: 18,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
                      height: 1.4,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: 18,
                  color: theme.colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadingFontSizeSlider(ThemeData theme, ReadingSettingsState readingSettings, ReadingSettingsNotifier readingSettingsNotifier) {
    return SliderContainer(
      title: 'Font Size',
      icon: Icons.format_size_rounded,
      valueLabel: '${readingSettings.fontSize.size.round()}px',
      value: readingSettings.fontSize.size.clamp(12.0, 36.0),
      min: 12.0,
      max: 36.0,
      divisions: 24,
      onChanged: (value) {
        HapticFeedback.lightImpact();
        readingSettingsNotifier.setFontSizeFromDouble(value);
      },
    );
  }

  Widget _buildReadingLineSpacingSlider(ThemeData theme, ReadingSettingsState readingSettings, ReadingSettingsNotifier readingSettingsNotifier) {
    return SliderContainer(
      title: 'Line Spacing',
      icon: Icons.format_line_spacing_rounded,
      valueLabel: '${readingSettings.lineSpacing.toStringAsFixed(1)}x',
      value: readingSettings.lineSpacing.clamp(1.0, 2.5),
      min: 1.0,
      max: 2.5,
      divisions: 15,
      onChanged: (value) {
        HapticFeedback.lightImpact();
        readingSettingsNotifier.setLineSpacing(value);
      },
    );
  }

  Widget _buildReadingTextPreview(ThemeData theme, ReadingSettingsState readingSettings) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.preview_rounded,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Live Preview',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${readingSettings.fontSize.size.round()}px • ${readingSettings.lineSpacing.toStringAsFixed(1)}x',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
          ],
        ),
          const SizedBox(height: 20),
          
          // Urdu text preview
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'اسلام علیکم ورحمۃ اللہ وبرکاتہ',
                  style: TextStyle(
                    fontFamily: readingSettings.fontFamily.fontFamily,
                    fontSize: readingSettings.fontSize.size,
                    height: readingSettings.lineSpacing,
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w400,
                  ),
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 12),
                Text(
                  'یہ متن آپ کی موجودہ ترتیبات کے ساتھ کیسا نظر آئے گا۔',
                  style: TextStyle(
                    fontFamily: readingSettings.fontFamily.fontFamily,
                    fontSize: readingSettings.fontSize.size - 1,
                    height: readingSettings.lineSpacing,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w400,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ],
            ),
          ),
          
        const SizedBox(height: 12),
          
          // English text preview
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'This is how English text will appear with your current settings.',
              style: GoogleFonts.inter(
                fontSize: readingSettings.fontSize.size - 1,
                height: readingSettings.lineSpacing,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w400,
              ),
            ),
        ),
      ],
      ),
    );
  }
}

/// A completely bulletproof slider container that cannot be dismissed during interaction
class SliderContainer extends StatefulWidget {
  final String title;
  final IconData icon;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  const SliderContainer({
    super.key,
    required this.title,
    required this.icon,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  @override
  State<SliderContainer> createState() => _SliderContainerState();
}

class _SliderContainerState extends State<SliderContainer> {
  // Internal state for drag tracking
  bool _isDragging = false;
  double _currentValue = 0;
  
  @override
  void initState() {
    super.initState();
    _currentValue = widget.value;
  }
  
  @override
  void didUpdateWidget(SliderContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && !_isDragging) {
      _currentValue = widget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 16), // Keep margin for spacing
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with icon, title and value
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  widget.icon,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.valueLabel,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20), // Increased height for better touch target
          
          // Custom slider implementation
          SizedBox(
            height: 40, // Fixed height for slider area
            child: Listener(
              onPointerDown: (event) {
                _startDrag(event);
              },
              onPointerMove: (event) {
                _updateDrag(event);
              },
              onPointerUp: (event) {
                _endDrag();
              },
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Calculate normalized position (0.0 to 1.0)
                  final normalizedValue = (_currentValue - widget.min) / (widget.max - widget.min);
                  
                  // Calculate actual position in pixels
                  final trackWidth = constraints.maxWidth;
                  final thumbPosition = normalizedValue * trackWidth;
                  
                  return Stack(
                    children: [
                      // Track background
                      Positioned.fill(
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 15),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.outline.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      
                      // Active track
                      Positioned(
                        left: 0,
                        top: 15,
                        bottom: 15,
                        width: thumbPosition,
                        child: Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      
                      // Thumb
                      Positioned(
                        left: thumbPosition - 10, // Center the thumb (20px wide)
                        top: 0,
                        child: Container(
                          width: 20,
                          height: 40,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.shadow.withValues(alpha: 0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          // Optional: Add visual feedback for drag state
                          child: _isDragging
                              ? Center(
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.8),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _startDrag(PointerDownEvent event) {
    setState(() {
      _isDragging = true;
    });
    
    // Process the initial position
    _updateValueFromPosition(event.localPosition.dx);
    HapticFeedback.selectionClick();
  }

  void _updateDrag(PointerMoveEvent event) {
    if (!_isDragging) return;
    
    _updateValueFromPosition(event.localPosition.dx);
  }

  void _endDrag() {
    if (!_isDragging) return;
    
    setState(() {
      _isDragging = false;
    });
    
    // APPLY THE CHANGE ONLY AT THE END OF THE DRAG
    // This is where we actually update the font size
    widget.onChanged(_currentValue);
    
    HapticFeedback.lightImpact();
    
    // Auto-dismiss the bottom sheet after changing value
    // Brief delay to allow the user to see the final value
    Future.delayed(const Duration(milliseconds: 300), () {
      // Find the nearest ProviderScope to access the Riverpod provider
      final context = this.context;
      if (context.mounted) {
        // Access the provider and set it to false to dismiss the panel
        ProviderScope.containerOf(context).read(settingsPanelVisibilityProvider.notifier).state = false;
      }
    });
  }

  void _updateValueFromPosition(double dx) {
    // We need to get the RenderBox to calculate the correct position
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    
    // Get the actual width of the slider area
    final width = renderBox.size.width - 40; // Account for padding
    
    // Calculate normalized position (0-1)
    double normalizedPosition = (dx - 20) / width; // Adjust for left padding
    normalizedPosition = normalizedPosition.clamp(0.0, 1.0);
    
    // Calculate the actual value
    final range = widget.max - widget.min;
    double newValue = widget.min + (normalizedPosition * range);
    
    // Apply divisions if provided
    if (widget.divisions > 0) {
      final step = range / widget.divisions;
      newValue = (newValue / step).round() * step;
    }
    
    // Clamp to valid range
    newValue = newValue.clamp(widget.min, widget.max);
    
    // Only update if value changed
    if (newValue != _currentValue) {
      setState(() {
        _currentValue = newValue;
      });
      
      // CRITICAL CHANGE: Don't call widget.onChanged during the drag
      // This prevents the font size from updating and triggering a rebuild
      // while we're still dragging
      // widget.onChanged(newValue);
    }
  }
}
