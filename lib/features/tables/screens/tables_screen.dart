import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/tables_provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../routes/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/shared/widgets/bottom_nav_bar.dart';
import '../../../models/table_model.dart';

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
      body: Consumer<TablesProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
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
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 0),
    );
  }

  void _handleTableTap(TableModel table) {
    final cartProvider = context.read<CartProvider>();
    cartProvider.setSelectedTable(table);
    AppRouter.navigateTo(context, AppRouter.products);
  }

  void _handleNewOrder() {
    final cartProvider = context.read<CartProvider>();
    cartProvider.setSelectedTable(null);
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.table_restaurant_rounded,
              size: 48,
              color: _statusColor,
            ),
            const SizedBox(height: 12),
            Text(
              'Table ',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
    );
  }
}
