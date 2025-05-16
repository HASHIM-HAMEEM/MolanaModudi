import '../../domain/entities/category_entity.dart';
import 'package:flutter/material.dart'; // For Color

/// Model implementation of CategoryEntity
class CategoryModel extends CategoryEntity {
  const CategoryModel({
    required super.id,
    required String title,
    super.count,
    super.displayColor,
    super.icon,
    super.keywords,
    super.description,
  }) : super(
          name: title,
        );
  
  // Factory constructor to create from JSON
  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    // Parse icon data if available
    IconData? iconData;
    if (json['iconCodePoint'] != null) {
      iconData = IconData(
        json['iconCodePoint'] as int,
        fontFamily: json['iconFontFamily'] as String?,
        fontPackage: json['iconFontPackage'] as String?,
      );
    }
    
    return CategoryModel(
      id: json['id'] as String,
      title: json['title'] as String,
      count: json['count'] as int? ?? 0,
      // Color can be parsed from hex string if provided
      displayColor: json['color'] != null ? Color(int.parse(json['color'] as String, radix: 16)) : null,
      icon: iconData,
      keywords: json['keywords'] != null ? List<String>.from(json['keywords'] as List) : null,
      description: json['description'] as String?,
    );
  }
  
  // Convert to JSON representation
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': name,
      'count': count,
      'color': displayColor?.value.toRadixString(16),
      'iconCodePoint': icon?.codePoint,
      'iconFontFamily': icon?.fontFamily,
      'iconFontPackage': icon?.fontPackage,
      'keywords': keywords,
      'description': description,
    };
  }
}
