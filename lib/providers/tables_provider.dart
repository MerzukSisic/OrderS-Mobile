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

      if (response['success'] == true) {
        final List<dynamic> data = response['data'] ?? [];
        _tables = data.map((json) => TableModel.fromJson(json)).toList();
        _error = null;
      } else {
        _error = response['message'] ?? 'Failed to load tables';
      }
    } catch (e) {
      _error = 'Error loading tables: ';
      _tables = [];
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
  Future<void> updateTableStatus(String tableId, String status) async {
    try {
      final response = await _apiService.put(
        '/Tables//status?status=',
      );

      if (response['success'] == true) {
        // Update local state
        final index = _tables.indexWhere((table) => table.id == tableId);
        if (index != -1) {
          _tables[index] = TableModel(
            id: _tables[index].id,
            tableNumber: _tables[index].tableNumber,
            capacity: _tables[index].capacity,
            status: status,
            location: _tables[index].location,
            currentOrderId: _tables[index].currentOrderId,
          );
          notifyListeners();
        }
      }
    } catch (e) {
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

      final response = await _apiService.put('/Tables/', body: body);

      if (response['success'] == true) {
        await fetchTables(); // Refresh list
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Delete table (Admin only)
  Future<void> deleteTable(String tableId) async {
    try {
      final response = await _apiService.delete('/Tables/');

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
