import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modudi/features/settings/presentation/providers/settings_provider.dart';
import 'package:logging/logging.dart'; // Import logger

class ReadingSettingsPanel extends ConsumerStatefulWidget {
  final Function onClose;
  // Pass current settings values and callbacks to update them
  final double currentFontSize;
  final Function(double) onFontSizeChange;
  final double currentLineSpacing;
  final Function(double) onLineSpacingChange;
  final String currentFontType;
  final Function(String) onFontTypeChange;
  // Add recommended settings
  final Map<String, dynamic>? recommendedSettings;
  final Function? onApplyRecommendedSettings;

  const ReadingSettingsPanel({
    super.key,
    required this.onClose,
    required this.currentFontSize,
    required this.onFontSizeChange,
    required this.currentLineSpacing,
    required this.onLineSpacingChange,
    required this.currentFontType,
    required this.onFontTypeChange,
    this.recommendedSettings,
    this.onApplyRecommendedSettings,
  });

  @override
  ConsumerState<ReadingSettingsPanel> createState() => _ReadingSettingsPanelState();
}

class _ReadingSettingsPanelState extends ConsumerState<ReadingSettingsPanel> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['Appearance', 'Text'];
  final _log = Logger('ReadingSettingsPanel'); // Add logger

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(settingsProvider);
    _log.info('Building ReadingSettingsPanel. Current themeMode state: ${settingsState.themeMode}'); // Log build
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final size = MediaQuery.of(context).size;
    
    // Calculate responsive width - not too wide on larger screens
    final panelWidth = size.width < 600 ? size.width * 0.85 : 360.0;

    return SafeArea(
      child: Container(
        color: Colors.transparent,
        child: Stack(
          children: [
            // Semi-transparent background
            Positioned.fill(
              child: GestureDetector(
                onTap: () => widget.onClose(),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.3),
                ),
              ),
            ),
            
            // Centered settings panel
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: panelWidth,
              child: Material(
                elevation: 8,
                color: theme.colorScheme.surface,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.fromLTRB(24, 16, 16, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Reading Settings',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => widget.onClose(),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                    ),
                    
                    // Tabs
                    Container(
                      height: 56,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: TabBar(
                        controller: _tabController,
                        labelColor: colors.primary,
                        unselectedLabelColor: colors.onSurface.withValues(alpha: 0.6),
                        indicatorColor: colors.primary,
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                        tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
                      ),
                    ),
                    
                    // Divider
                    Divider(height: 1, thickness: 1, color: colors.surfaceContainerHighest),
                    
                    // Tab content
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // Appearance Tab
                          _buildAppearanceTab(theme, settingsState, settingsNotifier),
                          
                          // Text Options Tab - Enhanced with font selection
                          _buildEnhancedTextOptionsTab(theme, settingsState, settingsNotifier),
                        ],
                      ),
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

  // Appearance Tab Content
  Widget _buildAppearanceTab(ThemeData theme, SettingsState settingsState, SettingsNotifier settingsNotifier) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Text(
              "Choose a theme",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            // Theme options grid
            GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 24,
              childAspectRatio: 1.2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                // Explicitly creating theme cards with more debug logs
                _buildDebugThemeCard(
                  theme, 
                  'Light', 
                  Icons.wb_sunny_outlined,
                  settingsState.themeMode == AppThemeMode.light,
                  () {
                    _log.info('Light theme tapped - Attempting to apply Light theme'); 
                    settingsNotifier.setThemeMode(AppThemeMode.light);
                  },
                ),
                _buildDebugThemeCard(
                  theme, 
                  'Dark', 
                  Icons.nightlight_outlined,
                  settingsState.themeMode == AppThemeMode.dark,
                  () {
                    _log.info('Dark theme tapped - Attempting to apply Dark theme'); 
                    settingsNotifier.setThemeMode(AppThemeMode.dark);
                  },
                ),
                _buildDebugThemeCard(
                  theme, 
                  'Sepia', 
                  Icons.color_lens_outlined,
                  settingsState.themeMode == AppThemeMode.sepia,
                  () {
                    _log.info('Sepia theme tapped - Attempting to apply Sepia theme'); 
                    settingsNotifier.setThemeMode(AppThemeMode.sepia);
                  },
                ),
                _buildDebugThemeCard(
                  theme, 
                  'Auto', 
                  Icons.brightness_auto_outlined,
                  settingsState.themeMode == AppThemeMode.system,
                  () {
                    _log.info('Auto theme tapped - Attempting to apply Auto theme'); 
                    settingsNotifier.setThemeMode(AppThemeMode.system);
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Reading tips
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.tips_and_updates, 
                        size: 18, 
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Reading Tips',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Tap screen to hide/show controls\n'
                    '• Use swipe gestures to turn pages\n'
                    '• Tap left/right edges for page navigation',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Enhanced theme card with better debugging
  Widget _buildDebugThemeCard(
    ThemeData theme, 
    String label, 
    IconData icon, 
    bool isSelected, 
    VoidCallback onTap
  ) {
    return Card(
      elevation: isSelected ? 4 : 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          width: 2,
        ),
      ),
      color: isSelected 
          ? theme.colorScheme.primary
          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: InkWell(
        onTap: () {
          _log.info('Theme card tapped: $label');
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        splashColor: theme.colorScheme.primary.withValues(alpha: 0.3),
        highlightColor: theme.colorScheme.primary.withValues(alpha: 0.2),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 32,
                  color: isSelected 
                      ? theme.colorScheme.onPrimary 
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelected 
                        ? theme.colorScheme.onPrimary 
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Text Options Tab Content - Enhanced with font selection
  Widget _buildEnhancedTextOptionsTab(ThemeData theme, SettingsState settingsState, SettingsNotifier settingsNotifier) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          
          // Font Family Selection
          _buildSectionTitle(theme, 'Font Family'),
          const SizedBox(height: 16),
          _buildFontFamilySelection(theme, settingsState, settingsNotifier),
          
          const SizedBox(height: 32),
          
          // Font size slider with improved design
          _buildEnhancedSliderSetting(
            theme,
            'Font Size',
            Icons.format_size,
            settingsState.fontSize.size,
            (value) {
              // Use the new fromSize method for more accurate font size setting
              final newSize = FontSize.fromSize(value);
              settingsNotifier.setFontSize(newSize);
            },
            12.0,
            28.0,
            16,
            '${settingsState.fontSize.size.round()}px',
          ),
          
          const SizedBox(height: 32),
          
          // Line spacing slider
          _buildEnhancedSliderSetting(
            theme,
            'Line Spacing',
            Icons.format_line_spacing,
            settingsState.lineSpacing,
            (value) => settingsNotifier.setLineSpacing(value),
            1.0,
            2.5,
            15,
            '${settingsState.lineSpacing.toStringAsFixed(1)}x',
          ),
          
          const SizedBox(height: 32),
          
          // Font preview
          _buildFontPreview(theme, settingsState),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurface,
      ),
    );
  }

  Widget _buildFontFamilySelection(ThemeData theme, SettingsState settingsState, SettingsNotifier settingsNotifier) {
    return Column(
        children: [
        // Urdu Fonts Row
        Row(
            children: [
            Expanded(
              child: _buildFontCard(
                theme,
                'Noto Nastaliq',
                'نوٹو نستعلیق',
                'NotoNastaliqUrdu',
                'NotoNastaliqUrdu',
                settingsState,
                settingsNotifier,
              ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFontCard(
                theme,
                'Jameel Noori Nastaleeq Regular',
                'جمیل نوری نستعلیق ریگولر',
                'JameelNooriNastaleeqRegular',
                'JameelNooriNastaleeqRegular',
                settingsState,
                settingsNotifier,
            ),
          ),
        ],
      ),
        const SizedBox(height: 12),
        // Arabic Font
        _buildFontCard(
          theme,
          'Noto Naskh Arabic',
          'نوتو نسخ العربية',
          'NotoNaskhArabic',
          'NotoNaskhArabic',
          settingsState,
          settingsNotifier,
            ),
      ],
    );
  }

  Widget _buildFontCard(
    ThemeData theme,
    String title,
    String preview,
    String fontFamily,
    String fontKey,
    SettingsState settingsState,
    SettingsNotifier settingsNotifier,
  ) {
    final isSelected = settingsState.fontFamily.displayName == fontKey;
    
    return Container(
      decoration: BoxDecoration(
      color: isSelected 
          ? theme.colorScheme.primary.withValues(alpha: 0.1)
          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected 
              ? theme.colorScheme.primary 
            : theme.colorScheme.outline.withValues(alpha: 0.2),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
      child: InkWell(
        onTap: () {
            // Update font family - we'll need to extend the FontFamily enum or use a different approach
            _log.info('Font selected: $fontKey');
            // For now, just log the selection - proper implementation would need font system updates
        },
          borderRadius: BorderRadius.circular(16),
        child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  color: isSelected 
                      ? theme.colorScheme.primary 
                      : theme.colorScheme.onSurface,
                ),
              ),
                const SizedBox(height: 8),
                Text(
                  preview,
                  style: TextStyle(
                    fontFamily: fontFamily,
                    fontSize: 18,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    height: 1.5,
                  ),
                  textDirection: TextDirection.rtl,
                ),
            ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedSliderSetting(
    ThemeData theme,
    String title,
    IconData icon,
    double value,
    ValueChanged<double> onChanged,
    double min,
    double max,
    int divisions,
    String valueLabel,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
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
                  valueLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
          ],
        ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
              activeTrackColor: theme.colorScheme.primary,
              inactiveTrackColor: theme.colorScheme.outline.withValues(alpha: 0.2),
              thumbColor: theme.colorScheme.primary,
              overlayColor: theme.colorScheme.primary.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFontPreview(ThemeData theme, SettingsState settingsState) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.preview,
                size: 20,
                color: theme.colorScheme.primary,
                ),
              const SizedBox(width: 8),
              Text(
                'Preview',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'اسلام علیکم ورحمۃ اللہ وبرکاتہ',
            style: TextStyle(
              fontSize: settingsState.fontSize.size + 2,
              height: settingsState.lineSpacing,
              fontFamily: 'NotoNastaliqUrdu', // Use current font selection
              color: theme.colorScheme.onSurface,
            ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 8),
          Text(
            'This is how your text will appear with current settings.',
            style: TextStyle(
              fontSize: settingsState.fontSize.size,
              height: settingsState.lineSpacing,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
      ),
    );
  }
} 