import 'package:flutter/foundation.dart';
import 'package:orders_mobile/core/services/api/common_api_services.dart';
import 'package:orders_mobile/models/tables/table_model.dart';

class TablesProvider with ChangeNotifier {
  final TablesApiService _apiService = TablesApiService();

  // State
  List<TableModel> _tables = [];
  TableModel? _selectedTable;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<TableModel> get tables => _tables;
  TableModel? get selectedTable => _selectedTable;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Get available tables
  List<TableModel> get availableTables {
    return _tables.where((t) => t.status == 'Available').toList();
  }

  /// Get occupied tables
  List<TableModel> get occupiedTables {
    return _tables.where((t) => t.status == 'Occupied').toList();
  }

  /// Get reserved tables
  List<TableModel> get reservedTables {
    return _tables.where((t) => t.status == 'Reserved').toList();
  }

  /// Fetch all tables
  Future<void> fetchTables({String? status}) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.getTables(status: status);

      if (response.success && response.data != null) {
        _tables = response.data!;
      } else {
        _setError(response.error ?? 'Failed to fetch tables');
      }
    } catch (e) {
      _setError('Error fetching tables: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch table by ID
  Future<void> fetchTableById(String id) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.getTableById(id);

      if (response.success && response.data != null) {
        _selectedTable = response.data;
      } else {
        _setError(response.error ?? 'Failed to fetch table');
      }
    } catch (e) {
      _setError('Error fetching table: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch available tables
  Future<void> fetchAvailableTables() async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.getAvailableTables();

      if (response.success && response.data != null) {
        _tables = response.data!;
      } else {
        _setError(response.error ?? 'Failed to fetch available tables');
      }
    } catch (e) {
      _setError('Error fetching available tables: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Create table (Admin only)
  Future<bool> createTable({
    required String tableNumber,
    required int capacity,
    String? location,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.createTable(
        tableNumber: tableNumber,
        capacity: capacity,
        location: location,
      );

      if (response.success && response.data != null) {
        await fetchTables(); // Refresh list
        return true;
      } else {
        _setError(response.error ?? 'Failed to create table');
        return false;
      }
    } catch (e) {
      _setError('Error creating table: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update table (Admin only)
  Future<bool> updateTable(
    String id, {
    String? tableNumber,
    int? capacity,
    String? location,
    String? status,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.updateTable(
        id,
        tableNumber: tableNumber,
        capacity: capacity,
        location: location,
        status: status,
      );

      if (response.success) {
        await fetchTables(); // Refresh list
        return true;
      } else {
        _setError(response.error ?? 'Failed to update table');
        return false;
      }
    } catch (e) {
      _setError('Error updating table: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update table status
  Future<bool> updateTableStatus({
    required String tableId,
    required String status,
  }) async {
    _clearError();

    try {
      final response = await _apiService.updateTableStatus(
        tableId: tableId,
        status: status,
      );

      if (response.success) {
        // Update local state
        final index = _tables.indexWhere((t) => t.id == tableId);
        if (index != -1) {
          _tables[index] = _tables[index].copyWith(status: status);
        }
        
        if (_selectedTable?.id == tableId) {
          _selectedTable = _selectedTable!.copyWith(status: status);
        }
        
        notifyListeners();
        return true;
      } else {
        _setError(response.error ?? 'Failed to update table status');
        return false;
      }
    } catch (e) {
      _setError('Error updating table status: $e');
      return false;
    }
  }

  /// Delete table (Admin only)
  Future<bool> deleteTable(String id) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.deleteTable(id);

      if (response.success) {
        _tables.removeWhere((t) => t.id == id);
        if (_selectedTable?.id == id) {
          _selectedTable = null;
        }
        notifyListeners();
        return true;
      } else {
        _setError(response.error ?? 'Failed to delete table');
        return false;
      }
    } catch (e) {
      _setError('Error deleting table: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Set selected table
  void setSelectedTable(TableModel? table) {
    _selectedTable = table;
    notifyListeners();
  }

  /// Get table by ID (from local state)
  TableModel? getTableById(String id) {
    try {
      return _tables.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get table by number (from local state)
  TableModel? getTableByNumber(String tableNumber) {
    try {
      return _tables.firstWhere((t) => t.tableNumber == tableNumber);
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
      debugPrint('❌ Tables Error: $error');
    }
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}