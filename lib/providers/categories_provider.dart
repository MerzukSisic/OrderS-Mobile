import 'package:flutter/foundation.dart';
import 'package:orders_mobile/core/services/api/common_api_services.dart';
import 'package:orders_mobile/models/products/category_model.dart';

class CategoriesProvider with ChangeNotifier {
  final CategoriesApiService _apiService = CategoriesApiService();

  // State
  List<CategoryModel> _categories = [];
  CategoryModel? _selectedCategory;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<CategoryModel> get categories => _categories;
  CategoryModel? get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetch all categories
  Future<void> fetchCategories() async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.getCategories();

      if (response.success && response.data != null) {
        _categories = response.data!;
      } else {
        _setError(response.error ?? 'Failed to fetch categories');
      }
    } catch (e) {
      _setError('Error fetching categories: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch category by ID
  Future<void> fetchCategoryById(String id) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.getCategoryById(id);

      if (response.success && response.data != null) {
        _selectedCategory = response.data;
      } else {
        _setError(response.error ?? 'Failed to fetch category');
      }
    } catch (e) {
      _setError('Error fetching category: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch category with products
  Future<Map<String, dynamic>?> fetchCategoryWithProducts(String id) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.getCategoryWithProducts(id);

      if (response.success && response.data != null) {
        return response.data;
      } else {
        _setError(response.error ?? 'Failed to fetch category with products');
        return null;
      }
    } catch (e) {
      _setError('Error fetching category with products: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Create category (Admin only)
  Future<bool> createCategory({
    required String name,
    String? description,
    String? imageUrl,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.createCategory(
        name: name,
        description: description,
        imageUrl: imageUrl,
      );

      if (response.success && response.data != null) {
        await fetchCategories(); // Refresh list
        return true;
      } else {
        _setError(response.error ?? 'Failed to create category');
        return false;
      }
    } catch (e) {
      _setError('Error creating category: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update category (Admin only)
  Future<bool> updateCategory(
    String id, {
    String? name,
    String? description,
    String? imageUrl,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.updateCategory(
        id,
        name: name,
        description: description,
        imageUrl: imageUrl,
      );

      if (response.success) {
        await fetchCategories(); // Refresh list
        return true;
      } else {
        _setError(response.error ?? 'Failed to update category');
        return false;
      }
    } catch (e) {
      _setError('Error updating category: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Delete category (Admin only)
  Future<bool> deleteCategory(String id) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.deleteCategory(id);

      if (response.success) {
        _categories.removeWhere((c) => c.id == id);
        if (_selectedCategory?.id == id) {
          _selectedCategory = null;
        }
        notifyListeners();
        return true;
      } else {
        _setError(response.error ?? 'Failed to delete category');
        return false;
      }
    } catch (e) {
      _setError('Error deleting category: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Set selected category
  void setSelectedCategory(CategoryModel? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  /// Get category by ID (from local state)
  CategoryModel? getCategoryById(String id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  // ========== PRIVATE HELPERS ==========

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    if (error != null) {
      debugPrint('❌ Categories Error: $error');
    }
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}