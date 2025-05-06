import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeline_tile/timeline_tile.dart'; // Use timeline_tile package
import 'package:flutter_markdown/flutter_markdown.dart'; // For rendering description

import '../providers/biography_provider.dart';
import '../providers/biography_state.dart';

class BiographyScreen extends ConsumerWidget {
  const BiographyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(biographyNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Biography of Maulana Maududi'),
        backgroundColor: theme.colorScheme.surface, // Or your preferred color
        elevation: 1,
      ),
      body: _buildBody(context, state, ref),
    );
  }

  Widget _buildBody(BuildContext context, BiographyState state, WidgetRef ref) {
    final theme = Theme.of(context);

    switch (state.status) {
      case BiographyStatus.loading:
      case BiographyStatus.initial:
        return const Center(child: CircularProgressIndicator());

      case BiographyStatus.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                const SizedBox(height: 16),
                Text(
                  'Failed to load biography',
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  state.errorMessage ?? 'An unknown error occurred.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => ref.read(biographyNotifierProvider.notifier).fetchBiography(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        );

      case BiographyStatus.success:
        if (state.events.isEmpty) {
          return Center(
            child: Text(
              'Biography information is currently unavailable.',
              style: theme.textTheme.titleMedium,
            ),
          );
        }

        // Use ListView with TimelineTile for a nice chronological display
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          itemCount: state.events.length,
          itemBuilder: (context, index) {
            final event = state.events[index];
            final isFirst = index == 0;
            final isLast = index == state.events.length - 1;

            return TimelineTile(
              alignment: TimelineAlign.manual,
              lineXY: 0.15, // Position of the line
              isFirst: isFirst,
              isLast: isLast,
              indicatorStyle: IndicatorStyle(
                indicatorXY: 0.2, // Center the indicator vertically
                width: 30,
                height: 30, // Make indicator slightly larger
                padding: const EdgeInsets.all(4),
                indicator: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.primary, // Use primary color
                  ),
                  child: Center(
                    child: Text(
                      (index + 1).toString(), // Event number
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              beforeLineStyle: LineStyle(
                color: theme.colorScheme.primary.withOpacity(0.5),
                thickness: 2,
              ),
              afterLineStyle: LineStyle(
                color: theme.colorScheme.primary.withOpacity(0.5),
                thickness: 2,
              ),
              endChild: Container(
                constraints: const BoxConstraints(
                  minHeight: 100, // Ensure minimum height for content
                ),
                padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.date,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Use MarkdownBody for potentially formatted descriptions from Gemini
                    MarkdownBody(
                      data: event.description,
                      styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                        p: theme.textTheme.bodyMedium?.copyWith(height: 1.4), // Improve line spacing
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
    }
  }
} 