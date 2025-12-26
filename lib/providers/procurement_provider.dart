import 'package:flutter/foundation.dart';
import '../core/services/api_service.dart';
import '../core/constants/api_constants.dart';
import '../models/procurement_model.dart';

class ProcurementProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  // State
  List<ProcurementOrder> _procurementOrders = [];
  ProcurementOrder? _selectedOrder;
  bool _isLoading = false;
  String? _error;
  String? _selectedStoreFilter;

  // Getters
  List<ProcurementOrder> get procurementOrders => _procurementOrders;
  ProcurementOrder? get selectedOrder => _selectedOrder;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get selectedStoreFilter => _selectedStoreFilter;

  // Filtered orders by status
  List<ProcurementOrder> getOrdersByStatus(String status) {
    return _procurementOrders
        .where((order) => order.status == status)
        .toList();
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error state
  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Set store filter
  void setStoreFilter(String? storeId) {
    _selectedStoreFilter = storeId;
    notifyListeners();
    // Reload with filter
    fetchProcurementOrders();
  }

  // Fetch all procurement orders
  Future<void> fetchProcurementOrders() async {
    _setLoading(true);
    _setError(null);

    try {
      String endpoint = ApiConstants.procurement;
      
      // Add store filter if selected
      if (_selectedStoreFilter != null && _selectedStoreFilter!.isNotEmpty) {
        endpoint += '?storeId=$_selectedStoreFilter';
      }

      final response = await _apiService.get(endpoint);

      if (response is List) {
        _procurementOrders = response
            .map((json) => ProcurementOrder.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        _procurementOrders = [];
      }

      _setLoading(false);
    } catch (e) {
      _setError('Greška pri učitavanju nabavki: ${e.toString()}');
      _setLoading(false);
      debugPrint('Error fetching procurement orders: $e');
    }
  }

  // Fetch single procurement order by ID
  Future<void> fetchProcurementOrderById(String id) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await _apiService.get('${ApiConstants.procurement}/$id');

      if (response is Map<String, dynamic>) {
        _selectedOrder = ProcurementOrder.fromJson(response);
      }

      _setLoading(false);
    } catch (e) {
      _setError('Greška pri učitavanju nabavke: ${e.toString()}');
      _setLoading(false);
      debugPrint('Error fetching procurement order: $e');
    }
  }

  // Create new procurement order
  Future<ProcurementOrder?> createProcurementOrder(CreateProcurementDto dto) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await _apiService.post(
        ApiConstants.procurement,
        body: dto.toJson(),
      );

      if (response is Map<String, dynamic>) {
        final newOrder = ProcurementOrder.fromJson(response);
        
        // Add to list
        _procurementOrders.insert(0, newOrder);
        _selectedOrder = newOrder;
        
        _setLoading(false);
        notifyListeners();
        
        return newOrder;
      }

      _setLoading(false);
      return null;
    } catch (e) {
      _setError('Greška pri kreiranju nabavke: ${e.toString()}');
      _setLoading(false);
      debugPrint('Error creating procurement order: $e');
      return null;
    }
  }

  // Create Stripe Payment Intent
  Future<String?> createPaymentIntent(String procurementOrderId) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await _apiService.post(
        '${ApiConstants.procurement}/$procurementOrderId/payment-intent',
        body: {},
      );

      _setLoading(false);

      if (response is Map<String, dynamic>) {
        final paymentIntent = PaymentIntentResponse.fromJson(response);
        return paymentIntent.clientSecret;
      }

      return null;
    } catch (e) {
      _setError('Greška pri kreiranju plaćanja: ${e.toString()}');
      _setLoading(false);
      debugPrint('Error creating payment intent: $e');
      return null;
    }
  }

  // Confirm payment
  Future<bool> confirmPayment(String procurementOrderId, String paymentIntentId) async {
    _setLoading(true);
    _setError(null);

    try {
      final dto = ConfirmPaymentDto(paymentIntentId: paymentIntentId);
      
      await _apiService.post(
        '${ApiConstants.procurement}/$procurementOrderId/confirm-payment',
        body: dto.toJson(),
      );

      // Reload the order to get updated status
      await fetchProcurementOrderById(procurementOrderId);
      
      // Refresh the list
      await fetchProcurementOrders();

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Greška pri potvrdi plaćanja: ${e.toString()}');
      _setLoading(false);
      debugPrint('Error confirming payment: $e');
      return false;
    }
  }

  // Update procurement status
  Future<bool> updateProcurementStatus(String id, String status) async {
    _setLoading(true);
    _setError(null);

    try {
      await _apiService.put(
        '${ApiConstants.procurement}/$id/status?status=$status',
        body: {},
      );

      // Update local state
      final index = _procurementOrders.indexWhere((order) => order.id == id);
      if (index != -1) {
        final updatedOrder = ProcurementOrder(
          id: _procurementOrders[index].id,
          storeId: _procurementOrders[index].storeId,
          storeName: _procurementOrders[index].storeName,
          supplier: _procurementOrders[index].supplier,
          status: status,
          totalAmount: _procurementOrders[index].totalAmount,
          orderDate: _procurementOrders[index].orderDate,
          deliveryDate: status == ProcurementStatus.received 
              ? DateTime.now() 
              : _procurementOrders[index].deliveryDate,
          stripePaymentIntentId: _procurementOrders[index].stripePaymentIntentId,
          notes: _procurementOrders[index].notes,
          items: _procurementOrders[index].items,
        );

        _procurementOrders[index] = updatedOrder;
        
        if (_selectedOrder?.id == id) {
          _selectedOrder = updatedOrder;
        }
      }

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Greška pri ažuriranju statusa: ${e.toString()}');
      _setLoading(false);
      debugPrint('Error updating procurement status: $e');
      return false;
    }
  }

  // Clear selected order
  void clearSelectedOrder() {
    _selectedOrder = null;
    notifyListeners();
  }

  // Reset provider state
  void reset() {
    _procurementOrders = [];
    _selectedOrder = null;
    _isLoading = false;
    _error = null;
    _selectedStoreFilter = null;
    notifyListeners();
  }
}