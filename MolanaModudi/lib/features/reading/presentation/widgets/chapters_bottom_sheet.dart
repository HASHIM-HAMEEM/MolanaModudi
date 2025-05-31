import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/reading_provider.dart';
import 'package:modudi/features/books/data/models/book_models.dart';

class ChaptersBottomSheet extends ConsumerWidget {
  final String bookId;
  const ChaptersBottomSheet({super.key, required this.bookId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(readingNotifierProvider(bookId).notifier);
    final state = ref.watch(readingNotifierProvider(bookId));
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    // Build chapter list from headings
    final headings = state.headings ?? [];
    final chapterKeys = state.mainChapterKeys ?? [];
    List<String> chapters = [];
    
    for (var i = 0; i < chapterKeys.length; i++) {
      final key = chapterKeys[i];
      final Heading firstHeading = headings.firstWhere(
        (h) => ((h.chapterId?.toString() ?? h.volumeId?.toString() ?? '') == key),
        orElse: () => Heading(firestoreDocId: 'temp', sequence: 0),
      );
      final title = firstHeading.title ?? 'Chapter ${i + 1}';
      chapters.add(title);
    }
    
    if (chapters.isEmpty) {
      chapters = List.generate(state.totalChapters ?? 0, (index) => 'Chapter ${index + 1}');
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
        child: Column(
          children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: colors.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                Icon(Icons.list_rounded, color: colors.primary, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Chapters (${chapters.length})',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close_rounded, color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          
          if (chapters.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.menu_book_outlined,
                      size: 64,
                      color: colors.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No chapters found',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This book is presented as a single reading',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: colors.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: chapters.length,
                itemBuilder: (context, index) {
                  final chapterTitle = chapters[index];
                  final isCurrentChapter = index == state.currentChapter;
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isCurrentChapter 
                        ? colors.primary.withValues(alpha: 0.1)
                        : colors.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: isCurrentChapter
                        ? Border.all(color: colors.primary.withValues(alpha: 0.3))
                        : null,
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isCurrentChapter ? colors.primary : colors.outline.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isCurrentChapter ? colors.onPrimary : colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        chapterTitle,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: isCurrentChapter ? FontWeight.w600 : FontWeight.w500,
                          color: isCurrentChapter ? colors.primary : colors.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: isCurrentChapter 
                        ? Icon(Icons.play_circle_filled_rounded, color: colors.primary, size: 20)
                        : Icon(Icons.arrow_forward_ios_rounded, color: colors.onSurfaceVariant, size: 16),
                    onTap: () {
                        HapticFeedback.lightImpact();
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          notifier.goToChapter(state.mainChapterKeys![index]);
                        });
                        Navigator.of(context).pop();
                    },
                    ),
                  );
                },
              ),
            ),
          ],
      ),
    );
  }
}
