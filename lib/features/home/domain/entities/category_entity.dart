import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart'; // For Color

/// Represents a category for grouping books or other content.
class CategoryEntity extends Equatable {
  final String id;
  final String name;
  final int count; // Number of items in this category
  final Color? displayColor; // Optional color for UI

  const CategoryEntity({
    required this.id,
    required this.name,
    this.count = 0,
    this.displayColor,
  });

  // Add copyWith method
  CategoryEntity copyWith({
    String? id,
    String? name,
    int? count,
    Color? displayColor,
  }) {
    return CategoryEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      count: count ?? this.count,
      displayColor: displayColor ?? this.displayColor,
    );
  }

  @override
  List<Object?> get props => [id, name, count, displayColor];
}
