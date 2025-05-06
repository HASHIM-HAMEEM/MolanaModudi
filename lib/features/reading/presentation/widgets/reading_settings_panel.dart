import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/settings_provider.dart';
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
  int _currentIndex = 0;
  final List<String> _tabs = ['Appearance', 'Text', 'Language'];
  final _log = Logger('ReadingSettingsPanel'); // Add logger

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _currentIndex = _tabController.index;
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
                  color: Colors.black.withOpacity(0.3),
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
                        unselectedLabelColor: colors.onSurface.withOpacity(0.6),
                        indicatorColor: colors.primary,
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                        tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
                      ),
                    ),
                    
                    // Divider
                    Divider(height: 1, thickness: 1, color: colors.surfaceVariant),
                    
                    // Tab content
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // Appearance Tab
                          _buildAppearanceTab(theme, settingsState, settingsNotifier),
                          
                          // Text Options Tab
                          _buildTextOptionsTab(theme),
                          
                          // Language Options Tab
                          _buildLanguageOptionsTab(theme, settingsState, settingsNotifier),
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
                color: theme.colorScheme.primary.withOpacity(0.08),
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
          : theme.colorScheme.surfaceVariant.withOpacity(0.3),
      child: InkWell(
        onTap: () {
          _log.info('Theme card tapped: $label');
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        splashColor: theme.colorScheme.primary.withOpacity(0.3),
        highlightColor: theme.colorScheme.primary.withOpacity(0.2),
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

  // Text Options Tab Content
  Widget _buildTextOptionsTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          
          // Font size slider
          _buildSliderSetting(
            'Font Size',
            widget.currentFontSize,
            widget.onFontSizeChange,
            12.0,
            24.0,
            12,
            '${widget.currentFontSize.round()}',
          ),
          
          const SizedBox(height: 16),
          // Line spacing slider
          _buildSliderSetting(
            'Line Spacing',
            widget.currentLineSpacing,
            widget.onLineSpacingChange,
            1.0,
            2.5,
            15,
            '${widget.currentLineSpacing.toStringAsFixed(1)}',
          ),
          
          const SizedBox(height: 16),
          // Font type selection
          Text('Font Type', style: _getSectionStyle(theme)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12.0,
            children: [
              _buildFontTypeCard(theme, 'Serif', 'AaBbCc', widget.currentFontType == 'Serif'),
              _buildFontTypeCard(theme, 'Sans Serif', 'AaBbCc', widget.currentFontType == 'Sans Serif'),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // AI-recommended settings
          if (widget.recommendedSettings != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.smart_toy, size: 18, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'AI-Recommended Settings',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildRecommendedSettingItem(
                    theme, 
                    'Font Size', 
                    '${widget.recommendedSettings!['fontSize'] ?? '?'}'
                  ),
                  _buildRecommendedSettingItem(
                    theme, 
                    'Line Spacing', 
                    '${widget.recommendedSettings!['lineSpacing'] ?? '?'}'
                  ),
                  _buildRecommendedSettingItem(
                    theme, 
                    'Font Type', 
                    widget.recommendedSettings!['fontType'] as String? ?? '?'
                  ),
                  if (widget.recommendedSettings!['explanation'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        widget.recommendedSettings!['explanation'] as String,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      if (widget.onApplyRecommendedSettings != null) {
                        widget.onApplyRecommendedSettings!();
                      }
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Apply Recommended Settings'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                      minimumSize: const Size.fromHeight(44),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Helper method for recommended setting item
  Widget _buildRecommendedSettingItem(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  // Language Options Tab Content
  Widget _buildLanguageOptionsTab(ThemeData theme, SettingsState settingsState, SettingsNotifier settingsNotifier) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Text Direction',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          
          // Text Direction Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildDirectionToggle(
                theme,
                'LTR',
                Icons.format_textdirection_l_to_r,
                settingsState.language == AppLanguage.english,
                () => settingsNotifier.setLanguage(AppLanguage.english),
              ),
              const SizedBox(width: 32),
              _buildDirectionToggle(
                theme,
                'RTL',
                Icons.format_textdirection_r_to_l,
                settingsState.language == AppLanguage.arabic || settingsState.language == AppLanguage.urdu,
                () => settingsNotifier.setLanguage(AppLanguage.urdu),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Language Selection
          const Text(
            'Language',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          
          _buildLanguageOption(
            theme,
            'English',
            settingsState.language == AppLanguage.english,
            () => settingsNotifier.setLanguage(AppLanguage.english),
          ),
          const SizedBox(height: 8),
          _buildLanguageOption(
            theme,
            'Arabic',
            settingsState.language == AppLanguage.arabic,
            () => settingsNotifier.setLanguage(AppLanguage.arabic),
          ),
          const SizedBox(height: 8),
          _buildLanguageOption(
            theme,
            'Urdu',
            settingsState.language == AppLanguage.urdu,
            () => settingsNotifier.setLanguage(AppLanguage.urdu),
          ),
          
          const Spacer(),
          
          // Language info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, 
                      size: 18, 
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Language Setting',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Changing the language affects the app interface and reading direction. Some fonts may display better with certain languages.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper widgets
  Widget _buildFontTypeCard(
    ThemeData theme,
    String label,
    String text,
    bool isSelected
  ) {
    return Card(
      elevation: isSelected ? 2 : 0,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          width: 2,
        ),
      ),
      color: isSelected 
          ? theme.colorScheme.primary
          : theme.colorScheme.surfaceVariant.withOpacity(0.3),
      child: InkWell(
        onTap: () {
          _log.info('Font type selected: $label');
          widget.onFontTypeChange(label.toLowerCase());
        },
        borderRadius: BorderRadius.circular(12),
        splashColor: theme.colorScheme.primary.withOpacity(0.3),
        highlightColor: theme.colorScheme.primary.withOpacity(0.2),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected 
                  ? theme.colorScheme.onPrimary 
                  : theme.colorScheme.onSurfaceVariant,
              fontFamily: label.toLowerCase(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDirectionToggle(
    ThemeData theme,
    String label,
    IconData icon,
    bool isSelected,
    VoidCallback onTap
  ) {
    return Card(
      elevation: isSelected ? 2 : 0,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          width: 2,
        ),
      ),
      color: isSelected 
          ? theme.colorScheme.primary
          : theme.colorScheme.surfaceVariant.withOpacity(0.3),
      child: InkWell(
        onTap: () {
          _log.info('Direction toggle selected: $label');
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        splashColor: theme.colorScheme.primary.withOpacity(0.3),
        highlightColor: theme.colorScheme.primary.withOpacity(0.2),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected 
                    ? theme.colorScheme.onPrimary 
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
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
    );
  }

  Widget _buildLanguageOption(
    ThemeData theme,
    String label,
    bool isSelected,
    VoidCallback onTap
  ) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected 
              ? theme.colorScheme.primary 
              : theme.colorScheme.outline.withOpacity(0.3),
          width: isSelected ? 2 : 1,
        ),
      ),
      color: isSelected 
          ? theme.colorScheme.primary.withOpacity(0.1)
          : Colors.transparent,
      child: InkWell(
        onTap: () {
          _log.info('Language option selected: $label');
          onTap();
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            children: [
              Radio(
                value: true,
                groupValue: isSelected,
                onChanged: (_) => onTap(),
                activeColor: theme.colorScheme.primary,
              ),
              Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected 
                      ? theme.colorScheme.primary 
                      : theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliderSetting(
    String title,
    double value,
    ValueChanged<double> onChanged,
    double min,
    double max,
    int divisions,
    String? valueLabel,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            if (valueLabel != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  valueLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Material(
          color: Colors.transparent,
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
              activeTrackColor: Theme.of(context).colorScheme.primary,
              inactiveTrackColor: Theme.of(context).colorScheme.surfaceVariant,
              thumbColor: Theme.of(context).colorScheme.primary,
              overlayColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: (newValue) {
                _log.info('Slider value changed to: $newValue');
                onChanged(newValue);
              },
            ),
          ),
        ),
        // Add min/max indicators
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                min.toInt().toString(),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                max.toInt().toString(),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  TextStyle _getSectionStyle(ThemeData theme) {
    return TextStyle(
      fontWeight: FontWeight.w500,
      color: theme.colorScheme.onSurface,
    );
  }
} 