import 'package:orders_mobile/core/api/api_client.dart';
import 'package:orders_mobile/models/auth/user_model.dart';
import 'package:orders_mobile/models/products/category_model.dart';
import 'package:orders_mobile/models/tables/table_model.dart';
import 'package:orders_mobile/models/products/accompaniment_group.dart';

// ==================== CATEGORIES API SERVICE ====================

class CategoriesApiService {
  final ApiClient _client = ApiClient();

  /// Get all categories
  Future<ApiResponse<List<CategoryModel>>> getCategories() async {
    return await _client.get(
      '/categories',
      queryParameters: const {
        'page': 1,
        'pageSize': 100,
      },
      fromJson: (json) =>
          (json as List).map((item) => CategoryModel.fromJson(item)).toList(),
    );
  }

  /// Get category by ID
  Future<ApiResponse<CategoryModel>> getCategoryById(String id) async {
    return await _client.get(
      '/categories/$id',
      fromJson: (json) => CategoryModel.fromJson(json),
    );
  }

  /// Get category with products
  Future<ApiResponse<Map<String, dynamic>>> getCategoryWithProducts(
      String id) async {
    return await _client.get(
      '/categories/$id/with-products',
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  /// Create category (Admin only)
  Future<ApiResponse<CategoryModel>> createCategory({
    required String name,
    String? description,
    String? imageUrl,
  }) async {
    return await _client.post(
      '/categories',
      data: {
        'name': name,
        'description': description,
        'imageUrl': imageUrl,
      },
      fromJson: (json) => CategoryModel.fromJson(json),
    );
  }

  /// Update category (Admin only)
  Future<ApiResponse<void>> updateCategory(
    String id, {
    String? name,
    String? description,
    String? imageUrl,
  }) async {
    return await _client.put(
      '/categories/$id',
      data: {
        if (name != null) 'name': name,
        if (description != null) 'description': description,
        if (imageUrl != null) 'imageUrl': imageUrl,
      },
    );
  }

  /// Delete category (Admin only)
  Future<ApiResponse<void>> deleteCategory(String id) async {
    return await _client.delete('/categories/$id');
  }
}

// ==================== TABLES API SERVICE ====================

class TablesApiService {
  final ApiClient _client = ApiClient();

  /// Get all tables
  Future<ApiResponse<List<TableModel>>> getTables({String? status}) async {
    return await _client.get(
      '/tables',
      queryParameters: {
        if (status != null) 'status': status,
        'page': 1,
        'pageSize': 100,
      },
      fromJson: (json) =>
          (json as List).map((item) => TableModel.fromJson(item)).toList(),
    );
  }

  /// Get table by ID
  Future<ApiResponse<TableModel>> getTableById(String id) async {
    return await _client.get(
      '/tables/$id',
      fromJson: (json) => TableModel.fromJson(json),
    );
  }

  /// Get available tables
  Future<ApiResponse<List<TableModel>>> getAvailableTables() async {
    return await _client.get(
      '/tables/available',
      queryParameters: const {
        'page': 1,
        'pageSize': 100,
      },
      fromJson: (json) =>
          (json as List).map((item) => TableModel.fromJson(item)).toList(),
    );
  }

  /// Create table (Admin only)
  Future<ApiResponse<TableModel>> createTable({
    required String tableNumber,
    required int capacity,
    String? location,
  }) async {
    return await _client.post(
      '/tables',
      data: {
        'tableNumber': tableNumber,
        'capacity': capacity,
        'location': location,
      },
      fromJson: (json) => TableModel.fromJson(json),
    );
  }

  /// Update table (Admin only)
  Future<ApiResponse<void>> updateTable(
    String id, {
    String? tableNumber,
    int? capacity,
    String? location,
    String? status,
  }) async {
    return await _client.put(
      '/tables/$id',
      data: {
        if (tableNumber != null) 'tableNumber': tableNumber,
        if (capacity != null) 'capacity': capacity,
        if (location != null) 'location': location,
        if (status != null) 'status': status,
      },
    );
  }

  /// Update table status
  Future<ApiResponse<void>> updateTableStatus({
    required String tableId,
    required String status, // "Available", "Occupied", "Reserved"
  }) async {
    return await _client.put(
      '/tables/$tableId/status',
      data: {'status': status},
    );
  }

  /// Delete table (Admin only)
  Future<ApiResponse<void>> deleteTable(String id) async {
    return await _client.delete('/tables/$id');
  }
}

// ==================== USERS API SERVICE ====================

class UsersApiService {
  final ApiClient _client = ApiClient();

  /// Get all users (Admin only)
  Future<ApiResponse<List<UserModel>>> getUsers({String? role}) async {
    // ✅ FIX: If role is provided, use the by-role endpoint
    if (role != null && role.isNotEmpty) {
      return await _client.get(
        '/users/by-role/$role',
        queryParameters: const {
          'page': 1,
          'pageSize': 100,
        },
        fromJson: (json) =>
            (json as List).map((item) => UserModel.fromJson(item)).toList(),
      );
    }

    // ✅ Otherwise, get all users
    return await _client.get(
      '/users',
      queryParameters: const {
        'page': 1,
        'pageSize': 100,
      },
      fromJson: (json) =>
          (json as List).map((item) => UserModel.fromJson(item)).toList(),
    );
  }

  /// Get user by ID (Admin only)
  Future<ApiResponse<UserModel>> getUserById(String id) async {
    return await _client.get(
      '/users/$id',
      fromJson: (json) => UserModel.fromJson(json),
    );
  }

  /// Get waiters
  Future<ApiResponse<List<UserModel>>> getWaiters() async {
    return await _client.get(
      '/users/by-role/Waiter',
      queryParameters: const {
        'page': 1,
        'pageSize': 100,
      },
      fromJson: (json) =>
          (json as List).map((item) => UserModel.fromJson(item)).toList(),
    );
  }

  /// Create user (Admin only)
  Future<ApiResponse<UserModel>> createUser({
    required String fullName,
    required String email,
    required String password,
    required String role,
    String? phoneNumber,
  }) async {
    return await _client.post(
      '/users',
      data: {
        'fullName': fullName,
        'email': email,
        'password': password,
        'role': role,
        'phoneNumber': phoneNumber,
      },
      fromJson: (json) => UserModel.fromJson(json),
    );
  }

  /// Update user (Admin only)
  Future<ApiResponse<void>> updateUser(
    String id, {
    String? fullName,
    String? email,
    String? phoneNumber,
    String? role,
    bool? isActive,
  }) async {
    return await _client.put(
      '/users/$id',
      data: {
        if (fullName != null) 'fullName': fullName,
        if (email != null) 'email': email,
        if (phoneNumber != null) 'phoneNumber': phoneNumber,
        if (role != null) 'role': role,
        if (isActive != null) 'isActive': isActive,
      },
    );
  }

  /// Delete user (Admin only)
  Future<ApiResponse<void>> deleteUser(String id) async {
    return await _client.delete('/users/$id');
  }
}

// ==================== ACCOMPANIMENTS API SERVICE ====================

class AccompanimentsApiService {
  final ApiClient _client = ApiClient();

  /// Get accompaniments by product ID
  Future<ApiResponse<List<AccompanimentGroup>>> getByProductId(
      String productId) async {
    return await _client.get(
      '/accompaniments/product/$productId',
      queryParameters: const {
        'page': 1,
        'pageSize': 100,
      },
      fromJson: (json) => (json as List)
          .map((item) => AccompanimentGroup.fromJson(item))
          .toList(),
    );
  }

  /// Get accompaniment group by ID
  Future<ApiResponse<AccompanimentGroup>> getGroupById(String id) async {
    return await _client.get(
      '/accompaniments/groups/$id',
      fromJson: (json) => AccompanimentGroup.fromJson(json),
    );
  }

  /// Create accompaniment group (Admin only)
  Future<ApiResponse<AccompanimentGroup>> createGroup({
    required String name,
    required String productId,
    required String selectionType, // "Single" or "Multiple"
    required bool isRequired,
    int? minSelections,
    int? maxSelections,
    int displayOrder = 0,
    List<Map<String, dynamic>>? accompaniments,
  }) async {
    return await _client.post(
      '/accompaniments/groups',
      data: {
        'name': name,
        'productId': productId,
        'selectionType': selectionType,
        'isRequired': isRequired,
        'minSelections': minSelections,
        'maxSelections': maxSelections,
        'displayOrder': displayOrder,
        'accompaniments': accompaniments ?? [],
      },
      fromJson: (json) => AccompanimentGroup.fromJson(json),
    );
  }

  /// Update accompaniment group (Admin only)
  Future<ApiResponse<void>> updateGroup(
    String id, {
    required String name,
    required String selectionType,
    required bool isRequired,
    int? minSelections,
    int? maxSelections,
    required int displayOrder,
  }) async {
    return await _client.put(
      '/accompaniments/groups/$id',
      data: {
        'name': name,
        'selectionType': selectionType,
        'isRequired': isRequired,
        'minSelections': minSelections,
        'maxSelections': maxSelections,
        'displayOrder': displayOrder,
      },
    );
  }

  /// Delete accompaniment group (Admin only)
  Future<ApiResponse<void>> deleteGroup(String id) async {
    return await _client.delete('/accompaniments/groups/$id');
  }

  /// Add accompaniment to group (Admin only)
  Future<ApiResponse<Map<String, dynamic>>> addAccompaniment({
    required String groupId,
    required String name,
    required double extraCharge,
    int displayOrder = 0,
    bool isAvailable = true,
  }) async {
    return await _client.post(
      '/accompaniments/groups/$groupId/accompaniments',
      data: {
        'name': name,
        'extraCharge': extraCharge,
        'displayOrder': displayOrder,
        'isAvailable': isAvailable,
      },
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  /// Update accompaniment (Admin only)
  Future<ApiResponse<void>> updateAccompaniment(
    String id, {
    required String name,
    required double extraCharge,
    required int displayOrder,
    required bool isAvailable,
  }) async {
    return await _client.put(
      '/accompaniments/$id',
      data: {
        'name': name,
        'extraCharge': extraCharge,
        'displayOrder': displayOrder,
        'isAvailable': isAvailable,
      },
    );
  }

  /// Get accompaniment by ID
  Future<ApiResponse<Map<String, dynamic>>> getAccompanimentById(
      String id) async {
    return await _client.get(
      '/accompaniments/$id',
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  /// Toggle accompaniment availability (Admin only)
  Future<ApiResponse<Map<String, dynamic>>> toggleAvailability(
      String id) async {
    return await _client.put(
      '/accompaniments/$id/toggle-availability',
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  /// Delete accompaniment (Admin only)
  Future<ApiResponse<void>> deleteAccompaniment(String id) async {
    return await _client.delete('/accompaniments/$id');
  }

  /// Validate accompaniment selection
  Future<ApiResponse<Map<String, dynamic>>> validateSelection({
    required String productId,
    required List<String> selectedAccompanimentIds,
  }) async {
    return await _client.post(
      '/accompaniments/validate',
      data: {
        'productId': productId,
        'selectedAccompanimentIds': selectedAccompanimentIds,
      },
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  /// Calculate total extra charges
  Future<ApiResponse<double>> calculateCharges(
      List<String> accompanimentIds) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/accompaniments/calculate-charges',
      data: accompanimentIds,
    );

    if (response.success && response.data != null) {
      return ApiResponse.success(response.data!['totalExtraCharge'] as double);
    }

    return ApiResponse.failure(response.error ?? 'Failed to calculate charges');
  }
}
