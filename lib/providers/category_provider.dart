import 'package:flutter/material.dart';
import 'package:receipt_scanner_flutter/models/category.dart';
import 'package:receipt_scanner_flutter/services/storage_service.dart';

class CategoryProvider extends ChangeNotifier {
  final StorageService _storageService = StorageService();
  List<Category> _categories = [];

  List<Category> get categories => _categories;

  Future<void> loadCategories() async {
    _categories = await CategoryService.getAllCategories(_storageService);
    notifyListeners();
  }

  Future<void> addCategory(Category category) async {
    await _storageService.addCustomCategory(category);
    await loadCategories();
  }

  Future<void> deleteCategory(String id) async {
    await _storageService.deleteCustomCategory(id);
    await loadCategories();
  }
} 