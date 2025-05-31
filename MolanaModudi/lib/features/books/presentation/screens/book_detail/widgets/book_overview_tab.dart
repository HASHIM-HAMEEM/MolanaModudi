import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modudi/core/extensions/string_extensions.dart'; // Add import for language extensions

import '../../../../data/models/book_models.dart';

/// Book overview tab showing description, metadata, and reading actions
class BookOverviewTab extends ConsumerWidget {
  final Book book;

  const BookOverviewTab({
    super.key,
    required this.book,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Get language code for proper text direction
    final String language = book.languageCode ?? 'en';
    final bool isRTL = language.isRTL;
    final TextDirection textDirection = isRTL ? TextDirection.rtl : TextDirection.ltr;
    final TextAlign textAlign = isRTL ? TextAlign.justify : TextAlign.right;
    
    // Always use Jameel Noori Nastaleeq for Urdu language regardless of settings
    final String fontFamily = language.isUrdu ? 'JameelNooriNastaleeqRegular' : language.preferredFontFamily;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Book Description
          if (book.description != null && book.description!.isNotEmpty) ...[
            _buildSectionTitle('About this Book', theme),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Directionality(
                textDirection: textDirection,
              child: Text(
                book.description!,
                style: theme.textTheme.bodyMedium?.copyWith(
                    height: isRTL ? 2.0 : 1.5, // Increase line height for Urdu
                  color: colorScheme.onSurface,
                    fontFamily: fontFamily,
                    fontSize: isRTL ? 18 : 14, // Larger font for Urdu/Arabic for better readability
                    letterSpacing: isRTL ? 0 : 0.2, // No letter spacing for RTL languages
                    wordSpacing: isRTL ? 3 : 0, // Increased word spacing for Urdu
                ),
                  textAlign: textAlign,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Book Metadata
          _buildSectionTitle('Book Details', theme),
          const SizedBox(height: 8),
          _buildMetadataCard(theme),

          const SizedBox(height: 80), // Bottom padding for floating bottom bar
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurface,
      ),
    );
  }

  Widget _buildMetadataCard(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final language = book.languageCode ?? 'en';
    final bool isRTL = language.isRTL;
    final String fontFamily = language.preferredFontFamily;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          if (book.author != null && book.author!.isNotEmpty)
            _buildMetadataRow('Author', book.author!, Icons.person_outline, colorScheme, isRTL, fontFamily),
          
          if (book.publisher != null && book.publisher!.isNotEmpty)
            _buildMetadataRow('Publisher', book.publisher!, Icons.business_outlined, colorScheme, isRTL, fontFamily),
        ],
      ),
    );
  }

  Widget _buildMetadataRow(String label, String value, IconData icon, ColorScheme colorScheme, bool isRTL, String fontFamily) {
    // Always use Jameel Noori Nastaleeq for Urdu language
    final String actualFontFamily = isRTL ? 'JameelNooriNastaleeqRegular' : fontFamily;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isRTL) Icon(
            icon,
            size: 18,
            color: colorScheme.primary,
          ),
          if (!isRTL) const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Directionality(
                  textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
                  child: Text(
                  value,
                  style: TextStyle(
                      fontSize: isRTL ? 16 : 14,
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                      fontFamily: actualFontFamily,
                      height: isRTL ? 1.8 : 1.5,
                    ),
                    textAlign: isRTL ? TextAlign.justify : TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
          if (isRTL) const SizedBox(width: 12),
          if (isRTL) Icon(
            icon,
            size: 18,
            color: colorScheme.primary,
          ),
        ],
      ),
    );
  }
} 