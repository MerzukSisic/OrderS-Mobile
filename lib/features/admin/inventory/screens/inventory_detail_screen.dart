import 'package:flutter/material.dart';
import 'package:orders_mobile/core/theme/app_colors.dart';
import 'package:orders_mobile/models/inventory/store_product_model.dart';
import '../widgets/adjust_inventory_dialog.dart';

class InventoryDetailScreen extends StatelessWidget {
  final dynamic product;

  const InventoryDetailScreen({super.key, required this.product});

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  String _getString(dynamic v) => v == null ? '' : v.toString();

  String _getProductName() {
    try {
      final v = (product as dynamic).productName;
      if (v != null) return _getString(v);
    } catch (_) {}

    try {
      final v = (product as dynamic).name;
      if (v != null) return _getString(v);
    } catch (_) {}

    return 'Product';
  }

  int _getCurrentStock() {
    try {
      return _toInt((product as dynamic).currentStock);
    } catch (_) {}

    try {
      return _toInt((product as dynamic).stock);
    } catch (_) {}

    try {
      return _toInt((product as dynamic).quantity);
    } catch (_) {}

    return 0;
  }

  int _getMinStockLevel() {
    try {
      return _toInt((product as dynamic).minStockLevel);
    } catch (_) {}

    try {
      return _toInt((product as dynamic).minimumStockLevel);
    } catch (_) {}

    try {
      return _toInt((product as dynamic).minStock);
    } catch (_) {}

    try {
      return _toInt((product as dynamic).minimumStock);
    } catch (_) {}

    return 0;
  }

  dynamic _tryGet(dynamic Function() getter) {
    try {
      return getter();
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = _getProductName();
    final currentStock = _getCurrentStock();
    final minStock = _getMinStockLevel();

    final id = _tryGet(() => (product as dynamic).id) ??
        _tryGet(() => (product as dynamic).storeProductId);

    final unit = _tryGet(() => (product as dynamic).unit) ??
        _tryGet(() => (product as dynamic).unitName);

    final category = _tryGet(() => (product as dynamic).categoryName) ??
        _tryGet(() => (product as dynamic).category);

    final price = _tryGet(() => (product as dynamic).price) ??
        _tryGet(() => (product as dynamic).salePrice);

    final isLow = currentStock > 0 && currentStock <= minStock;
    final isOut = currentStock == 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                if (id != null) _InfoRow(label: 'ID', value: _getString(id)),
                if (category != null)
                  _InfoRow(label: 'Category', value: _getString(category)),
                if (unit != null)
                  _InfoRow(label: 'Unit', value: _getString(unit)),
                if (price != null)
                  _InfoRow(label: 'Price', value: _getString(price)),
                const Divider(height: 24),
                _InfoRow(label: 'Stock', value: '$currentStock'),
                _InfoRow(label: 'Minimum Stock', value: '$minStock'),
                const SizedBox(height: 12),
                if (isOut)
                  _StatusChip(text: 'Out of stock', color: Colors.red)
                else if (isLow)
                  _StatusChip(text: 'Low stock', color: Colors.orange)
                else
                  _StatusChip(text: 'OK', color: Colors.green),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: product is StoreProductModel
                ? () async {
                    final result = await showDialog<bool>(
                      context: context,
                      builder: (_) => AdjustInventoryDialog(
                          product: product as StoreProductModel),
                    );
                    if (result == true && context.mounted) {
                      Navigator.pop(context);
                    }
                  }
                : null,
            icon: const Icon(Icons.edit),
            label: const Text('Edit Stock'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[400],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String text;
  final Color color;

  const _StatusChip({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
