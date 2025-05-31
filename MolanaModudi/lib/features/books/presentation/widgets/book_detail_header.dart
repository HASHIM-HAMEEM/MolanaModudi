import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:modudi/core/l10n/app_localizations_wrapper.dart';
import '../../data/models/book_models.dart';

/// Displays the book's main information section below the cover image.
/// This includes description and book details like author, publisher, etc.
class BookDetailHeader extends StatelessWidget {
  final Book book;

  const BookDetailHeader({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor.withAlpha((0.5 * 255).round()),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withAlpha((0.03 * 255).round()),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description section
          _buildDescriptionSection(context, theme, colorScheme),
          
          const SizedBox(height: 24),
          
          // Book details section
          if (_hasBookDetails()) 
            _buildBookDetailsSection(context, theme, colorScheme),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.primary.withAlpha((0.1 * 255).round()),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.description_outlined,
                color: colorScheme.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Text(
              AppLocalizations.of(context)!.bookDetailScreenDescriptionTitle,
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          book.description ?? AppLocalizations.of(context)!.bookDetailScreenNoDescription,
          style: TextStyle(
            fontFamily: 'NotoNastaliqUrdu',
            fontSize: 17,
            height: 1.8,
            color: colorScheme.onSurfaceVariant,
          ),
          textDirection: TextDirection.rtl,
        ),
      ],
    );
  }

  Widget _buildBookDetailsSection(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor.withAlpha((0.5 * 255).round()),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withAlpha((0.03 * 255).round()),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: colorScheme.secondary,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                AppLocalizations.of(context)!.bookDetailScreenBookDetailsTitle,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (book.author != null)
            _buildDetailRow(context, theme, colorScheme,
              AppLocalizations.of(context)!.bookDetailScreenAuthorLabel,
              book.author!),
          if (book.publisher != null)
            _buildDetailRow(context, theme, colorScheme,
              AppLocalizations.of(context)!.bookDetailScreenPublisherLabel,
              book.publisher!),
          if (book.additionalFields['page_count'] != null)
            _buildDetailRow(context, theme, colorScheme,
              AppLocalizations.of(context)!.bookDetailScreenPagesLabel,
              '${book.additionalFields['page_count']}'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, ThemeData theme, ColorScheme colorScheme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    label,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    value,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: colorScheme.onSurface,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            thickness: 0.5,
            color: theme.dividerColor.withAlpha((0.7 * 255).round()),
          ),
        ],
      ),
    );
  }

  bool _hasBookDetails() {
    return book.author != null ||
           book.publisher != null ||
           book.publicationDate != null ||
           book.defaultLanguage != null ||
           book.additionalFields['page_count'] != null;
  }
}
