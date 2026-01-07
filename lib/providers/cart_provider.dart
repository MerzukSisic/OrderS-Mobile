import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../models/table_model.dart';

class CartItem {
  final ProductModel product;
  int quantity;
  String? notes;
  List<String> selectedAccompanimentIds; // ✅ DODATO!

  CartItem({
    required this.product,
    this.quantity = 1,
    this.notes,
    this.selectedAccompanimentIds = const [], // ✅ DODATO!
  });

  double get subtotal => product.price * quantity;
}

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];
  TableModel? _selectedTable;
  String? _activeOrderId;
  String _orderType = 'DineIn';
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

  void setSelectedTable(TableModel? table) {
    _selectedTable = table;
    notifyListeners();
  }

  void setActiveOrderId(String? orderId) {
    _activeOrderId = orderId;
    notifyListeners();
  }

  void setOrderType(String type) {
    _orderType = type;
    notifyListeners();
  }

  void setPartnerOrder(bool isPartner) {
    _isPartnerOrder = isPartner;
    notifyListeners();
  }

  void setOrderNotes(String? notes) {
    _orderNotes = notes;
    notifyListeners();
  }

  // ✅ FIXED: Dodao selectedAccompanimentIds parameter
  void addItem(
    ProductModel product,
    int quantity, {
    String? notes,
    List<String>? selectedAccompanimentIds,
  }) {
    if (quantity <= 0) return;

    final accompaniments = selectedAccompanimentIds ?? [];

    // ✅ FIXED: Provjera i product.id I accompaniments
    final existingIndex = _items.indexWhere((item) {
      if (item.product.id != product.id) return false;
      
      // Uporedi accompaniment IDs
      final itemIds = item.selectedAccompanimentIds.toSet();
      final newIds = accompaniments.toSet();
      
      return itemIds.length == newIds.length && 
             itemIds.difference(newIds).isEmpty;
    });

    if (existingIndex >= 0) {
      // Isti proizvod sa istim prilozima → povećaj quantity
      _items[existingIndex].quantity += quantity;
      if (notes != null) {
        _items[existingIndex].notes = notes;
      }
    } else {
      // Različit proizvod ILI različiti prilozi → novi item
      _items.add(CartItem(
        product: product,
        quantity: quantity,
        notes: notes,
        selectedAccompanimentIds: accompaniments,
      ));
    }

    notifyListeners();
  }

  void removeItem(String productId) {
    _items.removeWhere((item) => item.product.id == productId);
    notifyListeners();
  }

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

  void clear() {
    _items.clear();
    _selectedTable = null;
    _activeOrderId = null;
    _orderType = 'DineIn';
    _isPartnerOrder = false;
    _orderNotes = null;
    notifyListeners();
  }

  CartItem? getItem(String productId) {
    try {
      return _items.firstWhere((item) => item.product.id == productId);
    } catch (e) {
      return null;
    }
  }

  bool hasProduct(String productId) {
    return _items.any((item) => item.product.id == productId);
  }

  int getProductQuantity(String productId) {
    final idx = _items.indexWhere((x) => x.product.id == productId);
    if (idx < 0) return 0;
    return _items[idx].quantity;
  }
}