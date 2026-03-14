import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:orders_mobile/core/services/api/business_api_service.dart';
import 'package:orders_mobile/core/theme/app_colors.dart';
import 'package:orders_mobile/models/inventory/store_model.dart';
import 'package:orders_mobile/models/inventory/store_product_model.dart';
import 'package:orders_mobile/providers/business_providers.dart';

class AddStoreProductDialog extends StatefulWidget {
  final Store store;
  final Set<String> existingNames;
  final VoidCallback onAdded;

  const AddStoreProductDialog({
    super.key,
    required this.store,
    required this.existingNames,
    required this.onAdded,
  });

  @override
  State<AddStoreProductDialog> createState() => _AddStoreProductDialogState();
}

class _AddStoreProductDialogState extends State<AddStoreProductDialog> {
  final _inventoryApi = InventoryApiService();
  List<StoreProductModel> _allProducts = [];
  List<StoreProductModel> _filtered = [];
  StoreProductModel? _selected;
  bool _loading = true;
  String _search = '';
  final _searchCtrl = TextEditingController();
  final _currentStockCtrl = TextEditingController(text: '0');
  final _minimumStockCtrl = TextEditingController(text: '0');
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _currentStockCtrl.dispose();
    _minimumStockCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    final response = await _inventoryApi.getAllStoreProducts();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (response.success && response.data != null) {
        _allProducts = response.data!
            .where((p) => !widget.existingNames.contains(p.name.toLowerCase()))
            .toList();
        _filtered = _allProducts;
      }
    });
  }

  void _onSearch(String q) {
    setState(() {
      _search = q;
      _filtered = _allProducts.where((p) =>
        p.name.toLowerCase().contains(q.toLowerCase()) ||
        p.unit.toLowerCase().contains(q.toLowerCase()),
      ).toList();
    });
  }

  Future<void> _handleAdd() async {
    if (_selected == null) return;
    final currentStock = int.tryParse(_currentStockCtrl.text.trim()) ?? 0;
    final minimumStock = int.tryParse(_minimumStockCtrl.text.trim()) ?? 0;

    setState(() => _saving = true);
    final provider = context.read<InventoryProvider>();
    final success = await provider.createStoreProduct(
      storeId: widget.store.id,
      name: _selected!.name,
      description: _selected!.description,
      purchasePrice: _selected!.purchasePrice,
      currentStock: currentStock,
      minimumStock: minimumStock,
      unit: _selected!.unit,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (success) {
      widget.onAdded();
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(provider.error ?? 'Failed to add product'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.inventory_2_outlined, color: AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Add Product to Store',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.5)),
                  prefixIcon: const Icon(Icons.search, color: AppColors.primary, size: 20),
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onChanged: _onSearch,
              ),
            ),
            const SizedBox(height: 8),

            // Product list
            SizedBox(
              height: 220,
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _filtered.isEmpty
                      ? Center(
                          child: Text(
                            _search.isEmpty ? 'No products available' : 'No results',
                            style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.6)),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) {
                            final p = _filtered[i];
                            final isSelected = _selected?.id == p.id;
                            return ListTile(
                              selected: isSelected,
                              selectedTileColor: AppColors.primary.withValues(alpha: 0.1),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              leading: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: (isSelected ? AppColors.primary : AppColors.textSecondary).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.inventory_2_outlined, size: 14, color: isSelected ? AppColors.primary : AppColors.textSecondary),
                              ),
                              title: Text(
                                p.name,
                                style: TextStyle(color: AppColors.textPrimary, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal, fontSize: 14),
                              ),
                              subtitle: Text(
                                '${p.unit}  ·  ${p.purchasePrice.toStringAsFixed(2)} KM',
                                style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.7), fontSize: 12),
                              ),
                              trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.primary, size: 18) : null,
                              onTap: () => setState(() => _selected = p),
                            );
                          },
                        ),
            ),

            // Stock fields (shown when product is selected)
            if (_selected != null) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Set stock for "${_selected!.name}"',
                      style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _stockField(_currentStockCtrl, 'Current Stock')),
                        const SizedBox(width: 12),
                        Expanded(child: _stockField(_minimumStockCtrl, 'Minimum Stock')),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            // Actions
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _selected == null || _saving ? null : _handleAdd,
                    icon: _saving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.add, size: 16),
                    label: Text(_saving ? 'Adding...' : 'Add to Store'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stockField(TextEditingController ctrl, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surfaceVariant,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }
}
