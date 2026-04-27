import 'package:flutter/foundation.dart';
import 'package:orders_mobile/core/services/api/common_api_services.dart';
import 'package:orders_mobile/models/auth/user_model.dart';
import 'package:orders_mobile/models/products/accompaniment_group.dart';

// ==================== USERS PROVIDER ====================

class UsersProvider with ChangeNotifier {
  final UsersApiService _apiService = UsersApiService();

  // State
  List<UserModel> _users = [];
  UserModel? _selectedUser;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<UserModel> get users => _users;
  UserModel? get selectedUser => _selectedUser;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Get waiters
  List<UserModel> get waiters {
    return _users.where((u) => u.role == 'Waiter').toList();
  }

  /// Get admins
  List<UserModel> get admins {
    return _users.where((u) => u.role == 'Admin').toList();
  }

  /// Get bartenders
  List<UserModel> get bartenders {
    return _users.where((u) => u.role == 'Bartender').toList();
  }

  /// Get active users
  List<UserModel> get activeUsers {
    return _users.where((u) => u.isActive).toList();
  }

  /// Fetch all users (Admin only)
  Future<void> fetchUsers({String? role}) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.getUsers(role: role);

      if (response.success && response.data != null) {
        _users = response.data!;
      } else {
        _setError(response.error ?? 'Failed to fetch users');
      }
    } catch (e) {
      _setError('Error fetching users: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch user by ID (Admin only)
  Future<void> fetchUserById(String id) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.getUserById(id);

      if (response.success && response.data != null) {
        _selectedUser = response.data;
      } else {
        _setError(response.error ?? 'Failed to fetch user');
      }
    } catch (e) {
      _setError('Error fetching user: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch waiters
  Future<void> fetchWaiters() async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.getWaiters();

      if (response.success && response.data != null) {
        _users = response.data!;
      } else {
        _setError(response.error ?? 'Failed to fetch waiters');
      }
    } catch (e) {
      _setError('Error fetching waiters: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Create user (Admin only)
  Future<bool> createUser({
    required String fullName,
    required String email,
    required String password,
    required String role,
    String? phoneNumber,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.createUser(
        fullName: fullName,
        email: email,
        password: password,
        role: role,
        phoneNumber: phoneNumber,
      );

      if (response.success && response.data != null) {
        await fetchUsers(); // Refresh list
        return true;
      } else {
        _setError(response.error ?? 'Failed to create user');
        return false;
      }
    } catch (e) {
      _setError('Error creating user: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update user (Admin only)
  Future<bool> updateUser(
    String id, {
    String? fullName,
    String? email,
    String? phoneNumber,
    String? role,
    bool? isActive,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.updateUser(
        id,
        fullName: fullName,
        email: email,
        phoneNumber: phoneNumber,
        role: role,
        isActive: isActive,
      );

      if (response.success) {
        await fetchUsers(); // Refresh list
        return true;
      } else {
        _setError(response.error ?? 'Failed to update user');
        return false;
      }
    } catch (e) {
      _setError('Error updating user: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Delete user (Admin only)
  Future<bool> deleteUser(String id) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.deleteUser(id);

      if (response.success) {
        _users.removeWhere((u) => u.id == id);
        if (_selectedUser?.id == id) {
          _selectedUser = null;
        }
        notifyListeners();
        return true;
      } else {
        _setError(response.error ?? 'Failed to delete user');
        return false;
      }
    } catch (e) {
      _setError('Error deleting user: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Set selected user
  void setSelectedUser(UserModel? user) {
    _selectedUser = user;
    notifyListeners();
  }

  /// Get user by ID (from local state)
  UserModel? getUserById(String id) {
    try {
      return _users.firstWhere((u) => u.id == id);
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
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}

// ==================== ACCOMPANIMENTS PROVIDER ====================

class AccompanimentsProvider with ChangeNotifier {
  final AccompanimentsApiService _apiService = AccompanimentsApiService();

  // State
  List<AccompanimentGroup> _accompanimentGroups = [];
  AccompanimentGroup? _selectedGroup;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<AccompanimentGroup> get accompanimentGroups => _accompanimentGroups;
  AccompanimentGroup? get selectedGroup => _selectedGroup;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Get required groups
  List<AccompanimentGroup> get requiredGroups {
    return _accompanimentGroups.where((g) => g.isRequired).toList();
  }

  /// Get optional groups
  List<AccompanimentGroup> get optionalGroups {
    return _accompanimentGroups.where((g) => !g.isRequired).toList();
  }

  /// Fetch accompaniments by product ID
  Future<void> fetchByProductId(String productId) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.getByProductId(productId);

      if (response.success && response.data != null) {
        _accompanimentGroups = response.data!;
      } else {
        _setError(response.error ?? 'Failed to fetch accompaniments');
      }
    } catch (e) {
      _setError('Error fetching accompaniments: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch group by ID
  Future<void> fetchGroupById(String id) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.getGroupById(id);

      if (response.success && response.data != null) {
        _selectedGroup = response.data;
      } else {
        _setError(response.error ?? 'Failed to fetch group');
      }
    } catch (e) {
      _setError('Error fetching group: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Create accompaniment group (Admin only)
  Future<bool> createGroup({
    required String name,
    required String productId,
    required String selectionType,
    required bool isRequired,
    int? minSelections,
    int? maxSelections,
    int displayOrder = 0,
    List<Map<String, dynamic>>? accompaniments,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.createGroup(
        name: name,
        productId: productId,
        selectionType: selectionType,
        isRequired: isRequired,
        minSelections: minSelections,
        maxSelections: maxSelections,
        displayOrder: displayOrder,
        accompaniments: accompaniments,
      );

      if (response.success && response.data != null) {
        await fetchByProductId(productId); // Refresh list
        return true;
      } else {
        _setError(response.error ?? 'Failed to create group');
        return false;
      }
    } catch (e) {
      _setError('Error creating group: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update accompaniment group (Admin only)
  Future<bool> updateGroup(
    String id, {
    required String name,
    required String selectionType,
    required bool isRequired,
    int? minSelections,
    int? maxSelections,
    required int displayOrder,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.updateGroup(
        id,
        name: name,
        selectionType: selectionType,
        isRequired: isRequired,
        minSelections: minSelections,
        maxSelections: maxSelections,
        displayOrder: displayOrder,
      );

      if (response.success) {
        // Refresh - need productId
        if (_selectedGroup != null) {
          await fetchByProductId(_selectedGroup!.productId);
        }
        return true;
      } else {
        _setError(response.error ?? 'Failed to update group');
        return false;
      }
    } catch (e) {
      _setError('Error updating group: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Delete accompaniment group (Admin only)
  Future<bool> deleteGroup(String id) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.deleteGroup(id);

      if (response.success) {
        _accompanimentGroups.removeWhere((g) => g.id == id);
        if (_selectedGroup?.id == id) {
          _selectedGroup = null;
        }
        notifyListeners();
        return true;
      } else {
        _setError(response.error ?? 'Failed to delete group');
        return false;
      }
    } catch (e) {
      _setError('Error deleting group: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Toggle accompaniment availability (Admin only)
  Future<bool> toggleAccompanimentAvailability(String accompanimentId) async {
    _clearError();

    try {
      final response = await _apiService.toggleAvailability(accompanimentId);

      if (response.success && response.data != null) {
        // Update local state
        for (var group in _accompanimentGroups) {
          final index =
              group.accompaniments.indexWhere((a) => a.id == accompanimentId);
          if (index != -1) {
            final newAvailability = response.data!['isAvailable'] as bool;
            group.accompaniments[index] = group.accompaniments[index].copyWith(
              isAvailable: newAvailability,
            );
            notifyListeners();
            break;
          }
        }
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

  /// Set selected group
  void setSelectedGroup(AccompanimentGroup? group) {
    _selectedGroup = group;
    notifyListeners();
  }

  /// Clear accompaniments
  void clearAccompaniments() {
    _accompanimentGroups = [];
    _selectedGroup = null;
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
      debugPrint('❌ Accompaniments Error: $error');
    }
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}
