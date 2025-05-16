import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:modudi/features/books/data/models/book_models.dart';
import 'package:modudi/features/home/domain/entities/category_entity.dart';

/// Service to categorize books based on predefined categories and book titles
class BookCategorizationService {
  static final _log = Logger('BookCategorizationService');

  // Predefined categories with their respective book titles
  static final Map<String, Map<String, dynamic>> _categories = {
    'tafsir': {
      'id': 'tafsir',
      'name': 'Tafsir',
      'description': 'Qur\'anic Commentary',
      'icon': Icons.menu_book,
      'color': const Color(0xFF3B82F6), // blue-500
      'books': [
        'قرآن کی چار بنیادی اصطلاحیں: الٰہ، ربّ، عبادت، دین',
        'تعلیمات',
        'خطبات',
      ],
    },
    'biography': {
      'id': 'biography',
      'name': 'Biography',
      'description': 'Personal Reflections',
      'icon': Icons.person,
      'color': const Color(0xFFF59E0B), // amber-500
      'books': [
        'سرورِ عالم صلی اللہ علیہ وسلم',
        'شہادتِ امام حسین رضی اللہ عنہ',
        'تحریک آزادی ہند اور مسلمان (حصہ اول)',
        'تحریک آزادی ہند اور مسلمان (حصہ دوم)',
        'مسلمانوں کا ماضی و حال اور مستقبل',
      ],
    },
    'political_thought': {
      'id': 'political_thought',
      'name': 'Political Thought',
      'description': 'Islamic State',
      'icon': Icons.account_balance,
      'color': const Color(0xFF8B5CF6), // violet-500
      'books': [
        'اسلامی ریاست',
        'اسلامی دستور کی تدوین',
        'اسلامی ریاست میں ذِمّیوں کے حقوق',
        'اسلامی حکومت کس طرح قائم ہوتی ہے؟',
        'اسلام اور جاہلیت',
        'دعوت اسلامی اور اس کے مطالبات',
        'دعوت اسلامی اور اس کا طریق کار',
        'تحریک اسلامی کی اخلاقی بنیادیں',
        'اسلام اور عدلِ اجتماعی',
        'اسلامک پبلی کیشنز',
        'بغاوت کا ظہور',
        'انسان کے بنیادی حقوق',
        'سلامتی کا راستہ',
      ],
    },
    'islamic_law_social': {
      'id': 'islamic_law_social',
      'name': 'Law & Society',
      'description': 'Islamic Law, Social and Cultural Issues',
      'icon': Icons.balance,
      'color': const Color(0xFF10B981), // emerald-500
      'books': [
        // Islamic Law books
        'اسلامی قانون',
        'معاشیات اسلام',
        'اسلامی نظمِ معیشت کے اُصول اور مقاصد',
        'اسلام اور جدید معاشی نظریات',
        'مسئلہ قربانی',
        'یتیم پوتے کی وراثت کا مسئلہ',
        'مسئلہ تعدد ازواج',
        'سُود',
        'مسئلہ جبرو قدر',
        'مرتد کی سزا',
        'انسان کا معاشی مسئلہ اور اس کا اسلامی حل',
        'اسلامی نظام تعلیم',
        'اسلام کا نظام حیات',
        'اسلامی نظام زندگی اور اس کے بنیادی تصورات',
        // Social & Cultural books
        'خواتین اور دینی مسائل',
        'پردہ',
        'قادیانی مسئلہ اور اس کے مذہبی، سیاسی اور معاشرتی پہلو',
        'جہاد فی سبیل اللہ',
        'اسلام اور ضبط ولادت',
        'بناؤ اور بگاڑ',
        'توحید اور رسالت و زندگی بعد موت کا عقلی ثبوت',
        'دینِ حق',
        'شہادتِ حق',
        'تجدید و احیائے دین',
        'تنقیحات',
        'مرض اور اس کا علاج',
        'سانحۂ مسجد اقصیٰ',
        'مسئلہ قومیت',
      ],
    },
  };

  /// Get all predefined categories
  static List<Map<String, dynamic>> getPredefinedCategories() {
    return _categories.values.toList();
  }

  /// Categorize books based on predefined book titles
  static List<CategoryEntity> categorizeBooks(List<Book> books) {
    _log.info('Categorizing ${books.length} books using predefined categories');
    
    // Create category entities from predefined categories
    final List<CategoryEntity> categoryEntities = _categories.values.map((categoryData) {
      return CategoryEntity(
        id: categoryData['id'] as String,
        name: categoryData['name'] as String,
        description: categoryData['description'] as String,
        displayColor: categoryData['color'] as Color,
        icon: categoryData['icon'] as IconData,
        count: 0, // Will be updated below
      );
    }).toList();
    
    // Count books for each category
    for (final book in books) {
      final String bookTitle = book.title ?? '';
      
      // Check each category for matching book titles
      for (int i = 0; i < categoryEntities.length; i++) {
        final categoryId = categoryEntities[i].id;
        final categoryBooks = _categories[categoryId]?['books'] as List<dynamic>?;
        
        if (categoryBooks != null) {
          // Check if the book title exactly matches or contains any of the category's book titles
          final bool matches = categoryBooks.any((categoryBookTitle) {
            return bookTitle == categoryBookTitle || 
                   bookTitle.contains(categoryBookTitle.toString());
          });
          
          if (matches) {
            // Increment the category count
            categoryEntities[i] = categoryEntities[i].copyWith(
              count: categoryEntities[i].count + 1,
            );
            break; // Book is categorized, move to next book
          }
        }
      }
    }
    
    // Ensure all categories have at least a minimum count for display
    final List<CategoryEntity> finalCategories = categoryEntities.map((category) {
      return category.count > 0 ? category : category.copyWith(count: 1);
    }).toList();
    
    // Sort categories by count (descending)
    finalCategories.sort((a, b) => b.count.compareTo(a.count));
    
    _log.info('Categorization complete. Categories: ${finalCategories.map((c) => "${c.name}: ${c.count}").join(', ')}');
    return finalCategories;
  }
  
  /// Get the category for a specific book
  static String? getCategoryForBook(Book book) {
    final String bookTitle = book.title ?? '';
    
    for (final categoryEntry in _categories.entries) {
      final categoryId = categoryEntry.key;
      final categoryData = categoryEntry.value;
      final categoryBooks = categoryData['books'] as List<dynamic>?;
      
      if (categoryBooks != null) {
        // Check if the book title exactly matches or contains any of the category's book titles
        final bool matches = categoryBooks.any((categoryBookTitle) {
          return bookTitle == categoryBookTitle || 
                 bookTitle.contains(categoryBookTitle.toString());
        });
        
        if (matches) {
          return categoryId;
        }
      }
    }
    
    // For backward compatibility: check if the book title contains keywords related to Islamic Law or Social issues
    final String bookTitleLower = book.title?.toLowerCase() ?? '';
    final bool isLawRelated = bookTitleLower.contains('قانون') || 
                            bookTitleLower.contains('شریعت') || 
                            bookTitleLower.contains('فقہ');
    final bool isSocialRelated = bookTitleLower.contains('معاشرت') || 
                               bookTitleLower.contains('ثقافت') || 
                               bookTitleLower.contains('سماجی');
    
    if (isLawRelated || isSocialRelated) {
      return 'islamic_law_social';
    }
    
    return null; // Book doesn't match any category
  }
}
