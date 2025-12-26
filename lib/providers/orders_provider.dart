import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../core/services/api_service.dart';
import '../core/constants/api_constants.dart';

class OrdersProvider with ChangeNotifier {
  final ApiService _apiService;

  OrdersProvider(this._apiService);

  List<OrderModel> _orders = [];
  bool _isLoading = false;
  String? _error;

  List<OrderModel> get orders => List.unmodifiable(_orders);
  List<OrderModel> get activeOrders => _orders.where((o) =>
      o.status != 'Completed' && o.status != 'Cancelled'
  ).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetch Orders
  Future<void> fetchOrders() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _apiService.get(ApiConstants.orders);
      if (response is List) {
        _orders = response.map((json) => OrderModel.fromJson(json)).toList();
        _orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create Order
  Future<bool> createOrder({
    String? tableId,
    required String type,
    required bool isPartnerOrder,
    String? notes,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _apiService.post(
        ApiConstants.orders,
        body: {
          'tableId': tableId,
          'type': type,
          'isPartnerOrder': isPartnerOrder,
          'notes': notes,
          'items': items,
        },
      );

      if (response != null) {
        final order = OrderModel.fromJson(response);
        _orders.insert(0, order);
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Get Order by ID
  OrderModel? getOrderById(String id) {
    try {
      return _orders.firstWhere((order) => order.id == id);
    } catch (e) {
      return null;
    }
  }

Future<OrderModel?> fetchOrderById(String id) async {
  try {
    final response = await _apiService.get('${ApiConstants.orders}/$id');
    if (response == null) return null;

    final order = OrderModel.fromJson(response);

    final index = _orders.indexWhere((o) => o.id == order.id);
    if (index >= 0) {
      _orders[index] = order;
    } else {
      _orders.insert(0, order);
    }

    notifyListeners();
    return order;
  } catch (e) {
    _error = e.toString();
    notifyListeners();
    return null;
  }
}

Future<bool> updateOrderStatus({
  required String orderId,
  required String status,
}) async {
  try {
    _isLoading = true;
    _error = null;
    notifyListeners();

    await _apiService.put(
      '${ApiConstants.orders}/$orderId/status',
      body: {'status': status},
    );

    await fetchOrders();
    _isLoading = false;
    notifyListeners();
    return true;
  } catch (e) {
    _error = e.toString();
    _isLoading = false;
    notifyListeners();
    return false;
  }
}

Future<bool> updateOrderItems({
  required String orderId,
  required List<Map<String, dynamic>> items,
  String? notes,
}) async {
  try {
    _isLoading = true;
    _error = null;
    notifyListeners();

    await _apiService.put(
      '${ApiConstants.orders}/$orderId/items',
      body: {'notes': notes, 'items': items},
    );

    await fetchOrders();
    _isLoading = false;
    notifyListeners();
    return true;
  } catch (e) {
    _error = e.toString();
    _isLoading = false;
    notifyListeners();
    return false;
  }
}



  // Refresh
  Future<void> refresh() => fetchOrders();
}
