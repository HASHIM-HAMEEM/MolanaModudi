import 'dart:io'; // For File operations
import 'dart:convert'; // For utf8 encoding/decoding
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:epub_view/epub_view.dart';
import 'package:modudi/core/services/api_service.dart'; // For repository provider dependency
import 'package:modudi/core/services/gemini_service.dart'; // Import for geminiServiceProvider
import 'package:modudi/features/reading/data/repositories/reading_repository_impl.dart';
import 'package:modudi/features/reading/domain/entities/file_entity.dart';
import 'package:modudi/features/reading/domain/repositories/reading_repository.dart';
import '../../../home/data/providers/home_data_providers.dart';
import 'reading_state.dart';
import 'dart:async';
import 'package:modudi/features/book_detail/presentation/providers/book_detail_provider.dart'; // Need book details for language check
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reading_models.dart';

// Provider for ReadingRepository
final readingRepositoryProvider = Provider<ReadingRepository>((ref) {
  // final apiService = ref.watch(archiveApiServiceProvider); // Use existing API service
  final geminiService = ref.watch(geminiServiceProvider); // Add GeminiService
  return ReadingRepositoryImpl(
    // apiService: apiService, // Removed apiService parameter
    geminiService: geminiService
  );
});

// StateNotifier for Reading Screen logic
class ReadingNotifier extends StateNotifier<ReadingState> {
  final ReadingRepository _repository;
  final String _bookId;
  final _log = Logger('ReadingNotifier');
  
  // Reading progress tracking
  int _currentChapter = 0;
  double _textScrollPosition = 0.0;
  int _totalChapters = 0;
  Timer? _positionCheckTimer;
  static const _allowedLanguages = {'eng', 'ara', 'urd'}; // Allowed language codes

  ReadingNotifier(this._repository, this._bookId) 
      : super(const ReadingState()) {
    _loadContent();
  }

  Future<void> _loadContent() async {
    state = state.copyWith(status: ReadingStatus.loadingMetadata, clearError: true);
    _log.info('Loading content for book ID: $_bookId...');

    try {
      // ---- Fetch Book Metadata (including title) ----
      // Note: Requires access to a suitable repository method
      // Using ReadingRepository for simplicity, assuming it can get basic metadata
      // Ideally, this might come from a different provider or be passed in.
      // final basicMetadata = await _repository.getBookMetadata(_bookId);
      final bookData = await _repository.getBookData(_bookId); // Changed to getBookData
      final bookTitle = bookData.title ?? _bookId; // Get title from Book object
      state = state.copyWith(bookTitle: bookTitle);
      _log.info('Fetched book title: $bookTitle');
      // ---- End Metadata Fetch ----

      // ---- Language Check ----
      // Fetch book details first to check language
      // We need a way to access the ref here, or pass it in, or fetch details differently.
      // For now, let's assume we get the details somehow.
      // This is a simplified placeholder. A proper solution might involve
      // changing the provider structure or how data is passed.
      // final bookDetails = await ref.read(bookDetailRepositoryProvider).getBookDetails(_bookId); // THIS WON'T WORK DIRECTLY IN StateNotifier

      // TEMPORARY WORKAROUND: Assume language check passed for now.
      // A better solution is needed here.
      // if (!_allowedLanguages.contains(bookDetails.language?.toLowerCase())) {
      //   throw Exception('Book language (${bookDetails.language}) is not supported.');
      // }
      // ---- End Language Check ----


      // final files = await _repository.getFiles(_bookId); // REMOVED
      /* 
      REMOVED FileEntity based logic:
      if (files.isEmpty) {
        throw Exception('No downloadable files found for book ID: $_bookId.');
      }

      // ---- Add Detailed File Logging ----
      _log.info('Files received for book ID $_bookId:');
      for (final file in files) {
        _log.info('  - Name: ${file.name}, Format: ${file.format}');
      }
      // ---- End Detailed File Logging ----

      FileEntity? selectedFile = null;
      bool isEpub = false;
      bool isText = false;
      bool isPdf = false;

      // 1. Prioritize PDF format per the user's requirements
      try { 
        selectedFile = files.firstWhere((f) => f.format.toLowerCase().contains('pdf')); 
        isPdf = true;
        _log.info('Selected PDF file: ${selectedFile.name}');
      } catch (_) {}

      // 2. If no PDF, fallback to EPUB
      if (selectedFile == null) {
        try { 
          selectedFile = files.firstWhere((f) => f.format.toLowerCase() == 'epub'); 
          isEpub = true;
          _log.info('No PDF found, falling back to EPUB: ${selectedFile.name}');
        } catch (_) {}
      }

      // 3. If no PDF or EPUB, look for plain text formats
      if (selectedFile == null) {
        try {
          selectedFile = files.firstWhere((f) {
            final formatLower = f.format.toLowerCase();
            if (formatLower.contains('zip')) return false;
            return formatLower.contains('text') || formatLower.contains('txt') || f.name.toLowerCase().endsWith('.txt');
          });
          isText = true;
          _log.info('No PDF or EPUB found, falling back to text: ${selectedFile.name}');
        } catch (_) {}
      }

      // 4. Handle case where no suitable file is found
      if (selectedFile == null) {
        _log.warning('No supported file format (EPUB, Text, PDF) found for $_bookId.');
        // Determine more specific error
        final djvuExists = files.any((f) => f.format.toLowerCase().contains('djvu'));
        if (djvuExists) {
          throw Exception('Unsupported format: DjVu file is available but cannot be read.');
        } else {
           throw Exception('No supported file format (EPUB, Text, or PDF) could be found for this book.');
        }
      }

      _log.info('Selected file - Format: ${selectedFile.format}, Name: ${selectedFile.name}, Type: ${isEpub ? 'EPUB' : isText ? 'Text' : isPdf ? 'PDF' : 'Unknown'}');

      // Download the file (common logic)
      state = state.copyWith(status: ReadingStatus.downloading, downloadProgress: 0.0);
      final tempDir = await getTemporaryDirectory();
      final safeFilename = selectedFile.name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final savePath = '${tempDir.path}/$_bookId/$safeFilename';
      final file = File(savePath);
      if (!await file.parent.exists()) {
         await file.parent.create(recursive: true);
      }
      await _repository.downloadFile(selectedFile.downloadUrl, savePath, (count, total) {
         double progress = total > 0 ? count / total : 0.0;
        if ((progress * 100).toInt() % 5 == 0 || progress == 1.0) {
           if (mounted) { state = state.copyWith(downloadProgress: progress); }
        }
      });
      */

      // --- Refactored Content Loading --- 
      state = state.copyWith(status: ReadingStatus.loadingContent);
      _log.info('Fetching headings for book ID: $_bookId');
      final headings = await _repository.getBookHeadings(_bookId);
      
      if (headings.isEmpty) {
        // Handle case where book data exists but no headings found
        _log.warning('No headings found for book ID: $_bookId');
        throw Exception('Book content (headings) could not be loaded.');
      }
      
      // --- Determine Format (Simplified: Assuming Text for now) --- 
      // TODO: Implement proper format detection (EPUB/PDF/Text)
      bool isTextContent = true; // Defaulting to text
      bool isEpub = false; // Placeholder
      bool isPdf = false;  // Placeholder

      await _loadSavedProgress(); // Load progress after metadata/headings fetch

      // --- Load Content Based on Determined Type --- 
      if (isTextContent) {
        _log.info('Processing headings as text content');
        // Concatenate content from all headings
        StringBuffer textBuffer = StringBuffer();
        for (final heading in headings) {
          if (heading.title != null) {
            // Add heading title (e.g., with markdown)
            textBuffer.writeln('\n## ${heading.title}\n'); 
          }
          if (heading.content != null) {
            textBuffer.writeln(heading.content!.join('\n')); // Join content strings
          }
        }
        String textContent = _formatTextContent(textBuffer.toString());

        // Simple chapter estimation based on number of headings
        _totalChapters = headings.length > 0 ? headings.length : 1;
        state = state.copyWith(
          status: ReadingStatus.displayingText,
          textContent: textContent,
          totalChapters: _totalChapters,
          currentChapter: _currentChapter, // Keep loaded progress
          textScrollPosition: _textScrollPosition, // Keep loaded progress
        );
        _log.info('Text content loaded from ${headings.length} headings.');
      } else if (isEpub) {
         _log.warning('EPUB loading logic not yet implemented for Firestore data.');
         // TODO: Implement EPUB handling - Needs URL/path from Book/Heading?
         throw UnimplementedError('EPUB loading from Firestore not implemented');
      } else if (isPdf) {
        _log.warning('PDF loading logic not yet implemented for Firestore data.');
        // TODO: Implement PDF handling - Needs URL/path from Book/Heading?
         throw UnimplementedError('PDF loading from Firestore not implemented');
      }
      // --- End Content Loading Logic ---
      
      /*
      REMOVED old content loading logic based on downloaded files:
      if (isEpub) {
         // ... EPUB loading ...
      } else if (isText) {
         // ... Text loading ...
      } else if (isPdf) {
        // ... PDF loading ...
      }
      */

    } catch (e, stackTrace) {
      _log.severe('Failed to load book content for $_bookId: $e', e, stackTrace);
      state = state.copyWith(
        status: ReadingStatus.error,
        // Use the specific error message from the exception
        errorMessage: e is Exception ? e.toString().replaceFirst('Exception: ', '') : e.toString(),
      );
    }
  }
  
  // Load previously saved reading progress
  Future<void> _loadSavedProgress() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/reading_progress.json');
      
      if (await file.exists()) {
        final String contents = await file.readAsString();
        final Map<String, dynamic> data = jsonDecode(contents);
        
        if (data.containsKey(_bookId)) {
          final bookData = data[_bookId];
          
          _currentChapter = bookData['currentChapter'] ?? 0;
          _textScrollPosition = bookData['textScrollPosition'] ?? 0.0;
          
          // Load EPUB CFI position if available
          final lastPosition = bookData['lastPosition'];
          
          _log.info('Loaded reading progress for $_bookId: chapter $_currentChapter, position $lastPosition');
          
          state = state.copyWith(
            currentChapter: _currentChapter,
            textScrollPosition: _textScrollPosition,
            lastPosition: lastPosition,
          );
        }
      }
    } catch (e) {
      _log.warning('Error loading reading progress: $e');
      // Continue without saved progress
    }
  }
  
  // Save current reading progress
  Future<void> _saveProgress() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/reading_progress.json');
      
      Map<String, dynamic> allData = {};
      
      // Load existing data if file exists
      if (await file.exists()) {
        final String contents = await file.readAsString();
        allData = jsonDecode(contents);
      }
      
      // Update data for current book
      allData[_bookId] = {
        'currentChapter': state.currentChapter,
        'textScrollPosition': state.textScrollPosition,
        'lastPosition': state.lastPosition,
        'lastRead': DateTime.now().toIso8601String(),
      };
      
      // Save to file
      await file.writeAsString(jsonEncode(allData));
      _log.info('Saved reading progress for $_bookId');
    } catch (e) {
      _log.warning('Error saving reading progress: $e');
    }
  }
  
  // Update progress information
  void _updateProgress(int chapterNumber) {
    if (!mounted) return;
    
    // Only update if there's a significant change
    if (chapterNumber != state.currentChapter) {
      state = state.copyWith(
        currentChapter: chapterNumber,
      );
      
      // Save progress after a delay to avoid excessive disk writes
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _saveProgress();
        }
      });
    }
  }
  
  // Public method to update text scroll position (for plain text reading)
  void updateTextPosition(double position) {
    if (!mounted) return;
    _textScrollPosition = position;
    
    // Calculate chapter based on scroll position (simple division)
    final newChapter = (_textScrollPosition * _totalChapters).floor();
    
    state = state.copyWith(
      textScrollPosition: _textScrollPosition,
      currentChapter: newChapter,
    );
    
    // Save progress after a delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _saveProgress();
      }
    });
  }
  
  // Method to navigate to a specific chapter
  void navigateToChapter(int chapterIndex) {
    if (!mounted) return;
    
    if (state.status == ReadingStatus.displayingEpub && state.epubController != null) {
      if (chapterIndex >= 0 && chapterIndex < _totalChapters) {
        state.epubController!.scrollTo(index: chapterIndex);
        _log.info('Navigated to chapter: $chapterIndex');
      }
    } else if (state.status == ReadingStatus.displayingText) {
      // For text, we calculate a scroll position based on chapter index
      final position = chapterIndex / _totalChapters.toDouble();
      updateTextPosition(position);
      _log.info('Set text position to: $position for chapter $chapterIndex');
    }
  }
  
  // Gets the current reading progress as a percentage
  double getProgressPercentage() {
    if (_totalChapters <= 0) return 0.0;
    return state.currentChapter / _totalChapters;
  }
  
  // Public method to reload content
  Future<void> reload() async {
    await _loadContent();
  }

   // Ensure controllers are disposed
  @override
  void dispose() {
    // Save progress one last time before disposing
    _saveProgress();
    _positionCheckTimer?.cancel();
    state.epubController?.dispose();
    super.dispose();
  }

  // Format text content for better readability
  String _formatTextContent(String text) {
    if (text.isEmpty) return text;
    
    _log.info('Formatting text content for better readability');
    
    try {
      // Remove control characters and replace with spaces
      String formatted = text.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), ' ');
      
      // Remove excessive whitespace - replace 3+ newlines with 2 newlines
      formatted = formatted.replaceAll(RegExp(r'\n{3,}'), '\n\n');
      
      // Add proper paragraph spacing - replace single newline between text with double newline
      formatted = formatted.replaceAll(RegExp(r'([^\n])\n([^\n])'), r'$1\n\n$2');
      
      // Fix common OCR issues like split words
      formatted = formatted.replaceAll(RegExp(r'([a-zA-Z])- ([a-zA-Z])'), r'$1$2');
      
      // Fix other common OCR artifacts like unexpected symbols
      formatted = formatted.replaceAll(RegExp(r'[^\x20-\x7E\n\r\t\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\u0900-\u097F]'), ' ');
      
      // Process paragraphs for better readability
      List<String> paragraphs = formatted.split('\n\n');
      List<String> cleanedParagraphs = [];
      
      for (String p in paragraphs) {
        // Skip empty paragraphs
        if (p.trim().isEmpty) continue;
        
        // Clean up whitespace within paragraph
        p = p.trim().replaceAll(RegExp(r'\s+'), ' ');
        
        // Don't indent if it looks like a heading (all caps or starts with #)
        if (p == p.toUpperCase() || p.startsWith('#') || p.length < 50) {
          cleanedParagraphs.add(p);
        } else {
          // Add paragraph indentation
          cleanedParagraphs.add('    $p');
        }
      }
      
      return cleanedParagraphs.join('\n\n');
    } catch (e, st) {
      _log.severe('Error formatting text content: $e', e, st);
      // Return original text if formatting fails
      return text;
    }
  }

  /// Update the reading progress and save it to reading history
  Future<void> saveReadingProgress({
    required String bookId,
    required String title,
    String? author,
    String? coverUrl,
    required double progress,
    int? currentPage,
    int? totalPages,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recentBooksJson = prefs.getStringList('recentBooks') ?? [];
      
      // Create new book data
      final newBook = {
        'id': bookId,
        'title': title,
        'author': author,
        'coverUrl': coverUrl,
        'progress': progress,
        'lastReadTime': DateTime.now().millisecondsSinceEpoch,
        'currentPage': currentPage,
        'totalPages': totalPages,
      };
      
      // Convert to JSON string
      final newBookJson = json.encode(newBook);
      
      // Remove existing entry for this book if exists
      final updatedList = recentBooksJson.where((item) {
        try {
          final Map<String, dynamic> data = json.decode(item);
          return data['id'] != bookId;
        } catch (e) {
          return true; // Keep entries that can't be parsed
        }
      }).toList();
      
      // Add new entry at the beginning
      updatedList.insert(0, newBookJson);
      
      // Keep only the last 20 books
      if (updatedList.length > 20) {
        updatedList.removeRange(20, updatedList.length);
      }
      
      // Save to SharedPreferences
      await prefs.setStringList('recentBooks', updatedList);
      _log.info('Saved reading progress for book: $title, progress: ${(progress * 100).toInt()}%');
    } catch (e) {
      _log.severe('Error saving reading progress: $e');
    }
  }

  // Add before the _formatTextContent method
  double? _lastSavedProgress;

  // Update position tracking
  void _positionUpdate(double position) {
    _textScrollPosition = position;
    
    // Calculate progress percentage
    final progress = position.clamp(0.0, 1.0);
    
    // Save reading progress periodically (don't save on every tiny update)
    if (_lastSavedProgress == null || (_lastSavedProgress! - progress).abs() > 0.05) {
      // Get book metadata from state
      final bookTitle = state.bookTitle ?? _bookId;
      
      // Save reading progress
      saveReadingProgress(
        bookId: _bookId,
        title: bookTitle,
        progress: progress,
        currentPage: _currentChapter,
        totalPages: _totalChapters,
      );
      
      _lastSavedProgress = progress;
    }
  }
  
  // Update position when page changes in PDF
  void updatePdfPosition(int currentPage, int totalPages) {
    _currentChapter = currentPage;
    _totalChapters = totalPages;
    final progress = totalPages > 0 ? currentPage / totalPages : 0.0;
    _positionUpdate(progress);
  }

  // Add a method to update state with AI-extracted chapters
  void updateChapters(List<Map<String, dynamic>> chapters) {
    if (!mounted) return;
    
    _log.info('Updating chapters with AI extraction: ${chapters.length} chapters found');
    state = state.copyWith(
      aiExtractedChapters: chapters,
      totalChapters: chapters.length, // Update total chapters
    );
    
    // Save updated chapters to reading history
    _saveProgress();
  }

  // Add a method to update state with vocabulary data
  void updateVocabulary(List<Map<String, dynamic>> words) {
    if (!mounted) return;
    
    _log.info('Updating vocabulary with ${words.length} difficult words');
    state = state.copyWith(
      difficultWords: words,
      aiFeatureStatus: {'vocabulary': AiFeatureStatus.ready},
    );
  }

  // Add a method to update state with book summary
  void updateBookSummary(Map<String, dynamic> summary) {
    if (!mounted) return;
    
    _log.info('Updating book summary');
    state = state.copyWith(
      bookSummary: summary,
      aiFeatureStatus: {'summary': AiFeatureStatus.ready},
    );
    
    // Save updated summary to reading history
    _saveProgress();
  }

  // Update the _extractChapters method to use PDF pages from the state
  List<PlaceholderChapter> _extractChapters(ReadingState state) {
    List<PlaceholderChapter> chapters = [];
    
    // First check if we have AI-extracted chapters
    if (state.aiExtractedChapters != null && state.aiExtractedChapters!.isNotEmpty) {
      _log.info('Using AI-extracted chapters: ${state.aiExtractedChapters!.length}');
      
      chapters = state.aiExtractedChapters!.asMap().entries.map((entry) {
        final chapter = entry.value;
        return PlaceholderChapter(
          id: (entry.key).toString(),
          title: chapter['title'] ?? 'Chapter ${entry.key + 1}',
          pageStart: chapter['pageStart'] ?? (entry.key + 1),
          subtitle: chapter['subtitle'],
        );
      }).toList();
      
      return chapters;
    }
    
    // Otherwise fallback to existing extraction logic
    if (state.status == ReadingStatus.displayingEpub && state.epubController != null) {
      // Get chapters from state instead
      final totalChapters = state.totalChapters;
      
      // Create placeholder chapters based on total count
      for (int i = 0; i < totalChapters; i++) {
        chapters.add(PlaceholderChapter(
          id: i.toString(),
          title: 'Chapter ${i + 1}',
          pageStart: i + 1,
        ));
      }
    } else if (state.status == ReadingStatus.displayingText) {
      // For text files, create simple chapter divisions
      chapters = [
        const PlaceholderChapter(id: '1', title: 'Beginning', pageStart: 1),
        const PlaceholderChapter(id: '2', title: 'Middle', pageStart: 2),
        const PlaceholderChapter(id: '3', title: 'End', pageStart: 3),
      ];
    } else if (state.status == ReadingStatus.displayingPdf) {
      // For PDFs, check if we have page info in the state
      final currentPage = state.currentChapter;
      final totalPages = state.totalChapters;
      
      if (totalPages > 0) {
        // Create chapter markers at regular intervals
        final numberOfMarkers = totalPages < 10 ? totalPages : 10;
        final interval = totalPages ~/ numberOfMarkers;
        
        for (int i = 0; i < numberOfMarkers; i++) {
          final pageNum = i * interval;
          chapters.add(PlaceholderChapter(
            id: pageNum.toString(),
            title: 'Page ${pageNum + 1}',
            pageStart: pageNum + 1,
          ));
        }
        
        // Add the last page if not already included
        if (totalPages % numberOfMarkers != 0) {
          chapters.add(PlaceholderChapter(
            id: (totalPages - 1).toString(),
            title: 'Page $totalPages',
            pageStart: totalPages,
          ));
        }
      }
    }
    
    return chapters;
  }

  // AI feature methods
  
  /// Extract chapters using AI analysis
  Future<void> extractChaptersWithAi({bool forceTocExtraction = false}) async {
    if (!mounted) return;
    
    // Update AI feature status
    state = state.copyWith(
      aiFeatureStatus: {'chapters': AiFeatureStatus.loading},
    );
    
    try {
      String contentToAnalyze = '';
      String? bookType;
      bool isTableOfContents = forceTocExtraction; // Use the explicit flag
      
      if (state.textContent != null) {
        contentToAnalyze = state.textContent!;
        bookType = 'text';
      } else if (state.status == ReadingStatus.displayingPdf && state.pdfPath != null) {
        // For PDF, use the book title as general context, 
        // but rely on isTableOfContents flag for specific TOC prompt.
        contentToAnalyze = state.bookTitle ?? _bookId;
        
        // If not forced, check if it's likely a TOC page based on position
        if (!isTableOfContents && state.currentChapter < 5) { 
          isTableOfContents = true;
          _log.info('Detected potential table of contents page based on position');
        }
        
        // If extracting specifically from TOC, log it
        if (forceTocExtraction) {
           _log.info('Forcing Table of Contents extraction for PDF');
           // Ideally, we would extract text from the current page here.
           // Since we can't, we rely on the specialized prompt in GeminiService
           // and pass the bookTitle as context.
           contentToAnalyze = "Table of Contents page for: ${state.bookTitle ?? _bookId}"; // Use a placeholder or title
        }
        
        bookType = 'pdf';
      } else if (state.status == ReadingStatus.displayingEpub) {
        contentToAnalyze = state.bookTitle ?? _bookId;
        bookType = 'epub';
      }
      
      if (contentToAnalyze.isNotEmpty) {
        final chapters = await _repository.extractChaptersFromContent(
          contentToAnalyze, // This content might just be context if isTableOfContents is true
          bookType: bookType,
          bookTitle: state.bookTitle,
          isTableOfContents: isTableOfContents, // Pass the flag
        );
        
        if (chapters.isNotEmpty) {
          state = state.copyWith(
            aiExtractedChapters: chapters,
            totalChapters: chapters.length,
            aiFeatureStatus: {'chapters': AiFeatureStatus.ready},
          );
          _log.info('AI extracted ${chapters.length} chapters');
          _saveProgress(); // Save the extracted chapters
          return;
        }
      }
      
      // If we get here, something went wrong
      _log.warning('Chapter extraction failed. Content was empty or AI returned no chapters.');
      state = state.copyWith(
        aiFeatureStatus: {'chapters': AiFeatureStatus.error},
      );
    } catch (e) {
      _log.warning('Error extracting chapters: $e');
      state = state.copyWith(
        aiFeatureStatus: {'chapters': AiFeatureStatus.error},
      );
    }
  }
  
  /// Generate a book summary using AI
  Future<void> generateBookSummary({String? language}) async {
    if (!mounted) return;
    
    _log.info('Generating book summary');
    state = state.copyWith(
      aiFeatureStatus: {'summary': AiFeatureStatus.loading},
    );
    
    try {
      // Determine what content to use for summarization
      String textToSummarize = '';
      String? currentLanguage = language;
      
      if (state.textContent != null && state.textContent!.isNotEmpty) {
        // For text content, use a sample to avoid token limits
        textToSummarize = state.textContent!.length > 5000
            ? state.textContent!.substring(0, 5000)
            : state.textContent!;
      } else {
        // If no text content, use the book title
        textToSummarize = state.bookTitle ?? _bookId;
      }
      
      // Generate the summary
      final summary = await _repository.generateBookSummary(
        textToSummarize,
        bookTitle: state.bookTitle,
        language: currentLanguage,
      );
      
      if (summary != null) {
        state = state.copyWith(
          bookSummary: summary,
          aiFeatureStatus: {'summary': AiFeatureStatus.ready},
        );
        _log.info('Generated book summary');
        return;
      }
      
      // If we get here, something went wrong
      state = state.copyWith(
        aiFeatureStatus: {'summary': AiFeatureStatus.error},
      );
    } catch (e) {
      _log.warning('Error generating book summary: $e');
      state = state.copyWith(
        aiFeatureStatus: {'summary': AiFeatureStatus.error},
      );
    }
  }
  
  /// Get book recommendations based on reading history
  Future<void> getBookRecommendations({String? preferredGenre}) async {
    if (!mounted) return;
    
    state = state.copyWith(
      aiFeatureStatus: {'recommendations': AiFeatureStatus.loading},
    );
    
    try {
      // In a real app, you'd get recent books from a reading history provider
      List<String> recentBooks = [state.bookTitle ?? _bookId];
      
      final recommendations = await _repository.getBookRecommendations(
        recentBooks,
        preferredGenre: preferredGenre ?? '',
      );
      
      state = state.copyWith(
        bookRecommendations: recommendations,
        aiFeatureStatus: {'recommendations': AiFeatureStatus.ready},
      );
      _log.info('Generated ${recommendations.length} book recommendations');
    } catch (e) {
      _log.severe('Error getting book recommendations: $e');
      state = state.copyWith(
        aiFeatureStatus: {'recommendations': AiFeatureStatus.error},
      );
    }
  }
  
  /// Analyze difficult words in the text
  Future<void> analyzeDifficultWords(String text) async {
    if (!mounted) return;
    
    // Update AI feature status
    state = state.copyWith(
      aiFeatureStatus: {'vocabulary': AiFeatureStatus.loading},
    );
    
    try {
      // Limit text length to avoid token limits
      final textToAnalyze = text.length > 3000 ? text.substring(0, 3000) : text;
      
      final Map<String, dynamic> wordsMap = await _repository.explainDifficultWords(textToAnalyze);
      
      // Convert to the format expected by ReadingState
      final List<Map<String, dynamic>> wordsList = wordsMap.entries.map((entry) {
        return {
          'word': entry.key,
          'definition': entry.value,
        };
      }).toList();
      
      if (wordsList.isNotEmpty) {
        state = state.copyWith(
          difficultWords: wordsList,
          aiFeatureStatus: {'vocabulary': AiFeatureStatus.ready},
        );
        _log.info('Analyzed ${wordsList.length} difficult words');
        return;
      }
      
      // If we get here, no words were found
      state = state.copyWith(
        aiFeatureStatus: {'vocabulary': AiFeatureStatus.error},
      );
    } catch (e) {
      _log.warning('Error analyzing difficult words: $e');
      state = state.copyWith(
        aiFeatureStatus: {'vocabulary': AiFeatureStatus.error},
      );
    }
  }

  /// Search within book content using AI
  Future<void> searchWithinContent(String query) async {
    if (!mounted || state.textContent == null || query.trim().isEmpty) return;
    
    state = state.copyWith(
      aiFeatureStatus: {'search': AiFeatureStatus.loading},
      lastSearchQuery: query,
    );
    
    try {
      final results = await _repository.searchWithinContent(
        query,
        state.textContent!,
      );
      
      state = state.copyWith(
        searchResults: results,
        aiFeatureStatus: {'search': AiFeatureStatus.ready},
      );
      _log.info('Found ${results.length} search results for query: $query');
    } catch (e) {
      _log.severe('Error searching within content: $e');
      state = state.copyWith(
        aiFeatureStatus: {'search': AiFeatureStatus.error},
      );
    }
  }
  
  /// Translate selected text using AI
  Future<void> translateText(String text, String targetLanguage) async {
    if (!mounted || text.trim().isEmpty) return;
    
    state = state.copyWith(
      aiFeatureStatus: {'translation': AiFeatureStatus.loading},
    );
    
    try {
      final translated = await _repository.translateText(
        text,
        targetLanguage,
      );
      
      state = state.copyWith(
        currentTranslation: translated,
        aiFeatureStatus: {'translation': AiFeatureStatus.ready},
      );
      _log.info('Translated text to $targetLanguage');
    } catch (e) {
      _log.severe('Error translating text: $e');
      state = state.copyWith(
        aiFeatureStatus: {'translation': AiFeatureStatus.error},
      );
    }
  }
  
  /// Analyze themes and concepts in the text
  Future<void> analyzeThemesAndConcepts() async {
    if (!mounted || state.textContent == null) return;
    
    state = state.copyWith(
      aiFeatureStatus: {'themes': AiFeatureStatus.loading},
    );
    
    try {
      // Limit text to analyze to avoid token limits
      final textToAnalyze = state.textContent!.length > 5000
          ? state.textContent!.substring(0, 5000)
          : state.textContent!;
      
      final analysis = await _repository.analyzeThemesAndConcepts(textToAnalyze);
      
      state = state.copyWith(
        themeAnalysis: analysis,
        aiFeatureStatus: {'themes': AiFeatureStatus.ready},
      );
      _log.info('Analyzed themes and concepts');
    } catch (e) {
      _log.severe('Error analyzing themes and concepts: $e');
      state = state.copyWith(
        aiFeatureStatus: {'themes': AiFeatureStatus.error},
      );
    }
  }
  
  /// Get recommended reading settings based on text content
  Future<void> getRecommendedReadingSettings({String? language}) async {
    if (!mounted) return;
    
    _log.info('Getting recommended reading settings');
    state = state.copyWith(
      aiFeatureStatus: {'settings': AiFeatureStatus.loading},
    );
    
    try {
      String textSample = '';
      
      if (state.textContent != null && state.textContent!.isNotEmpty) {
        // Get sample text
        textSample = state.textContent!.length > 1000
            ? state.textContent!.substring(0, 1000)
            : state.textContent!;
      } else if (state.bookTitle != null) {
        // Use title as fallback
        textSample = state.bookTitle!;
      } else {
        textSample = 'Unknown book';
      }
      
      final settings = await _repository.getRecommendedReadingSettings(
        textSample,
        language: language,
      );
      
      if (settings.isNotEmpty) {
        state = state.copyWith(
          recommendedSettings: settings,
          aiFeatureStatus: {'settings': AiFeatureStatus.ready},
        );
        _log.info('Got recommended reading settings');
        return;
      }
      
      // If we get here, something went wrong
      state = state.copyWith(
        aiFeatureStatus: {'settings': AiFeatureStatus.error},
      );
    } catch (e) {
      _log.warning('Error getting reading settings: $e');
      state = state.copyWith(
        aiFeatureStatus: {'settings': AiFeatureStatus.error},
      );
    }
  }
  
  /// Generate smart bookmarks for the content
  Future<void> suggestBookmarks() async {
    if (!mounted) return;
    
    _log.info('Generating smart bookmarks');
    state = state.copyWith(
      aiFeatureStatus: {'bookmarks': AiFeatureStatus.loading},
    );
    
    try {
      final String contentToAnalyze;
      
      if (state.textContent != null && state.textContent!.isNotEmpty) {
        // Limit to first 10000 characters to avoid token limits
        contentToAnalyze = state.textContent!.length > 10000
            ? state.textContent!.substring(0, 10000)
            : state.textContent!;
      } else {
        // Not enough content for analysis
        state = state.copyWith(
          aiFeatureStatus: {'bookmarks': AiFeatureStatus.error},
        );
        return;
      }
      
      final bookmarks = await _repository.suggestBookmarks(contentToAnalyze);
      
      if (bookmarks.isNotEmpty) {
        state = state.copyWith(
          suggestedBookmarks: bookmarks,
          aiFeatureStatus: {'bookmarks': AiFeatureStatus.ready},
        );
        _log.info('Generated ${bookmarks.length} smart bookmarks');
        return;
      }
      
      // If we get here, something went wrong
      state = state.copyWith(
        aiFeatureStatus: {'bookmarks': AiFeatureStatus.error},
      );
    } catch (e) {
      _log.warning('Error generating bookmarks: $e');
      state = state.copyWith(
        aiFeatureStatus: {'bookmarks': AiFeatureStatus.error},
      );
    }
  }
  
  /// Generate speech markers for text-to-speech
  Future<void> generateSpeechMarkers(String text, {String? voiceStyle, String? language}) async {
    if (!mounted) return;
    
    _log.info('Generating speech markers for TTS');
    
    try {
      final markers = await _repository.generateTtsPrompt(
        text,
        voiceStyle: voiceStyle,
        language: language,
      );
      
      state = state.copyWith(
        speechMarkers: markers,
      );
    } catch (e) {
      _log.warning('Error generating speech markers: $e');
    }
  }
  
  /// Start text-to-speech
  void startSpeaking() {
    if (!mounted) return;
    
    _log.info('Starting text-to-speech');
    state = state.copyWith(
      isSpeaking: true,
    );
  }
  
  /// Stop text-to-speech
  void stopSpeaking() {
    if (!mounted) return;
    
    _log.info('Stopping text-to-speech');
    state = state.copyWith(
      isSpeaking: false,
      highlightedTextPosition: null, // Clear highlighting
    );
  }

  /// Clear an AI feature's data and reset its status
  void clearAiFeature(String feature) {
    if (!mounted) return;
    
    _log.info('Clearing AI feature: $feature');
    
    switch (feature) {
      case 'chapters':
        state = state.copyWith(
          aiExtractedChapters: [],
          aiFeatureStatus: {feature: AiFeatureStatus.initial},
        );
        break;
      case 'vocabulary':
        state = state.copyWith(
          difficultWords: [],
          aiFeatureStatus: {feature: AiFeatureStatus.initial},
        );
        break;
      case 'summary':
        state = state.copyWith(
          bookSummary: null,
          aiFeatureStatus: {feature: AiFeatureStatus.initial},
        );
        break;
      case 'recommendations':
        state = state.copyWith(
          bookRecommendations: [],
          aiFeatureStatus: {feature: AiFeatureStatus.initial},
        );
        break;
      case 'search':
        state = state.copyWith(
          searchResults: [],
          lastSearchQuery: null,
          aiFeatureStatus: {feature: AiFeatureStatus.initial},
        );
        break;
      case 'bookmarks':
        state = state.copyWith(
          suggestedBookmarks: [],
          aiFeatureStatus: {feature: AiFeatureStatus.initial},
        );
        break;
      case 'themes':
        state = state.copyWith(
          themeAnalysis: null,
          aiFeatureStatus: {feature: AiFeatureStatus.initial},
        );
        break;
      case 'settings':
        state = state.copyWith(
          recommendedSettings: null,
          aiFeatureStatus: {feature: AiFeatureStatus.initial},
        );
        break;
    }
  }

  // Update text highlighting for TTS
  void updateHighlightedTextPosition(Map<String, dynamic> position) {
    if (!mounted) return;
    
    state = state.copyWith(
      highlightedTextPosition: position,
    );
  }
  
  // Update bookmarks
  void updateBookmarks(List<Map<String, dynamic>> bookmarks) {
    if (!mounted) return;
    
    _log.info('Updating bookmarks with ${bookmarks.length} entries');
    state = state.copyWith(
      suggestedBookmarks: bookmarks,
      aiFeatureStatus: {'bookmarks': AiFeatureStatus.ready},
    );
    
    // Save updated bookmarks to reading history
    _saveProgress();
  }
}

// Provider for the ReadingNotifier (using family for bookId)
final readingNotifierProvider = 
  StateNotifierProvider.family<ReadingNotifier, ReadingState, String>((ref, bookId) {
    final repository = ref.watch(readingRepositoryProvider);
    return ReadingNotifier(repository, bookId);
}); 