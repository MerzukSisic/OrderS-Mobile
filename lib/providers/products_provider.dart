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
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/Products');

      if (response is List) {
        _products = response.map((e) => ProductModel.fromJson(e)).toList();
      } else if (response is Map && response['data'] is List) {
        final data = response['data'] as List;
        _products = data.map((e) => ProductModel.fromJson(e)).toList();
      } else {
        _products = [];
        _error = 'Unexpected response format for products.';
      }
    } catch (e) {
      _products = [];
      _error = e.toString();
    } finally {
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

  // ========== ADMIN CRUD OPERATIONS ==========

  // Create Product
  Future<ProductModel> createProduct(Map<String, dynamic> productData) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _apiService.post('/Products', body: productData);
      
      final newProduct = ProductModel.fromJson(response);
      _products.add(newProduct);
      
      notifyListeners();
      return newProduct;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update Product
  Future<void> updateProduct(String productId, Map<String, dynamic> productData) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _apiService.put('/Products/$productId', body: productData);
      
      // Refresh products to get updated data
      await fetchProducts();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete Product
  Future<void> deleteProduct(String productId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _apiService.delete('/Products/$productId');
      
      // Remove from local list
      _products.removeWhere((product) => product.id == productId);
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get Product Details by ID (from API)
  Future<ProductModel> getProductDetails(String productId) async {
    try {
      final response = await _apiService.get('/Products/$productId');
      return ProductModel.fromJson(response);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}