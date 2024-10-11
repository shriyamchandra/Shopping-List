// lib/models/grocery_item.dart
import 'package:flutter/material.dart';

import 'category.dart';

enum Priority { high, medium, low }

class GroceryItem {
  final String id;
  final String name;
  final int quantity;
  final Category category;
  final bool isPurchased;
  final Priority priority;
  final String note; // New field for notes

  GroceryItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.category,
    this.isPurchased = false,
    this.priority = Priority.medium,
    this.note = '', // Initialize note with empty string
  });

  GroceryItem copyWith({
    String? id,
    String? name,
    int? quantity,
    Category? category,
    bool? isPurchased,
    Priority? priority,
    String? note, // Allow updating the note
  }) {
    return GroceryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      category: category ?? this.category,
      isPurchased: isPurchased ?? this.isPurchased,
      priority: priority ?? this.priority,
      note: note ?? this.note, // Update note if provided
    );
  }
}
