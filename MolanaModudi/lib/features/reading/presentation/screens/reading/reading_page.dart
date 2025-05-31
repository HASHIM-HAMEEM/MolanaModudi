import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

import '../../../../../routes/route_names.dart';
import '../../providers/reading_provider.dart';
import '../../providers/reading_state.dart';
import '../../providers/unified_reading_progress_provider.dart';
// import '../../services/unified_reading_progress_service.dart'; // Unused
import 'providers/reading_ui_provider.dart';
import 'widgets/reading_scaffold.dart';
import 'widgets/reading_header.dart';
import 'widgets/reading_content.dart';
import 'widgets/reading_controls.dart';
import '../../widgets/reader_settings_bottom_sheet.dart';

/// Main reading page - extracted from monolithic ReadingScreen
class ReadingPage extends ConsumerStatefulWidget {
  final String bookId;

  const ReadingPage({
    super.key,
    required this.bookId,
  });

  @override
  ConsumerState<ReadingPage> createState() => _ReadingPageState();
}

class _ReadingPageState extends ConsumerState<ReadingPage> {
  final _log = Logger('ReadingPage');
  String? _chapterId;
  String? _headingId;
  void Function(String)? _navigateToHeadingCallback;
  
  // Reading session tracking
  bool _sessionStarted = false;

  @override
  void initState() {
    super.initState();
    
    // Process query parameters for chapter and heading navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _processNavigationParameters();
      }
    });
  }

  @override
  void dispose() {
    // End reading session when leaving the page
    _endReadingSession();
    super.dispose();
  }

  /// Start a reading session for the current book
  Future<void> _startReadingSession(ReadingState readingState) async {
    if (_sessionStarted || !mounted) return;
    
    try {
      final service = ref.read(unifiedReadingProgressServiceProvider);
      
      // Get book metadata from reading state
      final book = readingState.book;
      if (book == null) return;
      
      final totalChapters = readingState.totalChapters ?? 
                          readingState.mainChapterKeys?.length ?? 
                          0;
      
      await service.startReadingSession(
        bookId: widget.bookId,
        bookTitle: book.title ?? 'Unknown Book',
        author: book.author,
        coverUrl: book.thumbnailUrl,
        currentChapter: readingState.currentChapter,
        totalChapters: totalChapters,
        initialProgress: readingState.textScrollPosition ?? 0.0,
      );
      
      _sessionStarted = true;
      ref.read(readingSessionActiveProvider.notifier).state = true;
      
      _log.info('Started reading session for: ${book.title}');
      
    } catch (e) {
      _log.warning('Failed to start reading session: $e');
    }
  }

  /// End the current reading session
  Future<void> _endReadingSession() async {
    if (!_sessionStarted) return;
    
    try {
      final service = ref.read(unifiedReadingProgressServiceProvider);
      await service.endReadingSession();
      
      _sessionStarted = false;
      ref.read(readingSessionActiveProvider.notifier).state = false;
      
      _log.info('Ended reading session for book: ${widget.bookId}');
      
    } catch (e) {
      _log.warning('Failed to end reading session: $e');
    }
  }

  /// Update reading progress in the unified service
  Future<void> _updateReadingProgress(ReadingState readingState) async {
    if (!_sessionStarted || !mounted) return;
    
    try {
      final service = ref.read(unifiedReadingProgressServiceProvider);
      
      // Use the current chapter title from the state if available
      final currentChapterTitle = readingState.currentChapterTitle;
      
      // Get the first heading ID if available
      final currentHeadingId = readingState.headings?.isNotEmpty == true 
          ? readingState.headings!.first.firestoreDocId
          : null;
      
      await service.updateProgress(
        scrollProgress: readingState.textScrollPosition ?? 0.0,
        currentChapter: readingState.currentChapter,
        currentChapterTitle: currentChapterTitle,
        currentHeadingId: currentHeadingId,
        ref: ref,
      );
      
    } catch (e) {
      _log.warning('Failed to update reading progress: $e');
    }
  }

  /// Set the callback function for heading navigation
  void _setNavigateToHeadingCallback(void Function(String) callback) {
    _navigateToHeadingCallback = callback;
  }

  /// Wait for content to load and then navigate
  void _waitForContentAndNavigate(String chapterId, String? headingId) async {
    if (!mounted) return;
    
    // Check current state
    final currentState = ref.read(readingNotifierProvider(widget.bookId));
    
    // If already loaded, navigate immediately
    if (currentState.status == ReadingStatus.displayingText && 
        currentState.mainChapterKeys != null) {
      _navigateToSpecificContent(chapterId, headingId);
      return;
    }
    
    // Otherwise, wait with timeout
    int attempts = 0;
    const maxAttempts = 50; // 5 seconds max
    
    while (mounted && attempts < maxAttempts) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
      
      final state = ref.read(readingNotifierProvider(widget.bookId));
      if (state.status == ReadingStatus.displayingText && 
          state.mainChapterKeys != null) {
        _navigateToSpecificContent(chapterId, headingId);
        return;
      }
    }
    
    _log.warning('Timeout waiting for content to load for navigation');
  }

  /// Process navigation parameters from URL query parameters
  void _processNavigationParameters() {
    if (!mounted) return;

    try {
      final routerState = GoRouterState.of(context);
      final uri = routerState.uri;
      
      _chapterId = uri.queryParameters['chapterId'];
      _headingId = uri.queryParameters['headingId'];
      
      _log.info('Processing navigation parameters: chapterId=$_chapterId, headingId=$_headingId');
      
      if (_chapterId != null) {
        // Use a simple timer-based approach instead of ref.listenManual
        _waitForContentAndNavigate(_chapterId!, _headingId);
      }
    } catch (e) {
      _log.severe('Error processing navigation parameters: $e');
    }
  }

  /// Navigate to specific content by chapter ID and heading ID
  void _navigateToSpecificContent(String chapterId, String? headingId) {
    _log.info('Navigating to specific content: chapterId=$chapterId, headingId=$headingId');
    
    try {
      final state = ref.read(readingNotifierProvider(widget.bookId));
      final notifier = ref.read(readingNotifierProvider(widget.bookId).notifier);
      
      if (state.mainChapterKeys == null) {
        _log.warning('mainChapterKeys is null for chapter ID: $chapterId. Cannot perform navigation lookup.');
        return;
      }
      
      _log.info('Ready to navigate to chapter ID: $chapterId. Available chapters: ${state.mainChapterKeys!.length}');
      
      // Find the logical chapter index for the given chapter ID
      int targetIndex = -1;
      
      // First approach - direct match against mainChapterKeys list
      for (int i = 0; i < state.mainChapterKeys!.length; i++) {
        String key = state.mainChapterKeys![i];
        _log.info('Checking chapter key at index $i: $key against target ID: $chapterId');
        if (key == chapterId) {
          targetIndex = i;
          break;
        }
      }
      
      // Second approach - try numeric approach if the ID is numeric
      if (targetIndex == -1) {
        final parsedId = int.tryParse(chapterId);
        if (parsedId != null) {
          // Check if it's 1-based or 0-based indexing
          if (parsedId > 0 && parsedId <= state.mainChapterKeys!.length) {
            targetIndex = parsedId - 1; // Convert to 0-based index
            _log.info('Using numeric chapter ID as 1-based index: $parsedId -> $targetIndex');
          } else if (parsedId >= 0 && parsedId < state.mainChapterKeys!.length) {
            targetIndex = parsedId; // Already 0-based
            _log.info('Using numeric chapter ID as 0-based index: $parsedId');
          }
        }
      }
      
      if (targetIndex >= 0 && targetIndex < state.mainChapterKeys!.length) {
        _log.info('Found valid target index: $targetIndex for chapter ID: $chapterId');
        
        // Navigate to chapter
        notifier.navigateToLogicalChapter(targetIndex);
        
        // Navigate to specific heading within the chapter
        if (headingId != null && _navigateToHeadingCallback != null) {
              _navigateToHeadingCallback!(headingId);
        }
      } else {
        _log.warning('Chapter ID: $chapterId not found in mainChapterKeys or index out of bounds.');
      }
    } catch (e) {
      _log.severe('Error in _navigateToSpecificContent: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    _log.info('Building ReadingPage for bookId: ${widget.bookId}');
    final readingState = ref.watch(readingNotifierProvider(widget.bookId));
    final readingUiState = ref.watch(readingUiProvider);
    final settingsPanelVisible = ref.watch(settingsPanelVisibilityProvider);

    if (readingState.status == ReadingStatus.displayingText && !_sessionStarted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _startReadingSession(readingState);
      });
    }

    ref.listen<ReadingState>(readingNotifierProvider(widget.bookId), (previous, next) {
      if (mounted) {
        if (previous?.textScrollPosition != next.textScrollPosition) {
          _updateReadingProgress(next);
        }
        if (previous?.currentChapter != next.currentChapter) {
          _updateReadingProgress(next);
          }
        }
    });
    
    // Handle loading and error states by showing a simpler scaffold or message
    if (readingState.status == ReadingStatus.loading || 
        readingState.status == ReadingStatus.loadingMetadata ||
        readingState.status == ReadingStatus.loadingContent) {
      return Scaffold(
        appBar: AppBar(title: Text(readingState.bookTitle ?? 'Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    if (readingState.status == ReadingStatus.error) {
      return Scaffold(
        appBar: AppBar(title: Text(readingState.bookTitle ?? 'Error')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Error loading book: ${readingState.errorMessage ?? "Unknown error"}', textAlign: TextAlign.center),
          ),
        ),
      );
    }
    
    // Main content display
    return Stack(
      children: [
        ReadingScaffold(
      bookId: widget.bookId,
          showHeaderFooter: readingUiState.showHeaderFooter,
      onHeaderFooterToggle: () => ref.read(readingUiProvider.notifier).toggleHeaderFooter(),
          onBackPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(RouteNames.home);
            }
          },
      header: ReadingHeader(
        bookId: widget.bookId,
            onBackPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(RouteNames.home);
              }
            },
      ),
      content: ReadingContent(
        bookId: widget.bookId,
        readingState: readingState,
        onNavigateToHeadingCallbackSet: _setNavigateToHeadingCallback,
      ),
      controls: ReadingControls(bookId: widget.bookId),
        ),
        
        // Settings Panel Overlay
        if (settingsPanelVisible)
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                print('[DEBUG] ReadingPage: Scrim tapped, hiding settings panel');
                ref.read(settingsPanelVisibilityProvider.notifier).state = false;
              },
              child: Container(
                color: Colors.black.withValues(alpha: 0.5), // Scrim
              ),
            ),
      ),
        if (settingsPanelVisible)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Material(
              type: MaterialType.transparency,
              child: ReaderSettingsBottomSheet(),
            ),
          ),
      ],
    );
  }
} 