import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/orders_provider.dart';
import '../../../providers/tables_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/services/api_service.dart';
import '../../../models/accompaniment.dart';
import '../../../routes/app_router.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final TextEditingController _notesController = TextEditingController();
  final Map<String, List<Accompaniment>> _accompanimentCache = {};

  @override
  void initState() {
    super.initState();
    _loadAccompanimentsForCartItems();
  }

  Future<void> _loadAccompanimentsForCartItems() async {
    final cart = context.read<CartProvider>();
    
    for (var item in cart.items) {
      if (item.selectedAccompanimentIds.isNotEmpty) {
        try {
          final groups = await ApiService().getProductAccompaniments(item.product.id);
          final allAccompaniments = groups.expand((g) => g.accompaniments).toList();
          
          final selectedAccs = allAccompaniments
              .where((acc) => item.selectedAccompanimentIds.contains(acc.id))
              .toList();
          
          setState(() {
            _accompanimentCache['${item.product.id}_${item.selectedAccompanimentIds.join(',')}'] = selectedAccs;
          });
        } catch (e) {
          debugPrint('Error loading accompaniments: $e');
        }
      }
    }
  }

  String _safeCurrency(num value) {
    try {
      final s = Formatters.currency(value.toDouble());
      if (s.trim().isNotEmpty) return s;
    } catch (_) {}
    return '${value.toStringAsFixed(2)} KM';
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    final cartProvider = context.read<CartProvider>();
    final ordersProvider = context.read<OrdersProvider>();
    final isEditing = cartProvider.activeOrderId != null;

    if (cartProvider.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your cart is empty'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (ordersProvider.isLoading) return;

    final notes = _notesController.text.trim();
    final items = cartProvider.items
        .map((item) => {
              'productId': item.product.id,
              'quantity': item.quantity,
              'notes': item.notes,
              'selectedAccompanimentIds': item.selectedAccompanimentIds,
            })
        .toList();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      bool ok;

      if (isEditing) {
        ok = await ordersProvider.updateOrderItems(
          orderId: cartProvider.activeOrderId!,
          notes: notes,
          items: items,
        );
      } else {
        ok = await ordersProvider.createOrder(
          tableId: cartProvider.selectedTable?.id,
          type: cartProvider.orderType,
          isPartnerOrder: cartProvider.isPartnerOrder,
          notes: notes,
          items: items,
        );
      }

      if (!ok) {
        throw Exception(ordersProvider.error ?? 'Request failed');
      }

      if (mounted) Navigator.pop(context);

      if (mounted) {
        await context.read<TablesProvider>().fetchTables();
      }

      cartProvider.clear();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing ? 'Order updated successfully!' : 'Order placed successfully!',
          ),
          backgroundColor: AppColors.success,
        ),
      );

      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRouter.orders,
        (route) => false,
      );
    } catch (e) {
      if (mounted) Navigator.pop(context);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing
                ? 'Failed to update order: ${ordersProvider.error ?? e.toString()}'
                : 'Failed to place order: ${ordersProvider.error ?? e.toString()}',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Checkout'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, _) {
          if (cart.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 64,
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Your cart is empty',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, AppRouter.products);
                    },
                    child: const Text('Browse Products'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cart Items List
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: cart.items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final item = cart.items[index];
                          final cacheKey = '${item.product.id}_${item.selectedAccompanimentIds.join(',')}';
                          final accompaniments = _accompanimentCache[cacheKey] ?? [];
                          
                          return _ProductCard(
                            item: item,
                            accompaniments: accompaniments,
                            onDecrease: () => cart.decreaseQuantity(item.product.id),
                            onIncrease: () => cart.increaseQuantity(item.product.id),
                          );
                        },
                      ),

                      const SizedBox(height: 32),

                      // ORDER TYPE Section
                      const Text(
                        'ORDER TYPE',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _RadioTile(
                              label: 'Cafe',
                              icon: Icons.restaurant,
                              selected: cart.orderType == 'DineIn',
                              onTap: () => cart.setOrderType('DineIn'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _RadioTile(
                              label: 'Delivery',
                              icon: Icons.delivery_dining,
                              selected: cart.orderType == 'TakeAway',
                              onTap: () => cart.setOrderType('TakeAway'),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // DELIVERY METHOD Section
                      const Text(
                        'DELIVERY METHOD',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _RadioTile(
                              label: 'In store',
                              icon: Icons.store,
                              selected: !cart.isPartnerOrder,
                              onTap: () => cart.setPartnerOrder(false),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _RadioTile(
                              label: 'Takeout',
                              icon: Icons.shopping_bag,
                              selected: cart.isPartnerOrder,
                              onTap: () => cart.setPartnerOrder(true),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Summary
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            _SummaryRow(
                              label: 'Subtotal (${cart.items.length})',
                              value: _safeCurrency(cart.totalAmount),
                            ),
                            const SizedBox(height: 12),
                            _SummaryRow(
                              label: 'Taxes',
                              value: _safeCurrency(0),
                            ),
                            const Divider(height: 32),
                            _SummaryRow(
                              label: 'Total',
                              value: _safeCurrency(cart.totalAmount),
                              isTotal: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _placeOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        cart.activeOrderId != null ? 'Update order' : 'Place order',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// Product Card with FULL accompaniments display
class _ProductCard extends StatelessWidget {
  final CartItem item;
  final List<Accompaniment> accompaniments;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  const _ProductCard({
    required this.item,
    required this.accompaniments,
    required this.onDecrease,
    required this.onIncrease,
  });

  String _safeCurrency(num value) {
    try {
      final s = Formatters.currency(value.toDouble());
      if (s.trim().isNotEmpty) return s;
    } catch (_) {}
    return '${value.toStringAsFixed(2)} KM';
  }

  @override
  Widget build(BuildContext context) {
    final p = item.product;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Product Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 64,
                  height: 64,
                  color: AppColors.surfaceVariant,
                  child: (p.imageUrl != null && p.imageUrl!.isNotEmpty)
                      ? Image.network(
                          p.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.restaurant,
                            color: AppColors.textSecondary,
                            size: 28,
                          ),
                        )
                      : const Icon(
                          Icons.restaurant,
                          color: AppColors.textSecondary,
                          size: 28,
                        ),
                ),
              ),

              const SizedBox(width: 14),

              // Product Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          _safeCurrency(p.price),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '× ${item.quantity}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Quantity Stepper
              _QuantityStepper(
                quantity: item.quantity,
                onDecrease: onDecrease,
                onIncrease: onIncrease,
              ),
            ],
          ),

          // Accompaniments Display
          if (accompaniments.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.add_circle_outline,
                        size: 16,
                        color: AppColors.primary.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Prilozi:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...accompaniments.map((acc) => Padding(
                    padding: const EdgeInsets.only(left: 22, top: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            acc.name,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (acc.extraCharge > 0)
                          Text(
                            '+${_safeCurrency(acc.extraCharge)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary.withValues(alpha: 0.7),
                            ),
                          ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  const _QuantityStepper({
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(icon: Icons.remove, onTap: onDecrease),
          Container(
            width: 32,
            alignment: Alignment.center,
            child: Text(
              quantity.toString(),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          _StepperButton(icon: Icons.add, onTap: onIncrease),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _StepperButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        child: Icon(icon, size: 18, color: AppColors.textPrimary),
      ),
    );
  }
}

class _RadioTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _RadioTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.textSecondary.withValues(alpha: 0.2),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: selected ? AppColors.primary : AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: isTotal ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: FontWeight.bold,
            color: isTotal ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}