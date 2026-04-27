import 'package:flutter/foundation.dart';
import 'package:orders_mobile/core/services/api/products_api_service.dart';
import 'package:orders_mobile/models/products/product_model.dart';

class ProductsProvider with ChangeNotifier {
  final ProductsApiService _apiService = ProductsApiService();

  // State
  List<ProductModel> _products = [];
  List<ProductModel> _filteredProducts = [];
  ProductModel? _selectedProduct;
  bool _isLoading = false;
  String? _error;

  // Filters
  String? _selectedCategoryId;
  bool? _availabilityFilter;
  String? _searchQuery;

  // Getters
  List<ProductModel> get products =>
      (_searchQuery != null && _searchQuery!.isNotEmpty) ||
              _selectedCategoryId != null ||
              _availabilityFilter != null
          ? _filteredProducts
          : _products;
  ProductModel? get selectedProduct => _selectedProduct;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get selectedCategoryId => _selectedCategoryId;

  /// Fetch all products
  Future<void> fetchProducts({
    String? categoryId,
    bool? isAvailable,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.getProducts(
        categoryId: categoryId,
        isAvailable: isAvailable,
      );

      if (response.success && response.data != null) {
        _products = response.data!;
        _applyFilters();
      } else {
        _setError(response.error ?? 'Failed to fetch products');
      }
    } catch (e) {
      _setError('Error fetching products: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch product by ID
  Future<void> fetchProductById(String id) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.getProductById(id);

      if (response.success && response.data != null) {
        _selectedProduct = response.data;
      } else {
        _setError(response.error ?? 'Failed to fetch product');
      }
    } catch (e) {
      _setError('Error fetching product: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Create new product (Admin only)
  Future<ProductModel?> createProduct(Map<String, dynamic> productData) async {
    _clearError();

    try {
      final response = await _apiService.createProduct(productData);

      if (response.success && response.data != null) {
        // Add to local state
        _products.add(response.data!);
        _applyFilters();

        debugPrint('✅ Product created: ${response.data!.name}');
        return response.data;
      } else {
        _setError(response.error ?? 'Failed to create product');
        return null;
      }
    } catch (e) {
      _setError('Error creating product: $e');
      return null;
    }
  }

  /// Update product (Admin only)
  Future<ProductModel?> updateProduct(
    String productId,
    Map<String, dynamic> productData,
  ) async {
    _clearError();

    try {
      final response = await _apiService.updateProduct(productId, productData);

      if (response.success && response.data != null) {
        // Update local state
        final index = _products.indexWhere((p) => p.id == productId);
        if (index != -1) {
          _products[index] = response.data!;
          _applyFilters();
        }

        // Update selected product if it's the same
        if (_selectedProduct?.id == productId) {
          _selectedProduct = response.data;
        }

        notifyListeners();
        debugPrint('✅ Product updated: ${response.data!.name}');
        return response.data;
      } else {
        _setError(response.error ?? 'Failed to update product');
        return null;
      }
    } catch (e) {
      _setError('Error updating product: $e');
      return null;
    }
  }

  /// Delete product (Admin only)
  Future<bool> deleteProduct(String productId) async {
    _clearError();

    try {
      final response = await _apiService.deleteProduct(productId);

      if (response.success) {
        // Remove from local state
        _products.removeWhere((p) => p.id == productId);
        _applyFilters();

        // Clear selected product if it was deleted
        if (_selectedProduct?.id == productId) {
          _selectedProduct = null;
        }

        notifyListeners();
        debugPrint('✅ Product deleted: $productId');
        return true;
      } else {
        _setError(response.error ?? 'Failed to delete product');
        return false;
      }
    } catch (e) {
      _setError('Error deleting product: $e');
      return false;
    }
  }

  /// Search products
  Future<void> searchProducts(String query) async {
    _searchQuery = query;

    if (query.isEmpty) {
      _filteredProducts = [];
      notifyListeners();
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.searchProducts(query);

      if (response.success && response.data != null) {
        _filteredProducts = response.data!;
      } else {
        _setError(response.error ?? 'Search failed');
      }
    } catch (e) {
      _setError('Search error: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Get products by location
  Future<void> fetchProductsByLocation({
    required String location,
    bool? isAvailable,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.getProductsByLocation(
        location: location,
        isAvailable: isAvailable,
      );

      if (response.success && response.data != null) {
        _products = response.data!;
        _applyFilters();
      } else {
        _setError(response.error ?? 'Failed to fetch products');
      }
    } catch (e) {
      _setError('Error fetching products: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Toggle product availability
  Future<bool> toggleProductAvailability(String productId) async {
    _clearError();

    try {
      final response = await _apiService.toggleAvailability(productId);

      if (response.success && response.data != null) {
        final newAvailability = response.data!['isAvailable'] as bool;

        // Update local state
        final index = _products.indexWhere((p) => p.id == productId);
        if (index != -1) {
          _products[index] =
              _products[index].copyWith(isAvailable: newAvailability);
          _applyFilters();
        }

        if (_selectedProduct?.id == productId) {
          _selectedProduct =
              _selectedProduct!.copyWith(isAvailable: newAvailability);
        }

        notifyListeners();
        return true;
      } else {
        _setError(response.error ?? 'Failed to toggle availability');
        return false;
      }
    } catch (e) {
      _setError('Toggle error: $e');
      return false;
    }
  }

  /// Set category filter
  void setCategoryFilter(String? categoryId) {
    _selectedCategoryId = categoryId;
    _applyFilters();
  }

  /// Set availability filter
  void setAvailabilityFilter(bool? available) {
    _availabilityFilter = available;
    _applyFilters();
  }

  /// Clear filters
  void clearFilters() {
    _selectedCategoryId = null;
    _availabilityFilter = null;
    _searchQuery = null;
    _filteredProducts = [];
    notifyListeners();
  }

  /// Apply local filters
  void _applyFilters() {
    _filteredProducts = _products.where((product) {
      bool matches = true;

      if (_selectedCategoryId != null) {
        matches = matches && product.categoryId == _selectedCategoryId;
      }

      if (_availabilityFilter != null) {
        matches = matches && product.isAvailable == _availabilityFilter;
      }

      if (_searchQuery != null && _searchQuery!.isNotEmpty) {
        final query = _searchQuery!.toLowerCase();
        matches = matches &&
            (product.name.toLowerCase().contains(query) ||
                (product.description?.toLowerCase().contains(query) ?? false));
      }

      return matches;
    }).toList();

    notifyListeners();
  }

  /// Get product by ID (from local state)
  ProductModel? getProductById(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get products by category (from local state)
  List<ProductModel> getProductsByCategory(String categoryId) {
    return _products.where((p) => p.categoryId == categoryId).toList();
  }

  /// Get available products
  List<ProductModel> get availableProducts {
    return _products.where((p) => p.isAvailable).toList();
  }

  /// Set selected product
  void setSelectedProduct(ProductModel? product) {
    _selectedProduct = product;
    notifyListeners();
  }

  // ========== PRIVATE HELPERS ==========

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    if (error != null) {
      debugPrint('❌ Products Error: $error');
    }
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}
