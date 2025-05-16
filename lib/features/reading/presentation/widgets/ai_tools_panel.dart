import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import '../providers/reading_state.dart';
import '../providers/reading_provider.dart';

class AiToolsPanel extends ConsumerStatefulWidget {
  final VoidCallback onClose;
  final String bookId;
  final ReadingState bookState;
  final VoidCallback? onExtractChapters;
  final VoidCallback? onAnalyzeVocabulary;
  final bool isLoading;

  const AiToolsPanel({
    super.key,
    required this.onClose,
    required this.bookId,
    required this.bookState,
    this.onExtractChapters,
    this.onAnalyzeVocabulary,
    this.isLoading = false,
  });

  @override
  ConsumerState<AiToolsPanel> createState() => _AiToolsPanelState();
}

class _AiToolsPanelState extends ConsumerState<AiToolsPanel> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _log = Logger('AiToolsPanel');
  
  // Controllers
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _selectedTextController = TextEditingController();
  
  // State variables
  bool _isLoadingSummary = false;
  bool _isLoadingRecommendations = false;
  bool _isLoadingSearch = false;
  bool _isLoadingTranslation = false;
  String? _summary;
  List<Map<String, dynamic>>? _recommendations;
  List<Map<String, dynamic>>? _searchResults;
  String? _translatedText;
  
  // Settings
  String _targetLanguage = 'English';
  final List<String> _availableLanguages = [
    'English', 'Spanish', 'French', 'German', 'Arabic', 
    'Chinese', 'Japanese', 'Korean', 'Russian', 'Portuguese',
    'Italian', 'Hindi', 'Urdu'
  ];
  
  final List<String> _voiceStyles = [
    'Natural', 'Formal', 'Friendly', 'Enthusiastic', 
    'Calm', 'Authoritative', 'Poetic'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _selectedTextController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    
    // Calculate responsive width
    final panelWidth = size.width < 600 
      ? size.width 
      : size.width * 0.4 > 450 ? 450.0 : size.width * 0.4;

    return Material(
      elevation: 0,
      color: Colors.transparent,
      child: Stack(
        children: [
          // Semi-transparent background
          Positioned.fill(
            child: GestureDetector(
              onTap: () => widget.onClose(),
              child: Container(
                color: Colors.black.withOpacity(0.4),
              ),
            ),
          ),
          
          // Main panel
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutQuart,
            top: 0,
            bottom: 0,
            right: 0,
            width: panelWidth,
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header
                  _buildHeader(theme),
                  
                  // Tab Bar
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                      border: Border(
                        bottom: BorderSide(
                          color: theme.colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      dividerColor: Colors.transparent,
                      labelColor: theme.colorScheme.primary,
                      unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                      indicatorColor: theme.colorScheme.primary,
                      tabs: const [
                        Tab(
                          icon: Icon(Icons.menu_book_outlined),
                          text: 'Chapters',
                        ),
                        Tab(
                          icon: Icon(Icons.translate_outlined),
                          text: 'Language',
                        ),
                        Tab(
                          icon: Icon(Icons.summarize_outlined),
                          text: 'Summary',
                        ),
                        Tab(
                          icon: Icon(Icons.recommend_outlined),
                          text: 'Recommendations',
                        ),
                        Tab(
                          icon: Icon(Icons.search),
                          text: 'Search',
                        ),
                        Tab(
                          icon: Icon(Icons.bookmark_outline),
                          text: 'Smart Bookmarks',
                        ),
                      ],
                    ),
                  ),
                  
                  // Tab Content
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildChaptersTab(theme),
                        _buildLanguageTab(theme),
                        _buildSummaryTab(theme),
                        _buildRecommendationsTab(theme),
                        _buildSearchTab(theme),
                        _buildBookmarksTab(theme),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Header widget
  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 16, 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.smart_toy_outlined,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Text(
                'AI Reading Assistant',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => widget.onClose(),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
  
  // Chapters Tab
  Widget _buildChaptersTab(ThemeData theme) {
    final isLoading = widget.bookState.isAiFeatureLoading('chapters');
    final hasChapters = widget.bookState.aiExtractedChapters != null && 
                         widget.bookState.aiExtractedChapters!.isNotEmpty;
    final isPdf = widget.bookState.status == ReadingStatus.displayingText;
                         
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeading(
          'Automatic Chapter Detection',
          'Extract chapters and sections from your document using AI analysis',
        ),
        
        const SizedBox(height: 16),
        
        if (isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Analyzing document structure...'),
                ],
              ),
            ),
          )
        else if (!hasChapters) 
          Column(
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  if (widget.onExtractChapters != null) {
                    widget.onExtractChapters!();
                  } else {
                    // Use the provider directly
                    ref.read(readingNotifierProvider(widget.bookId).notifier)
                       .extractChaptersWithAi();
                  }
                },
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Extract Chapters with AI'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
              
              // Add specific option for PDFs to extract from contents page
              if (isPdf) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                
                _buildSectionHeading(
                  'Table of Contents Detection',
                  'Extract chapters from the current page if it contains a table of contents',
                ),
                
                const SizedBox(height: 16),
                
                Card(
                  elevation: 0,
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Are you viewing a Table of Contents?',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Navigate to the content/index page in your PDF that shows chapter titles and page numbers, then click the button below.',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            // This explicitly sets the isTableOfContents flag
                            ref.read(readingNotifierProvider(widget.bookId).notifier)
                              .extractChaptersWithAi(forceTocExtraction: true);
                          },
                          icon: const Icon(Icons.menu_book),
                          label: const Text('Extract Chapters from Table of Contents'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                            backgroundColor: theme.colorScheme.primaryContainer,
                            foregroundColor: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Detected Chapters',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              // Display extracted chapters
              ...widget.bookState.aiExtractedChapters!.map((chapter) => 
                Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 0,
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  child: ListTile(
                    title: Text(
                      chapter['title'] ?? 'Unnamed Chapter',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: chapter['subtitle'] != null
                        ? Text(chapter['subtitle'])
                        : null,
                    trailing: Text(
                      "Page ${chapter['pageStart'] ?? '?'}",
                      style: theme.textTheme.bodySmall,
                    ),
                    onTap: () {
                      // Navigate to chapter
                      final pageStart = chapter['pageStart'];
                      if (pageStart != null) {
                        // Handle navigation based on content type
                        if (widget.bookState.status == ReadingStatus.displayingText) {
                          // Text/EPUB navigation
                          ref.read(readingNotifierProvider(widget.bookId).notifier)
                            .navigateToChapter(pageStart - 1);
                        }
                        widget.onClose();
                      }
                    },
                  ),
                )
              ),
              
              // Reset button
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  ref.read(readingNotifierProvider(widget.bookId).notifier)
                     .clearAiFeature('chapters');
                },
                icon: const Icon(Icons.restart_alt),
                label: const Text('Clear & Regenerate'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(40),
                ),
              ),
            ],
          ),
          
        const SizedBox(height: 16),
        
        const Divider(),
        
        const SizedBox(height: 16),
        
        _buildSectionHeading(
          'Chapter Navigation Tips',
          'How to effectively use AI-generated chapters',
        ),
        
        const SizedBox(height: 8),
        
        Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTipItem(
                  'Tap any chapter to immediately jump to that section',
                  theme,
                ),
                _buildTipItem(
                  'AI analyzes document structure, headings, and content transitions',
                  theme,
                ),
                _buildTipItem(
                  'For better results with PDFs, navigate to the table of contents page first',
                  theme,
                ),
                _buildTipItem(
                  'For better results, try regenerating after scrolling through more content',
                  theme,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Reusable section widget
  Widget _buildToolSection({
    required String title,
    required IconData icon,
    required String description,
    Widget? actionButton,
    Widget? content,
    Widget? expandedContent,
  }) {
    final theme = Theme.of(context);
    
    return ExpansionTile(
      title: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          description,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      childrenPadding: EdgeInsets.zero,
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      tilePadding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      children: [
        if (actionButton != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: actionButton,
          ),
        if (content != null)
          content,
        if (expandedContent != null)
          expandedContent,
      ],
    );
  }
  
  // Action button with loading state
  Widget _buildActionButton({
    required String label,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(44),
      ),
      child: isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(label),
    );
  }
  
  // Feature implementation methods
  Future<void> _generateSummary() async {
    if (widget.bookState.textContent == null) {
      return;
    }
    
    setState(() {
      _isLoadingSummary = true;
    });
    
    try {
      // Generate summary using the reading provider
      await ref.read(readingNotifierProvider(widget.bookId).notifier)
        .generateBookSummary();
      
      // Get the summary from the updated state
      final updatedState = ref.read(readingNotifierProvider(widget.bookId));
      final bookSummary = updatedState.bookSummary;
      
      setState(() {
        _summary = bookSummary != null && bookSummary.containsKey('summary') 
            ? bookSummary['summary']?.toString() 
            : 'Unable to generate summary.';
        _isLoadingSummary = false;
      });
    } catch (e) {
      _log.severe('Error generating summary: $e');
      setState(() {
        _isLoadingSummary = false;
        _summary = 'Error generating summary.';
      });
    }
  }
  
  Future<void> _getBookRecommendations() async {
    setState(() {
      _isLoadingRecommendations = true;
    });
    
    try {
      final repository = ref.read(readingRepositoryProvider);
      
      // Get recently read books from history
      // This is a simplified example; in a real app, you'd get this from a provider
      List<String> recentBooks = [widget.bookState.bookTitle ?? widget.bookId];
      
      final recommendations = await repository.getBookRecommendations(recentBooks);
      
      setState(() {
        _recommendations = recommendations;
        _isLoadingRecommendations = false;
      });
    } catch (e) {
      _log.severe('Error getting book recommendations: $e');
      setState(() {
        _isLoadingRecommendations = false;
      });
    }
  }
  
  Future<void> _searchWithinContent() async {
    final query = _searchController.text.trim();
    if (query.isEmpty || widget.bookState.textContent == null) {
      return;
    }
    
    setState(() {
      _isLoadingSearch = true;
    });
    
    try {
      final repository = ref.read(readingRepositoryProvider);
      
      final results = await repository.searchWithinContent(
        query,
        widget.bookState.textContent!,
      );
      
      setState(() {
        _searchResults = results;
        _isLoadingSearch = false;
      });
    } catch (e) {
      _log.severe('Error searching within content: $e');
      setState(() {
        _isLoadingSearch = false;
      });
    }
  }
  
  Future<void> _translateSelectedText() async {
    if (widget.bookState.textContent == null) {
      return;
    }
    
    // In a real implementation, you would get the selected text
    // For this example, we'll just use the first 300 characters
    final text = widget.bookState.textContent!.length > 300
        ? widget.bookState.textContent!.substring(0, 300)
        : widget.bookState.textContent!;
    
    setState(() {
      _isLoadingTranslation = true;
    });
    
    try {
      final repository = ref.read(readingRepositoryProvider);
      
      final translationResult = await repository.translateText(text, _targetLanguage);
      
      setState(() {
        _translatedText = translationResult.containsKey('translatedText') 
            ? translationResult['translatedText']?.toString() 
            : 'Translation failed.';
        _isLoadingTranslation = false;
      });
    } catch (e) {
      _log.severe('Error translating text: $e');
      setState(() {
        _isLoadingTranslation = false;
        _translatedText = 'Error translating text.';
      });
    }
  }

  Future<void> _loadVocabularyData() async {
    if (widget.bookState.textContent == null || widget.bookState.textContent!.isEmpty) {
      return;
    }
    
    if (widget.onAnalyzeVocabulary != null) {
      widget.onAnalyzeVocabulary!();
      return;
    }
    
    // Otherwise call directly
    ref.read(readingNotifierProvider(widget.bookId).notifier)
        .analyzeDifficultWords(widget.bookState.textContent!);
  }

  // Language Tab (Translation + Vocabulary)
  Widget _buildLanguageTab(ThemeData theme) {
    final hasVocabulary = widget.bookState.difficultWords != null && 
                          widget.bookState.difficultWords!.isNotEmpty;
    final isLoadingVocabulary = widget.bookState.isAiFeatureLoading('vocabulary');
    final isLoadingTranslation = widget.bookState.isAiFeatureLoading('translation');
    final hasTranslation = widget.bookState.currentTranslation != null;
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // --- TRANSLATION SECTION ---
        _buildSectionHeading(
          'Text Translation',
          'Translate selected text to another language',
        ),
        
        const SizedBox(height: 16),
        
        // Language selector
        DropdownButtonFormField<String>(
          value: _targetLanguage,
          decoration: InputDecoration(
            labelText: 'Target Language',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          items: _availableLanguages.map((language) => 
            DropdownMenuItem(
              value: language,
              child: Text(language),
            )
          ).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _targetLanguage = value;
              });
            }
          },
        ),
        
        const SizedBox(height: 16),
        
        // Text input field
        TextField(
          controller: _selectedTextController,
          decoration: InputDecoration(
            labelText: 'Text to Translate',
            hintText: 'Enter or paste text here',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          minLines: 3,
          maxLines: 5,
        ),
        
        const SizedBox(height: 16),
        
        // Translate button
        ElevatedButton.icon(
          onPressed: isLoadingTranslation ? null : _translateInputText,
          icon: isLoadingTranslation 
              ? const SizedBox(
                  width: 20, 
                  height: 20, 
                  child: CircularProgressIndicator(strokeWidth: 2)
                )
              : const Icon(Icons.translate),
          label: Text(isLoadingTranslation ? 'Translating...' : 'Translate'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
          ),
        ),
        
        // Translation result
        if (hasTranslation) ...[
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.2),
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Translated to: $_targetLanguage',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Text(
                      'From: ${widget.bookState.currentTranslation!['detectedLanguage'] ?? 'Unknown'}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                SelectableText(
                  widget.bookState.currentTranslation!['translated'] ?? 'Translation not available',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
        
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),
        
        // --- VOCABULARY SECTION ---
        _buildSectionHeading(
          'Advanced Vocabulary',
          'Identify and explain difficult words in the text',
        ),
        
        const SizedBox(height: 16),
        
        if (isLoadingVocabulary)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Analyzing vocabulary...'),
                ],
              ),
            ),
          )
        else if (!hasVocabulary)
          ElevatedButton.icon(
            onPressed: () {
              _loadVocabularyData();
            },
            icon: const Icon(Icons.psychology_alt),
            label: const Text('Analyze Difficult Words'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
          )
        else
          _buildDifficultWordsList(context, widget.bookState),
      ],
    );
  }
  
  // Summary Tab (Book summary & theme analysis)
  Widget _buildSummaryTab(ThemeData theme) {
    final isLoadingSummary = widget.bookState.isAiFeatureLoading('summary');
    final hasSummary = widget.bookState.bookSummary != null;
    final isLoadingThemes = widget.bookState.isAiFeatureLoading('themes');
    final hasThemes = widget.bookState.themeAnalysis != null;
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // --- BOOK SUMMARY SECTION ---
        _buildSectionHeading(
          'Book Summary',
          'AI-generated summary of the book\'s content',
        ),
        
        const SizedBox(height: 16),
        
        if (isLoadingSummary)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Generating summary...'),
                ],
              ),
            ),
          )
        else if (!hasSummary)
          ElevatedButton.icon(
            onPressed: _generateSummary,
            icon: const Icon(Icons.summarize),
            label: const Text('Generate Book Summary'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 0,
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Summary',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.bookState.bookSummary!['summary'] ?? 'Summary not available',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              
              if (widget.bookState.bookSummary!['themes'] != null) ...[
                Text(
                  'Main Themes',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (widget.bookState.bookSummary!['themes'] as List?)
                      ?.map((theme) => Chip(
                            label: Text(theme.toString()),
                            backgroundColor: theme.colorScheme.primaryContainer.withOpacity(0.5),
                            side: BorderSide.none,
                          ))
                      .toList() ??
                      [],
                ),
                const SizedBox(height: 16),
              ],
              
              if (widget.bookState.bookSummary!['keyTakeaways'] != null) ...[
                Text(
                  'Key Takeaways',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...((widget.bookState.bookSummary!['keyTakeaways'] as List?) ?? [])
                    .map((takeaway) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.check_circle_outline, size: 16),
                              const SizedBox(width: 8),
                              Expanded(child: Text(takeaway.toString())),
                            ],
                          ),
                        ))
                    ,
                const SizedBox(height: 16),
              ],
              
              // Reset button
              OutlinedButton.icon(
                onPressed: () {
                  ref.read(readingNotifierProvider(widget.bookId).notifier)
                     .clearAiFeature('summary');
                },
                icon: const Icon(Icons.restart_alt),
                label: const Text('Clear & Regenerate'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(40),
                ),
              ),
            ],
          ),
          
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),
        
        // --- THEME ANALYSIS SECTION ---
        _buildSectionHeading(
          'Theme & Concept Analysis',
          'In-depth analysis of themes, tone, and style',
        ),
        
        const SizedBox(height: 16),
        
        if (isLoadingThemes)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Analyzing themes and concepts...'),
                ],
              ),
            ),
          )
        else if (!hasThemes)
          ElevatedButton.icon(
            onPressed: () {
              ref.read(readingNotifierProvider(widget.bookId).notifier)
                 .analyzeThemesAndConcepts();
            },
            icon: const Icon(Icons.psychology),
            label: const Text('Analyze Themes & Concepts'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Major Themes
              if (widget.bookState.themeAnalysis!['majorThemes'] != null) ...[
                Text(
                  'Major Themes',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 0,
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: ((widget.bookState.themeAnalysis!['majorThemes'] as List?) ?? [])
                          .map((theme) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  "• $theme",
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ),
              ],
              
              // Style & Tone
              Row(
                children: [
                  if (widget.bookState.themeAnalysis!['tone'] != null)
                    Expanded(
                      child: Card(
                        elevation: 0,
                        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                        margin: const EdgeInsets.only(bottom: 16, right: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tone',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.bookState.themeAnalysis!['tone'] ?? 'Not available',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                  if (widget.bookState.themeAnalysis!['style'] != null)
                    Expanded(
                      child: Card(
                        elevation: 0,
                        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                        margin: const EdgeInsets.only(bottom: 16, left: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Style',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.bookState.themeAnalysis!['style'] ?? 'Not available',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              
              // Reset button
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  ref.read(readingNotifierProvider(widget.bookId).notifier)
                     .clearAiFeature('themes');
                },
                icon: const Icon(Icons.restart_alt),
                label: const Text('Clear & Regenerate'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(40),
                ),
              ),
            ],
          ),
      ],
    );
  }
  
  // Recommendations Tab
  Widget _buildRecommendationsTab(ThemeData theme) {
    final isLoadingRecommendations = widget.bookState.isAiFeatureLoading('recommendations');
    final hasRecommendations = widget.bookState.bookRecommendations != null && 
                              widget.bookState.bookRecommendations!.isNotEmpty;
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeading(
          'Personalized Book Recommendations',
          'AI-powered suggestions based on your reading history',
        ),
        
        const SizedBox(height: 16),
        
        // Genre preference
        const Text(
          'Preferred Genre (Optional)',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        
        const SizedBox(height: 8),
        
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            'Fiction', 'Non-fiction', 'Fantasy', 'Science Fiction', 
            'Biography', 'History', 'Self-Help', 'Religion', 
            'Philosophy', 'Politics', 'Science'
          ].map((genre) => ChoiceChip(
            label: Text(genre),
            selected: false, // Could be expanded to track selection
            onSelected: (_) {
              // Get recommendations with this genre
              ref.read(readingNotifierProvider(widget.bookId).notifier)
                .getBookRecommendations(preferredGenre: genre);
            },
          )).toList(),
        ),
        
        const SizedBox(height: 24),
        
        if (isLoadingRecommendations)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Finding your next great reads...'),
                ],
              ),
            ),
          )
        else if (!hasRecommendations)
          ElevatedButton.icon(
            onPressed: () {
              ref.read(readingNotifierProvider(widget.bookId).notifier)
                .getBookRecommendations();
            },
            icon: const Icon(Icons.recommend),
            label: const Text('Get Book Recommendations'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recommended Books',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              ...widget.bookState.bookRecommendations!.map((book) => 
                Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 0,
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    book['title'] ?? 'Unknown Title',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'by ${book['author'] ?? 'Unknown Author'}',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            if (book['publicationYear'] != null)
                              Text(
                                book['publicationYear'].toString(),
                                style: theme.textTheme.bodySmall,
                              ),
                          ],
                        ),
                        if (book['genre'] != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              book['genre'].toString(),
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                        if (book['reason'] != null) ...[
                          const SizedBox(height: 8),
                          const Divider(),
                          const SizedBox(height: 8),
                          Text(
                            book['reason'].toString(),
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                        if (book['similarTo'] != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Similar to: ${book['similarTo']}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              
              // Reset button
              OutlinedButton.icon(
                onPressed: () {
                  ref.read(readingNotifierProvider(widget.bookId).notifier)
                     .clearAiFeature('recommendations');
                },
                icon: const Icon(Icons.restart_alt),
                label: const Text('Clear & Regenerate'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(40),
                ),
              ),
            ],
          ),
      ],
    );
  }
  
  // Search Tab
  Widget _buildSearchTab(ThemeData theme) {
    final isLoadingSearch = widget.bookState.isAiFeatureLoading('search');
    final hasResults = widget.bookState.searchResults != null && 
                       widget.bookState.searchResults!.isNotEmpty;
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeading(
          'Semantic Search',
          'Find relevant content using natural language understanding',
        ),
        
        const SizedBox(height: 16),
        
        // Search box
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            labelText: 'Search Query',
            hintText: 'What would you like to find?',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            suffixIcon: IconButton(
              icon: isLoadingSearch 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.search),
              onPressed: _handleSearch,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          onSubmitted: (_) => _handleSearch(),
        ),
        
        const SizedBox(height: 8),
        
        Text(
          'Try natural questions like "What are the main arguments?" or "Tell me about the characters"',
          style: theme.textTheme.bodySmall,
        ),
        
        if (widget.bookState.lastSearchQuery != null) ...[
          const SizedBox(height: 24),
          Row(
            children: [
              Text(
                'Results for: ',
                style: theme.textTheme.bodyMedium,
              ),
              Text(
                '"${widget.bookState.lastSearchQuery}"',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        
        if (isLoadingSearch)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Searching for relevant content...'),
                ],
              ),
            ),
          )
        else if (hasResults)
          ...widget.bookState.searchResults!.map((result) =>
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 0,
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Relevance indicator
                        if (result['relevanceScore'] != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getRelevanceColor(
                                result['relevanceScore'] as num? ?? 0, 
                                theme
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${result['relevanceScore']}%',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        // Paragraph indicator
                        if (result['paragraphIndex'] != null)
                          Text(
                            'Paragraph ${result['paragraphIndex']}',
                            style: theme.textTheme.bodySmall,
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // The text content
                    Text(
                      result['text'] ?? '',
                      style: theme.textTheme.bodyMedium,
                    ),
                    if (result['keyPhrase'] != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Key point: "${result['keyPhrase']}"',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                    if (result['explanation'] != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        result['explanation'],
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          )
        else if (widget.bookState.lastSearchQuery != null)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(Icons.search_off, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'No results found',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try modifying your search terms or using more general concepts',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
  
  // Bookmarks Tab
  Widget _buildBookmarksTab(ThemeData theme) {
    final isLoadingBookmarks = widget.bookState.isAiFeatureLoading('bookmarks');
    final hasBookmarks = widget.bookState.suggestedBookmarks != null && 
                         widget.bookState.suggestedBookmarks!.isNotEmpty;
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeading(
          'Smart Bookmarks',
          'AI identifies key passages worth remembering',
        ),
        
        const SizedBox(height: 16),
        
        if (isLoadingBookmarks)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Finding important passages...'),
                ],
              ),
            ),
          )
        else if (!hasBookmarks)
          ElevatedButton.icon(
            onPressed: () {
              ref.read(readingNotifierProvider(widget.bookId).notifier)
                .suggestBookMarksFromAi();
            },
            icon: const Icon(Icons.bookmark_add),
            label: const Text('Generate Smart Bookmarks'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Key Passages',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              ...widget.bookState.suggestedBookmarks!.map((bookmark) => 
                Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 0,
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (bookmark['type'] != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  bookmark['type'].toString(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                            if (bookmark['importance'] != null)
                              Row(
                                children: List.generate(
                                  bookmark['importance'] as int? ?? 0,
                                  (index) => const Icon(Icons.star, size: 14, color: Colors.amber),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '"${bookmark['text'] ?? ''}"',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        if (bookmark['position'] != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Position: ${bookmark['position']}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                        if (bookmark['note'] != null) ...[
                          const SizedBox(height: 8),
                          const Divider(),
                          const SizedBox(height: 8),
                          Text(
                            bookmark['note'].toString(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              
              // Reset button
              OutlinedButton.icon(
                onPressed: () {
                  ref.read(readingNotifierProvider(widget.bookId).notifier)
                     .clearAiFeature('bookmarks');
                },
                icon: const Icon(Icons.restart_alt),
                label: const Text('Clear & Regenerate'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(40),
                ),
              ),
            ],
          ),
      ],
    );
  }
  
  // Helper methods
  Widget _buildSectionHeading(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: const TextStyle(
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
  
  Widget _buildTipItem(String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.tips_and_updates,
            size: 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
  
  Color _getRelevanceColor(num relevance, ThemeData theme) {
    if (relevance > 80) {
      return Colors.green;
    } else if (relevance > 50) {
      return Colors.blue;
    } else {
      return Colors.grey;
    }
  }
  
  // Action methods
  void _handleSearch() {
    if (_searchController.text.trim().isEmpty) return;
    
    ref.read(readingNotifierProvider(widget.bookId).notifier)
       .searchWithinContent(_searchController.text);
  }
  
  void _translateInputText() {
    if (_selectedTextController.text.trim().isEmpty) return;
    
    ref.read(readingNotifierProvider(widget.bookId).notifier)
       .translateText(_selectedTextController.text, _targetLanguage);
  }

  Widget _buildDifficultWordsList(BuildContext context, ReadingState bookState) {
    if (bookState.difficultWords == null || bookState.difficultWords!.isEmpty) {
      return const Center(child: Text("No difficult words identified yet."));
    }

    // Convert the map to a list of widgets
    List<Widget> wordWidgets = [];
    bookState.difficultWords!.forEach((term, definition) {
      // Each term-definition pair becomes a Card
      wordWidgets.add(
        Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  term, // Display the term
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  definition, // Display the definition
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      );
    });

    return ListView(
      padding: const EdgeInsets.all(8.0),
      children: wordWidgets,
    );
  }
} 