// lib/models/menu_item.dart
import 'package:flutter/material.dart';

class MenuItem {
  final String id;  // This MUST be String, not int
  final String name;
  final String description;
  final double price;
  final String category;
  final int preparationTime;
  final String? imageUrl;
  final bool isAvailable;
  final String availableFrom;
  final String availableTo;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.preparationTime,
    this.imageUrl,
    required this.isAvailable,
    required this.availableFrom,
    required this.availableTo,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    // Safe parsing with null checks and type conversion
    return MenuItem(
      id: json['_id']?.toString() ?? '', // Convert to String safely
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: (json['price'] is num) ? (json['price'] as num).toDouble() : 0.0,
      category: json['category']?.toString() ?? 'snacks',
      preparationTime: json['preparationTime'] is int 
          ? json['preparationTime'] as int 
          : (json['preparationTime'] is num ? (json['preparationTime'] as num).toInt() : 15),
      imageUrl: json['imageUrl']?.toString(),
      isAvailable: json['isAvailable'] ?? true,
      availableFrom: json['availableFrom']?.toString() ?? '00:00',
      availableTo: json['availableTo']?.toString() ?? '23:59',
      createdBy: json['createdBy'] is Map 
          ? (json['createdBy']['_id']?.toString() ?? '')
          : (json['createdBy']?.toString() ?? ''),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  static DateTime _parseDate(dynamic date) {
    if (date == null) return DateTime.now();
    if (date is DateTime) return date;
    if (date is String) {
      try {
        return DateTime.parse(date);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  // Get category display name
  String get categoryDisplay {
    switch (category) {
      case 'breakfast':
        return 'Breakfast';
      case 'lunch':
        return 'Lunch';
      case 'snacks':
        return 'Snacks';
      case 'dinner':
        return 'Dinner';
      case 'beverages':
        return 'Beverages';
      case 'desserts':
        return 'Desserts';
      default:
        return category;
    }
  }

  // Get category icon
  IconData get categoryIcon {
    switch (category) {
      case 'breakfast':
        return Icons.free_breakfast;
      case 'lunch':
        return Icons.lunch_dining;
      case 'snacks':
        return Icons.fastfood;
      case 'dinner':
        return Icons.dinner_dining;
      case 'beverages':
        return Icons.local_cafe;
      case 'desserts':
        return Icons.cake;
      default:
        return Icons.restaurant;
    }
  }

  // Get category color
  Color get categoryColor {
    switch (category) {
      case 'breakfast':
        return const Color(0xFFF59E0B);
      case 'lunch':
        return const Color(0xFF10B981);
      case 'snacks':
        return const Color(0xFFEF4444);
      case 'dinner':
        return const Color(0xFF8B5CF6);
      case 'beverages':
        return const Color(0xFF3B82F6);
      case 'desserts':
        return const Color(0xFFEC4899);
      default:
        return const Color(0xFF6366F1);
    }
  }
}