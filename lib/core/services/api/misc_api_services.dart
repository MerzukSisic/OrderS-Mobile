import 'package:orders_mobile/core/api/api_client.dart';
import 'package:orders_mobile/models/products/product_model.dart';
import 'package:orders_mobile/models/procurement/procurement_order_model.dart';

// ==================== NOTIFICATIONS API SERVICE ====================

class NotificationsApiService {
  final ApiClient _client = ApiClient();

  /// Get user notifications
  Future<ApiResponse<List<Map<String, dynamic>>>> getNotifications({
    bool? isRead,
    String? type,
  }) async {
    return await _client.get(
      '/notifications',
      queryParameters: {
        if (isRead != null) 'isRead': isRead,
        if (type != null) 'type': type,
      },
      fromJson: (json) => (json as List).cast<Map<String, dynamic>>(),
    );
  }

  /// Get unread count
  Future<ApiResponse<int>> getUnreadCount() async {
    final response = await _client.get<Map<String, dynamic>>(
      '/notifications/unread-count',
    );

    if (response.success && response.data != null) {
      return ApiResponse.success(response.data!['count'] as int);
    }

    return ApiResponse.failure(response.error ?? 'Failed to get unread count');
  }

  /// Mark notification as read
  Future<ApiResponse<void>> markAsRead(String notificationId) async {
    return await _client.put('/notifications/$notificationId/read');
  }

  /// Mark all as read
  Future<ApiResponse<void>> markAllAsRead() async {
    return await _client.put('/notifications/mark-all-read');
  }

  /// Delete notification
  Future<ApiResponse<void>> deleteNotification(String notificationId) async {
    return await _client.delete('/notifications/$notificationId');
  }

  /// Delete all read notifications
  Future<ApiResponse<void>> deleteAllRead() async {
    return await _client.delete('/notifications/delete-all-read');
  }
}

// ==================== RECOMMENDATIONS API SERVICE ====================

class RecommendationsApiService {
  final ApiClient _client = ApiClient();

  /// Get recommended products
  Future<ApiResponse<List<ProductModel>>> getRecommendedProducts({
    String? userId,
    int count = 5,
  }) async {
    return await _client.get(
      '/recommendations',
      queryParameters: {
        if (userId != null) 'userId': userId,
        'count': count,
      },
      fromJson: (json) => (json as List)
          .map((item) => ProductModel.fromJson(item))
          .toList(),
    );
  }

  /// Get popular products
  Future<ApiResponse<List<ProductModel>>> getPopularProducts({
    int count = 10,
  }) async {
    return await _client.get(
      '/recommendations/popular',
      queryParameters: {'count': count},
      fromJson: (json) => (json as List)
          .map((item) => ProductModel.fromJson(item))
          .toList(),
    );
  }

  /// Get time-based recommendations
  Future<ApiResponse<List<ProductModel>>> getTimeBasedRecommendations({
    required int hour,
    int count = 5,
  }) async {
    return await _client.get(
      '/recommendations/time-based',
      queryParameters: {
        'hour': hour,
        'count': count,
      },
      fromJson: (json) => (json as List)
          .map((item) => ProductModel.fromJson(item))
          .toList(),
    );
  }
}

// ==================== RECEIPTS API SERVICE ====================

class ReceiptsApiService {
  final ApiClient _client = ApiClient();

  /// Get receipt by order ID
  Future<ApiResponse<Map<String, dynamic>>> getReceiptByOrderId(String orderId) async {
    return await _client.get(
      '/receipts/order/$orderId',
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  /// Get receipt by ID
  Future<ApiResponse<Map<String, dynamic>>> getReceiptById(String receiptId) async {
    return await _client.get(
      '/receipts/$receiptId',
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  /// Get receipts with filters
  Future<ApiResponse<List<Map<String, dynamic>>>> getReceipts({
    DateTime? fromDate,
    DateTime? toDate,
    String? paymentMethod,
  }) async {
    return await _client.get(
      '/receipts',
      queryParameters: {
        if (fromDate != null) 'fromDate': fromDate.toIso8601String(),
        if (toDate != null) 'toDate': toDate.toIso8601String(),
        if (paymentMethod != null) 'paymentMethod': paymentMethod,
      },
      fromJson: (json) => (json as List).cast<Map<String, dynamic>>(),
    );
  }
}

// ==================== PROCUREMENT API SERVICE ====================

class ProcurementApiService {
  final ApiClient _client = ApiClient();

  /// Get all procurement orders
  Future<ApiResponse<List<ProcurementOrderModel>>> getProcurementOrders({
    String? storeId,
  }) async {
    return await _client.get(
      '/procurement',
      queryParameters: {
        if (storeId != null) 'storeId': storeId,
      },
      fromJson: (json) => (json as List)
          .map((item) => ProcurementOrderModel.fromJson(item))
          .toList(),
    );
  }

  /// Get procurement order by ID
  Future<ApiResponse<ProcurementOrderModel>> getProcurementOrderById(String id) async {
    return await _client.get(
      '/procurement/$id',
      fromJson: (json) => ProcurementOrderModel.fromJson(json),
    );
  }

  /// Create procurement order
  Future<ApiResponse<ProcurementOrderModel>> createProcurementOrder({
    required String storeId,
    required String supplier,
    String? notes,
    required List<Map<String, dynamic>> items,
  }) async {
    return await _client.post(
      '/procurement',
      data: {
        'storeId': storeId,
        'supplier': supplier,
        'notes': notes,
        'items': items,
      },
      fromJson: (json) => ProcurementOrderModel.fromJson(json),
    );
  }

  /// Create payment intent for procurement
  /// Create payment intent for procurement
/// Returns: { clientSecret: "...", paymentIntentId: "pi_..." }
Future<ApiResponse<Map<String, dynamic>>> createPaymentIntent(String procurementOrderId) async {
  final response = await _client.post<Map<String, dynamic>>(
    '/procurement/$procurementOrderId/payment-intent',
    fromJson: (json) => json as Map<String, dynamic>,
  );

  if (response.success && response.data != null) {
    return ApiResponse.success(response.data!);
  }

  return ApiResponse.failure(response.error ?? 'Failed to create payment intent');
}

  /// Confirm payment
  Future<ApiResponse<void>> confirmPayment({
    required String procurementOrderId,
    required String paymentIntentId,
  }) async {
    return await _client.post(
      '/procurement/$procurementOrderId/confirm-payment',
      data: {'paymentIntentId': paymentIntentId},
    );
  }

  /// Update procurement status
  Future<ApiResponse<void>> updateProcurementStatus({
    required String procurementOrderId,
    required String status, // "Pending", "Paid", "Received", "Cancelled"
  }) async {
    return await _client.put(
      '/procurement/$procurementOrderId/status',
      data: {'status': status},
    );
  }

  /// Receive procurement
  Future<ApiResponse<void>> receiveProcurement({
    required String procurementOrderId,
    required List<Map<String, dynamic>> items,
    String? notes,
  }) async {
    return await _client.post(
      '/procurement/$procurementOrderId/receive',
      data: {
        'items': items,
        'notes': notes,
      },
    );
  }
}

// ==================== PAYMENTS API SERVICE (STRIPE) ====================

class PaymentsApiService {
  final ApiClient _client = ApiClient();

  /// Create payment intent for order
  Future<ApiResponse<Map<String, dynamic>>> createPaymentIntent({
    required String orderId,
    required double amount,
    required String currency,
    String? tableNumber,
    String? customerEmail,
  }) async {
    return await _client.post(
      '/payments/create-intent',
      data: {
        'orderId': orderId,
        'amount': amount,
        'currency': currency,
        'tableNumber': tableNumber,
        'customerEmail': customerEmail,
      },
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  /// Get payment intent
  Future<ApiResponse<Map<String, dynamic>>> getPaymentIntent(String paymentIntentId) async {
    return await _client.get(
      '/payments/intent/$paymentIntentId',
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  /// Confirm payment
  Future<ApiResponse<bool>> confirmPayment(String paymentIntentId) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/payments/confirm/$paymentIntentId',
    );

    if (response.success && response.data != null) {
      return ApiResponse.success(response.data!['success'] as bool);
    }

    return ApiResponse.failure(response.error ?? 'Payment confirmation failed');
  }

  /// Cancel payment intent
  Future<ApiResponse<bool>> cancelPaymentIntent(String paymentIntentId) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/payments/cancel/$paymentIntentId',
    );

    if (response.success && response.data != null) {
      return ApiResponse.success(response.data!['success'] as bool);
    }

    return ApiResponse.failure(response.error ?? 'Payment cancellation failed');
  }

  /// Create refund
  Future<ApiResponse<Map<String, dynamic>>> createRefund({
    required String paymentIntentId,
    double? amount,
    String? reason,
  }) async {
    return await _client.post(
      '/payments/refund',
      data: {
        'paymentIntentId': paymentIntentId,
        'amount': amount,
        'reason': reason,
      },
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  /// Get refund details
  Future<ApiResponse<Map<String, dynamic>>> getRefund(String refundId) async {
    return await _client.get(
      '/payments/refund/$refundId',
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }
}