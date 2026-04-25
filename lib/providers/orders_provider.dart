import 'package:flutter/foundation.dart';
import 'package:orders_mobile/core/services/api/orders_api_service.dart';
import 'package:orders_mobile/models/orders/order_model.dart';
import 'package:orders_mobile/models/products/product_model.dart';

class CartItem {
  final ProductModel product;
  final int quantity;
  final List<String> selectedAccompanimentIds;
  final String? notes;

  CartItem({
    required this.product,
    required this.quantity,
    this.selectedAccompanimentIds = const [],
    this.notes,
  });

  double get totalPrice {
    double basePrice = product.price;
    
    // Add accompaniment charges
    for (final group in product.accompanimentGroups) {
      for (final acc in group.accompaniments) {
        if (selectedAccompanimentIds.contains(acc.id)) {
          basePrice += acc.extraCharge;
        }
      }
    }
    
    return basePrice * quantity;
  }

  CartItem copyWith({
    ProductModel? product,
    int? quantity,
    List<String>? selectedAccompanimentIds,
    String? notes,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      selectedAccompanimentIds: selectedAccompanimentIds ?? this.selectedAccompanimentIds,
      notes: notes ?? this.notes,
    );
  }

  // Generate unique key based on product + accompaniments
  String get uniqueKey {
    final accIds = selectedAccompanimentIds.toList()..sort();
    return '${product.id}_${accIds.join('_')}';
  }
}

class OrdersProvider with ChangeNotifier {
  final OrdersApiService _apiService = OrdersApiService();

  // State
  List<OrderModel> _orders = [];
  OrderModel? _selectedOrder;
  bool _isLoading = false;
  String? _error;

  // Cart state
  final Map<String, CartItem> _cart = {}; // Key: uniqueKey from CartItem
  String? _selectedTableId;
  String _orderType = 'DineIn';
  bool _isPartnerOrder = false;
  String? _orderNotes;

  // Getters - Orders
  List<OrderModel> get orders => _orders;
  OrderModel? get selectedOrder => _selectedOrder;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Getters - Cart
  List<CartItem> get cartItems => _cart.values.toList();
  int get cartCount => _cart.values.fold(0, (sum, item) => sum + item.quantity);
  double get cartTotal => _cart.values.fold(0.0, (sum, item) => sum + item.totalPrice);
  bool get hasItems => _cart.isNotEmpty;
  String? get selectedTableId => _selectedTableId;
  String get orderType => _orderType;
  bool get isPartnerOrder => _isPartnerOrder;
  String? get orderNotes => _orderNotes;

  // ========== CART OPERATIONS ==========

  /// Add item to cart
  void addToCart({
    required ProductModel product,
    int quantity = 1,
    List<String> selectedAccompanimentIds = const [],
    String? notes,
  }) {
    final item = CartItem(
      product: product,
      quantity: quantity,
      selectedAccompanimentIds: selectedAccompanimentIds,
      notes: notes,
    );

    final key = item.uniqueKey;

    if (_cart.containsKey(key)) {
      // Same product with same accompaniments - increase quantity
      _cart[key] = _cart[key]!.copyWith(
        quantity: _cart[key]!.quantity + quantity,
      );
    } else {
      // New item or different accompaniments
      _cart[key] = item;
    }

    notifyListeners();
  }

  /// Update cart item quantity
  void updateCartItemQuantity(String key, int quantity) {
    if (quantity <= 0) {
      removeFromCart(key);
      return;
    }

    if (_cart.containsKey(key)) {
      _cart[key] = _cart[key]!.copyWith(quantity: quantity);
      notifyListeners();
    }
  }

  /// Remove from cart
  void removeFromCart(String key) {
    _cart.remove(key);
    notifyListeners();
  }

  /// Clear cart
  void clearCart() {
    _cart.clear();
    _selectedTableId = null;
    _orderType = 'DineIn';
    _isPartnerOrder = false;
    _orderNotes = null;
    notifyListeners();
  }

  /// Set table for order
  void setTable(String? tableId) {
    _selectedTableId = tableId;
    notifyListeners();
  }

  /// Set order type
  void setOrderType(String type) {
    _orderType = type;
    if (type == 'TakeAway') {
      _selectedTableId = null;
    }
    notifyListeners();
  }

  /// Toggle partner order
  void togglePartnerOrder() {
    _isPartnerOrder = !_isPartnerOrder;
    notifyListeners();
  }

  /// Set order notes
  void setOrderNotes(String? notes) {
    _orderNotes = notes;
    notifyListeners();
  }

  // ========== ORDER OPERATIONS ==========

  /// Create order from cart
  Future<bool> createOrderFromCart() async {
    if (_cart.isEmpty) {
      _setError('Cart is empty');
      return false;
    }

    if (_orderType == 'DineIn' && _selectedTableId == null) {
      _setError('Please select a table for dine-in orders');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      final items = _cart.values.map((item) => {
        'productId': item.product.id,
        'quantity': item.quantity,
        'notes': item.notes,
        'selectedAccompanimentIds': item.selectedAccompanimentIds,
      }).toList();

      final response = await _apiService.createOrder(
        tableId: _selectedTableId,
        type: _orderType,
        isPartnerOrder: _isPartnerOrder,
        notes: _orderNotes,
        items: items,
      );

      if (response.success && response.data != null) {
        _selectedOrder = response.data;
        clearCart();
        await fetchOrders(); // Refresh orders list
        return true;
      } else {
        _setError(response.error ?? 'Failed to create order');
        return false;
      }
    } catch (e) {
      _setError('Error creating order: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch all orders
  Future<void> fetchOrders({
    String? waiterId,
    DateTime? fromDate,
    DateTime? toDate,
    String? status,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.getOrders(
        waiterId: waiterId,
        fromDate: fromDate,
        toDate: toDate,
        status: status,
      );

      if (response.success && response.data != null) {
        _orders = response.data!;
      } else {
        _setError(response.error ?? 'Failed to fetch orders');
      }
    } catch (e) {
      _setError('Error fetching orders: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch active orders
  Future<void> fetchActiveOrders() async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.getActiveOrders();

      if (response.success && response.data != null) {
        _orders = response.data!;
      } else {
        _setError(response.error ?? 'Failed to fetch active orders');
      }
    } catch (e) {
      _setError('Error fetching active orders: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch order by ID
  Future<void> fetchOrderById(String id) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.getOrderById(id);

      if (response.success && response.data != null) {
        _selectedOrder = response.data;
      } else {
        _setError(response.error ?? 'Failed to fetch order');
      }
    } catch (e) {
      _setError('Error fetching order: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Update order status
  Future<bool> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    _clearError();

    try {
      final response = await _apiService.updateOrderStatus(
        orderId: orderId,
        status: status,
      );

      if (response.success) {
        await fetchOrders(); // Refresh
        return true;
      } else {
        _setError(response.error ?? 'Failed to update status');
        return false;
      }
    } catch (e) {
      _setError('Error updating status: $e');
      return false;
    }
  }

  /// Complete order
  Future<bool> completeOrder(String orderId) async {
    _clearError();

    try {
      final response = await _apiService.completeOrder(orderId);

      if (response.success) {
        await fetchOrders(); // Refresh
        return true;
      } else {
        _setError(response.error ?? 'Failed to complete order');
        return false;
      }
    } catch (e) {
      _setError('Error completing order: $e');
      return false;
    }
  }

  /// Cancel order
  Future<bool> cancelOrder({
    required String orderId,
    required String reason,
  }) async {
    _clearError();

    try {
      final response = await _apiService.cancelOrder(
        orderId: orderId,
        reason: reason,
      );

      if (response.success) {
        await fetchOrders(); // Refresh
        return true;
      } else {
        _setError(response.error ?? 'Failed to cancel order');
        return false;
      }
    } catch (e) {
      _setError('Error cancelling order: $e');
      return false;
    }
  }

  /// Soft-delete (archive) an order by cancelling it with an explicit admin reason.
  /// No physical DB row is removed — the order is preserved with status Cancelled.
  Future<bool> softDeleteOrder(String orderId) async {
    return cancelOrder(
      orderId: orderId,
      reason: 'Archived by admin',
    );
  }

  /// Set selected order
  void setSelectedOrder(OrderModel? order) {
    _selectedOrder = order;
    notifyListeners();
  }

  /// Get order by ID (from local state)
  OrderModel? getOrderById(String id) {
    try {
      return _orders.firstWhere((o) => o.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get active orders (from local state)
  List<OrderModel> get activeOrders {
    return _orders.where((o) => 
      o.status != 'Completed' && o.status != 'Cancelled'
    ).toList();
  }

  // ========== PRIVATE HELPERS ==========

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    if (error != null) {
      debugPrint('❌ Orders Error: $error');
    }
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}