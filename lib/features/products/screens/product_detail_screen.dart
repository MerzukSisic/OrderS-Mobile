import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/product_model.dart';
import '../../../providers/cart_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/services/navigation_service.dart';
import '../widgets/ingredient_chip.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _showSnack(String message) {
    final rootCtx = NavigationService.context ?? context;
    ScaffoldMessenger.of(rootCtx).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.warning,
        duration: const Duration(seconds: 2),
      ),
    );
  }


  void _openCart() {
    // Uses your global navigation if available
    if (NavigationService.context != null) {
      NavigationService.navigateTo('/checkout');
      return;
    }
    Navigator.pushNamed(context, '/checkout');
  }

  void _addToCart() {
    const qty = 1;
    final notes = _notesController.text.trim();

    context.read<CartProvider>().addItem(
          widget.product,
          qty,
          notes: notes.isEmpty ? null : notes,
        );

    final rootCtx = NavigationService.context ?? context;
    ScaffoldMessenger.of(rootCtx).showSnackBar(
      SnackBar(
        content: Text('${widget.product.name} x$qty added to cart'),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'VIEW CART',
          textColor: AppColors.white,
          onPressed: _openCart,
        ),
      ),
    );
  }

  int _qtyInCart(CartProvider cart, String productId) {
    try {
      for (final item in cart.items) {
        if (item.product.id == productId) return item.quantity;
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.product.name),
        actions: [
          Consumer<CartProvider>(
            builder: (context, cart, _) {
              return IconButton(
                onPressed: _openCart,
                icon: Stack(
                  children: [
                    const Icon(Icons.shopping_cart_outlined),
                    if (cart.itemCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 16,
                          height: 16,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${cart.itemCount}',
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Consumer<CartProvider>(
            builder: (context, cart, _) {
              final inCartQty = _qtyInCart(cart, widget.product.id);
              final canOrder = widget.product.isAvailable && widget.product.stock > 0;

              if (!canOrder) {
                return SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surfaceVariant.withValues(alpha: 0.8),
                      foregroundColor: AppColors.textDisabled,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Out of stock',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );
              }

              // Not in cart -> show Add to cart
              if (inCartQty <= 0) {
                return SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _addToCart,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Add to cart',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );
              }

              // In cart -> show stepper
              return _BottomCartStepper(
                quantity: inCartQty,
                canDecrease: inCartQty > 0,
                canIncrease: inCartQty < widget.product.stock,
                onDecrease: () => cart.decreaseQuantity(widget.product.id),
                onIncrease: () => cart.increaseQuantity(widget.product.id),
              );
            },
          ),
        ),
      ),
      body: Column(
        children: [
          // Image
          Expanded(
            child: Center(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 40),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: widget.product.imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          widget.product.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.restaurant,
                            size: 80,
                            color: AppColors.textDisabled,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.restaurant,
                        size: 80,
                        color: AppColors.textDisabled,
                      ),
              ),
            ),
          ),

          // Info container
          Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Name + price
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.product.name,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _PricePill(amount: widget.product.price),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Category
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      widget.product.categoryName,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Description
                  if (widget.product.description != null &&
                      widget.product.description!.trim().isNotEmpty) ...[
                    Text(
                      widget.product.description!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Ingredients
                  if (widget.product.ingredients.isNotEmpty) ...[
                    Text('Ingredients', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.product.ingredients
                          .map(
                            (ingredient) => IngredientChip(
                              name: ingredient.storeProductName,
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Info chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildInfoChip(
                        icon: Icons.inventory_2_outlined,
                        label: 'Stock: ${widget.product.stock}',
                      ),
                      _buildInfoChip(
                        icon: Icons.access_time,
                        label: '~${widget.product.preparationTimeMinutes} min',
                      ),
                      _buildInfoChip(
                        icon: Icons.location_on_outlined,
                        label: widget.product.preparationLocation,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Notes
                  TextField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Special instructions (optional)',
                      hintText: 'e.g., No sugar, extra hot',
                    ),
                    maxLines: 2,
                  ),

                  const SizedBox(height: 16),

                  // (Quantity and Add to cart/In-cart stepper moved to bottom bar)
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _PricePill extends StatelessWidget {
  final double amount;
  const _PricePill({required this.amount});

  @override
  Widget build(BuildContext context) {
    String text;
    try {
      text = Formatters.currency(amount);
      if (text.trim().isEmpty) {
        text = '${amount.toStringAsFixed(2)} KM';
      }
    } catch (_) {
      text = '${amount.toStringAsFixed(2)} KM';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.white,
          fontWeight: FontWeight.w900,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _BottomCartStepper extends StatelessWidget {
  final int quantity;
  final bool canDecrease;
  final bool canIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  const _BottomCartStepper({
    required this.quantity,
    required this.canDecrease,
    required this.canIncrease,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.textSecondary.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _StepperCircleButton(
            icon: Icons.remove_rounded,
            enabled: canDecrease,
            primary: false,
            onTap: canDecrease ? onDecrease : null,
          ),
          const SizedBox(width: 14),
          Text(
            quantity.toString(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 14),
          _StepperCircleButton(
            icon: Icons.add_rounded,
            enabled: canIncrease,
            primary: true,
            onTap: canIncrease ? onIncrease : null,
          ),
        ],
      ),
    );
  }
}

class _StepperCircleButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final bool primary;
  final VoidCallback? onTap;

  const _StepperCircleButton({
    required this.icon,
    required this.enabled,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final border = AppColors.textSecondary.withValues(alpha: 0.22);

    final bg = !enabled
        ? AppColors.surface
        : (primary ? AppColors.primary : AppColors.surface);

    final fg = !enabled
        ? AppColors.textDisabled
        : (primary ? AppColors.white : AppColors.textPrimary);

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: primary ? null : Border.all(color: border),
        ),
        child: Center(
          child: Icon(icon, size: 22, color: fg),
        ),
      ),
    );
  }
}

