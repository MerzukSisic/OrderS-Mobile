import 'package:flutter/material.dart';
import 'package:orders_mobile/core/services/api/misc_api_services.dart';
import 'package:orders_mobile/core/theme/app_colors.dart';
import 'package:orders_mobile/core/utils/app_notification.dart';
import 'package:orders_mobile/core/utils/formatters.dart';
import 'package:orders_mobile/core/widgets/admin_scaffold.dart';
import 'package:orders_mobile/features/orders/widgets/order_status_badge.dart';
import 'package:orders_mobile/models/orders/order_model.dart';
import 'package:orders_mobile/models/receipts/receipt_model.dart';
import 'package:orders_mobile/providers/orders_provider.dart';
import 'package:orders_mobile/routes/app_router.dart';
import 'package:provider/provider.dart';


class AdminOrderDetailScreen extends StatefulWidget {
  final OrderModel order;

  const AdminOrderDetailScreen({
    super.key,
    required this.order,
  });

  @override
  State<AdminOrderDetailScreen> createState() => _AdminOrderDetailScreenState();
}

class _AdminOrderDetailScreenState extends State<AdminOrderDetailScreen> {
  Future<void> _updateOrderStatus(String newStatus) async {
    final ordersProvider = context.read<OrdersProvider>();

    // Confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Order Status'),
        content: Text(
          'Are you sure you want to change the order status to "$newStatus"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final success = await ordersProvider.updateOrderStatus(
      orderId: widget.order.id,
      status: newStatus,
    );

    if (!mounted) return;

    Navigator.pop(context); // Close loading

    if (success) {
      AppNotification.success(context, 'Order status updated to $newStatus');
      Navigator.pop(context); // Go back to list
    } else {
      AppNotification.error(context, 'Failed to update order status. Please try again.');
    }
  }

  Future<void> _deleteOrder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive Order'),
        content: const Text(
          'Are you sure you want to archive this order? '
          'The order will be cancelled and no data will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
            ),
            child: const Text('Archive'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final success =
        await context.read<OrdersProvider>().softDeleteOrder(widget.order.id);

    if (!mounted) return;

    Navigator.pop(context); // Close loading

    if (success) {
      AppNotification.success(context, 'Order archived successfully');
      Navigator.pop(context); // Go back to list
    } else {
      AppNotification.error(context, 'Failed to archive order. Please try again.');
    }
  }

  double _calculateSubtotal() {
    return widget.order.totalAmount;
  }

  double _calculateTax() {
    final subtotal = _calculateSubtotal();
    return subtotal * 0.17;
  }

  String _safeCurrency(double value) {
    try {
      final s = Formatters.currency(value);
      if (s.trim().isNotEmpty) return s;
    } catch (_) {}
    return '${value.toStringAsFixed(2)} KM';
  }

  void _showNotification(String message, {bool isError = false}) {
    if (!mounted) return;
    AppNotification.show(context, message, isError: isError);
  }

  void _showReceiptsDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.4,
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text('Receipts', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildReceiptTile(context, icon: Icons.person, title: 'Customer Receipt', subtitle: 'Complete receipt with pricing', color: AppColors.primary, onTap: () => _fetchAndShowCustomerReceipt(context)),
                  const SizedBox(height: 12),
                  _buildReceiptTile(context, icon: Icons.restaurant, title: 'Kitchen Receipt', subtitle: 'Kitchen items only', color: AppColors.success, onTap: () => _fetchAndShowKitchenReceipt(context)),
                  const SizedBox(height: 12),
                  _buildReceiptTile(context, icon: Icons.local_bar, title: 'Bar Receipt', subtitle: 'Bar items only', color: AppColors.info, onTap: () => _fetchAndShowBarReceipt(context)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptTile(BuildContext context, {required IconData icon, required String title, required String subtitle, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(subtitle, style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.8), fontSize: 13)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchAndShowCustomerReceipt(BuildContext ctx) async {
    Navigator.pop(ctx);
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    try {
      final response = await ReceiptsApiService().getCustomerReceipt(widget.order.id);
      if (!mounted) return;
      Navigator.pop(context);
      if (response.success && response.data != null) {
        _showCustomerReceiptView(context, CustomerReceiptModel.fromJson(response.data!));
      } else {
        _showNotification('Failed to load receipt: ${response.error}', isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showNotification('Error loading receipt: $e', isError: true);
    }
  }

  Future<void> _fetchAndShowKitchenReceipt(BuildContext ctx) async {
    Navigator.pop(ctx);
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    try {
      final response = await ReceiptsApiService().getKitchenReceipt(widget.order.id);
      if (!mounted) return;
      Navigator.pop(context);
      if (response.success && response.data != null) {
        _showKitchenReceiptView(context, KitchenReceiptModel.fromJson(response.data!));
      } else {
        _showNotification('No kitchen items in this order', isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showNotification('Error loading receipt: $e', isError: true);
    }
  }

  Future<void> _fetchAndShowBarReceipt(BuildContext ctx) async {
    Navigator.pop(ctx);
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    try {
      final response = await ReceiptsApiService().getBarReceipt(widget.order.id);
      if (!mounted) return;
      Navigator.pop(context);
      if (response.success && response.data != null) {
        _showBarReceiptView(context, BarReceiptModel.fromJson(response.data!));
      } else {
        _showNotification('No bar items in this order', isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showNotification('Error loading receipt: $e', isError: true);
    }
  }

  void _showCustomerReceiptView(BuildContext context, CustomerReceiptModel receipt) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Customer Receipt', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Order: ${receipt.orderNumber}', style: const TextStyle(fontSize: 16)),
                      if (receipt.tableNumber != null) Text('Table: ${receipt.tableNumber}'),
                      Text('Waiter: ${receipt.waiterName}'),
                      Text('Date: ${Formatters.dateTime(receipt.createdAt)}'),
                      const Divider(height: 32),
                      ...receipt.items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text('${item.productName} × ${item.quantity}', style: const TextStyle(fontWeight: FontWeight.w600))),
                                Text(_safeCurrency(item.subtotal), style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            if (item.unitPrice > 0)
                              Text('${_safeCurrency(item.unitPrice)} each', style: TextStyle(fontSize: 12, color: AppColors.textSecondary.withValues(alpha: 0.7))),
                          ],
                        ),
                      )),
                      const Divider(height: 32),
                      _buildReceiptSummaryRow('Subtotal', _safeCurrency(receipt.subtotal)),
                      if (receipt.discount > 0) _buildReceiptSummaryRow('Discount', '-${_safeCurrency(receipt.discount)}'),
                      _buildReceiptSummaryRow('Tax (17%)', _safeCurrency(receipt.tax)),
                      const Divider(height: 16),
                      _buildReceiptSummaryRow('TOTAL', _safeCurrency(receipt.total), isTotal: true),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showKitchenReceiptView(BuildContext context, KitchenReceiptModel receipt) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(children: [Icon(Icons.restaurant, color: AppColors.success), SizedBox(width: 8), Text('Kitchen Receipt', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))]),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Order: ${receipt.orderNumber}', style: const TextStyle(fontSize: 16)),
                      if (receipt.tableNumber != null) Text('Table: ${receipt.tableNumber}'),
                      Text('Waiter: ${receipt.waiterName}'),
                      const Divider(height: 24),
                      ...receipt.items.map((item) => Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(8)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                                Text('× ${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              ],
                            ),
                            if (item.notes != null && item.notes!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(item.notes!, style: TextStyle(fontSize: 12, color: AppColors.warning, fontStyle: FontStyle.italic)),
                            ],
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBarReceiptView(BuildContext context, BarReceiptModel receipt) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(children: [Icon(Icons.local_bar, color: AppColors.info), SizedBox(width: 8), Text('Bar Receipt', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))]),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Order: ${receipt.orderNumber}', style: const TextStyle(fontSize: 16)),
                      if (receipt.tableNumber != null) Text('Table: ${receipt.tableNumber}'),
                      Text('Waiter: ${receipt.waiterName}'),
                      const Divider(height: 24),
                      ...receipt.items.map((item) => Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                            Text('× ${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: isTotal ? 16 : 14, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontSize: isTotal ? 18 : 14, fontWeight: FontWeight.bold, color: isTotal ? AppColors.primary : AppColors.textPrimary)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subtotal = _calculateSubtotal();
    final tax = _calculateTax();
    final total = subtotal + tax;

    return AdminScaffold(
      title: 'Order #${widget.order.id.substring(0, 8).toUpperCase()}',
      currentRoute: AppRouter.adminOrders,
      actions: [
        // ✅ Back button
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back to Orders',
        ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Action Buttons Row (Print, Delete)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showReceiptsDialog(context),
                  icon: const Icon(Icons.print),
                  label: const Text('Print'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _deleteOrder,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Order Overview Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.textSecondary.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Order Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      OrderStatusBadge(status: widget.order.status),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Order Details Grid
                  Wrap(
                    spacing: 32,
                    runSpacing: 20,
                    children: [
                      _InfoRow(
                        icon: Icons.access_time,
                        label: 'Created',
                        value: Formatters.dateTime(widget.order.createdAt),
                      ),
                      if (widget.order.completedAt != null)
                        _InfoRow(
                          icon: Icons.check_circle,
                          label: 'Completed',
                          value: Formatters.dateTime(widget.order.completedAt!),
                          valueColor: AppColors.success,
                        ),
                      _InfoRow(
                        icon: Icons.person,
                        label: 'Waiter',
                        value: widget.order.waiterName,
                      ),
                      _InfoRow(
                        icon: widget.order.type == 'DineIn'
                            ? Icons.restaurant
                            : Icons.takeout_dining,
                        label: 'Order Type',
                        value: widget.order.type == 'DineIn' ? 'Dine In' : 'Take Away',
                      ),
                      if (widget.order.tableNumber != null)
                        _InfoRow(
                          icon: Icons.table_restaurant,
                          label: 'Table',
                          value: widget.order.tableNumber.toString(),
                        ),
                      if (widget.order.isPartnerOrder)
                        _InfoRow(
                          icon: Icons.business,
                          label: 'Partner Order',
                          value: 'Yes',
                          valueColor: AppColors.info,
                        ),
                    ],
                  ),

                  if (widget.order.notes != null && widget.order.notes!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.note_alt,
                          size: 20,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Order Notes',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.order.notes!,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Order Items Section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.textSecondary.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Order Items',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${widget.order.items.length} ${widget.order.items.length == 1 ? 'item' : 'items'}',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Items List
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.order.items.length,
                    separatorBuilder: (context, index) => const Divider(height: 32),
                    itemBuilder: (context, index) {
                      final item = widget.order.items[index];
                      return _OrderItemRow(item: item);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Order Summary
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.textSecondary.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Order Summary',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _SummaryRow('Subtotal', _safeCurrency(subtotal)),
                  const SizedBox(height: 12),
                  _SummaryRow('Tax (17% PDV)', _safeCurrency(tax)),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(),
                  ),
                  _SummaryRow(
                    'Total',
                    _safeCurrency(total),
                    isTotal: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Action Buttons
            if (widget.order.status != 'Completed' && widget.order.status != 'Cancelled')
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  if (widget.order.status == 'Pending')
                    _ActionButton(
                      label: 'Mark as Preparing',
                      icon: Icons.restaurant,
                      color: AppColors.warning,
                      onPressed: () => _updateOrderStatus('Preparing'),
                    ),
                  if (widget.order.status == 'Preparing')
                    _ActionButton(
                      label: 'Mark as Ready',
                      icon: Icons.check_circle_outline,
                      color: AppColors.info,
                      onPressed: () => _updateOrderStatus('Ready'),
                    ),
                  if (widget.order.status == 'Ready' || widget.order.status == 'Preparing')
                    _ActionButton(
                      label: 'Complete Order',
                      icon: Icons.done_all,
                      color: AppColors.success,
                      onPressed: () => _updateOrderStatus('Completed'),
                    ),
                  _ActionButton(
                    label: 'Cancel Order',
                    icon: Icons.cancel_outlined,
                    color: AppColors.error,
                    onPressed: () => _updateOrderStatus('Cancelled'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: AppColors.textSecondary.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OrderItemRow extends StatelessWidget {
  final OrderItem item;

  const _OrderItemRow({required this.item});

  String _safeCurrency(double value) {
    try {
      final s = Formatters.currency(value);
      if (s.trim().isNotEmpty) return s;
    } catch (_) {}
    return '${value.toStringAsFixed(2)} KM';
  }

  Color _getItemStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return AppColors.statusPending;
      case 'Preparing':
        return AppColors.statusPreparing;
      case 'Ready':
        return AppColors.statusReady;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accompaniments = item.selectedAccompaniments;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product Icon
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            item.preparationLocation == 'Kitchen' 
                ? Icons.restaurant_menu
                : Icons.local_bar,
            color: AppColors.textSecondary,
            size: 28,
          ),
        ),

        const SizedBox(width: 16),

        // Item Details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      item.productName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getItemStatusColor(item.status).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.status,
                      style: TextStyle(
                        color: _getItemStatusColor(item.status),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  Icon(
                    item.preparationLocation == 'Kitchen' 
                        ? Icons.kitchen 
                        : Icons.local_bar,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    item.preparationLocation,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Qty: ${item.quantity}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),

              // Accompaniments
              if (accompaniments.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Prilozi:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ...accompaniments.map((acc) => Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                acc.name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            if (acc.extraCharge > 0)
                              Text(
                                '+${_safeCurrency(acc.extraCharge)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
              ],

              // Item Notes
              if (item.notes != null && item.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.comment,
                        size: 14,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item.notes!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textPrimary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Price Row
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${_safeCurrency(item.unitPrice)} × ${item.quantity} = ',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    _safeCurrency(item.subtotal),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;

  const _SummaryRow(
    this.label,
    this.value, {
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 18 : 15,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isTotal ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 22 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: isTotal ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: AppColors.white),
      label: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: AppColors.white,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}