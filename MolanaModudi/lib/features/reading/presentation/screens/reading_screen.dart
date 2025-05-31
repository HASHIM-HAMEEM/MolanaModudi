import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Import for Completer and Timer
import 'package:flutter/services.dart';
// Import AppLocalizations
// Add this import
// Add simple bookmark service
// Add simple bookmark model
// Import the new refactored reading page
import 'reading/reading_page.dart';

// Import widgets as they are created
// Import Library Panel
// Import shared models
// Import GoRouter for navigation extensions
// Import RouteNames for route constants
// Import reading provider and state
// Import AI Tools Panel
import '../../../../core/extensions/string_extensions.dart';
// Import app colors
import 'package:modudi/features/books/data/models/book_models.dart'; // Ensure Heading model is imported

// Enhanced Content Section with better animations and interactions
class _EnhancedContentSection extends ConsumerStatefulWidget {
  final String title;
  final String textContent;
  final String language;
  final ColorScheme colors;
  final TextStyle textStyle;
  final bool isBookmarked;
  final VoidCallback onBookmarkToggle;
  final Heading? heading;
  final String chapterId;
  final String chapterTitle;
  final String bookFirestoreId;

  const _EnhancedContentSection({
    required this.title,
    required this.textContent,
    required this.language,
    required this.colors,
    required this.textStyle,
    required this.isBookmarked,
    required this.onBookmarkToggle,
    required this.heading,
    required this.chapterId,
    required this.chapterTitle,
    required this.bookFirestoreId,
  });

  @override
  ConsumerState<_EnhancedContentSection> createState() => _EnhancedContentSectionState();
}

class _EnhancedContentSectionState extends ConsumerState<_EnhancedContentSection> 
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              // Enhanced title section
              if (widget.title.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: widget.colors.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: widget.colors.outline.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
              child: Row(
                children: [
            Expanded(
                        child: Text(
                          widget.title,
                          style: widget.textStyle.copyWith(
                            fontSize: widget.textStyle.fontSize! + 6,
                            fontWeight: FontWeight.w700,
                            color: widget.colors.onSurface,
                            height: 1.3,
                          ),
                          textAlign: widget.language.isRtl ? TextAlign.right : TextAlign.left,
                        ),
                      ),
                      // Bookmark icon integrated into title section
                      Container(
                        decoration: BoxDecoration(
                          color: widget.isBookmarked 
                            ? widget.colors.primary.withValues(alpha: 0.1)
                            : widget.colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
                        child: IconButton(
                          icon: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Icon(
                              widget.isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                              key: ValueKey(widget.isBookmarked),
                              color: widget.isBookmarked 
                                ? widget.colors.primary 
                                : widget.colors.onSurfaceVariant,
                              size: 22,
                            ),
                          ),
              onPressed: () {
                            HapticFeedback.lightImpact();
                            widget.onBookmarkToggle();
                          },
                          tooltip: widget.isBookmarked ? 'Remove bookmark' : 'Add bookmark',
                    ),
                  ),
                ],
              ),
            ),
                const SizedBox(height: 24),
              ],
              
              // Enhanced content text with better typography
              Container(
                padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                  color: widget.colors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                      color: widget.colors.shadow.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                ),
              ],
            ),
                child: SelectableText(
                  widget.textContent,
                  style: widget.textStyle.copyWith(
                    height: 1.8,
                    letterSpacing: 0.2,
                  ),
                  textAlign: widget.language.isRtl ? TextAlign.right : TextAlign.justify,
                  contextMenuBuilder: (context, editableTextState) {
                    // Disable system context menu to prevent the crash
                    return const SizedBox.shrink();
                  },
                  onSelectionChanged: (selection, cause) {
                    // Handle text selection without system context menu
                    if (selection.isValid && !selection.isCollapsed) {
                      final selectedText = selection.textInside(widget.textContent);
                      if (selectedText.isNotEmpty) {
                        _showCustomTextMenu(context, selectedText);
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show custom text menu for selected text without system context menu
  void _showCustomTextMenu(BuildContext context, String selectedText) {
    final colors = widget.colors;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Selected Text',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: colors.onSurfaceVariant),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Selected text preview
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.outline.withValues(alpha: 0.3)),
              ),
              child: Text(
                selectedText.length > 100 ? '${selectedText.substring(0, 100)}...' : selectedText,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Action buttons
            ListTile(
              leading: Icon(Icons.copy, color: colors.primary),
              title: Text('Copy', style: TextStyle(color: colors.onSurface)),
              onTap: () {
                Clipboard.setData(ClipboardData(text: selectedText));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Text copied to clipboard')),
                );
              },
            ),
            
            ListTile(
              leading: Icon(Icons.share, color: colors.primary),
              title: Text('Share', style: TextStyle(color: colors.onSurface)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Share functionality coming soon')),
                );
              },
            ),
            
            ListTile(
              leading: Icon(Icons.bookmark_add, color: colors.primary),
              title: Text('Bookmark', style: TextStyle(color: colors.onSurface)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Text bookmarked')),
                );
              },
            ),
            
            // Add bottom padding for safe area
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}

/// Backward compatibility wrapper - delegates to the new refactored ReadingPage
/// This maintains existing route compatibility while using the clean architecture
class ReadingScreen extends ReadingPage {
  const ReadingScreen({
    super.key,
    required super.bookId,
  });
}

// Keep the rest of the original ReadingScreen code for backward compatibility
// This allows gradual migration while maintaining existing functionality
