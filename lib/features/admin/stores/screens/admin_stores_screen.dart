import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import 'package:orders_mobile/core/theme/app_colors.dart';
import 'package:orders_mobile/core/utils/app_notification.dart';
import 'package:orders_mobile/core/widgets/admin_scaffold.dart';
import 'package:orders_mobile/core/widgets/app_search_bar.dart';
import 'package:orders_mobile/models/inventory/store_model.dart';
import 'package:orders_mobile/providers/business_providers.dart';
import 'package:orders_mobile/routes/app_router.dart';

class AdminStoresScreen extends StatefulWidget {
  const AdminStoresScreen({super.key});

  @override
  State<AdminStoresScreen> createState() => _AdminStoresScreenState();
}

class _AdminStoresScreenState extends State<AdminStoresScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _typeFilter = 'all';
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback(
      (_) => context.read<StoresProvider>().fetchStores(),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Store> _filterStores(List<Store> stores) {
    var filtered = stores;

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered
          .where((s) =>
              s.name.toLowerCase().contains(q) ||
              (s.location?.toLowerCase().contains(q) ?? false))
          .toList();
    }

    if (_typeFilter == 'external') {
      filtered = filtered.where((s) => s.isExternal).toList();
    } else if (_typeFilter == 'internal') {
      filtered = filtered.where((s) => !s.isExternal).toList();
    }

    if (_statusFilter == 'active') {
      filtered = filtered.where((s) => s.isActive).toList();
    } else if (_statusFilter == 'inactive') {
      filtered = filtered.where((s) => !s.isActive).toList();
    }

    return filtered;
  }

  void _showDeleteDialog(Store store) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Store'),
        content: Text('Delete "${store.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final provider = context.read<StoresProvider>();
              final success = await provider.deleteStore(store.id);
              if (!mounted) return;
              AppNotification.show(
                context,
                success
                    ? 'Store deleted'
                    : 'Failed to delete store. Please try again.',
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
      title: 'Stores',
      currentRoute: AppRouter.adminStores,
      backgroundColor: AppColors.background,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
          onPressed: () => context.read<StoresProvider>().fetchStores(),
          tooltip: 'Refresh',
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final provider = context.read<StoresProvider>();
          final result =
              await Navigator.pushNamed(context, AppRouter.adminStoreCreate);
          if (result == true && mounted) {
            provider.fetchStores();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('New Store'),
        backgroundColor: AppColors.primary,
      ),
      body: Column(
        children: [
          // Search + Filters header
          Container(
            color: AppColors.surface,
            child: Column(
              children: [
                AppSearchBar(
                  controller: _searchController,
                  hintText: 'Search stores...',
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  onChanged: (v) =>
                      setState(() => _searchQuery = v.toLowerCase()),
                ),
                // Type filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                  child: Row(
                    children: [
                      _chip(
                        label: 'All',
                        selected: _typeFilter == 'all',
                        onTap: () => setState(() => _typeFilter = 'all'),
                      ),
                      const SizedBox(width: 8),
                      _chip(
                        label: 'Internal',
                        selected: _typeFilter == 'internal',
                        onTap: () => setState(() => _typeFilter = 'internal'),
                      ),
                      const SizedBox(width: 8),
                      _chip(
                        label: 'External',
                        selected: _typeFilter == 'external',
                        onTap: () => setState(() => _typeFilter = 'external'),
                      ),
                    ],
                  ),
                ),
                // Status filter
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
                        label: 'Active',
                        selected: _statusFilter == 'active',
                        onTap: () => setState(() => _statusFilter = 'active'),
                      ),
                      const SizedBox(width: 8),
                      _chip(
                        label: 'Inactive',
                        selected: _statusFilter == 'inactive',
                        onTap: () => setState(() => _statusFilter = 'inactive'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: Consumer<StoresProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading && provider.stores.isEmpty) {
                  return const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary));
                }
                if (provider.error != null && provider.stores.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Failed to load stores. Please try again.',
                          style: TextStyle(color: AppColors.error),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => provider.fetchStores(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final filtered = _filterStores(provider.stores);

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.store_outlined,
                            size: 64,
                            color:
                                AppColors.textSecondary.withValues(alpha: 0.4)),
                        const SizedBox(height: 16),
                        Text(
                          provider.stores.isEmpty
                              ? 'No stores yet'
                              : 'No stores match your filters',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: provider.fetchStores,
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) => _buildStoreCard(filtered[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreCard(Store store) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: (store.isExternal ? AppColors.warning : AppColors.primary)
                .withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            store.isExternal ? Icons.storefront : Icons.warehouse,
            color: store.isExternal ? AppColors.warning : AppColors.primary,
          ),
        ),
        title: Text(store.name,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (store.location != null && store.location!.isNotEmpty)
              Text(store.location!,
                  style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Row(
              children: [
                _Badge(
                  label: store.isExternal ? 'External' : 'Internal',
                  color:
                      store.isExternal ? AppColors.warning : AppColors.primary,
                ),
                const SizedBox(width: 6),
                _Badge(
                  label: store.isActive ? 'Active' : 'Inactive',
                  color: store.isActive ? AppColors.success : AppColors.error,
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              color: AppColors.primary,
              onPressed: () async {
                final provider = context.read<StoresProvider>();
                final result = await Navigator.pushNamed(
                  context,
                  AppRouter.adminStoreEdit,
                  arguments: store,
                );
                if (result == true && mounted) {
                  provider.fetchStores();
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              color: AppColors.error,
              onPressed: () => _showDeleteDialog(store),
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
