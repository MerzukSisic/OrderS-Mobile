import 'package:orders_mobile/core/api/api_client.dart';
import 'package:orders_mobile/models/orders/order_model.dart';

class OrdersApiService {
  final ApiClient _client = ApiClient();

  /// Create order
  Future<ApiResponse<OrderModel>> createOrder({
    String? tableId,
    required String type, // "DineIn" or "TakeAway"
    bool isPartnerOrder = false,
    String? notes,
    required List<Map<String, dynamic>> items,
  }) async {
    return await _client.post(
      '/orders',
      data: {
        'tableId': tableId,
        'type': type,
        'isPartnerOrder': isPartnerOrder,
        'notes': notes,
        'items': items,
      },
      fromJson: (json) => OrderModel.fromJson(json),
    );
  }

  /// Get order by ID
  Future<ApiResponse<OrderModel>> getOrderById(String id) async {
    return await _client.get(
      '/orders/$id',
      fromJson: (json) => OrderModel.fromJson(json),
    );
  }

  /// Get orders with filters
  Future<ApiResponse<List<OrderModel>>> getOrders({
    String? waiterId,
    DateTime? fromDate,
    DateTime? toDate,
    String? status,
  }) async {
    return await _client.get(
      '/orders',
      queryParameters: {
        if (waiterId != null) 'waiterId': waiterId,
        if (fromDate != null) 'fromDate': fromDate.toIso8601String(),
        if (toDate != null) 'toDate': toDate.toIso8601String(),
        if (status != null) 'status': status,
      },
      fromJson: (json) => (json as List)
          .map((item) => OrderModel.fromJson(item))
          .toList(),
    );
  }

  /// Get active orders
  Future<ApiResponse<List<OrderModel>>> getActiveOrders() async {
    return await _client.get(
      '/orders/active',
      fromJson: (json) => (json as List)
          .map((item) => OrderModel.fromJson(item))
          .toList(),
    );
  }

  /// Get orders by table
  Future<ApiResponse<List<OrderModel>>> getOrdersByTable(String tableId) async {
    return await _client.get(
      '/orders/table/$tableId',
      fromJson: (json) => (json as List)
          .map((item) => OrderModel.fromJson(item))
          .toList(),
    );
  }

  /// Get order items by location (for Kitchen/Bar screens)
  Future<ApiResponse<List<Map<String, dynamic>>>> getOrderItemsByLocation({
    required String location, // "Kitchen" or "Bar"
    String? status,
  }) async {
    return await _client.get(
      '/orders/items/by-location',
      queryParameters: {
        'location': location,
        if (status != null) 'status': status,
      },
      fromJson: (json) => (json as List).cast<Map<String, dynamic>>(),
    );
  }

  /// Update order status
  Future<ApiResponse<void>> updateOrderStatus({
    required String orderId,
    required String status, // "Pending", "Preparing", "Ready", "Completed", "Cancelled"
  }) async {
    return await _client.put(
      '/orders/$orderId/status',
      data: {'status': status},
    );
  }

  /// Complete order
  Future<ApiResponse<void>> completeOrder(String orderId) async {
    return await _client.put('/orders/$orderId/complete');
  }

  /// Cancel order
  Future<ApiResponse<void>> cancelOrder({
    required String orderId,
    required String reason,
  }) async {
    return await _client.put(
      '/orders/$orderId/cancel',
      data: {'reason': reason},
    );
  }

  /// Add item to existing order
  Future<ApiResponse<Map<String, dynamic>>> addItemToOrder({
    required String orderId,
    required String productId,
    required int quantity,
    String? notes,
    List<String>? selectedAccompanimentIds,
  }) async {
    return await _client.post(
      '/orders/$orderId/items',
      data: {
        'productId': productId,
        'quantity': quantity,
        'notes': notes,
        'selectedAccompanimentIds': selectedAccompanimentIds ?? [],
      },
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  /// Update order item status (for Kitchen/Bar)
  Future<ApiResponse<void>> updateOrderItemStatus({
    required String itemId,
    required String status, // "Pending", "Preparing", "Ready", "Completed", "Cancelled"
  }) async {
    return await _client.put(
      '/orders/items/$itemId/status',
      data: {'status': status},
    );
  }
}