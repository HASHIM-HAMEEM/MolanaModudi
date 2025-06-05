import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:modudi/features/reading/presentation/providers/reading_settings_provider.dart';

class ReadingSettingsBottomSheet extends ConsumerStatefulWidget {
  const ReadingSettingsBottomSheet({super.key});

  @override
  ConsumerState<ReadingSettingsBottomSheet> createState() => _ReadingSettingsBottomSheetState();
}

class _ReadingSettingsBottomSheetState extends ConsumerState<ReadingSettingsBottomSheet> with TickerProviderStateMixin {
  late double _previewFontSize;
  late double _previewLineHeight;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final readingSettings = ref.read(readingSettingsProvider);
    _previewFontSize = readingSettings.fontSize.size;
    _previewLineHeight = 1.5; // Default line height
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final readingSettings = ref.watch(readingSettingsProvider);
    final readingSettingsNotifier = ref.read(readingSettingsProvider.notifier);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: colors.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Row(
                  children: [
                    Icon(Icons.settings_rounded, color: colors.primary, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      'Reading Settings',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close_rounded, color: colors.onSurfaceVariant),
                      iconSize: 20,
                    ),
                  ],
                ),
              ),

              // Tab Bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  labelColor: colors.onPrimary,
                  unselectedLabelColor: colors.onSurfaceVariant,
                  labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                  unselectedLabelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
                  tabs: const [
                    Tab(icon: Icon(Icons.text_fields_rounded, size: 18), text: 'Text'),
                    Tab(icon: Icon(Icons.palette_rounded, size: 18), text: 'Theme'),
                    Tab(icon: Icon(Icons.bookmark_rounded, size: 18), text: 'Bookmarks'),
                    Tab(icon: Icon(Icons.psychology_rounded, size: 18), text: 'AI'),
                  ],
                ),
              ),

              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTextSettingsTab(colors),
                    _buildThemeSettingsTab(colors, readingSettings, readingSettingsNotifier),
                    _buildBookmarksTab(colors),
                    _buildAIInsightsTab(colors),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTextSettingsTab(ColorScheme colors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Font Size Section
          _buildSectionHeader('Font Size', Icons.format_size_rounded, colors),
          const SizedBox(height: 12),
          _buildFontSizeSlider(colors),
          const SizedBox(height: 24),

          // Line Height Section
          _buildSectionHeader('Line Spacing', Icons.format_line_spacing_rounded, colors),
          const SizedBox(height: 12),
          _buildLineHeightSlider(colors),
          const SizedBox(height: 24),

          // Preview Section
          _buildSectionHeader('Preview', Icons.preview_rounded, colors),
          const SizedBox(height: 12),
          _buildPreviewText(colors),
          const SizedBox(height: 16),

          // Apply Button
          _buildActionButtons(colors, context),
        ],
      ),
    );
  }

  Widget _buildThemeSettingsTab(ColorScheme colors, ReadingSettingsState readingSettings, ReadingSettingsNotifier readingSettingsNotifier) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Theme Mode', Icons.brightness_6_rounded, colors),
          const SizedBox(height: 16),
          
          // Theme options
          ...ReadingThemeMode.values.map((themeMode) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    readingSettingsNotifier.setReadingThemeMode(themeMode);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: readingSettings.themeMode == themeMode 
                        ? colors.primary.withValues(alpha: 0.1)
                        : colors.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: readingSettings.themeMode == themeMode 
                          ? colors.primary 
                          : colors.outline.withValues(alpha: 0.2),
                        width: readingSettings.themeMode == themeMode ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getThemeIcon(themeMode),
                          color: readingSettings.themeMode == themeMode 
                            ? colors.primary 
                            : colors.onSurfaceVariant,
                          size: 24,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getThemeTitle(themeMode),
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: colors.onSurface,
                                ),
                              ),
                              Text(
                                _getThemeDescription(themeMode),
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (readingSettings.themeMode == themeMode)
                          Icon(Icons.check_circle_rounded, color: colors.primary, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBookmarksTab(ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(Icons.bookmark_border_outlined, size: 64, color: colors.onSurfaceVariant.withValues(alpha: 0.6)),
          const SizedBox(height: 24),
          Text(
            'Bookmarks',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Your reading bookmarks will appear here. Tap and hold on any text while reading to create a bookmark.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: colors.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Navigate to bookmarks screen
            },
            icon: const Icon(Icons.bookmark_add_rounded, size: 18),
            label: Text(
              'Manage Bookmarks',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIInsightsTab(ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(Icons.psychology_outlined, size: 64, color: colors.onSurfaceVariant.withValues(alpha: 0.6)),
          const SizedBox(height: 24),
          Text(
            'AI Insights',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Get intelligent insights, summaries, and contextual information about the content you\'re reading.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: colors.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.outline.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.construction_rounded, color: colors.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Coming Soon',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getThemeIcon(ReadingThemeMode themeMode) {
    switch (themeMode) {
      case ReadingThemeMode.light:
        return Icons.light_mode_rounded;
      case ReadingThemeMode.dark:
        return Icons.dark_mode_rounded;
      case ReadingThemeMode.sepia:
        return Icons.auto_stories_rounded;
      case ReadingThemeMode.system:
        return Icons.brightness_auto_rounded;
    }
  }

  String _getThemeTitle(ReadingThemeMode themeMode) {
    switch (themeMode) {
      case ReadingThemeMode.light:
        return 'Light Mode';
      case ReadingThemeMode.dark:
        return 'Dark Mode';
      case ReadingThemeMode.sepia:
        return 'Sepia Mode';
      case ReadingThemeMode.system:
        return 'System Default';
    }
  }

  String _getThemeDescription(ReadingThemeMode themeMode) {
    switch (themeMode) {
      case ReadingThemeMode.light:
        return 'Clean and bright interface for reading';
      case ReadingThemeMode.dark:
        return 'Easy on the eyes in low light while reading';
      case ReadingThemeMode.sepia:
        return 'Warm, paper-like reading experience';
      case ReadingThemeMode.system:
        return 'Follows your global app theme setting';
    }
  }

  Widget _buildSectionHeader(String title, IconData icon, ColorScheme colors) {
    return Row(
      children: [
        Icon(icon, color: colors.primary, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colors.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildFontSizeSlider(ColorScheme colors) {
    return Column(
      children: [
        Row(
          children: [
            Icon(Icons.text_decrease, color: colors.onSurfaceVariant, size: 20),
            Expanded(
              child: Slider(
                value: _previewFontSize,
                min: 12.0,
                max: 28.0,
                divisions: 16,
                label: '${_previewFontSize.toInt()}px',
                onChanged: (value) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _previewFontSize = value;
                  });
                },
                onChangeEnd: (value) {
                  // Update actual settings when dragging ends
                  ref.read(readingSettingsProvider.notifier).setFontSizeFromDouble(value);
                },
              ),
            ),
            Icon(Icons.text_increase, color: colors.onSurfaceVariant, size: 20),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Small', style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12)),
            Text('Large', style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _buildLineHeightSlider(ColorScheme colors) {
    return Column(
      children: [
        Row(
          children: [
            Icon(Icons.density_small, color: colors.onSurfaceVariant, size: 20),
            Expanded(
              child: Slider(
                value: _previewLineHeight,
                min: 1.0,
                max: 2.5,
                divisions: 15,
                label: '${_previewLineHeight.toStringAsFixed(1)}x',
                onChanged: (value) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _previewLineHeight = value;
                  });
                },
              ),
            ),
            Icon(Icons.density_large, color: colors.onSurfaceVariant, size: 20),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Tight', style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12)),
            Text('Loose', style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _buildPreviewText(ColorScheme colors) {
    return Container(
      height: 120, // Fixed height instead of Expanded
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: SingleChildScrollView(
        child: Text(
          '''اسلام کے نام سے دنیا میں بہت سے نظام موجود ہیں، لیکن حقیقی اسلامی نظام وہ ہے جو قرآن و سنت کی روشنی میں قائم ہو۔ یہ ایک مکمل ضابطہ حیات ہے جو انسان کی انفرادی اور اجتماعی زندگی کے ہر شعبے کو محیط ہے۔

Islamic principles guide every aspect of human life, from personal conduct to social interactions. This comprehensive system encompasses spiritual, moral, economic, and political dimensions of existence.''',
          style: TextStyle(
            fontFamily: 'NotoNastaliqUrdu',
            fontSize: _previewFontSize,
            height: _previewLineHeight,
            color: colors.onSurface,
          ),
          textDirection: TextDirection.rtl,
        ),
      ),
    );
  }

  Widget _buildActionButtons(ColorScheme colors, BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          HapticFeedback.mediumImpact();
          Navigator.of(context).pop();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Text(
          'Apply Changes',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
} 