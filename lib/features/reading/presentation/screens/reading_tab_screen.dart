import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Screen for the main 'Reading' tab.
/// Shows currently reading books and reading history.
class ReadingTabScreen extends ConsumerStatefulWidget {
  const ReadingTabScreen({super.key});

  @override
  ConsumerState<ReadingTabScreen> createState() => _ReadingTabScreenState();
}

class _ReadingTabScreenState extends ConsumerState<ReadingTabScreen> {
  final _log = Logger('ReadingTabScreen');
  List<RecentBook> _recentBooks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecentBooks();
  }

  Future<void> _loadRecentBooks() async {
    setState(() {
      _isLoading = true;
    });

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
      
      setState(() {
        _recentBooks = books;
        _isLoading = false;
      });
    } catch (e) {
      _log.severe('Error loading recent books: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reading'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _recentBooks.isEmpty
              ? _buildEmptyState()
              : _buildBooksList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.menu_book,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Your reading list is empty',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Books you read will appear here',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              context.go('/library');
            },
            icon: const Icon(Icons.library_books),
            label: const Text('Browse Library'),
          ),
        ],
      ),
    );
  }

  Widget _buildBooksList() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Continue Reading',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        if (_recentBooks.isNotEmpty)
          _buildContinueReadingCard(_recentBooks.first),
        
        const SizedBox(height: 24),
        
        Text(
          'Reading History',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        
        ..._recentBooks.skip(1).map((book) => _buildHistoryItem(book)).toList(),
      ],
    );
  }

  Widget _buildContinueReadingCard(RecentBook book) {
    return GestureDetector(
      onTap: () {
        context.go('/read/${book.id}');
      },
      child: Card(
        elevation: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book cover and details
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Book cover
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                  child: book.coverUrl != null
                      ? Image.network(
                          book.coverUrl!,
                          height: 120,
                          width: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 120,
                            width: 80,
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                            child: const Icon(Icons.book, size: 40),
                          ),
                        )
                      : Container(
                          height: 120,
                          width: 80,
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                          child: const Icon(Icons.book, size: 40),
                        ),
                ),
                
                // Book details
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book.title,
                          style: Theme.of(context).textTheme.titleMedium!.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        const SizedBox(height: 4),
                        
                        Text(
                          book.author ?? 'Unknown Author',
                          style: Theme.of(context).textTheme.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        const SizedBox(height: 8),
                        
                        LinearProgressIndicator(
                          value: book.progress,
                          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        ),
                        
                        const SizedBox(height: 4),
                        
                        Text(
                          'Progress: ${(book.progress * 100).toInt()}%',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            // Continue reading button
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      context.go('/read/${book.id}');
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Continue Reading'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(RecentBook book) {
    final lastReadDate = DateTime.fromMillisecondsSinceEpoch(book.lastReadTime);
    final now = DateTime.now();
    final difference = now.difference(lastReadDate);
    
    String timeAgo;
    if (difference.inDays > 365) {
      timeAgo = '${(difference.inDays / 365).floor()} year(s) ago';
    } else if (difference.inDays > 30) {
      timeAgo = '${(difference.inDays / 30).floor()} month(s) ago';
    } else if (difference.inDays > 0) {
      timeAgo = '${difference.inDays} day(s) ago';
    } else if (difference.inHours > 0) {
      timeAgo = '${difference.inHours} hour(s) ago';
    } else if (difference.inMinutes > 0) {
      timeAgo = '${difference.inMinutes} minute(s) ago';
    } else {
      timeAgo = 'Just now';
    }

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: book.coverUrl != null
            ? Image.network(
                book.coverUrl!,
                height: 56,
                width: 40,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 56,
                  width: 40,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  child: const Icon(Icons.book, size: 24),
                ),
              )
            : Container(
                height: 56,
                width: 40,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                child: const Icon(Icons.book, size: 24),
              ),
        title: Text(
          book.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          'Last read: $timeAgo',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: Text(
          '${(book.progress * 100).toInt()}%',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        onTap: () {
          context.go('/read/${book.id}');
        },
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