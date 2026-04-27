import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import 'package:orders_mobile/core/theme/app_colors.dart';
import 'package:orders_mobile/core/utils/app_notification.dart';
import 'package:orders_mobile/core/widgets/admin_scaffold.dart';
import 'package:orders_mobile/core/widgets/app_search_bar.dart';
import 'package:orders_mobile/models/tables/table_model.dart';
import 'package:orders_mobile/providers/tables_provider.dart';
import 'package:orders_mobile/routes/app_router.dart';

class AdminTablesScreen extends StatefulWidget {
  const AdminTablesScreen({super.key});

  @override
  State<AdminTablesScreen> createState() => _AdminTablesScreenState();
}

class _AdminTablesScreenState extends State<AdminTablesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback(
      (_) => context.read<TablesProvider>().fetchTables(),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TableModel> _filterTables(List<TableModel> tables) {
    var filtered = tables;

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered
          .where((t) =>
              t.tableNumber.toLowerCase().contains(q) ||
              (t.location?.toLowerCase().contains(q) ?? false))
          .toList();
    }

    if (_statusFilter != 'all') {
      filtered = filtered
          .where((t) => t.status.toLowerCase() == _statusFilter)
          .toList();
    }

    return filtered;
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Available':
        return AppColors.success;
      case 'Occupied':
        return AppColors.error;
      case 'Reserved':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  void _showDeleteDialog(TableModel table) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Table'),
        content:
            Text('Delete table ${table.tableNumber}? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final provider = context.read<TablesProvider>();
              final success = await provider.deleteTable(table.id);
              if (!mounted) return;
              AppNotification.show(
                context,
                success
                    ? 'Table deleted'
                    : 'Failed to delete table. Please try again.',
                isError: !success,
              );
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.primary.withValues(alpha: 0.15),
      checkmarkColor: AppColors.primary,
      side: BorderSide(
        color:
            selected ? AppColors.primary : Colors.grey.withValues(alpha: 0.3),
      ),
      labelStyle: TextStyle(
        color: selected ? AppColors.primary : null,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        fontSize: 13,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Tables',
      currentRoute: AppRouter.adminTables,
      backgroundColor: AppColors.background,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
          onPressed: () => context.read<TablesProvider>().fetchTables(),
          tooltip: 'Refresh',
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final provider = context.read<TablesProvider>();
          final result =
              await Navigator.pushNamed(context, AppRouter.adminTableCreate);
          if (result == true && mounted) {
            provider.fetchTables();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('New Table'),
        backgroundColor: AppColors.primary,
      ),
      body: Column(
        children: [
          // Search + Status filter header
          Container(
            color: AppColors.surface,
            child: Column(
              children: [
                AppSearchBar(
                  controller: _searchController,
                  hintText: 'Search tables...',
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  onChanged: (v) =>
                      setState(() => _searchQuery = v.toLowerCase()),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Row(
                    children: [
                      _chip(
                        label: 'All',
                        selected: _statusFilter == 'all',
                        onTap: () => setState(() => _statusFilter = 'all'),
                      ),
                      const SizedBox(width: 8),
                      _chip(
                        label: 'Available',
                        selected: _statusFilter == 'available',
                        onTap: () =>
                            setState(() => _statusFilter = 'available'),
                      ),
                      const SizedBox(width: 8),
                      _chip(
                        label: 'Occupied',
                        selected: _statusFilter == 'occupied',
                        onTap: () => setState(() => _statusFilter = 'occupied'),
                      ),
                      const SizedBox(width: 8),
                      _chip(
                        label: 'Reserved',
                        selected: _statusFilter == 'reserved',
                        onTap: () => setState(() => _statusFilter = 'reserved'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: Consumer<TablesProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading && provider.tables.isEmpty) {
                  return const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary));
                }
                if (provider.error != null && provider.tables.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Failed to load tables. Please try again.',
                          style: TextStyle(color: AppColors.error),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => provider.fetchTables(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final filtered = _filterTables(provider.tables);

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.table_restaurant_outlined,
                            size: 64,
                            color:
                                AppColors.textSecondary.withValues(alpha: 0.4)),
                        const SizedBox(height: 16),
                        Text(
                          provider.tables.isEmpty
                              ? 'No tables yet'
                              : 'No tables match your filters',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: provider.fetchTables,
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) => _buildTableCard(filtered[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableCard(TableModel table) {
    final statusColor = _statusColor(table.status);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              table.tableNumber,
              style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
            ),
          ),
        ),
        title: Row(
          children: [
            Text('Table ${table.tableNumber}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            _Badge(label: table.status, color: statusColor),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.people_outline, size: 14),
              const SizedBox(width: 4),
              Text('Capacity: ${table.capacity}',
                  style: TextStyle(color: AppColors.textSecondary)),
            ]),
            if (table.location != null && table.location!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Row(children: [
                const Icon(Icons.location_on_outlined, size: 14),
                const SizedBox(width: 4),
                Text(table.location!,
                    style: TextStyle(color: AppColors.textSecondary)),
              ]),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              color: AppColors.primary,
              onPressed: () async {
                final provider = context.read<TablesProvider>();
                final result = await Navigator.pushNamed(
                  context,
                  AppRouter.adminTableEdit,
                  arguments: table,
                );
                if (result == true && mounted) {
                  provider.fetchTables();
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              color: AppColors.error,
              onPressed: () => _showDeleteDialog(table),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.bold, color: color)),
    );
  }
}
