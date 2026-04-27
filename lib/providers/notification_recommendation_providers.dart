import 'package:flutter/foundation.dart';
import 'package:orders_mobile/core/services/api/misc_api_services.dart';
import 'package:orders_mobile/models/products/product_model.dart';

// ==================== NOTIFICATIONS PROVIDER ====================

class NotificationsProvider with ChangeNotifier {
  final NotificationsApiService _apiService = NotificationsApiService();

  // State
  List<Map<String, dynamic>> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Map<String, dynamic>> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasUnread => _unreadCount > 0;

  /// Get unread notifications
  List<Map<String, dynamic>> get unreadNotifications {
    return _notifications.where((n) => n['isRead'] == false).toList();
  }

  /// Get read notifications
  List<Map<String, dynamic>> get readNotifications {
    return _notifications.where((n) => n['isRead'] == true).toList();
  }

  /// Fetch notifications
  Future<void> fetchNotifications({
    bool? isRead,
    String? type,
    bool silent = false,
  }) async {
    if (!silent) {
      _setLoading(true);
    }
    _clearError();

    try {
      final response = await _apiService.getNotifications(
        isRead: isRead,
        type: type,
      );

      if (response.success && response.data != null) {
        _notifications = response.data!;
        await _fetchUnreadCount(); // Update unread count
      } else {
        _setError(response.error ?? 'Failed to fetch notifications');
      }
    } catch (e) {
      _setError('Error fetching notifications: $e');
    } finally {
      if (!silent) {
        _setLoading(false);
      }
    }
  }

  /// Fetch unread count
  Future<void> _fetchUnreadCount() async {
    try {
      final response = await _apiService.getUnreadCount();

      if (response.success && response.data != null) {
        _unreadCount = response.data!;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching unread count: $e');
    }
  }

  /// Mark notification as read
  Future<bool> markAsRead(String notificationId) async {
    _clearError();

    try {
      final response = await _apiService.markAsRead(notificationId);

      if (response.success) {
        // Update local state
        final index =
            _notifications.indexWhere((n) => n['id'] == notificationId);
        if (index != -1) {
          _notifications[index]['isRead'] = true;
          _unreadCount = (_unreadCount - 1).clamp(0, double.infinity).toInt();
          notifyListeners();
        }
        return true;
      } else {
        _setError(response.error ?? 'Failed to mark as read');
        return false;
      }
    } catch (e) {
      _setError('Error marking as read: $e');
      return false;
    }
  }

  /// Mark all as read
  Future<bool> markAllAsRead() async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.markAllAsRead();

      if (response.success) {
        await fetchNotifications(); // Refresh
        return true;
      } else {
        _setError(response.error ?? 'Failed to mark all as read');
        return false;
      }
    } catch (e) {
      _setError('Error marking all as read: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Delete notification
  Future<bool> deleteNotification(String notificationId) async {
    _clearError();

    try {
      final response = await _apiService.deleteNotification(notificationId);

      if (response.success) {
        _notifications.removeWhere((n) => n['id'] == notificationId);
        notifyListeners();
        return true;
      } else {
        _setError(response.error ?? 'Failed to delete notification');
        return false;
      }
    } catch (e) {
      _setError('Error deleting notification: $e');
      return false;
    }
  }

  /// Delete all read notifications
  Future<bool> deleteAllRead() async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.deleteAllRead();

      if (response.success) {
        await fetchNotifications(); // Refresh
        return true;
      } else {
        _setError(response.error ?? 'Failed to delete read notifications');
        return false;
      }
    } catch (e) {
      _setError('Error deleting read notifications: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Refresh notifications and unread count
  Future<void> refresh() async {
    await fetchNotifications(silent: true);
  }

  // ========== PRIVATE HELPERS ==========

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    if (error != null) {
      debugPrint('❌ Notifications Error: $error');
    }
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}

// ==================== RECOMMENDATIONS PROVIDER ====================

class RecommendationsProvider with ChangeNotifier {
  final RecommendationsApiService _apiService = RecommendationsApiService();

  // State
  List<ProductModel> _recommendedProducts = [];
  List<ProductModel> _popularProducts = [];
  List<ProductModel> _timeBasedProducts = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<ProductModel> get recommendedProducts => _recommendedProducts;
  List<ProductModel> get popularProducts => _popularProducts;
  List<ProductModel> get timeBasedProducts => _timeBasedProducts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetch recommended products
  Future<void> fetchRecommendedProducts({
    String? userId,
    int count = 5,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.getRecommendedProducts(
        userId: userId,
        count: count,
      );

      if (response.success && response.data != null) {
        _recommendedProducts = response.data!;
      } else {
        _setError(response.error ?? 'Failed to fetch recommendations');
      }
    } catch (e) {
      _setError('Error fetching recommendations: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch popular products
  Future<void> fetchPopularProducts({int count = 10}) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.getPopularProducts(count: count);

      if (response.success && response.data != null) {
        _popularProducts = response.data!;
      } else {
        _setError(response.error ?? 'Failed to fetch popular products');
      }
    } catch (e) {
      _setError('Error fetching popular products: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch time-based recommendations
  Future<void> fetchTimeBasedRecommendations({
    int? hour,
    int count = 5,
  }) async {
    _setLoading(true);
    _clearError();

    final currentHour = hour ?? DateTime.now().hour;

    try {
      final response = await _apiService.getTimeBasedRecommendations(
        hour: currentHour,
        count: count,
      );

      if (response.success && response.data != null) {
        _timeBasedProducts = response.data!;
      } else {
        _setError(
            response.error ?? 'Failed to fetch time-based recommendations');
      }
    } catch (e) {
      _setError('Error fetching time-based recommendations: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch all recommendations at once
  Future<void> fetchAllRecommendations({
    String? userId,
    int recommendedCount = 5,
    int popularCount = 10,
    int timeBasedCount = 5,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      await Future.wait([
        fetchRecommendedProducts(userId: userId, count: recommendedCount),
        fetchPopularProducts(count: popularCount),
        fetchTimeBasedRecommendations(count: timeBasedCount),
      ]);
    } catch (e) {
      _setError('Error fetching recommendations: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ========== PRIVATE HELPERS ==========

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    if (error != null) {
      debugPrint('❌ Recommendations Error: $error');
    }
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}

// ==================== RECEIPTS PROVIDER ====================

class ReceiptsProvider with ChangeNotifier {
  final ReceiptsApiService _apiService = ReceiptsApiService();

  // State
  List<Map<String, dynamic>> _receipts = [];
  Map<String, dynamic>? _selectedReceipt;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Map<String, dynamic>> get receipts => _receipts;
  Map<String, dynamic>? get selectedReceipt => _selectedReceipt;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetch receipt by order ID
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

  /// Fetch receipt by ID
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

  /// Fetch receipts with filters
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

  /// Set selected receipt
  void setSelectedReceipt(Map<String, dynamic>? receipt) {
    _selectedReceipt = receipt;
    notifyListeners();
  }

  /// Clear selected receipt
  void clearSelectedReceipt() {
    _selectedReceipt = null;
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
      debugPrint('❌ Receipts Error: $error');
    }
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}
