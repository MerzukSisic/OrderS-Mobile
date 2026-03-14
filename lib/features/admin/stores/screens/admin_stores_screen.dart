import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import 'package:orders_mobile/core/theme/app_colors.dart';
import 'package:orders_mobile/core/widgets/admin_scaffold.dart';
import 'package:orders_mobile/models/inventory/store_model.dart';
import 'package:orders_mobile/providers/business_providers.dart';
import 'package:orders_mobile/routes/app_router.dart';

class AdminStoresScreen extends StatefulWidget {
  const AdminStoresScreen({super.key});

  @override
  State<AdminStoresScreen> createState() => _AdminStoresScreenState();
}

class _AdminStoresScreenState extends State<AdminStoresScreen> {
  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback(
      (_) => context.read<StoresProvider>().fetchStores(),
    );
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
              final messenger = ScaffoldMessenger.of(context);
              final success = await provider.deleteStore(store.id);
              messenger.showSnackBar(SnackBar(
                content: Text(success ? 'Store deleted' : provider.error ?? 'Failed to delete'),
                backgroundColor: success ? AppColors.success : AppColors.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Stores',
      currentRoute: AppRouter.adminStores,
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final provider = context.read<StoresProvider>();
          final result = await Navigator.pushNamed(context, AppRouter.adminStoreCreate);
          if (result == true && mounted) {
            provider.fetchStores();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('New Store'),
        backgroundColor: AppColors.primary,
      ),
      body: Consumer<StoresProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.stores.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (provider.error != null && provider.stores.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(provider.error!, style: TextStyle(color: AppColors.error)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => provider.fetchStores(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (provider.stores.isEmpty) {
            return const Center(child: Text('No stores yet'));
          }
          return RefreshIndicator(
            onRefresh: provider.fetchStores,
            color: AppColors.primary,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.stores.length,
              itemBuilder: (context, i) => _buildStoreCard(provider.stores[i]),
            ),
          );
        },
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
            color: (store.isExternal ? AppColors.warning : AppColors.primary).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            store.isExternal ? Icons.storefront : Icons.warehouse,
            color: store.isExternal ? AppColors.warning : AppColors.primary,
          ),
        ),
        title: Text(store.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (store.location != null && store.location!.isNotEmpty)
              Text(store.location!, style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Row(
              children: [
                _Badge(
                  label: store.isExternal ? 'External' : 'Internal',
                  color: store.isExternal ? AppColors.warning : AppColors.primary,
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
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
    );
  }
}
