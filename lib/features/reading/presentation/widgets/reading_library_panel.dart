import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/reading_models.dart';

class ReadingLibraryPanel extends ConsumerWidget {
  final Function onClose;
  final List<PlaceholderChapter> chapters;
  final Function(String) onChapterSelected;
  final Function? onRequestAiExtraction;
  final bool isLoadingAiFeatures;

  const ReadingLibraryPanel({
    super.key,
    required this.onClose,
    required this.chapters,
    required this.onChapterSelected,
    this.onRequestAiExtraction,
    this.isLoadingAiFeatures = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Material(
      elevation: 12,
      color: theme.colorScheme.surface,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.75,
        height: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16.0),
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
                  Text(
                    'Chapters',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => onClose(),
                  ),
                ],
              ),
            ),
            
            // AI Chapter Extraction button (if chapters are empty)
            if (chapters.isEmpty && onRequestAiExtraction != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No chapters found',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This book does not have a structured table of contents. Use AI to extract chapters based on content analysis.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: isLoadingAiFeatures ? null : () => onRequestAiExtraction!(),
                      icon: isLoadingAiFeatures 
                          ? const SizedBox(
                              width: 16, 
                              height: 16, 
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.smart_toy_outlined),
                      label: Text(isLoadingAiFeatures ? 'Analyzing...' : 'Extract Chapters with AI'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                      ),
                    ),
                  ],
                ),
              ),
            
            // Chapters list
            Expanded(
              child: chapters.isEmpty && onRequestAiExtraction == null
                  ? Center(
                      child: Text(
                        'No chapters available',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      itemCount: chapters.length,
                      itemBuilder: (context, index) {
                        final chapter = chapters[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.primaryContainer,
                            child: Text(
                              '${chapter.pageStart}',
                              style: TextStyle(
                                color: theme.colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            chapter.title,
                            style: theme.textTheme.titleMedium,
                          ),
                          subtitle: chapter.subtitle != null
                              ? Text(
                                  chapter.subtitle!,
                                  style: theme.textTheme.bodySmall,
                                )
                              : null,
                          onTap: () => onChapterSelected(chapter.id),
                        );
                      },
                    ),
            ),
            
            // AI Analysis button (if chapters exist)
            if (chapters.isNotEmpty && onRequestAiExtraction != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      'Not seeing all chapters?',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: isLoadingAiFeatures ? null : () => onRequestAiExtraction!(),
                            icon: isLoadingAiFeatures
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.refresh, size: 16),
                            label: Text(isLoadingAiFeatures ? 'Analyzing...' : 'Improve with AI'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(36),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
} 