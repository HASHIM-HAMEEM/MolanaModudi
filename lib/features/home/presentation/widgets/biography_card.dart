import 'package:flutter/material.dart';

class BiographyCard extends StatelessWidget {
  final String title;
  final String summary;
  final VoidCallback? onReadMore;

  const BiographyCard({
    super.key,
    this.title = 'About Maulana Maududi',
    this.summary = "Abul A'la Maududi was an influential Islamic scholar, theologian, and political thinker who founded the Jamaat-e-Islami.",
    this.onReadMore,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: textTheme.titleLarge),
          const SizedBox(height: 8.0),
          Text(summary, style: textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.8))),
          if (onReadMore != null)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: TextButton(
                onPressed: onReadMore,
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Read Full Biography',
                      style: textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right, size: 16, color: theme.colorScheme.primary),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
