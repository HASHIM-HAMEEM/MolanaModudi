import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/themes/app_color.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:modudi/features/settings/presentation/providers/settings_provider.dart';
import 'package:modudi/core/utils/localization_helper.dart';
import 'package:modudi/core/themes/font_utils.dart';

/// Screen for the main 'Reading' tab.
/// Shows currently reading books and reading history.
class ReadingTabScreen extends ConsumerStatefulWidget {
  const ReadingTabScreen({super.key});

  @override
  ConsumerState<ReadingTabScreen> createState() => _ReadingTabScreenState();
}

class _ReadingTabScreenState extends ConsumerState<ReadingTabScreen> with SingleTickerProviderStateMixin {
  final _log = Logger('ReadingTabScreen');
  List<RecentBook> _recentBooks = [];
  bool _isLoading = true;
  late AnimationController _animationController;
  final ScrollController _scrollController = ScrollController();
  Timer? _refreshTimer;
  
  // Helper method to scale font sizes based on settings - using the global utility
  double _scaleFontSize(double baseSize) {
    return FontUtils.getScaledFontSize(baseSize, ref);
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _loadRecentBooks();
    
    // Periodically refresh reading data (every 5 minutes)
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _loadRecentBooks();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadRecentBooks() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final recentBooksJson = prefs.getStringList('recentBooks') ?? [];
      
      final List<RecentBook> books = [];
      for (final bookJson in recentBooksJson) {
        try {
          final Map<String, dynamic> bookData = json.decode(bookJson);
          books.add(RecentBook.fromJson(bookData));
        } catch (e) {
          _log.warning('Failed to parse recent book: $e');
        }
      }
      
      // Sort by last read time (most recent first)
      books.sort((a, b) => b.lastReadTime.compareTo(a.lastReadTime));
      
      if (mounted) {
        setState(() {
          _recentBooks = books;
          _isLoading = false;
        });
        
        // Start entrance animation
        _animationController.forward(from: 0.0);
      }
    } catch (e) {
      _log.severe('Error loading recent books: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the settings state for changes
    ref.watch(settingsProvider);
    
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSepia = theme.scaffoldBackgroundColor == AppColor.backgroundSepia;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.l10n.appTitle,
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w600,
            fontSize: _scaleFontSize(22),
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDark 
            ? AppColor.backgroundDark 
            : isSepia 
                ? AppColor.backgroundSepia 
                : AppColor.background,
        foregroundColor: isDark 
            ? AppColor.textPrimaryDark 
            : isSepia 
                ? AppColor.textPrimarySepia 
                : AppColor.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              HapticFeedback.lightImpact();
              _loadRecentBooks();
            },
            tooltip: 'Refresh reading list',
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _recentBooks.isEmpty
                ? _buildEmptyState()
                : _buildBooksList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSepia = theme.scaffoldBackgroundColor == AppColor.backgroundSepia;
    
    final primaryColor = isDark 
        ? AppColor.primaryDark 
        : isSepia 
            ? AppColor.primarySepia 
            : AppColor.primary;
    
    final textColor = isDark 
        ? AppColor.textPrimaryDark 
        : isSepia 
            ? AppColor.textPrimarySepia 
            : AppColor.textPrimary;
    
    return FadeTransition(
      opacity: _animationController,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeOutCubic,
        )),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.auto_stories,
                    size: 56,
                    color: primaryColor.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Your reading journey awaits',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Books you read will appear here, allowing you to easily continue your reading journey',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: textColor.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    context.go('/library');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.library_books),
                  label: const Text('Explore Library'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBooksList() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSepia = theme.scaffoldBackgroundColor == AppColor.backgroundSepia;
    
    final textColor = isDark 
        ? AppColor.textPrimaryDark 
        : isSepia 
            ? AppColor.textPrimarySepia 
            : AppColor.textPrimary;
    
    return FadeTransition(
      opacity: _animationController,
      child: ListView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // Continue Reading Section
          if (_recentBooks.isNotEmpty) ...[            
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 16),
              child: Text(
                'Continue Reading',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
            _buildContinueReadingCard(_recentBooks.first),
            const SizedBox(height: 32),
          ],
          
          // Reading History Section
          if (_recentBooks.length > 1) ...[            
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 16),
              child: Text(
                'Reading History',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
            ...List<RecentBook>.from(_recentBooks.skip(1)).asMap().entries.map((entry) {
              final index = entry.key;
              final book = entry.value;
              return AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  final delay = index * 0.1;
                  final slideAnimation = Tween<Offset>(
                    begin: const Offset(0, 0.2),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: _animationController,
                      curve: Interval(
                        delay.clamp(0.0, 0.9),
                        (delay + 0.6).clamp(0.0, 1.0),
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                  );
                  return FadeTransition(
                    opacity: Tween<double>(
                      begin: 0.0,
                      end: 1.0,
                    ).animate(
                      CurvedAnimation(
                        parent: _animationController,
                        curve: Interval(
                          delay.clamp(0.0, 0.9),
                          (delay + 0.6).clamp(0.0, 1.0),
                          curve: Curves.easeOut,
                        ),
                      ),
                    ),
                    child: SlideTransition(
                      position: slideAnimation,
                      child: child,
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildHistoryItem(book),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildContinueReadingCard(RecentBook book) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSepia = theme.scaffoldBackgroundColor == AppColor.backgroundSepia;
    
    final cardBackgroundColor = isDark 
        ? AppColor.surfaceDark 
        : isSepia 
            ? AppColor.surfaceSepia 
            : AppColor.surface;
    
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
    
    final accentColor = isDark 
        ? AppColor.accentDark 
        : isSepia 
            ? AppColor.accentSepia 
            : AppColor.accent;
    
    final progressBackgroundColor = isDark 
        ? AppColor.progressBackgroundDark 
        : isSepia 
            ? AppColor.primarySepia.withOpacity(0.1) 
            : AppColor.progressBackground;
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.1),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
          )),
          child: child,
        );
      },
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          context.go('/read/${book.id}');
        },
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            color: cardBackgroundColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.2)
                    : isSepia
                        ? AppColor.primarySepia.withOpacity(0.1)
                        : theme.colorScheme.shadow.withOpacity(0.1),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Book cover
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
                child: CachedNetworkImage(
                  imageUrl: book.coverUrl ?? '',
                  height: 200,
                  width: 120,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 200,
                    width: 120,
                    color: accentColor.withOpacity(0.1),
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 200,
                    width: 120,
                    color: accentColor.withOpacity(0.1),
                    child: Icon(Icons.book, size: 40, color: accentColor),
                  ),
                ),
              ),
              
              // Book details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        book.title,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 4),
                      
                      Text(
                        book.author ?? 'Unknown Author',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: secondaryTextColor,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const Spacer(),
                      
                      // Progress bar and details
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Progress',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: secondaryTextColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '${(book.progress * 100).toInt()}%',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: accentColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 4),
                          
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: book.progress,
                              backgroundColor: progressBackgroundColor,
                              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                              minHeight: 6,
                            ),
                          ),
                          
                          const SizedBox(height: 10),
                          
                          // Continue reading button
                          ElevatedButton.icon(
                            onPressed: () {
                              HapticFeedback.mediumImpact();
                              context.go('/read/${book.id}');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: const Icon(Icons.play_arrow, size: 18),
                            label: const Text('Continue Reading'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryItem(RecentBook book) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSepia = theme.scaffoldBackgroundColor == AppColor.backgroundSepia;
    
    final cardBackgroundColor = isDark 
        ? AppColor.surfaceDark 
        : isSepia 
            ? AppColor.surfaceSepia 
            : AppColor.surface;
    
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
    
    final accentColor = isDark 
        ? AppColor.accentDark 
        : isSepia 
            ? AppColor.accentSepia 
            : AppColor.accent;
    
    // Format time ago string
    final lastReadDate = DateTime.fromMillisecondsSinceEpoch(book.lastReadTime);
    final now = DateTime.now();
    final difference = now.difference(lastReadDate);
    
    String timeAgo;
    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      timeAgo = '$years ${years == 1 ? 'year' : 'years'} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      timeAgo = '$months ${months == 1 ? 'month' : 'months'} ago';
    } else if (difference.inDays > 0) {
      timeAgo = '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      timeAgo = '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      timeAgo = '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      timeAgo = 'Just now';
    }

    return Container(
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.15)
                : isSepia
                    ? AppColor.primarySepia.withOpacity(0.08)
                    : theme.colorScheme.shadow.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          context.go('/read/${book.id}');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Book cover
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: book.coverUrl ?? '',
                  height: 65,
                  width: 45,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 65,
                    width: 45,
                    color: accentColor.withOpacity(0.1),
                    child: const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 65,
                    width: 45,
                    color: accentColor.withOpacity(0.1),
                    child: Icon(Icons.book, size: 24, color: accentColor),
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Book details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      book.title,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: _scaleFontSize(16),
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    Text(
                      book.author ?? 'Unknown Author',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: secondaryTextColor,
                        fontSize: _scaleFontSize(12),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: secondaryTextColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          timeAgo,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: secondaryTextColor,
                            fontSize: _scaleFontSize(12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Progress indicator
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${(book.progress * 100).toInt()}%',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.w600,
                      fontSize: _scaleFontSize(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RecentBook {
  final String id;
  final String title;
  final String? author;
  final String? coverUrl;
  final double progress;
  final int lastReadTime;
  final int? currentPage;
  final int? totalPages;

  RecentBook({
    required this.id,
    required this.title,
    this.author,
    this.coverUrl,
    required this.progress,
    required this.lastReadTime,
    this.currentPage,
    this.totalPages,
  });

  factory RecentBook.fromJson(Map<String, dynamic> json) {
    return RecentBook(
      id: json['id'] as String,
      title: json['title'] as String,
      author: json['author'] as String?,
      coverUrl: json['coverUrl'] as String?,
      progress: (json['progress'] as num).toDouble(),
      lastReadTime: json['lastReadTime'] as int,
      currentPage: json['currentPage'] as int?,
      totalPages: json['totalPages'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'coverUrl': coverUrl,
      'progress': progress,
      'lastReadTime': lastReadTime,
      'currentPage': currentPage,
      'totalPages': totalPages,
    };
  }
} 