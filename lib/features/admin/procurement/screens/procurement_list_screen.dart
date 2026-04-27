import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:orders_mobile/core/theme/app_colors.dart';
import 'package:orders_mobile/core/utils/app_notification.dart';
import 'package:orders_mobile/core/widgets/admin_scaffold.dart';
import 'package:orders_mobile/providers/procurement_payments_providers.dart';
import 'package:orders_mobile/routes/app_router.dart';

class AdminProcurementListScreen extends StatefulWidget {
  const AdminProcurementListScreen({super.key});

  @override
  State<AdminProcurementListScreen> createState() =>
      _AdminProcurementListScreenState();
}

class _AdminProcurementListScreenState
    extends State<AdminProcurementListScreen> {
  String _selectedFilter = 'all'; // all, pending, paid, received

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    await context.read<ProcurementProvider>().fetchProcurementOrders();
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Procurement',
      currentRoute: AppRouter.procurementList,
      backgroundColor: AppColors.background,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
          onPressed: _loadData,
          tooltip: 'Refresh',
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            Navigator.pushNamed(context, AppRouter.procurementCreate),
        icon: const Icon(Icons.add),
        label: const Text('New Procurement'),
        backgroundColor: AppColors.primary,
      ),
      body: Column(
        children: [
          // Filter header
          Consumer<ProcurementProvider>(
            builder: (ctx, provider, _) => Container(
              color: AppColors.surface,
              child: _FilterRow(
                selected: _selectedFilter,
                total: provider.procurementOrders.length,
                pending: provider.pendingOrders.length,
                paid: provider.paidOrders.length,
                received: provider.receivedOrders.length,
                onChanged: (v) => setState(() => _selectedFilter = v),
              ),
            ),
          ),

          // Content
          Expanded(
            child: Consumer<ProcurementProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading && provider.procurementOrders.isEmpty) {
                  return const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary));
                }

                if (provider.error != null &&
                    provider.procurementOrders.isEmpty) {
                  return _ErrorState(
                    message:
                        'Failed to load procurement orders. Please try again.',
                    onRetry: _loadData,
                  );
                }

                final orders = _applyFilter(provider.procurementOrders);

                return RefreshIndicator(
                  onRefresh: _loadData,
                  color: AppColors.primary,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _HeaderBlock(provider: provider),
                      const SizedBox(height: 12),
                      if (orders.isEmpty)
                        _EmptyState(
                          onCreate: () => Navigator.pushNamed(
                              context, AppRouter.procurementCreate),
                        )
                      else
                        ...orders.map((o) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _ProcurementOrderCard(
                                order: o,
                                onTap: () => _showOrderDialog(context, o),
                              ),
                            )),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<dynamic> _applyFilter(List<dynamic> orders) {
    switch (_selectedFilter) {
      case 'pending':
        return orders.where((o) => o.status == 'Pending').toList();
      case 'paid':
        return orders.where((o) => o.status == 'Paid').toList();
      case 'received':
        return orders.where((o) => o.status == 'Received').toList();
      default:
        return orders;
    }
  }

  void _showOrderDialog(BuildContext context, dynamic order) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(order.supplier ?? 'N/A'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${_translateStatus(order.status)}'),
            Text('Store: ${order.storeName ?? 'N/A'}'),
            Text(
                'Amount: ${(order.totalAmount as double).toStringAsFixed(2)} KM'),
            Text('Items: ${order.items.length}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (order.status == 'Pending')
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  AppRouter.procurementCheckout,
                  arguments: {
                    'existingOrderId': order.id,
                    'storeId': order.storeId ?? '',
                    'sourceStoreId': null,
                    'items': (order.items as List)
                        .map((item) => {
                              'productName': item.storeProductName,
                              'quantity': item.quantity,
                              'unitCost': item.unitCost,
                            })
                        .toList(),
                  },
                );
              },
              icon: const Icon(Icons.payment, size: 18),
              label: const Text('Pay Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          if (order.status == 'Paid')
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await _receiveOrder(order);
              },
              icon: const Icon(Icons.inventory_2, size: 18),
              label: const Text('Receive'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
              ),
            ),
          if (order.status == 'Paid' &&
              (order.stripePaymentIntentId as String?)?.isNotEmpty == true)
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showRefundDialog(context, order);
              },
              icon: const Icon(Icons.undo, size: 18),
              label: const Text('Refund'),
            ),
        ],
      ),
    );
  }

  void _showRefundDialog(BuildContext context, dynamic order) {
    final reasonController = TextEditingController();
    final amountController = TextEditingController(
      text: (order.totalAmount as double).toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Refund payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount (KM)',
                helperText: 'Leave the full paid amount for a full refund.',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: reasonController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Reason',
                hintText: 'Cancelled procurement, duplicate payment...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final amount = double.tryParse(
                amountController.text.trim().replaceAll(',', '.'),
              );
              if (amount == null || amount <= 0) {
                AppNotification.error(context, 'Enter a valid refund amount.');
                return;
              }

              Navigator.pop(dialogContext);
              await _refundOrder(
                paymentIntentId: order.stripePaymentIntentId as String,
                amount: amount,
                reason: reasonController.text.trim(),
              );
            },
            icon: const Icon(Icons.undo, size: 18),
            label: const Text('Refund'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    ).whenComplete(() {
      reasonController.dispose();
      amountController.dispose();
    });
  }

  Future<void> _refundOrder({
    required String paymentIntentId,
    required double amount,
    required String reason,
  }) async {
    final result = await context.read<PaymentsProvider>().createRefund(
          paymentIntentId: paymentIntentId,
          amount: amount,
          reason: reason.isEmpty ? 'Procurement refund' : reason,
        );

    if (!mounted) return;

    if (result != null) {
      AppNotification.success(context, 'Refund request created successfully');
      await _loadData();
    } else {
      final error = context.read<PaymentsProvider>().error ??
          'Failed to create refund. Please try again.';
      AppNotification.error(context, error);
    }
  }

  Future<void> _receiveOrder(dynamic order) async {
    final items = (order.items as List)
        .map((item) => {
              'itemId': item.id,
              'receivedQuantity': item.quantity,
            })
        .toList();

    final success =
        await context.read<ProcurementProvider>().receiveProcurement(
              procurementOrderId: order.id,
              items: items,
            );

    if (!mounted) return;

    if (success) {
      AppNotification.success(context, 'Order received — inventory updated');
    } else {
      AppNotification.error(
          context, 'Failed to receive order. Please try again.');
    }
  }

  String _translateStatus(String status) {
    switch (status) {
      case 'Pending':
        return 'Pending';
      case 'Paid':
        return 'Paid';
      case 'Received':
        return 'Received';
      case 'Cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }
}

class _HeaderBlock extends StatelessWidget {
  final ProcurementProvider provider;
  const _HeaderBlock({required this.provider});

  @override
  Widget build(BuildContext context) {
    final totalOrders = provider.procurementOrders.length;
    final pendingCount = provider.pendingOrders.length;
    final paidCount = provider.paidOrders.length;
    final totalAmount = provider.procurementOrders.fold<double>(
      0,
      (sum, o) => sum + (o.totalAmount),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppColors.textSecondary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Procurement Orders',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('Recent procurements, payments and statuses',
              style: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.8))),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _StatCard(
                      title: 'Total',
                      value: '$totalOrders',
                      icon: Icons.shopping_bag,
                      color: AppColors.primary)),
              const SizedBox(width: 12),
              Expanded(
                  child: _StatCard(
                      title: 'Pending',
                      value: '$pendingCount',
                      icon: Icons.pending,
                      color: AppColors.warning)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _StatCard(
                      title: 'Paid',
                      value: '$paidCount',
                      icon: Icons.check_circle,
                      color: AppColors.success)),
              const SizedBox(width: 12),
              Expanded(
                  child: _StatCard(
                      title: 'Value',
                      value: '${totalAmount.toStringAsFixed(0)} KM',
                      icon: Icons.attach_money,
                      color: Colors.green)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard(
      {required this.title,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: AppColors.textSecondary.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 11,
                        color:
                            AppColors.textSecondary.withValues(alpha: 0.85))),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  final String selected;
  final int total;
  final int pending;
  final int paid;
  final int received;
  final ValueChanged<String> onChanged;

  const _FilterRow({
    required this.selected,
    required this.total,
    required this.pending,
    required this.paid,
    required this.received,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, String key, int count) {
      final isSelected = selected == key;
      return FilterChip(
        label: Text('$label ($count)'),
        selected: isSelected,
        onSelected: (_) => onChanged(key),
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primary.withValues(alpha: 0.18),
        checkmarkColor: AppColors.primary,
        side: BorderSide(
            color: isSelected
                ? AppColors.primary
                : AppColors.textSecondary.withValues(alpha: 0.20)),
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primary : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          chip('All', 'all', total),
          const SizedBox(width: 8),
          chip('Pending', 'pending', pending),
          const SizedBox(width: 8),
          chip('Paid', 'paid', paid),
          const SizedBox(width: 8),
          chip('Received', 'received', received),
        ],
      ),
    );
  }
}

class _ProcurementOrderCard extends StatelessWidget {
  final dynamic order;
  final VoidCallback onTap;

  const _ProcurementOrderCard({required this.order, required this.onTap});

  Color _statusColor(String status) {
    switch (status) {
      case 'Pending':
        return AppColors.warning;
      case 'Paid':
        return AppColors.success;
      case 'Received':
        return AppColors.info;
      case 'Cancelled':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'Pending':
        return Icons.pending;
      case 'Paid':
        return Icons.check_circle;
      case 'Received':
        return Icons.inventory;
      case 'Cancelled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  String _statusText(String status) {
    switch (status) {
      case 'Pending':
        return 'Pending';
      case 'Paid':
        return 'Paid';
      case 'Received':
        return 'Received';
      case 'Cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sc = _statusColor(order.status);
    final si = _statusIcon(order.status);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AppColors.textSecondary.withValues(alpha: 0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    order.supplier ?? 'N/A',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: sc.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(si, color: sc, size: 14),
                      const SizedBox(width: 6),
                      Text(_statusText(order.status),
                          style: TextStyle(
                              color: sc,
                              fontWeight: FontWeight.w700,
                              fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(order.storeName ?? 'N/A',
                style: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.85))),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${(order.totalAmount as double).toStringAsFixed(2)} KM',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary),
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.calendar_today,
                        size: 14,
                        color: AppColors.textSecondary.withValues(alpha: 0.7)),
                    const SizedBox(width: 6),
                    Text(
                      DateFormat('dd.MM.yyyy').format(order.orderDate),
                      style: TextStyle(
                          color: AppColors.textSecondary.withValues(alpha: 0.8),
                          fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.inventory_2_outlined,
                    size: 14,
                    color: AppColors.textSecondary.withValues(alpha: 0.7)),
                const SizedBox(width: 6),
                Text('${order.items.length} item(s)',
                    style: TextStyle(
                        color: AppColors.textSecondary.withValues(alpha: 0.8),
                        fontSize: 12)),
                const Spacer(),
                Icon(Icons.chevron_right,
                    color: AppColors.textSecondary.withValues(alpha: 0.7)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreate;
  const _EmptyState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppColors.textSecondary.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          Icon(Icons.shopping_bag_outlined,
              size: 64, color: AppColors.textSecondary.withValues(alpha: 0.35)),
          const SizedBox(height: 16),
          const Text('No Procurements',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('Create your first procurement by clicking the button below',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.85))),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('New Procurement'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                size: 64, color: AppColors.error.withValues(alpha: 0.6)),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}
