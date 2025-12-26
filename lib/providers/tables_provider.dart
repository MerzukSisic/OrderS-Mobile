import 'package:flutter/material.dart';
import '../models/table_model.dart';
import '../core/services/api_service.dart';

class TablesProvider with ChangeNotifier {
  final ApiService _apiService;

  TablesProvider(this._apiService);

  // State
  List<TableModel> _tables = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<TableModel> get tables => _tables;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Available tables
  List<TableModel> get availableTables {
    return _tables.where((table) => table.status == 'Available').toList();
  }

  // Occupied tables
  List<TableModel> get occupiedTables {
    return _tables.where((table) => table.status == 'Occupied').toList();
  }

  // Reserved tables
  List<TableModel> get reservedTables {
    return _tables.where((table) => table.status == 'Reserved').toList();
  }

  /// Fetch all tables
  Future<void> fetchTables() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/Tables');

      if (response is List) {
        _tables = response.map((json) => TableModel.fromJson(json)).toList();
        _error = null;
      } else if (response is Map && response['data'] is List) {
        final data = response['data'] as List;
        _tables = data.map((json) => TableModel.fromJson(json)).toList();
        _error = null;
      } else {
        _tables = [];
        _error = 'Unexpected response format for tables.';
      }
    } catch (e) {
      _tables = [];
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get table by ID
  TableModel? getTableById(String tableId) {
    try {
      return _tables.firstWhere((table) => table.id == tableId);
    } catch (e) {
      return null;
    }
  }

  /// Update table status
  /// ✅ FIX: Dodaj tableId i status u endpoint
  Future<void> updateTableStatus(String tableId, String status) async {
    try {
      await _apiService.put(
        '/Tables/$tableId/status?status=$status',
      );

      // ✅ Refresh tables after status update
      await fetchTables();
    } catch (e) {
      _error = 'Failed to update table status: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Create new table (Admin only)
  Future<void> createTable({
    required String tableNumber,
    required int capacity,
    String? location,
  }) async {
    try {
      final response = await _apiService.post('/Tables', body: {
        'tableNumber': tableNumber,
        'capacity': capacity,
        'location': location,
      });

      if (response['success'] == true) {
        await fetchTables(); // Refresh list
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Update table (Admin only)
  /// ✅ FIX: Dodaj tableId u endpoint
  Future<void> updateTable({
    required String tableId,
    String? tableNumber,
    int? capacity,
    String? location,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (tableNumber != null) body['tableNumber'] = tableNumber;
      if (capacity != null) body['capacity'] = capacity;
      if (location != null) body['location'] = location;

      final response = await _apiService.put('/Tables/$tableId', body: body);

      if (response['success'] == true) {
        await fetchTables(); // Refresh list
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Delete table (Admin only)
  /// ✅ FIX: Dodaj tableId u endpoint
  Future<void> deleteTable(String tableId) async {
    try {
      final response = await _apiService.delete('/Tables/$tableId');

      if (response['success'] == true) {
        _tables.removeWhere((table) => table.id == tableId);
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}