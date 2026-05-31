import 'package:flutter/foundation.dart';
import 'package:orders_mobile/core/services/api/misc_api_services.dart';

class ReceiptsProvider with ChangeNotifier {
  final ReceiptsApiService _apiService = ReceiptsApiService();

  List<Map<String, dynamic>> _receipts = [];
  Map<String, dynamic>? _selectedReceipt;
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get receipts => _receipts;
  Map<String, dynamic>? get selectedReceipt => _selectedReceipt;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchReceiptByOrderId(String orderId) async {
    _setLoading(true);
    _clearError();
    try {
      final response = await _apiService.getReceiptByOrderId(orderId);
      if (response.success && response.data != null) {
        _selectedReceipt = response.data;
      } else {
        _setError(response.error ?? 'Failed to fetch receipt');
      }
    } catch (e) {
      _setError('Error fetching receipt: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchReceiptById(String receiptId) async {
    _setLoading(true);
    _clearError();
    try {
      final response = await _apiService.getReceiptById(receiptId);
      if (response.success && response.data != null) {
        _selectedReceipt = response.data;
      } else {
        _setError(response.error ?? 'Failed to fetch receipt');
      }
    } catch (e) {
      _setError('Error fetching receipt: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchReceipts({
    DateTime? fromDate,
    DateTime? toDate,
    String? paymentMethod,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      final response = await _apiService.getReceipts(
        fromDate: fromDate,
        toDate: toDate,
        paymentMethod: paymentMethod,
      );
      if (response.success && response.data != null) {
        _receipts = response.data!;
      } else {
        _setError(response.error ?? 'Failed to fetch receipts');
      }
    } catch (e) {
      _setError('Error fetching receipts: $e');
    } finally {
      _setLoading(false);
    }
  }

  void setSelectedReceipt(Map<String, dynamic>? receipt) {
    _selectedReceipt = receipt;
    notifyListeners();
  }

  void clearSelectedReceipt() {
    _selectedReceipt = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    if (error != null) debugPrint('ReceiptsProvider error: $error');
    notifyListeners();
  }

  void _clearError() => _error = null;
}
