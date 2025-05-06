import 'package:flutter/material.dart';
import '../../domain/entities/category_entity.dart';
import '../../../../core/themes/app_color.dart'; // For colors
import 'category_card.dart';

// Placeholder data model
class _PlaceholderCategory {
  final String id;
  final String name;
  final int count;
  final Color color;

  _PlaceholderCategory(this.id, this.name, this.count, this.color);
}

class CategoryGrid extends StatelessWidget {
  final List<dynamic> categories; // Accept both CategoryEntity and _PlaceholderCategory
  final Function(String categoryId)? onCategoryTap;

  const CategoryGrid({
    super.key,
    required this.categories,
    this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    // Sample data matching the reference
    final sampleCategories = [
      _PlaceholderCategory('1', "Tafsir", 12, Colors.blue.shade100),
      _PlaceholderCategory('2', "Islamic Law", 8, Colors.green.shade100),
      _PlaceholderCategory('3', "Biography", 5, Colors.yellow.shade100),
      _PlaceholderCategory('4', "Political Thought", 7, Colors.purple.shade100),
    ];

    // Use sample data for now
    final displayCategories = categories.isEmpty ? sampleCategories : categories;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Text('Categories', style: textTheme.titleLarge),
        const SizedBox(height: 12.0),

        // Grid View
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(), // Disable grid scrolling
          shrinkWrap: true, // Fit content
          itemCount: displayCategories.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // Two columns
            crossAxisSpacing: 12.0, // Spacing between columns
            mainAxisSpacing: 12.0, // Spacing between rows
            childAspectRatio: 2.8, // Adjust aspect ratio for card height
          ),
          itemBuilder: (context, index) {
            final category = displayCategories[index];
            
            // Handle both CategoryEntity and _PlaceholderCategory
            String id, name;
            int count;
            Color iconBackgroundColor;
            
            if (category is CategoryEntity) {
              id = category.id;
              name = category.name;
              count = category.count;
              iconBackgroundColor = category.displayColor ?? Colors.blue.shade100;
            } else if (category is _PlaceholderCategory) {
              id = category.id;
              name = category.name;
              count = category.count;
              iconBackgroundColor = category.color;
            } else {
              // Fallback
              id = "unknown";
              name = "Unknown Category";
              count = 0;
              iconBackgroundColor = Colors.grey.shade200;
            }
            
            return CategoryCard(
              name: name,
              count: count,
              iconBackgroundColor: iconBackgroundColor,
              onTap: () {
                // TODO: Implement navigation or filtering based on category
                print('Tapped on category: $name');
                if (onCategoryTap != null) {
                  onCategoryTap!(id);
                }
              },
            );
          },
        ),
      ],
    );
  }
} 