import 'package:flutter/foundation.dart';
import 'package:orders_mobile/core/services/api/misc_api_services.dart';

class NotificationsProvider with ChangeNotifier {
  final NotificationsApiService _apiService = NotificationsApiService();

  List<Map<String, dynamic>> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasUnread => _unreadCount > 0;

  List<Map<String, dynamic>> get unreadNotifications =>
      _notifications.where((n) => n['isRead'] == false).toList();

  List<Map<String, dynamic>> get readNotifications =>
      _notifications.where((n) => n['isRead'] == true).toList();

  Future<void> fetchNotifications({
    bool? isRead,
    String? type,
    bool silent = false,
  }) async {
    if (!silent) _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.getNotifications(isRead: isRead, type: type);
      if (response.success && response.data != null) {
        _notifications = response.data!;
        await _fetchUnreadCount();
      } else {
        _setError(response.error ?? 'Failed to fetch notifications');
      }
    } catch (e) {
      _setError('Error fetching notifications: $e');
    } finally {
      if (!silent) _setLoading(false);
    }
  }

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

  Future<bool> markAsRead(String notificationId) async {
    _clearError();
    try {
      final response = await _apiService.markAsRead(notificationId);
      if (response.success) {
        final index = _notifications.indexWhere((n) => n['id'] == notificationId);
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

  Future<bool> markAllAsRead() async {
    _setLoading(true);
    _clearError();
    try {
      final response = await _apiService.markAllAsRead();
      if (response.success) {
        await fetchNotifications();
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

  Future<bool> deleteAllRead() async {
    _setLoading(true);
    _clearError();
    try {
      final response = await _apiService.deleteAllRead();
      if (response.success) {
        await fetchNotifications();
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

  Future<void> refresh() async => fetchNotifications(silent: true);

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    if (error != null) debugPrint('NotificationsProvider error: $error');
    notifyListeners();
  }

  void _clearError() => _error = null;
}
