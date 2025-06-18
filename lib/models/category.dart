import 'package:flutter/material.dart';
import 'package:receipt_scanner_flutter/services/storage_service.dart';
import 'package:receipt_scanner_flutter/theme/app_theme.dart';

class Category {
  final String id;
  final String name;
  final String icon;
  final Color color;
  final bool isCustom;

  Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.isCustom = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color.value,
      'isCustom': isCustom,
    };
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      icon: json['icon'],
      color: Color(json['color']),
      isCustom: json['isCustom'] ?? false,
    );
  }
}

class CategoryService {
  static List<Category> getDefaultCategories() {
    return [
      Category(
        id: 'shopping',
        name: 'Shopping',
        icon: '🛍️',
        color: AppTheme.categoryColors[0], // Orange
      ),
      Category(
        id: 'food',
        name: 'Alimentation',
        icon: '🍽️',
        color: AppTheme.categoryColors[1], // Violet
      ),
      Category(
        id: 'transport',
        name: 'Transport',
        icon: '🚗',
        color: AppTheme.categoryColors[2], // Turquoise
      ),
      Category(
        id: 'entertainment',
        name: 'Loisirs',
        icon: '🎮',
        color: AppTheme.categoryColors[3], // Rose
      ),
      Category(
        id: 'health',
        name: 'Santé',
        icon: '❤️',
        color: AppTheme.categoryColors[4], // Vert
      ),
      Category(
        id: 'home',
        name: 'Maison',
        icon: '🏠',
        color: AppTheme.categoryColors[5], // Bleu
      ),
      Category(
        id: 'other',
        name: 'Autre',
        icon: '📄',
        color: AppTheme.categoryColors[6], // Jaune
      ),
    ];
  }

  static Category getCategoryById(String id) {
    return getDefaultCategories().firstWhere(
      (cat) => cat.id == id,
      orElse: () => getDefaultCategories().firstWhere((cat) => cat.id == 'other'),
    );
  }

  static Future<List<Category>> getAllCategories(StorageService storageService) async {
    final custom = await storageService.getCustomCategories();
    final defaults = getDefaultCategories();
    return [...defaults, ...custom];
  }

  static Category? findCategoryByName(List<Category> categories, String name) {
    for (final cat in categories) {
      if (cat.name.toLowerCase() == name.toLowerCase()) return cat;
    }
    return null;
  }
}