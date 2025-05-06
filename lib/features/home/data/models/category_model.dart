import '../../domain/entities/category_entity.dart';
import 'package:flutter/material.dart'; // For Color

/// Model implementation of CategoryEntity
class CategoryModel extends CategoryEntity {
  const CategoryModel({
    required String id,
    required String title,
    int count = 0,
    Color? displayColor,
  }) : super(
          id: id,
          name: title,
          count: count,
          displayColor: displayColor,
        );
  
  // Factory constructor to create from JSON
  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      title: json['title'] as String,
      count: json['count'] as int? ?? 0,
      // Color can be parsed from hex string if provided
      displayColor: json['color'] != null ? Color(int.parse(json['color'] as String)) : null,
    );
  }
  
  // Convert to JSON representation
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': name,
      'count': count,
      'color': displayColor?.value.toRadixString(16),
    };
  }
}
