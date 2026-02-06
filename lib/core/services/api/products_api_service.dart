import 'package:orders_mobile/core/api/api_client.dart';
import 'package:orders_mobile/models/products/product_model.dart';

class ProductsApiService {
  final ApiClient _client = ApiClient();

  /// Get all products
  Future<ApiResponse<List<ProductModel>>> getProducts({
    String? categoryId,
    bool? isAvailable,
  }) async {
    return await _client.get(
      '/products',
      queryParameters: {
        if (categoryId != null) 'categoryId': categoryId,
        if (isAvailable != null) 'isAvailable': isAvailable,
      },
      fromJson: (json) => (json as List)
          .map((item) => ProductModel.fromJson(item))
          .toList(),
    );
  }

  /// Get product by ID
  Future<ApiResponse<ProductModel>> getProductById(String id) async {
    return await _client.get(
      '/products/$id',
      fromJson: (json) => ProductModel.fromJson(json),
    );
  }

  /// Search products
  Future<ApiResponse<List<ProductModel>>> searchProducts(String term) async {
    return await _client.get(
      '/products/search',
      queryParameters: {'term': term},
      fromJson: (json) => (json as List)
          .map((item) => ProductModel.fromJson(item))
          .toList(),
    );
  }

  /// Get products by location (Kitchen, Bar)
  Future<ApiResponse<List<ProductModel>>> getProductsByLocation({
    required String location,
    bool? isAvailable,
  }) async {
    return await _client.get(
      '/products/by-location',
      queryParameters: {
        'location': location,
        if (isAvailable != null) 'isAvailable': isAvailable,
      },
      fromJson: (json) => (json as List)
          .map((item) => ProductModel.fromJson(item))
          .toList(),
    );
  }

  /// Create product (Admin only)
  Future<ApiResponse<ProductModel>> createProduct(Map<String, dynamic> data) async {
    return await _client.post(
      '/products',
      data: data,
      fromJson: (json) => ProductModel.fromJson(json),
    );
  }

  /// Update product (Admin only)
  Future<ApiResponse<ProductModel>> updateProduct(
    String id,
    Map<String, dynamic> data,
  ) async {
    return await _client.put(
      '/products/$id',
      data: data,
      fromJson: (json) => ProductModel.fromJson(json),
    );
  }

  /// Toggle product availability (Admin only)
  Future<ApiResponse<Map<String, dynamic>>> toggleAvailability(String id) async {
    return await _client.put(
      '/products/$id/toggle-availability',
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  /// Bulk update availability (Admin only)
  Future<ApiResponse<void>> bulkUpdateAvailability({
    required List<String> productIds,
    required bool isAvailable,
  }) async {
    return await _client.put(
      '/products/bulk-availability',
      data: {
        'productIds': productIds,
        'isAvailable': isAvailable,
      },
    );
  }

  /// Delete product (Admin only)
  Future<ApiResponse<void>> deleteProduct(String id) async {
    return await _client.delete('/products/$id');
  }
}
