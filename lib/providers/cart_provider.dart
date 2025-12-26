import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../models/table_model.dart';

class CartItem {
  final ProductModel product;
  int quantity;
  String? notes;

  CartItem({
    required this.product,
    this.quantity = 1,
    this.notes,
  });

  double get subtotal => product.price * quantity;
}

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];
  TableModel? _selectedTable;
  String? _activeOrderId; // when not null, we are editing an existing order
  String _orderType = 'DineIn'; // DineIn or TakeAway
  bool _isPartnerOrder = false;
  String? _orderNotes;

  List<CartItem> get items => List.unmodifiable(_items);
  TableModel? get selectedTable => _selectedTable;
  String? get activeOrderId => _activeOrderId;
  bool get isEditingExistingOrder => _activeOrderId != null;
  String get orderType => _orderType;
  bool get isPartnerOrder => _isPartnerOrder;
  String? get orderNotes => _orderNotes;
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  double get totalAmount => _items.fold(0.0, (sum, item) => sum + item.subtotal);
  bool get isEmpty => _items.isEmpty;

  // Set Selected Table
  void setSelectedTable(TableModel? table) {
    _selectedTable = table;
    notifyListeners();
  }

  // Set Active Order Id (editing existing order)
  void setActiveOrderId(String? orderId) {
    _activeOrderId = orderId;
    notifyListeners();
  }

  // Set Order Type
  void setOrderType(String type) {
    _orderType = type;
    notifyListeners();
  }

  // Set Partner Order
  void setPartnerOrder(bool isPartner) {
    _isPartnerOrder = isPartner;
    notifyListeners();
  }

  // Set Order Notes
  void setOrderNotes(String? notes) {
    _orderNotes = notes;
    notifyListeners();
  }

  // Add Item
  void addItem(ProductModel product, int quantity, {String? notes}) {
    if (quantity <= 0) return;

    final existingIndex =
        _items.indexWhere((item) => item.product.id == product.id);

    if (existingIndex >= 0) {
      _items[existingIndex].quantity += quantity;
      if (notes != null) {
        _items[existingIndex].notes = notes;
      }
    } else {
      _items.add(CartItem(product: product, quantity: quantity, notes: notes));
    }

    notifyListeners();
  }

  // Remove Item
  void removeItem(String productId) {
    _items.removeWhere((item) => item.product.id == productId);
    notifyListeners();
  }

  // Update Quantity
  void updateQuantity(String productId, int quantity) {
    final idx = _items.indexWhere((x) => x.product.id == productId);
    if (idx < 0) return;

    if (quantity <= 0) {
      _items.removeAt(idx);
    } else {
      _items[idx].quantity = quantity;
    }
    notifyListeners();
  }

  // Increase Quantity
  void increaseQuantity(String productId) {
    final idx = _items.indexWhere((x) => x.product.id == productId);
    if (idx < 0) return;
    _items[idx].quantity += 1;
    notifyListeners();
  }

  void decreaseQuantity(String productId) {
    final idx = _items.indexWhere((x) => x.product.id == productId);
    if (idx < 0) return;

    _items[idx].quantity -= 1;
    if (_items[idx].quantity <= 0) {
      _items.removeAt(idx);
    }
    notifyListeners();
  }

  void updateItemNotes(String productId, String? notes) {
    final idx = _items.indexWhere((x) => x.product.id == productId);
    if (idx < 0) return;
    _items[idx].notes = notes;
    notifyListeners();
  }

  // Clear Cart
  void clear() {
    _items.clear();
    _selectedTable = null;
    _activeOrderId = null;
    _orderType = 'DineIn';
    _isPartnerOrder = false;
    _orderNotes = null;
    notifyListeners();
  }

  // Get Cart Item by Product ID
  CartItem? getItem(String productId) {
    try {
      return _items.firstWhere((item) => item.product.id == productId);
    } catch (e) {
      return null;
    }
  }

  // Check if product is in cart
  bool hasProduct(String productId) {
    return _items.any((item) => item.product.id == productId);
  }

  // Get product quantity in cart
  int getProductQuantity(String productId) {
    final idx = _items.indexWhere((x) => x.product.id == productId);
    if (idx < 0) return 0;
    return _items[idx].quantity;
  }
}
