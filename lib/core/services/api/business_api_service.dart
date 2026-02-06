import 'package:orders_mobile/core/api/api_client.dart';
import 'package:orders_mobile/models/inventory/store_model.dart';
import 'package:orders_mobile/models/statistics/dashboard_stats.dart';
import 'package:orders_mobile/models/statistics/daily_statistics.dart';
import 'package:orders_mobile/models/statistics/category_sales.dart';
import 'package:orders_mobile/models/statistics/product_sales.dart';
import 'package:orders_mobile/models/statistics/peak_hour.dart';
import 'package:orders_mobile/models/statistics/revenue_chart.dart';
import 'package:orders_mobile/models/inventory/inventory_log_model.dart';
import 'package:orders_mobile/models/inventory/store_product_model.dart';
import 'package:orders_mobile/models/inventory/consumption_forecast_model.dart';


// ==================== STATISTICS API SERVICE ====================

class StatisticsApiService {
  final ApiClient _client = ApiClient();

  /// Get dashboard statistics
  Future<ApiResponse<DashboardStats>> getDashboardStats() async {
    return await _client.get(
      '/statistics/dashboard',
      fromJson: (json) => DashboardStats.fromJson(json),
    );
  }

  /// Get daily statistics
  Future<ApiResponse<DailyStatistics>> getDailyStats(DateTime date) async {
    return await _client.get(
      '/statistics/daily',
      queryParameters: {'date': date.toIso8601String()},
      fromJson: (json) => DailyStatistics.fromJson(json),
    );
  }

  /// Get waiter performance
  Future<ApiResponse<List<Map<String, dynamic>>>> getWaiterPerformance({
    int days = 30,
  }) async {
    return await _client.get(
      '/statistics/waiter-performance',
      queryParameters: {'days': days},
      fromJson: (json) => (json as List).cast<Map<String, dynamic>>(),
    );
  }

  /// Get revenue chart
  Future<ApiResponse<RevenueChart>> getRevenueChart({
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    return await _client.get(
      '/statistics/revenue-chart',
      queryParameters: {
        'fromDate': fromDate.toIso8601String(),
        'toDate': toDate.toIso8601String(),
      },
      fromJson: (json) => RevenueChart.fromJson(json),
    );
  }

  /// Get top selling products
  Future<ApiResponse<List<ProductSales>>> getTopSellingProducts({
    int count = 10,
    int days = 30,
  }) async {
    return await _client.get(
      '/statistics/top-selling',
      queryParameters: {
        'count': count,
        'days': days,
      },
      fromJson: (json) => (json as List)
          .map((item) => ProductSales.fromJson(item))
          .toList(),
    );
  }

  /// Get peak hours
  Future<ApiResponse<List<PeakHour>>> getPeakHours({int days = 7}) async {
    return await _client.get(
      '/statistics/peak-hours',
      queryParameters: {'days': days},
      fromJson: (json) => (json as List)
          .map((item) => PeakHour.fromJson(item))
          .toList(),
    );
  }

  /// Get category sales
  Future<ApiResponse<List<CategorySales>>> getCategorySales({
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    return await _client.get(
      '/statistics/category-sales',
      queryParameters: {
        'fromDate': fromDate.toIso8601String(),
        'toDate': toDate.toIso8601String(),
      },
      fromJson: (json) => (json as List)
          .map((item) => CategorySales.fromJson(item))
          .toList(),
    );
  }
}

// ==================== INVENTORY API SERVICE ====================

class InventoryApiService {
  final ApiClient _client = ApiClient();

  /// Get all store products
  Future<ApiResponse<List<StoreProductModel>>> getAllStoreProducts({
    String? storeId,
  }) async {
    return await _client.get(
      '/inventory/store-products',
      queryParameters: {
        if (storeId != null) 'storeId': storeId,
      },
      fromJson: (json) => (json as List)
          .map((item) => StoreProductModel.fromJson(item))
          .toList(),
    );
  }

  /// Get store product by ID
  Future<ApiResponse<StoreProductModel>> getStoreProductById(String id) async {
    return await _client.get(
      '/inventory/store-products/$id',
      fromJson: (json) => StoreProductModel.fromJson(json),
    );
  }

  /// Get low stock products
  Future<ApiResponse<List<StoreProductModel>>> getLowStockProducts() async {
    return await _client.get(
      '/inventory/low-stock',
      fromJson: (json) => (json as List)
          .map((item) => StoreProductModel.fromJson(item))
          .toList(),
    );
  }

  /// Get inventory logs
  Future<ApiResponse<List<InventoryLogModel>>> getInventoryLogs({
    String? storeProductId,
    int days = 30,
  }) async {
    return await _client.get(
      '/inventory/logs',
      queryParameters: {
        if (storeProductId != null) 'storeProductId': storeProductId,
        'days': days,
      },
      fromJson: (json) => (json as List)
          .map((item) => InventoryLogModel.fromJson(item))
          .toList(),
    );
  }

  /// Get total stock value
  Future<ApiResponse<double>> getTotalStockValue({String? storeId}) async {
    final response = await _client.get<double>(
      '/inventory/stock-value',
      queryParameters: {
        if (storeId != null) 'storeId': storeId,
      },
    );

    if (response.success && response.data != null) {
      return ApiResponse.success(response.data!);
    }

    return ApiResponse.failure(response.error ?? 'Failed to get stock value');
  }

  /// Get consumption forecast
  Future<ApiResponse<List<ConsumptionForecastModel>>> getConsumptionForecast({
    int days = 30,
  }) async {
    return await _client.get(
      '/inventory/consumption-forecast',
      queryParameters: {'days': days},
      fromJson: (json) => (json as List)
          .map((item) => ConsumptionForecastModel.fromJson(item))
          .toList(),
    );
  }

  /// Create store product (Admin only)
  Future<ApiResponse<StoreProductModel>> createStoreProduct({
    required String storeId,
    required String name,
    String? description,
    required double purchasePrice,
    required int currentStock,
    required int minimumStock,
    required String unit,
  }) async {
    return await _client.post(
      '/inventory/store-products',
      data: {
        'storeId': storeId,
        'name': name,
        'description': description,
        'purchasePrice': purchasePrice,
        'currentStock': currentStock,
        'minimumStock': minimumStock,
        'unit': unit,
      },
      fromJson: (json) => StoreProductModel.fromJson(json),
    );
  }

  /// Update store product (Admin only)
  Future<ApiResponse<void>> updateStoreProduct(
    String id, {
    String? name,
    String? description,
    double? purchasePrice,
    int? currentStock,
    int? minimumStock,
    String? unit,
  }) async {
    return await _client.put(
      '/inventory/store-products/$id',
      data: {
        if (name != null) 'name': name,
        if (description != null) 'description': description,
        if (purchasePrice != null) 'purchasePrice': purchasePrice,
        if (currentStock != null) 'currentStock': currentStock,
        if (minimumStock != null) 'minimumStock': minimumStock,
        if (unit != null) 'unit': unit,
      },
    );
  }

  /// Adjust inventory
  Future<ApiResponse<void>> adjustInventory({
    required String storeProductId,
    required int quantityChange,
    required String type, // "Restock", "Sale", "Damage", "Adjustment"
    required String reason,
  }) async {
    return await _client.post(
      '/inventory/store-products/$storeProductId/adjust',
      data: {
        'quantityChange': quantityChange,
        'type': type,
        'reason': reason,
      },
    );
  }

  /// Delete store product (Admin only)
  Future<ApiResponse<void>> deleteStoreProduct(String id) async {
    return await _client.delete('/inventory/store-products/$id');
  }
}

// ==================== STORES API SERVICE ====================

class StoresApiService {
  final ApiClient _client = ApiClient();

  /// Get all stores
  Future<ApiResponse<List<Store>>> getStores() async {
    return await _client.get(
      '/stores',
      fromJson: (json) => (json as List)
          .map((item) => Store.fromJson(item))
          .toList(),
    );
  }

  /// Get store by ID
  Future<ApiResponse<Store>> getStoreById(String id) async {
    return await _client.get(
      '/stores/$id',
      fromJson: (json) => Store.fromJson(json),
    );
  }

  /// Create store (Admin only)
  Future<ApiResponse<Store>> createStore({
    required String name,
    String? address,
    String? phoneNumber,
  }) async {
    return await _client.post(
      '/stores',
      data: {
        'name': name,
        'address': address,
        'phoneNumber': phoneNumber,
      },
      fromJson: (json) => Store.fromJson(json),
    );
  }

  /// Update store (Admin only)
  Future<ApiResponse<void>> updateStore(
    String id, {
    String? name,
    String? address,
    String? phoneNumber,
  }) async {
    return await _client.put(
      '/stores/$id',
      data: {
        if (name != null) 'name': name,
        if (address != null) 'address': address,
        if (phoneNumber != null) 'phoneNumber': phoneNumber,
      },
    );
  }

  /// Delete store (Admin only)
  Future<ApiResponse<void>> deleteStore(String id) async {
    return await _client.delete('/stores/$id');
  }
}