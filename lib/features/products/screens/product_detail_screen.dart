import 'package:flutter/material.dart';
import 'package:orders_mobile/core/services/api_service.dart';
import 'package:orders_mobile/models/accompaniment_group.dart';
import 'package:provider/provider.dart';

import '../../../models/product_model.dart';
import '../../../providers/cart_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/services/navigation_service.dart';
import '../widgets/ingredient_chip.dart';
import '../../../core/widgets/accompaniment_selector.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final TextEditingController _notesController = TextEditingController();
  List<AccompanimentGroup> _accompanimentGroups = [];
  List<String> _selectedAccompanimentIds = [];
  double _totalAccompanimentCharge = 0.0;
  bool _isLoadingAccompaniments = true;
  int _selectorKey = 0; // ✅ Key za forsirani rebuild

  @override
  void initState() {
    super.initState();
    _loadAccompaniments();
  }
  
  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadAccompaniments() async {
    setState(() => _isLoadingAccompaniments = true);
    try {
      final groups = await ApiService().getProductAccompaniments(widget.product.id);
      
      setState(() {
        _accompanimentGroups = groups;
        _isLoadingAccompaniments = false;
      });
    } catch (e) {
      setState(() => _isLoadingAccompaniments = false);
      debugPrint('❌ ERROR loading accompaniments: $e');
    }
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
    if (NavigationService.context != null) {
      NavigationService.navigateTo('/checkout');
      return;
    }
    Navigator.pushNamed(context, '/checkout');
  }

  void _addToCart() {
    // Validate required accompaniments
    if (_accompanimentGroups.isNotEmpty) {
      for (var group in _accompanimentGroups) {
        if (group.isRequired) {
          final selectedForGroup = _selectedAccompanimentIds.where((id) {
            return group.accompaniments.any((acc) => acc.id == id);
          }).toList();

          if (selectedForGroup.isEmpty) {
            _showSnack('Morate izabrati ${group.name}');
            return;
          }
        }
      }
    }

    const qty = 1;
    final notes = _notesController.text.trim();

    // ✅ FIXED: Pass selectedAccompanimentIds
    context.read<CartProvider>().addItem(
      widget.product,
      qty,
      notes: notes.isEmpty ? null : notes,
      selectedAccompanimentIds: _selectedAccompanimentIds,
    );

    final rootCtx = NavigationService.context ?? context;
    ScaffoldMessenger.of(rootCtx).showSnackBar(
      SnackBar(
        content: Text('${widget.product.name} added to cart'),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'VIEW CART',
          textColor: AppColors.white,
          onPressed: _openCart,
        ),
      ),
    );

    // Clear selections after adding
    setState(() {
      _selectedAccompanimentIds = [];
      _totalAccompanimentCharge = 0.0;
      _notesController.clear();
      _selectorKey++; // ✅ Force rebuild AccompanimentSelector
    });
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
      // ✅ FIXED: Always show "Add to cart" button (no stepper)
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: widget.product.isAvailable && widget.product.stock > 0
                  ? _addToCart
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                elevation: 0,
                disabledBackgroundColor: AppColors.surfaceVariant.withValues(alpha: 0.8),
                disabledForegroundColor: AppColors.textDisabled,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                widget.product.isAvailable && widget.product.stock > 0
                    ? 'Add to cart'
                    : 'Out of stock',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
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
                      _PricePill(amount: widget.product.price + _totalAccompanimentCharge),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

                  if (widget.product.ingredients.isNotEmpty) ...[
                    Text('Ingredients', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.product.ingredients
                          .map((ingredient) => IngredientChip(name: ingredient.storeProductName))
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

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

                  TextField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Special instructions (optional)',
                      hintText: 'e.g., No sugar, extra hot',
                    ),
                    maxLines: 2,
                  ),

                  // Accompaniments Section
                  if (_isLoadingAccompaniments)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_accompanimentGroups.isNotEmpty)
                    AccompanimentSelector(
                      key: ValueKey(_selectorKey), // ✅ Force rebuild on each add
                      groups: _accompanimentGroups,
                      onSelectionChanged: (selectedIds) {
                        setState(() {
                          _selectedAccompanimentIds = selectedIds;
                        });
                      },
                      onTotalChargeChanged: (totalCharge) {
                        setState(() {
                          _totalAccompanimentCharge = totalCharge;
                        });
                      },
                    ),

                  const SizedBox(height: 16),
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