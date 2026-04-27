import 'package:flutter/foundation.dart';
import 'package:orders_mobile/core/services/api/business_api_service.dart';
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

// ==================== STATISTICS PROVIDER ====================

class StatisticsProvider with ChangeNotifier {
  final StatisticsApiService _apiService = StatisticsApiService();

  // State
  DashboardStats? _dashboardStats;
  DailyStatistics? _dailyStats;
  List<ProductSales> _topProducts = [];
  List<PeakHour> _peakHours = [];
  List<CategorySales> _categorySales = [];
  RevenueChart? _revenueChart;
  bool _isLoading = false;
  String? _error;

  // Getters
  DashboardStats? get dashboardStats => _dashboardStats;
  DailyStatistics? get dailyStats => _dailyStats;
  List<ProductSales> get topProducts => _topProducts;
  List<PeakHour> get peakHours => _peakHours;
  List<CategorySales> get categorySales => _categorySales;
  RevenueChart? get revenueChart => _revenueChart;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetch dashboard statistics
  Future<void> fetchDashboardStats() async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.getDashboardStats();

      if (response.success && response.data != null) {
        _dashboardStats = response.data;
      } else {
        _setError(response.error ?? 'Failed to fetch dashboard stats');
      }
    } catch (e) {
      _setError('Error fetching dashboard stats: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch daily statistics
  Future<void> fetchDailyStats(DateTime date) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.getDailyStats(date);

      if (response.success && response.data != null) {
        _dailyStats = response.data;
      } else {
        _setError(response.error ?? 'Failed to fetch daily stats');
      }
    } catch (e) {
      _setError('Error fetching daily stats: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch top selling products
  Future<void> fetchTopProducts({int count = 10, int days = 30}) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.getTopSellingProducts(
        count: count,
        days: days,
      );

      if (response.success && response.data != null) {
        _topProducts = response.data!;
      } else {
        _setError(response.error ?? 'Failed to fetch top products');
      }
    } catch (e) {
      _setError('Error fetching top products: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch peak hours
  Future<void> fetchPeakHours({int days = 7}) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.getPeakHours(days: days);

      if (response.success && response.data != null) {
        _peakHours = response.data!;
      } else {
        _setError(response.error ?? 'Failed to fetch peak hours');
      }
    } catch (e) {
      _setError('Error fetching peak hours: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch category sales
  Future<void> fetchCategorySales({
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.getCategorySales(
        fromDate: fromDate,
        toDate: toDate,
      );

      if (response.success && response.data != null) {
        _categorySales = response.data!;
      } else {
        _setError(response.error ?? 'Failed to fetch category sales');
      }
    } catch (e) {
      _setError('Error fetching category sales: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch revenue chart
  Future<void> fetchRevenueChart({
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.getRevenueChart(
        fromDate: fromDate,
        toDate: toDate,
      );

      if (response.success && response.data != null) {
        _revenueChart = response.data;
      } else {
        _setError(response.error ?? 'Failed to fetch revenue chart');
      }
    } catch (e) {
      _setError('Error fetching revenue chart: $e');
    } finally {
      _setLoading(false);
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
      debugPrint('❌ Statistics Error: $error');
    }
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}

// ==================== INVENTORY PROVIDER ====================

class InventoryProvider with ChangeNotifier {
  final InventoryApiService _apiService = InventoryApiService();

  // State
  List<StoreProductModel> _storeProducts = [];
  List<StoreProductModel> _lowStockProducts = [];
  List<InventoryLogModel> _inventoryLogs = [];
  List<ConsumptionForecastModel> _consumptionForecasts = [];
  StoreProductModel? _selectedProduct;
  double? _totalStockValue;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<StoreProductModel> get storeProducts => _storeProducts;
  List<StoreProductModel> get lowStockProducts => _lowStockProducts;
  List<InventoryLogModel> get inventoryLogs => _inventoryLogs;
  List<ConsumptionForecastModel> get consumptionForecasts =>
      _consumptionForecasts;
  StoreProductModel? get selectedProduct => _selectedProduct;
  double? get totalStockValue => _totalStockValue;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Get products that need reorder
  List<ConsumptionForecastModel> get productsNeedingReorder {
    return _consumptionForecasts.where((f) => f.needsReorder).toList();
  }

  /// Fetch all store products
  Future<void> fetchStoreProducts({String? storeId}) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.getAllStoreProducts(storeId: storeId);

      if (response.success && response.data != null) {
        _storeProducts = response.data!;
      } else {
        _setError(response.error ?? 'Failed to fetch store products');
      }
    } catch (e) {
      _setError('Error fetching store products: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch store product by ID
  Future<void> fetchStoreProductById(String id) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.getStoreProductById(id);

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

  /// Fetch low stock products
  Future<void> fetchLowStockProducts() async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.getLowStockProducts();

      if (response.success && response.data != null) {
        _lowStockProducts = response.data!;
      } else {
        _setError(response.error ?? 'Failed to fetch low stock products');
      }
    } catch (e) {
      _setError('Error fetching low stock products: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch inventory logs
  Future<void> fetchInventoryLogs({
    String? storeProductId,
    int days = 30,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.getInventoryLogs(
        storeProductId: storeProductId,
        days: days,
      );

      if (response.success && response.data != null) {
        _inventoryLogs = response.data!;
      } else {
        _setError(response.error ?? 'Failed to fetch inventory logs');
      }
    } catch (e) {
      _setError('Error fetching inventory logs: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch total stock value
  Future<void> fetchTotalStockValue({String? storeId}) async {
    _clearError();

    try {
      final response = await _apiService.getTotalStockValue(storeId: storeId);

      if (response.success && response.data != null) {
        _totalStockValue = response.data;
        notifyListeners();
      } else {
        _setError(response.error ?? 'Failed to fetch stock value');
      }
    } catch (e) {
      _setError('Error fetching stock value: $e');
    }
  }

  /// Fetch consumption forecast
  Future<void> fetchConsumptionForecast({int days = 30}) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.getConsumptionForecast(days: days);

      if (response.success && response.data != null) {
        _consumptionForecasts = response.data!;
      } else {
        _setError(response.error ?? 'Failed to fetch consumption forecast');
      }
    } catch (e) {
      _setError('Error fetching consumption forecast: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Adjust inventory
  Future<bool> adjustInventory({
    required String storeProductId,
    required int quantityChange,
    required String type,
    required String reason,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.adjustInventory(
        storeProductId: storeProductId,
        quantityChange: quantityChange,
        type: type,
        reason: reason,
      );

      if (response.success) {
        await fetchStoreProducts(); // Refresh
        return true;
      } else {
        _setError(response.error ?? 'Failed to adjust inventory');
        return false;
      }
    } catch (e) {
      _setError('Error adjusting inventory: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Create store product (Admin only)
  Future<bool> createStoreProduct({
    required String storeId,
    required String name,
    String? description,
    required double purchasePrice,
    required int currentStock,
    required int minimumStock,
    required String unit,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      final response = await _apiService.createStoreProduct(
        storeId: storeId,
        name: name,
        description: description,
        purchasePrice: purchasePrice,
        currentStock: currentStock,
        minimumStock: minimumStock,
        unit: unit,
      );
      if (response.success) {
        await fetchStoreProducts(storeId: storeId);
        return true;
      } else {
        _setError(response.error ?? 'Failed to create product');
        return false;
      }
    } catch (e) {
      _setError('Error creating product: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Delete store product (Admin only)
  Future<bool> deleteStoreProduct(String id, {String? storeId}) async {
    _clearError();
    try {
      final response = await _apiService.deleteStoreProduct(id);
      if (response.success) {
        await fetchStoreProducts(storeId: storeId);
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

  /// Set selected product
  void setSelectedProduct(StoreProductModel? product) {
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
      debugPrint('❌ Inventory Error: $error');
    }
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}

// ==================== STORES PROVIDER ====================

class StoresProvider with ChangeNotifier {
  final StoresApiService _apiService = StoresApiService();

  // State
  List<Store> _stores = [];
  Store? _selectedStore;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Store> get stores => _stores;
  Store? get selectedStore => _selectedStore;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetch all stores
  Future<void> fetchStores() async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.getStores();

      if (response.success && response.data != null) {
        _stores = response.data!;
      } else {
        _setError(response.error ?? 'Failed to fetch stores');
      }
    } catch (e) {
      _setError('Error fetching stores: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch store by ID
  Future<void> fetchStoreById(String id) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.getStoreById(id);

      if (response.success && response.data != null) {
        _selectedStore = response.data;
      } else {
        _setError(response.error ?? 'Failed to fetch store');
      }
    } catch (e) {
      _setError('Error fetching store: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Create store (Admin only)
  Future<bool> createStore({
    required String name,
    String? address,
    String? phoneNumber,
    bool isExternal = false,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.createStore(
        name: name,
        address: address,
        phoneNumber: phoneNumber,
        isExternal: isExternal,
      );

      if (response.success && response.data != null) {
        _selectedStore = response.data;
        await fetchStores(); // Refresh
        return true;
      } else {
        _setError(response.error ?? 'Failed to create store');
        return false;
      }
    } catch (e) {
      _setError('Error creating store: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update store (Admin only)
  Future<bool> updateStore(
    String id, {
    String? name,
    String? address,
    String? phoneNumber,
    bool? isExternal,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.updateStore(
        id,
        name: name,
        address: address,
        phoneNumber: phoneNumber,
        isExternal: isExternal,
      );

      if (response.success) {
        await fetchStores(); // Refresh
        return true;
      } else {
        _setError(response.error ?? 'Failed to update store');
        return false;
      }
    } catch (e) {
      _setError('Error updating store: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Delete store (Admin only)
  Future<bool> deleteStore(String id) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.deleteStore(id);

      if (response.success) {
        _stores.removeWhere((s) => s.id == id);
        if (_selectedStore?.id == id) {
          _selectedStore = null;
        }
        notifyListeners();
        return true;
      } else {
        _setError(response.error ?? 'Failed to delete store');
        return false;
      }
    } catch (e) {
      _setError('Error deleting store: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Set selected store
  void setSelectedStore(Store? store) {
    _selectedStore = store;
    notifyListeners();
  }

  /// Get store by ID (from local state)
  Store? getStoreById(String id) {
    try {
      return _stores.firstWhere((s) => s.id == id);
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
      debugPrint('❌ Stores Error: $error');
    }
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}
