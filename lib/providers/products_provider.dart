import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';
import '../core/services/api_service.dart';
import '../core/constants/api_constants.dart';

class ProductsProvider with ChangeNotifier {
  final ApiService _apiService;

  ProductsProvider(this._apiService);

  List<ProductModel> _products = [];
  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  String? _error;
  String? _selectedCategoryId;
  String _searchQuery = '';

  List<ProductModel> get products {
    var filtered = _products;

    // Filter by category
    if (_selectedCategoryId != null) {
      filtered =
          filtered.where((p) => p.categoryId == _selectedCategoryId).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((p) =>
              p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (p.description
                      ?.toLowerCase()
                      .contains(_searchQuery.toLowerCase()) ??
                  false))
          .toList();
    }

    return filtered;
  }

  List<CategoryModel> get categories => List.unmodifiable(_categories);
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get selectedCategoryId => _selectedCategoryId;
  String get searchQuery => _searchQuery;

  // Fetch Products
  Future<void> fetchProducts() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _apiService.get(ApiConstants.products);
      if (response is List) {
        _products =
            response.map((json) => ProductModel.fromJson(json)).toList();
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch Categories
  Future<void> fetchCategories() async {
    try {
      final response = await _apiService.get(ApiConstants.categories);
      if (response is List) {
        _categories =
            response.map((json) => CategoryModel.fromJson(json)).toList();
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Set Selected Category
  void setSelectedCategory(String? categoryId) {
    _selectedCategoryId = categoryId;
    notifyListeners();
  }

  // Set Search Query
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // Clear Filters
  void clearFilters() {
    _selectedCategoryId = null;
    _searchQuery = '';
    notifyListeners();
  }

  // Get Product by ID
  ProductModel? getProductById(String id) {
    try {
      return _products.firstWhere((product) => product.id == id);
    } catch (e) {
      return null;
    }
  }

  // Refresh
  Future<void> refresh() async {
    await Future.wait([
      fetchProducts(),
      fetchCategories(),
    ]);
  }
}
