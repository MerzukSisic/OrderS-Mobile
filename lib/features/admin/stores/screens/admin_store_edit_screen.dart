import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:orders_mobile/core/theme/app_colors.dart';
import 'package:orders_mobile/core/widgets/admin_scaffold.dart';
import 'package:orders_mobile/features/admin/stores/widgets/add_store_product_dialog.dart';
import 'package:orders_mobile/models/inventory/store_model.dart';
import 'package:orders_mobile/models/inventory/store_product_model.dart';
import 'package:orders_mobile/providers/business_providers.dart';
import 'package:orders_mobile/routes/app_router.dart';

class AdminStoreEditScreen extends StatefulWidget {
  final Store store;
  const AdminStoreEditScreen({super.key, required this.store});

  @override
  State<AdminStoreEditScreen> createState() => _AdminStoreEditScreenState();
}

class _AdminStoreEditScreenState extends State<AdminStoreEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _addressCtrl;
  late bool _isExternal;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.store.name);
    _addressCtrl = TextEditingController(text: widget.store.location ?? '');
    _isExternal = widget.store.isExternal;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<InventoryProvider>().fetchStoreProducts(storeId: widget.store.id);
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final success = await context.read<StoresProvider>().updateStore(
            widget.store.id,
            name: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
            address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
            isExternal: _isExternal,
          );
      if (!mounted) return;
      _showSnackBar(
        success ? 'Store updated successfully' : (context.read<StoresProvider>().error ?? 'Failed to update store'),
        success ? AppColors.success : AppColors.error,
      );
      if (success) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _showDeleteProductDialog(StoreProductModel product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Product', style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'Delete "${product.name}"? This cannot be undone.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await context
                  .read<InventoryProvider>()
                  .deleteStoreProduct(product.id, storeId: widget.store.id);
              if (mounted) {
                _showSnackBar(
                  success ? 'Product deleted' : 'Failed to delete product',
                  success ? AppColors.success : AppColors.error,
                );
              }
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
      title: 'Edit ${widget.store.name}',
      currentRoute: AppRouter.adminStores,
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Store info card ────────────────────────────────────────
            Form(
              key: _formKey,
              child: _buildCard(children: [
                _buildSectionTitle('Store Information', Icons.store_outlined),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _nameCtrl,
                  label: 'Store Name *',
                  hint: 'e.g. Main Warehouse',
                  icon: Icons.store_outlined,
                  validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _addressCtrl,
                  label: 'Address (optional)',
                  hint: 'e.g. 123 Main Street',
                  icon: Icons.location_on_outlined,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.business_outlined, color: AppColors.primary, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('External supplier', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                            Text(
                              _isExternal
                                  ? 'External supplier (products ordered from here)'
                                  : 'Internal store/warehouse',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary.withValues(alpha: 0.7)),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isExternal,
                        onChanged: (v) => setState(() => _isExternal = v),
                        activeThumbColor: AppColors.primary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _handleSave,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save, size: 18),
                  label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ]),
            ),

            const SizedBox(height: 16),

            // ── Store products card ────────────────────────────────────
            _buildCard(children: [
              Row(
                children: [
                  Expanded(child: _buildSectionTitle('Store Products', Icons.inventory_2_outlined)),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final invProvider = context.read<InventoryProvider>();
                      await showDialog(
                        context: context,
                        builder: (_) => AddStoreProductDialog(
                          store: widget.store,
                          existingNames: invProvider.storeProducts
                              .where((p) => p.storeId == widget.store.id)
                              .map((p) => p.name.toLowerCase())
                              .toSet(),
                          onAdded: () => invProvider.fetchStoreProducts(storeId: widget.store.id),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Product'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Consumer<InventoryProvider>(
                builder: (context, invProvider, _) {
                  if (invProvider.isLoading) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                    );
                  }
                  final products = invProvider.storeProducts
                      .where((p) => p.storeId == widget.store.id)
                      .toList();
                  if (products.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 40, color: AppColors.textSecondary.withValues(alpha: 0.3)),
                            const SizedBox(height: 8),
                            Text('No products yet. Add the first one.', style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.6))),
                          ],
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: products.map((p) => _buildProductRow(p)).toList(),
                  );
                },
              ),
            ]),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildProductRow(StoreProductModel product) {
    final isLow = product.isLowStock;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isLow ? AppColors.warning.withValues(alpha: 0.4) : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: (isLow ? AppColors.warning : AppColors.primary).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              size: 16,
              color: isLow ? AppColors.warning : AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        product.name,
                        style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isLow) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('Low Stock', style: TextStyle(color: AppColors.warning, fontSize: 10, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${product.currentStock} / min ${product.minimumStock} ${product.unit}  ·  ${product.purchasePrice.toStringAsFixed(2)} KM',
                  style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.7), fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            onPressed: () => _showDeleteProductDialog(product),
            tooltip: 'Delete',
            color: AppColors.error,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(width: 8),
        Expanded(child: Divider(color: AppColors.primary.withValues(alpha: 0.2))),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.5)),
            prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
            filled: true,
            fillColor: AppColors.surfaceVariant,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.error)),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          ),
        ),
      ],
    );
  }
}
