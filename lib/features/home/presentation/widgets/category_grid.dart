import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart'; // Import go_router for navigation
import '../../domain/entities/category_entity.dart';
import '../../../../core/themes/app_color.dart'; // For colors
import '../../../../routes/route_names.dart'; // Import route names
import 'category_card.dart';

// Predefined categories with icons and colors
class CategoryData {
  static List<Map<String, dynamic>> getPredefinedCategories() {
    return [
      {
        'id': 'tafsir',
        'name': 'Tafsir',
        'description': 'Quranic interpretation and explanation',
        'icon': Icons.menu_book,
        'color': const Color(0xFF3B82F6), // blue-500
        'keywords': ['quran', 'tafsir', 'interpretation', 'exegesis', 'commentary'],
      },
      {
        'id': 'islamic_law_social',
        'name': 'Law & Society',
        'description': 'Islamic law, social and cultural issues',
        'icon': Icons.balance,
        'color': const Color(0xFF10B981), // emerald-500
        'keywords': ['fiqh', 'shariah', 'law', 'legal', 'social', 'cultural', 'society', 'halal', 'haram', 'ruling'],
      },
      {
        'id': 'biography',
        'name': 'Biography',
        'description': 'Life stories and historical accounts',
        'icon': Icons.person,
        'color': const Color(0xFFF59E0B), // amber-500
        'keywords': ['biography', 'seerah', 'life', 'history', 'person'],
      },
      {
        'id': 'political_thought',
        'name': 'Political Thought',
        'description': 'Islamic governance and politics',
        'icon': Icons.account_balance,
        'color': const Color(0xFF8B5CF6), // violet-500
        'keywords': ['politics', 'governance', 'state', 'khilafah', 'government', 'political'],
      },
    ];
  }
  
  static IconData getCategoryIcon(String categoryId) {
    final categories = getPredefinedCategories();
    final category = categories.firstWhere(
      (cat) => cat['id'] == categoryId,
      orElse: () => {'icon': Icons.book_outlined},
    );
    return category['icon'] as IconData;
  }
  
  static Color getCategoryColor(String categoryId) {
    final categories = getPredefinedCategories();
    final category = categories.firstWhere(
      (cat) => cat['id'] == categoryId,
      orElse: () => {'color': const Color(0xFF64748B)}, // slate-500 as default
    );
    return category['color'] as Color;
  }
}

class CategoryGrid extends StatelessWidget {
  final List<CategoryEntity> categories;
  final Function(String categoryId)? onCategoryTap;
  final String title;
  final bool showTitle;

  const CategoryGrid({
    super.key,
    required this.categories,
    this.onCategoryTap,
    this.title = 'Categories',
    this.showTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSepia = theme.scaffoldBackgroundColor == AppColor.backgroundSepia;
    
    final textColor = isDark 
        ? AppColor.textPrimaryDark 
        : isSepia 
            ? AppColor.textPrimarySepia 
            : AppColor.textPrimary;

    // If no categories, create from predefined data
    List<CategoryEntity> displayCategories = categories.isNotEmpty 
        ? categories 
        : CategoryData.getPredefinedCategories().map((data) => 
            CategoryEntity(
              id: data['id'] as String,
              name: data['name'] as String,
              description: data['description'] as String,
              displayColor: data['color'] as Color,
              icon: data['icon'] as IconData,
              keywords: data['keywords'] as List<String>,
              count: 0, // Will be updated when books are categorized
            )
          ).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        if (showTitle) ...[  
          Padding(
            padding: const EdgeInsets.only(left: 4.0, bottom: 16.0),
            child: Text(
              title,
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        ],

        // Grid View - Show only first 4 categories in a 2x2 grid
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(), // Disable grid scrolling
          shrinkWrap: true, // Fit content
          itemCount: displayCategories.length > 4 ? 4 : displayCategories.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // Two columns
            crossAxisSpacing: 16.0, // Spacing between columns
            mainAxisSpacing: 16.0, // Spacing between rows
            childAspectRatio: 2.2, // Adjust aspect ratio for card height
          ),
          itemBuilder: (context, index) {
            final category = displayCategories[index];
            
            // Get icon and color (either from category or from predefined data)
            final IconData icon = category.icon ?? 
                CategoryData.getCategoryIcon(category.id);
                
            final Color color = category.displayColor ?? 
                CategoryData.getCategoryColor(category.id);
            
            // Create a circular background for the icon
            return CategoryCard(
              name: category.name,
              count: category.count,
              iconBackgroundColor: color,
              icon: icon,
              onTap: () {
                if (onCategoryTap != null) {
                  onCategoryTap!(category.id);
                } else {
                  // Navigate to category books screen
                  context.pushNamed(
                    RouteNames.categoryBooks,
                    pathParameters: {'categoryId': category.id},
                  );
                }
              },
            );
          },
        ),
      ],
    );
  }
}