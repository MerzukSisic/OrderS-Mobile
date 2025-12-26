import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/tables_provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/orders_provider.dart';
import '../../../providers/products_provider.dart';
import '../../../routes/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/shared/widgets/bottom_nav_bar.dart';
import '../../../models/table_model.dart';
import '../../../core/widgets/error_display.dart';
import '../../../core/widgets/loading_indicator.dart';

class TablesScreen extends StatefulWidget {
  const TablesScreen({super.key});

  @override
  State<TablesScreen> createState() => _TablesScreenState();
}

class _TablesScreenState extends State<TablesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TablesProvider>().fetchTables();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tables'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => context.read<TablesProvider>().fetchTables(),
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<TablesProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) {
              return const LoadingIndicator();
            }

            if (provider.error != null) {
              return ErrorDisplay(
                message: provider.error!,
                onRetry: () => context.read<TablesProvider>().fetchTables(),
              );
            }

            if (provider.tables.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.table_restaurant_rounded,
                      size: 64,
                      color: AppColors.textSecondary.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No tables available',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.3,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: provider.tables.length,
                    itemBuilder: (context, index) {
                      final table = provider.tables[index];
                      return _TableCard(
                        table: table,
                        onTap: () => _handleTableTap(table),
                      );
                    },
                  ),
                ),

                // New Order Button (bez stola)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: () => _handleNewOrder(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_rounded, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'New Order',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 0),
    );
  }

  Future<void> _handleTableTap(TableModel table) async {
    final cart = context.read<CartProvider>();

    final status = table.status.toLowerCase();
    final hasActiveOrder = table.currentOrderId != null;

    // If table is occupied and has an active order -> ask what to do
    if (status == 'occupied' && hasActiveOrder) {
      final choice = await showDialog<String>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: Text('Table ${table.tableNumber}'),
            content: const Text(
              'This table already has an active order. What would you like to do?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'cancel'),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'finish'),
                child: const Text('FINISH ORDER'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, 'add'),
                child: const Text('ADD ITEMS'),
              ),
            ],
          );
        },
      );

      if (!mounted || choice == null || choice == 'cancel') return;

      // Finish existing order
      if (choice == 'finish') {
        final orders = context.read<OrdersProvider>();
        final ok = await orders.updateOrderStatus(
          orderId: table.currentOrderId!,
          status: 'Completed',
        );

        if (!mounted) return;

        if (ok) {
          await context.read<TablesProvider>().fetchTables();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Order finished successfully.'),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(orders.error ?? 'Failed to finish order'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      // Add items to existing order: prefill cart from order, then go to products
      cart.clear();
      cart.setSelectedTable(table);
      cart.setActiveOrderId(table.currentOrderId);

      final orders = context.read<OrdersProvider>();
      final products = context.read<ProductsProvider>();

      if (products.products.isEmpty) {
        await products.fetchProducts();
      }

      final order = await orders.fetchOrderById(table.currentOrderId!);
      if (order != null) {
        for (final item in order.items) {
final p = products.getProductById(item.productId);
          if (p != null) {
            cart.addItem(p, item.quantity, notes: item.notes);
          }
        }
      }

      if (!mounted) return;
      AppRouter.navigateTo(context, AppRouter.products);
      return;
    }

    // New order on free table
    cart.clear();
    cart.setSelectedTable(table);
    cart.setActiveOrderId(null);

    if (!mounted) return;
    AppRouter.navigateTo(context, AppRouter.products);
  }

  void _handleNewOrder() {
    final cart = context.read<CartProvider>();
    cart.clear();
    cart.setSelectedTable(null);
    cart.setActiveOrderId(null);
    AppRouter.navigateTo(context, AppRouter.products);
  }
}

class _TableCard extends StatelessWidget {
  final TableModel table;
  final VoidCallback onTap;

  const _TableCard({
    required this.table,
    required this.onTap,
  });

  Color get _statusColor {
    switch (table.status) {
      case 'Available':
        return AppColors.success;
      case 'Occupied':
        return AppColors.error;
      case 'Reserved':
        return AppColors.warning;
      default:
        return AppColors.grey;
    }
  }

  IconData get _statusIcon {
    switch (table.status) {
      case 'Available':
        return Icons.check_circle_rounded;
      case 'Occupied':
        return Icons.people_rounded;
      case 'Reserved':
        return Icons.event_seat_rounded;
      default:
        return Icons.table_restaurant_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.surface,
              AppColors.surfaceVariant,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _statusColor.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.table_restaurant_rounded,
                    size: 48,
                    color: _statusColor,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Table',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _statusIcon,
                          size: 16,
                          color: _statusColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          table.status,
                          style: TextStyle(
                            color: _statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (table.location != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      table.location!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
