import 'package:flutter/material.dart';
import 'package:orders_mobile/core/theme/app_colors.dart';
import 'package:orders_mobile/core/services/api/orders_api_service.dart';
import 'package:orders_mobile/core/utils/app_notification.dart';
import 'package:orders_mobile/core/utils/user_message.dart';
import 'package:orders_mobile/core/constants/app_constants.dart';
import 'package:orders_mobile/features/shared/widgets/bottom_nav_bar.dart';
import 'package:orders_mobile/models/orders/order_model.dart';

class KitchenOrdersScreen extends StatefulWidget {
  const KitchenOrdersScreen({super.key});

  @override
  State<KitchenOrdersScreen> createState() => _KitchenOrdersScreenState();
}

class _KitchenOrdersScreenState extends State<KitchenOrdersScreen>
    with SingleTickerProviderStateMixin {
  final OrdersApiService _apiService = OrdersApiService();
  late TabController _tabController;

  List<OrderItem> _pendingOrders = [];
  List<OrderItem> _preparingOrders = [];
  List<OrderItem> _readyOrders = [];

  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showNotification(String message, {bool isError = false}) {
    AppNotification.show(context, message, isError: isError);
  }

  Future<void> _loadOrders() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      debugPrint('🍳 Loading Kitchen orders...');

      final pendingResponse = await _apiService.getOrderItemsByLocation(
        location: 'Kitchen',
        status: AppConstants.orderStatusPending,
      );

      final preparingResponse = await _apiService.getOrderItemsByLocation(
        location: 'Kitchen',
        status: AppConstants.orderStatusPreparing,
      );

      final readyResponse = await _apiService.getOrderItemsByLocation(
        location: 'Kitchen',
        status: AppConstants.orderStatusReady,
      );

      if (mounted) {
        setState(() {
          if (pendingResponse.success && pendingResponse.data != null) {
            _pendingOrders = (pendingResponse.data as List)
                .map((json) => OrderItem.fromJson(json as Map<String, dynamic>))
                .toList();
          } else {
            _pendingOrders = [];
          }

          if (preparingResponse.success && preparingResponse.data != null) {
            _preparingOrders = (preparingResponse.data as List)
                .map((json) => OrderItem.fromJson(json as Map<String, dynamic>))
                .toList();
          } else {
            _preparingOrders = [];
          }

          if (readyResponse.success && readyResponse.data != null) {
            _readyOrders = (readyResponse.data as List)
                .map((json) => OrderItem.fromJson(json as Map<String, dynamic>))
                .toList();
          } else {
            _readyOrders = [];
          }

          _isLoading = false;

          debugPrint(
              '✅ Loaded: ${_pendingOrders.length} pending, ${_preparingOrders.length} preparing, ${_readyOrders.length} ready');
        });
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading orders: $e');
      debugPrint('Stack trace: $stackTrace');

      if (mounted) {
        setState(() {
          _error = UserMessage.friendly(
            e,
            fallback: 'We could not load kitchen orders. Please try again.',
          );
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateItemStatus(String itemId, String newStatus) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      debugPrint('🔄 Updating item $itemId to $newStatus');

      final response = await _apiService.updateOrderItemStatus(
        itemId: itemId,
        status: newStatus,
      );

      debugPrint('📝 Update response: ${response.success}, ${response.error}');

      if (!mounted) return;

      Navigator.pop(context);

      if (response.success) {
        await _loadOrders();

        if (mounted) {
          _showNotification('Order updated to $newStatus');
        }
      } else {
        if (mounted) {
          _showNotification(
            response.error ??
                'We could not update the order. Please try again.',
            isError: true,
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Update error: $e');

      if (mounted) {
        Navigator.pop(context);

        _showNotification(
          'Failed to update order. Please try again.',
          isError: true,
        );
      }
    }
  }

  Future<void> _showRejectDialog(String itemId, String productName) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to reject:'),
            const SizedBox(height: 8),
            Text(
              productName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'This will notify the waiter that the item cannot be prepared.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text(
              'Reject',
              style: TextStyle(color: AppColors.white),
            ),
          ),
        ],
      ),
    );

    if (result == true) {
      await _updateItemStatus(itemId, AppConstants.orderStatusCancelled);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPending = _pendingOrders.length;
    final totalActive = _preparingOrders.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Kitchen Orders'),
            if (totalPending > 0 || totalActive > 0)
              Text(
                '$totalPending pending • $totalActive in progress',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorWeight: 3,
          tabs: [
            Tab(
              child: _buildTabLabel(
                  AppConstants.orderStatusPending, _pendingOrders.length, AppColors.error),
            ),
            Tab(
              child: _buildTabLabel(
                  AppConstants.orderStatusPreparing, _preparingOrders.length, AppColors.warning),
            ),
            Tab(
              child: _buildTabLabel(
                  AppConstants.orderStatusReady, _readyOrders.length, AppColors.success),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadOrders,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadOrders,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOrdersList(_pendingOrders, AppConstants.orderStatusPending),
                      _buildOrdersList(_preparingOrders, AppConstants.orderStatusPreparing),
                      _buildOrdersList(_readyOrders, AppConstants.orderStatusReady),
                    ],
                  ),
                ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 0),
    );
  }

  Widget _buildTabLabel(String label, int count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label),
        if (count > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOrdersList(List<OrderItem> orders, String status) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_outlined,
              size: 64,
              color: AppColors.textSecondary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No $status orders',
              style: TextStyle(
                color: AppColors.textSecondary.withValues(alpha: 0.7),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Orders will appear here when waiters place them',
              style: TextStyle(
                color: AppColors.textSecondary.withValues(alpha: 0.5),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final item = orders[index];
        return _KitchenOrderCard(
          item: item,
          onAccept: status == AppConstants.orderStatusPending
              ? () => _updateItemStatus(item.id, AppConstants.orderStatusPreparing)
              : null,
          onReady: status == AppConstants.orderStatusPreparing
              ? () => _updateItemStatus(item.id, AppConstants.orderStatusReady)
              : null,
          onReject: status == AppConstants.orderStatusPending || status == AppConstants.orderStatusPreparing
              ? () => _showRejectDialog(item.id, item.productName)
              : null,
        );
      },
    );
  }
}

class _KitchenOrderCard extends StatelessWidget {
  final OrderItem item;
  final VoidCallback? onAccept;
  final VoidCallback? onReady;
  final VoidCallback? onReject;

  const _KitchenOrderCard({
    required this.item,
    this.onAccept,
    this.onReady,
    this.onReject,
  });

  String _getTimeAgo(DateTime? createdAt) {
    if (createdAt == null) return '';

    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final timeAgo = _getTimeAgo(item.createdAt);
    final isUrgent = item.createdAt != null &&
        DateTime.now().difference(item.createdAt!).inMinutes >
            15; // 15 min for kitchen

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUrgent
              ? AppColors.error
              : AppColors.textSecondary.withValues(alpha: 0.1),
          width: isUrgent ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with gradient
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.warning.withValues(alpha: 0.2),
                  AppColors.warning.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warning,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.restaurant,
                    color: AppColors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (timeAgo.isNotEmpty)
                        Row(
                          children: [
                            Icon(
                              isUrgent ? Icons.warning : Icons.access_time,
                              size: 14,
                              color: isUrgent
                                  ? AppColors.error
                                  : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              timeAgo,
                              style: TextStyle(
                                fontSize: 12,
                                color: isUrgent
                                    ? AppColors.error
                                    : AppColors.textSecondary,
                                fontWeight: isUrgent
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.warning,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '×${item.quantity}',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(item.status).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getStatusIcon(item.status),
                        size: 14,
                        color: _getStatusColor(item.status),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        item.status,
                        style: TextStyle(
                          color: _getStatusColor(item.status),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Accompaniments
                if (item.selectedAccompaniments.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.add_circle_outline,
                                size: 16, color: AppColors.warning),
                            SizedBox(width: 6),
                            Text(
                              'Extras:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.warning,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...item.selectedAccompaniments.map((acc) => Padding(
                              padding: const EdgeInsets.only(left: 22, top: 4),
                              child: Text(
                                '• ${acc.name}',
                                style: const TextStyle(fontSize: 13),
                              ),
                            )),
                      ],
                    ),
                  ),
                ],

                // Notes
                if (item.notes != null && item.notes!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.priority_high,
                            size: 18, color: AppColors.error),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.notes!,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Action Buttons
                if (onAccept != null ||
                    onReady != null ||
                    onReject != null) ...[
                  const SizedBox(height: 16),
                  if (onAccept != null)
                    Row(
                      children: [
                        if (onReject != null)
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: onReject,
                              icon: const Icon(Icons.close, size: 18),
                              label: const Text('Reject'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.error,
                                side: const BorderSide(
                                    color: AppColors.error, width: 2),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        if (onReject != null) const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: onAccept,
                            icon: const Icon(Icons.play_arrow,
                                color: AppColors.white),
                            label: const Text(
                              'Start Cooking',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (onReady != null)
                    Row(
                      children: [
                        if (onReject != null)
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: onReject,
                              icon: const Icon(Icons.close, size: 18),
                              label: const Text('Reject'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.error,
                                side: const BorderSide(
                                    color: AppColors.error, width: 2),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        if (onReject != null) const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: onReady,
                            icon: const Icon(Icons.check_circle,
                                color: AppColors.white),
                            label: const Text(
                              'Dish Ready',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.warning,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case AppConstants.orderStatusPending:
        return AppColors.warning;
      case AppConstants.orderStatusPreparing:
        return AppColors.info;
      case AppConstants.orderStatusReady:
        return AppColors.success;
      case AppConstants.orderStatusCancelled:
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case AppConstants.orderStatusPending:
        return Icons.schedule;
      case AppConstants.orderStatusPreparing:
        return Icons.refresh;
      case AppConstants.orderStatusReady:
        return Icons.check_circle;
      case AppConstants.orderStatusCancelled:
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }
}
