import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import 'package:orders_mobile/core/theme/app_colors.dart';
import 'package:orders_mobile/core/utils/app_notification.dart';
import 'package:orders_mobile/core/widgets/admin_scaffold.dart';
import 'package:orders_mobile/providers/business_providers.dart';
import 'package:orders_mobile/routes/app_router.dart';

class AdminProcurementCreateScreen extends StatefulWidget {
  const AdminProcurementCreateScreen({super.key});

  @override
  State<AdminProcurementCreateScreen> createState() =>
      _AdminProcurementCreateScreenState();
}

class _AdminProcurementCreateScreenState
    extends State<AdminProcurementCreateScreen> {
  final _searchController = TextEditingController();
  String? _selectedDestinationStoreId;
  String? _selectedSourceStoreId;

  // cart: storeProductId -> {quantity, unitCost, productName}
  final Map<String, Map<String, dynamic>> _cart = {};

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      await context.read<StoresProvider>().fetchStores();
    });
  }

  Future<void> _loadProductsForStore() async {
    if (_selectedSourceStoreId == null) return;
    await context
        .read<InventoryProvider>()
        .fetchStoreProducts(storeId: _selectedSourceStoreId!);
  }

  double _total() {
    double sum = 0;
    for (final item in _cart.values) {
      sum += (item['quantity'] as int) * (item['unitCost'] as double);
    }
    return sum;
  }

  Future<void> _continue() async {
    if (_selectedDestinationStoreId == null) {
      _snack('Please select a destination store', isError: true);
      return;
    }
    if (_cart.isEmpty) {
      _snack('Please select at least one item', isError: true);
      return;
    }

    // Validate cart quantities against current stock
    final products = context.read<InventoryProvider>().storeProducts;
    final overStock = <String>[];
    for (final entry in _cart.entries) {
      final product = products.where((p) => p.id == entry.key).firstOrNull;
      if (product == null) continue;
      final requestedQty = entry.value['quantity'] as int;
      if (requestedQty > product.currentStock) {
        overStock.add(
          '${product.name}: requested $requestedQty, available ${product.currentStock}',
        );
      }
    }
    if (overStock.isNotEmpty) {
      _snack(
        'Insufficient stock:\n${overStock.join('\n')}',
        isError: true,
      );
      return;
    }

    final items = _cart.entries.map((e) {
      return {
        'storeProductId': e.key,
        'quantity': e.value['quantity'],
        'unitCost': e.value['unitCost'],
        'productName': e.value['productName'],
      };
    }).toList();

    final result = await Navigator.pushNamed(
      context,
      AppRouter.procurementCheckout,
      arguments: {
        'storeId': _selectedDestinationStoreId,
        'sourceStoreId': _selectedSourceStoreId,
        'items': items,
      },
    );

    // if checkout returns true => clear cart
    if (result == true && mounted) {
      setState(() => _cart.clear());
      _snack('Procurement successfully created!');
      await _loadProductsForStore();
    }
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    AppNotification.show(context, msg, isError: isError);
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'New Procurement',
      currentRoute: AppRouter.procurementCreate,
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _TopPanel(
            searchController: _searchController,
            selectedDestinationStoreId: _selectedDestinationStoreId,
            selectedSourceStoreId: _selectedSourceStoreId,
            onDestinationStoreChanged: (storeId) {
              setState(() {
                _selectedDestinationStoreId = storeId;
              });
            },
            onSourceStoreChanged: (storeId) async {
              setState(() {
                _selectedSourceStoreId = storeId;
                _cart.clear();
              });
              await _loadProductsForStore();
            },
            onSearchChanged: (_) => setState(() {}),
          ),
          Expanded(
            child: _selectedSourceStoreId == null
                ? const _PickStoreHint()
                : Consumer<InventoryProvider>(
                    builder: (context, provider, _) {
                      if (provider.isLoading) {
                        return const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary),
                        );
                      }

                      if (provider.error != null) {
                        return _ErrorState(
                          message: provider.error!,
                          onRetry: _loadProductsForStore,
                        );
                      }

                      final query = _searchController.text.trim().toLowerCase();
                      final products = provider.storeProducts.where((p) {
                        if (query.isEmpty) return true;
                        return p.name.toLowerCase().contains(query);
                      }).toList();

                      if (products.isEmpty) {
                        return const _EmptyProducts();
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final p = products[index];
                          final isInCart = _cart.containsKey(p.id);
                          final qty =
                              isInCart ? (_cart[p.id]!['quantity'] as int) : 0;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _ProductCard(
                              name: p.name,
                              price: p.purchasePrice,
                              stock: p.currentStock,
                              minStock: p.minimumStock,
                              selectedQty: qty,
                              selected: isInCart,
                              onTap: p.currentStock == 0
                                  ? null
                                  : () => _openAddItemSheet(
                                        productId: p.id,
                                        productName: p.name,
                                        defaultUnitCost: p.purchasePrice,
                                        currentStock: p.currentStock,
                                      ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
          _BottomBar(
            itemsCount: _cart.length,
            total: _total(),
            onContinue: _continue,
          ),
        ],
      ),
    );
  }

  Future<void> _openAddItemSheet({
    required String productId,
    required String productName,
    required double defaultUnitCost,
    required int currentStock,
  }) async {
    final existing = _cart[productId];

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddItemSheet(
        productName: productName,
        initialQty: existing?['quantity'] as int? ?? 1,
        initialUnitCost: existing?['unitCost'] as double? ?? defaultUnitCost,
        maxStock: currentStock,
        onRemove: existing == null
            ? null
            : () => Navigator.pop(context, {'remove': true}),
      ),
    );

    if (result == null) return;

    if (result['remove'] == true) {
      setState(() => _cart.remove(productId));
      return;
    }

    setState(() {
      _cart[productId] = {
        'productName': productName,
        'quantity': result['quantity'],
        'unitCost': result['unitCost'],
      };
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class _TopPanel extends StatelessWidget {
  final TextEditingController searchController;
  final String? selectedDestinationStoreId;
  final String? selectedSourceStoreId;
  final ValueChanged<String?> onDestinationStoreChanged;
  final ValueChanged<String?> onSourceStoreChanged;
  final ValueChanged<String> onSearchChanged;

  const _TopPanel({
    required this.searchController,
    required this.selectedDestinationStoreId,
    required this.selectedSourceStoreId,
    required this.onDestinationStoreChanged,
    required this.onSourceStoreChanged,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        children: [
          Consumer<StoresProvider>(
            builder: (context, storesProvider, _) {
              final internalStores =
                  storesProvider.stores.where((s) => !s.isExternal).toList();
              final externalStores =
                  storesProvider.stores.where((s) => s.isExternal).toList();
              return Column(
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedDestinationStoreId,
                    decoration: InputDecoration(
                      labelText: 'Destination Store',
                      hintText: 'Select your store',
                      filled: true,
                      fillColor: AppColors.surfaceVariant,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                    items: internalStores
                        .map((s) =>
                            DropdownMenuItem(value: s.id, child: Text(s.name)))
                        .toList(),
                    onChanged: onDestinationStoreChanged,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: selectedSourceStoreId,
                    decoration: InputDecoration(
                      labelText: 'Source Store (Supplier)',
                      hintText: 'Select supplier store',
                      filled: true,
                      fillColor: AppColors.surfaceVariant,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                    items: externalStores
                        .map((s) =>
                            DropdownMenuItem(value: s.id, child: Text(s.name)))
                        .toList(),
                    onChanged: onSourceStoreChanged,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search products...',
              prefixIcon: Icon(Icons.search,
                  color: AppColors.textSecondary.withValues(alpha: 0.6)),
              filled: true,
              fillColor: AppColors.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _PickStoreHint extends StatelessWidget {
  const _PickStoreHint();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'First select a store',
        style:
            TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.85)),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final String name;
  final double price;
  final int stock;
  final int minStock;
  final bool selected;
  final int selectedQty;
  final VoidCallback? onTap;

  const _ProductCard({
    required this.name,
    required this.price,
    required this.stock,
    required this.minStock,
    required this.selected,
    required this.selectedQty,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final outOfStock = stock == 0;
    final lowStock = !outOfStock && stock < minStock;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Opacity(
        opacity: outOfStock ? 0.5 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: outOfStock
                  ? AppColors.error.withValues(alpha: 0.25)
                  : selected
                      ? AppColors.primary.withValues(alpha: 0.35)
                      : AppColors.textSecondary.withValues(alpha: 0.12),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.inventory_2_outlined,
                    color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text('${price.toStringAsFixed(2)} KM',
                        style: TextStyle(
                            color: AppColors.textSecondary
                                .withValues(alpha: 0.85))),
                    if (outOfStock) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('Out of Stock',
                            style: TextStyle(
                                color: AppColors.error,
                                fontWeight: FontWeight.w700,
                                fontSize: 11)),
                      ),
                    ] else if (lowStock) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('Low Stock ($stock)',
                            style: const TextStyle(
                                color: AppColors.warning,
                                fontWeight: FontWeight.w700,
                                fontSize: 11)),
                      ),
                    ],
                  ],
                ),
              ),
              if (selected)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text('x$selectedQty',
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w900)),
                )
              else if (!outOfStock)
                Icon(Icons.add_circle_outline,
                    color: AppColors.textSecondary.withValues(alpha: 0.7)),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddItemSheet extends StatefulWidget {
  final String productName;
  final int initialQty;
  final double initialUnitCost;
  final int maxStock;
  final VoidCallback? onRemove;

  const _AddItemSheet({
    required this.productName,
    required this.initialQty,
    required this.initialUnitCost,
    required this.maxStock,
    this.onRemove,
  });

  @override
  State<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<_AddItemSheet> {
  late int qty;
  late TextEditingController unitCostCtrl;

  @override
  void initState() {
    super.initState();
    qty = widget.initialQty;
    unitCostCtrl =
        TextEditingController(text: widget.initialUnitCost.toStringAsFixed(2));
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(widget.productName,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _FieldCard(
                  title: 'Quantity',
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed:
                            qty <= 1 ? null : () => setState(() => qty--),
                        icon: const Icon(Icons.remove),
                      ),
                      Column(
                        children: [
                          Text('$qty',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w900)),
                          Text('/ ${widget.maxStock}',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: qty >= widget.maxStock
                                      ? AppColors.error
                                      : AppColors.textSecondary
                                          .withValues(alpha: 0.7))),
                        ],
                      ),
                      IconButton(
                        onPressed: qty >= widget.maxStock
                            ? null
                            : () => setState(() => qty++),
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _FieldCard(
                  title: 'Unit Cost (KM)',
                  child: TextField(
                    controller: unitCostCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(border: InputBorder.none),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (widget.onRemove != null) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: widget.onRemove,
                    icon: const Icon(Icons.delete),
                    label: const Text('Remove'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      foregroundColor: AppColors.error,
                      side: BorderSide(
                          color: AppColors.error.withValues(alpha: 0.6)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final unitCost = double.tryParse(
                            unitCostCtrl.text.replaceAll(',', '.')) ??
                        0;
                    if (unitCost <= 0) return;

                    Navigator.pop(
                        context, {'quantity': qty, 'unitCost': unitCost});
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Add',
                      style: TextStyle(
                          color: AppColors.white, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    unitCostCtrl.dispose();
    super.dispose();
  }
}

class _FieldCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _FieldCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppColors.textSecondary.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                color: AppColors.textSecondary.withValues(alpha: 0.85),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              )),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int itemsCount;
  final double total;
  final VoidCallback onContinue;

  const _BottomBar(
      {required this.itemsCount,
      required this.total,
      required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (itemsCount > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Items:',
                    style: TextStyle(
                        color:
                            AppColors.textSecondary.withValues(alpha: 0.85))),
                Text('$itemsCount',
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, color: AppColors.primary)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total:',
                    style: TextStyle(
                        color:
                            AppColors.textSecondary.withValues(alpha: 0.85))),
                Text('${total.toStringAsFixed(2)} KM',
                    style: const TextStyle(fontWeight: FontWeight.w900)),
              ],
            ),
            const SizedBox(height: 10),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyProducts extends StatelessWidget {
  const _EmptyProducts();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'No products available',
        style:
            TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.85)),
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
