import 'package:flutter_riverpod/flutter_riverpod.dart';

/// UI state for reading screen - separated from business logic
class ReadingUIState {
  final bool showHeaderFooter;
  final bool showVocabularyPanel;
  final bool showTranslationPanel;
  final bool showAiToolsPanel;
  final bool showSettingsPanel;
  final String selectedWord;
  final String wordDefinition;
  final String? translatedText;
  final bool isSpeaking;

  const ReadingUIState({
    this.showHeaderFooter = true,
    this.showVocabularyPanel = false,
    this.showTranslationPanel = false,
    this.showAiToolsPanel = false,
    this.showSettingsPanel = false,
    this.selectedWord = '',
    this.wordDefinition = '',
    this.translatedText,
    this.isSpeaking = false,
  });

  ReadingUIState copyWith({
    bool? showHeaderFooter,
    bool? showVocabularyPanel,
    bool? showTranslationPanel,
    bool? showAiToolsPanel,
    bool? showSettingsPanel,
    String? selectedWord,
    String? wordDefinition,
    String? translatedText,
    bool? isSpeaking,
  }) {
    return ReadingUIState(
      showHeaderFooter: showHeaderFooter ?? this.showHeaderFooter,
      showVocabularyPanel: showVocabularyPanel ?? this.showVocabularyPanel,
      showTranslationPanel: showTranslationPanel ?? this.showTranslationPanel,
      showAiToolsPanel: showAiToolsPanel ?? this.showAiToolsPanel,
      showSettingsPanel: showSettingsPanel ?? this.showSettingsPanel,
      selectedWord: selectedWord ?? this.selectedWord,
      wordDefinition: wordDefinition ?? this.wordDefinition,
      translatedText: translatedText ?? this.translatedText,
      isSpeaking: isSpeaking ?? this.isSpeaking,
    );
  }
}

/// UI state notifier for reading screen
class ReadingUINotifier extends StateNotifier<ReadingUIState> {
  ReadingUINotifier() : super(const ReadingUIState());

  /// Toggle header/footer visibility with throttling
  void toggleHeaderFooter() {
    state = state.copyWith(showHeaderFooter: !state.showHeaderFooter);
  }

  /// Show/hide vocabulary panel
  void setVocabularyPanel(bool show, {String word = '', String definition = ''}) {
    state = state.copyWith(
      showVocabularyPanel: show,
      selectedWord: word,
      wordDefinition: definition,
    );
  }

  /// Show/hide translation panel
  void setTranslationPanel(bool show, {String? translatedText}) {
    state = state.copyWith(
      showTranslationPanel: show,
      translatedText: translatedText,
    );
  }

  /// Show/hide AI tools panel
  void setAiToolsPanel(bool show) {
    state = state.copyWith(showAiToolsPanel: show);
  }

  /// Show/hide settings panel
  void setSettingsPanel(bool show) {
    state = state.copyWith(showSettingsPanel: show);
  }

  /// Clear all panels
  void clearAllPanels() {
    state = state.copyWith(
      showVocabularyPanel: false,
      showTranslationPanel: false,
      showAiToolsPanel: false,
      showSettingsPanel: false,
      selectedWord: '',
      wordDefinition: '',
      translatedText: null,
    );
  }

  /// Set speaking state for text-to-speech
  void setSpeaking(bool speaking) {
    state = state.copyWith(isSpeaking: speaking);
  }

  /// Hide header/footer (e.g., when scrolling)
  void hideHeaderFooter() {
    if (state.showHeaderFooter) {
      state = state.copyWith(showHeaderFooter: false);
    }
  }

  /// Show header/footer (e.g., when scroll stops)
  void showHeaderFooter() {
    if (!state.showHeaderFooter) {
      state = state.copyWith(showHeaderFooter: true);
    }
  }
}

/// Provider for reading UI state
final readingUiProvider = StateNotifierProvider<ReadingUINotifier, ReadingUIState>(
  (ref) => ReadingUINotifier(),
); 