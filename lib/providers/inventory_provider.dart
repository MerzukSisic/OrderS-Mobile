import 'package:flutter/foundation.dart';
import '../core/services/api_service.dart';
import '../core/constants/api_constants.dart';
import '../models/store_model.dart';

class InventoryProvider with ChangeNotifier {
  final ApiService _apiService;

  InventoryProvider(this._apiService);

  // State
  List<StoreProductItem> _storeProducts = [];
  List<StoreProductItem> _lowStockProducts = [];
  StoreProductItem? _selectedProduct;
  List<InventoryLog> _inventoryLogs = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String _filterType = 'all'; // 'all', 'low-stock', 'out-of-stock'
  String? _selectedStoreFilter;

  // Getters
  List<StoreProductItem> get storeProducts => _filteredProducts;
  List<StoreProductItem> get lowStockProducts => _lowStockProducts;
  StoreProductItem? get selectedProduct => _selectedProduct;
  List<InventoryLog> get inventoryLogs => _inventoryLogs;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String get filterType => _filterType;

  // Filtered products based on search and filter
  List<StoreProductItem> get _filteredProducts {
    List<StoreProductItem> filtered = List.from(_storeProducts);

    // Apply filter
    if (_filterType == 'low-stock') {
      filtered = filtered.where((p) => p.isLowStock && p.currentStock > 0).toList();
    } else if (_filterType == 'out-of-stock') {
      filtered = filtered.where((p) => p.currentStock == 0).toList();
    }

    // Apply search
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((p) {
        return p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (p.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      }).toList();
    }

    return filtered;
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error state
  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // Set filter type
  void setFilterType(String filter) {
    _filterType = filter;
    notifyListeners();
  }

  // Set store filter
  void setStoreFilter(String? storeId) {
    _selectedStoreFilter = storeId;
    notifyListeners();
    fetchStoreProducts();
  }

  // Fetch all store products
  Future<void> fetchStoreProducts() async {
    _setLoading(true);
    _setError(null);

    try {
      String endpoint = ApiConstants.inventory;

      // Add store filter if selected
      if (_selectedStoreFilter != null && _selectedStoreFilter!.isNotEmpty) {
        endpoint += '?storeId=$_selectedStoreFilter';
      }

      final response = await _apiService.get(endpoint);

      if (response is List) {
        _storeProducts = response
            .map((json) => StoreProductItem.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        _storeProducts = [];
      }

      _setLoading(false);
    } catch (e) {
      _setError('Greška pri učitavanju inventara: ${e.toString()}');
      _setLoading(false);
      debugPrint('Error fetching store products: $e');
    }
  }

  // Fetch low stock products
  Future<void> fetchLowStockProducts() async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await _apiService.get(ApiConstants.lowStock);

      if (response is List) {
        _lowStockProducts = response
            .map((json) => StoreProductItem.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        _lowStockProducts = [];
      }

      _setLoading(false);
    } catch (e) {
      _setError('Greška pri učitavanju proizvoda: ${e.toString()}');
      _setLoading(false);
      debugPrint('Error fetching low stock products: $e');
    }
  }

  // Fetch single store product by ID
  Future<void> fetchStoreProductById(String id) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await _apiService.get('${ApiConstants.inventory}/$id');

      if (response is Map<String, dynamic>) {
        _selectedProduct = StoreProductItem.fromJson(response);
      }

      _setLoading(false);
    } catch (e) {
      _setError('Greška pri učitavanju proizvoda: ${e.toString()}');
      _setLoading(false);
      debugPrint('Error fetching store product: $e');
    }
  }

  // Create new store product (Admin only)
  Future<StoreProductItem?> createStoreProduct(CreateStoreProductDto dto) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await _apiService.post(
        ApiConstants.inventory,
        body: dto.toJson(),
      );

      if (response is Map<String, dynamic>) {
        final newProduct = StoreProductItem.fromJson(response);
        _storeProducts.insert(0, newProduct);
        _setLoading(false);
        notifyListeners();
        return newProduct;
      }

      _setLoading(false);
      return null;
    } catch (e) {
      _setError('Greška pri kreiranju proizvoda: ${e.toString()}');
      _setLoading(false);
      debugPrint('Error creating store product: $e');
      return null;
    }
  }

  // Update store product (Admin only)
  Future<bool> updateStoreProduct(String id, UpdateStoreProductDto dto) async {
    _setLoading(true);
    _setError(null);

    try {
      await _apiService.put(
        '${ApiConstants.inventory}/$id',
        body: dto.toJson(),
      );

      // Reload products
      await fetchStoreProducts();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Greška pri ažuriranju proizvoda: ${e.toString()}');
      _setLoading(false);
      debugPrint('Error updating store product: $e');
      return false;
    }
  }

  // Delete store product (Admin only)
  Future<bool> deleteStoreProduct(String id) async {
    _setLoading(true);
    _setError(null);

    try {
      await _apiService.delete('${ApiConstants.inventory}/$id');

      // Remove from local list
      _storeProducts.removeWhere((p) => p.id == id);
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Greška pri brisanju proizvoda: ${e.toString()}');
      _setLoading(false);
      debugPrint('Error deleting store product: $e');
      return false;
    }
  }

  // Adjust inventory (Admin only)
  Future<bool> adjustInventory(String id, AdjustInventoryDto dto) async {
    _setLoading(true);
    _setError(null);

    try {
      await _apiService.post(
        '${ApiConstants.inventory}/$id/adjust',
        body: dto.toJson(),
      );

      // Reload products to get updated stock
      await fetchStoreProducts();
      if (_selectedProduct?.id == id) {
        await fetchStoreProductById(id);
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Greška pri ažuriranju zaliha: ${e.toString()}');
      _setLoading(false);
      debugPrint('Error adjusting inventory: $e');
      return false;
    }
  }

  // Fetch inventory logs
  Future<void> fetchInventoryLogs({String? storeProductId, int days = 30}) async {
    try {
      String endpoint = '${ApiConstants.inventory}/logs?days=$days';
      if (storeProductId != null) {
        endpoint += '&storeProductId=$storeProductId';
      }

      final response = await _apiService.get(endpoint);

      if (response is List) {
        _inventoryLogs = response
            .map((json) => InventoryLog.fromJson(json as Map<String, dynamic>))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching inventory logs: $e');
    }
  }

  // Clear selected product
  void clearSelectedProduct() {
    _selectedProduct = null;
    _inventoryLogs = [];
    notifyListeners();
  }

  // Reset provider state
  void reset() {
    _storeProducts = [];
    _lowStockProducts = [];
    _selectedProduct = null;
    _inventoryLogs = [];
    _isLoading = false;
    _error = null;
    _searchQuery = '';
    _filterType = 'all';
    _selectedStoreFilter = null;
    notifyListeners();
  }
}

// DTO Models for Inventory

class CreateStoreProductDto {
  final String storeId;
  final String name;
  final String? description;
  final double purchasePrice;
  final int currentStock;
  final int minimumStock;
  final String unit;

  const CreateStoreProductDto({
    required this.storeId,
    required this.name,
    this.description,
    required this.purchasePrice,
    this.currentStock = 0,
    this.minimumStock = 10,
    this.unit = 'pcs',
  });

  Map<String, dynamic> toJson() => {
        'storeId': storeId,
        'name': name,
        'description': description,
        'purchasePrice': purchasePrice,
        'currentStock': currentStock,
        'minimumStock': minimumStock,
        'unit': unit,
      };
}

class UpdateStoreProductDto {
  final String? name;
  final String? description;
  final double? purchasePrice;
  final int? currentStock;
  final int? minimumStock;
  final String? unit;

  const UpdateStoreProductDto({
    this.name,
    this.description,
    this.purchasePrice,
    this.currentStock,
    this.minimumStock,
    this.unit,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (name != null) data['name'] = name;
    if (description != null) data['description'] = description;
    if (purchasePrice != null) data['purchasePrice'] = purchasePrice;
    if (currentStock != null) data['currentStock'] = currentStock;
    if (minimumStock != null) data['minimumStock'] = minimumStock;
    if (unit != null) data['unit'] = unit;
    return data;
  }
}

class AdjustInventoryDto {
  final int quantityChange;
  final String type;
  final String? reason;

  const AdjustInventoryDto({
    required this.quantityChange,
    this.type = 'Adjustment',
    this.reason,
  });

  Map<String, dynamic> toJson() => {
        'quantityChange': quantityChange,
        'type': type,
        'reason': reason,
      };
}

class InventoryLog {
  final String id;
  final String storeProductId;
  final String storeProductName;
  final int quantityChange;
  final String type;
  final String? reason;
  final DateTime createdAt;

  const InventoryLog({
    required this.id,
    required this.storeProductId,
    required this.storeProductName,
    required this.quantityChange,
    required this.type,
    this.reason,
    required this.createdAt,
  });

  factory InventoryLog.fromJson(Map<String, dynamic> json) {
    return InventoryLog(
      id: json['id'] as String,
      storeProductId: json['storeProductId'] as String,
      storeProductName: json['storeProductName'] as String? ?? '',
      quantityChange: json['quantityChange'] as int,
      type: json['type'] as String,
      reason: json['reason'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}