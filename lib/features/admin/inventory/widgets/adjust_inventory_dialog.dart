import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:orders_mobile/core/theme/app_colors.dart';
import 'package:orders_mobile/models/inventory/store_product_model.dart';
import 'package:orders_mobile/providers/business_providers.dart';

class AdjustInventoryDialog extends StatefulWidget {
  final StoreProductModel product;

  const AdjustInventoryDialog({super.key, required this.product});

  @override
  State<AdjustInventoryDialog> createState() => _AdjustInventoryDialogState();
}

class _AdjustInventoryDialogState extends State<AdjustInventoryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _reasonController = TextEditingController();

  String _adjustmentType = 'addition';
  bool _isLoading = false;

  @override
  void dispose() {
    _quantityController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final quantity = int.parse(_quantityController.text);
      int quantityChange;
      String type;

      switch (_adjustmentType) {
        case 'addition':
          quantityChange = quantity;
          type = 'Addition';
          break;
        case 'subtraction':
          quantityChange = -quantity;
          type = 'Subtraction';
          break;
        case 'adjustment':
        default:
          quantityChange = quantity - widget.product.currentStock;
          type = 'Adjustment';
          break;
      }

      final provider = context.read<InventoryProvider>();
      final messenger = ScaffoldMessenger.of(context);
      final success = await provider.adjustInventory(
        storeProductId: widget.product.id,
        quantityChange: quantityChange,
        type: type,
        reason: _reasonController.text,
      );

      if (!mounted) return;
      if (success) {
        messenger.showSnackBar(const SnackBar(
          content: Text('Inventory adjusted successfully'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ));
        Navigator.pop(context, true);
      } else {
        messenger.showSnackBar(SnackBar(
          content: Text(provider.error ?? 'Failed to adjust inventory'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.edit, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Adjust Inventory', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        Text(widget.product.name,
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary.withValues(alpha: 0.8)),
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Current stock info
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Current Stock', style: TextStyle(fontSize: 11, color: AppColors.textSecondary.withValues(alpha: 0.8))),
                        const SizedBox(height: 2),
                        Text('${widget.product.currentStock} ${widget.product.unit}',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Min Stock', style: TextStyle(fontSize: 11, color: AppColors.textSecondary.withValues(alpha: 0.8))),
                        const SizedBox(height: 2),
                        Text('${widget.product.minimumStock} ${widget.product.unit}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Form
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Adjustment Type', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary.withValues(alpha: 0.9))),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _TypeButton(label: 'Add', type: 'addition', icon: Icons.add_circle_outline, color: AppColors.success, selected: _adjustmentType, onTap: (t) => setState(() => _adjustmentType = t))),
                        const SizedBox(width: 8),
                        Expanded(child: _TypeButton(label: 'Remove', type: 'subtraction', icon: Icons.remove_circle_outline, color: AppColors.error, selected: _adjustmentType, onTap: (t) => setState(() => _adjustmentType = t))),
                        const SizedBox(width: 8),
                        Expanded(child: _TypeButton(label: 'Set To', type: 'adjustment', icon: Icons.tune, color: AppColors.primary, selected: _adjustmentType, onTap: (t) => setState(() => _adjustmentType = t))),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text('Quantity', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary.withValues(alpha: 0.9))),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Enter quantity',
                        suffixText: widget.product.unit,
                        filled: true,
                        fillColor: AppColors.surfaceVariant,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.error)),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        final q = int.tryParse(v);
                        if (q == null || q <= 0) return 'Enter a valid quantity';
                        if (_adjustmentType == 'subtraction' && q > widget.product.currentStock) {
                          return 'Cannot subtract more than current stock (${widget.product.currentStock})';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    Text('Reason', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary.withValues(alpha: 0.9))),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _reasonController,
                      maxLines: 2,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Enter reason for adjustment',
                        filled: true,
                        fillColor: AppColors.surfaceVariant,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.error)),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Apply'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final String type;
  final IconData icon;
  final Color color;
  final String selected;
  final ValueChanged<String> onTap;

  const _TypeButton({required this.label, required this.type, required this.icon, required this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == type;
    return InkWell(
      onTap: () => onTap(type),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.12) : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? color : AppColors.surfaceVariant, width: isSelected ? 1.5 : 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : AppColors.textSecondary, size: 20),
            const SizedBox(height: 3),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? color : AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
