import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart'; // For Color

/// Represents a category for grouping books or other content.
class CategoryEntity extends Equatable {
  final String id;
  final String name;
  final int count; // Number of items in this category
  final Color? displayColor; // Optional color for UI
  final IconData? icon; // Icon to represent the category
  final List<String>? keywords; // Keywords for matching books to categories
  final String? description; // Optional description of the category

  const CategoryEntity({
    required this.id,
    required this.name,
    this.count = 0,
    this.displayColor,
    this.icon,
    this.keywords,
    this.description,
  });

  // Add copyWith method
  CategoryEntity copyWith({
    String? id,
    String? name,
    int? count,
    Color? displayColor,
    IconData? icon,
    List<String>? keywords,
    String? description,
  }) {
    return CategoryEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      count: count ?? this.count,
      displayColor: displayColor ?? this.displayColor,
      icon: icon ?? this.icon,
      keywords: keywords ?? this.keywords,
      description: description ?? this.description,
    );
  }

  @override
  List<Object?> get props => [id, name, count, displayColor, icon, keywords, description];
}
