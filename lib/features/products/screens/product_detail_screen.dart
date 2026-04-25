import 'package:flutter/material.dart';
import 'package:orders_mobile/core/services/api/common_api_services.dart';
import 'package:orders_mobile/core/utils/top_notification.dart';
import 'package:orders_mobile/models/products/accompaniment_group.dart';
import 'package:provider/provider.dart';

import '../../../models/products/product_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/services/navigation_service.dart';
import '../../../providers/orders_provider.dart'; // ✅ DODAJ IMPORT
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
  int _selectorKey = 0;

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
      final response = await AccompanimentsApiService()
          .getByProductId(widget.product.id);

      setState(() {
        _accompanimentGroups =
            response.success && response.data != null ? response.data! : [];
        _isLoadingAccompaniments = false;
      });
    } catch (e) {
      setState(() => _isLoadingAccompaniments = false);
      debugPrint('❌ ERROR loading accompaniments: $e');
    }
  }

  void _showNotification(String message, {bool isError = false}) {
    TopNotification.show(
      context,
      message: message,
      isError: isError,
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
            _showNotification('Morate izabrati ${group.name}',
                isError: true); // ✅ NOVO
            return;
          }
        }
      }
    }

    final notes = _notesController.text.trim();

    context.read<OrdersProvider>().addToCart(
          product: widget.product,
          quantity: 1,
          selectedAccompanimentIds: _selectedAccompanimentIds,
          notes: notes.isEmpty ? null : notes,
        );

    _showNotification('${widget.product.name} added to cart'); // ✅ NOVO

    // Clear selections after adding
    setState(() {
      _selectedAccompanimentIds = [];
      _totalAccompanimentCharge = 0.0;
      _notesController.clear();
      _selectorKey++;
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
          Consumer<OrdersProvider>(
            // ✅ PROMJENA: CartProvider -> OrdersProvider
            builder: (context, ordersProvider, _) {
              return IconButton(
                onPressed: _openCart,
                icon: Stack(
                  children: [
                    const Icon(Icons.shopping_cart_outlined),
                    if (ordersProvider.cartCount >
                        0) // ✅ PROMJENA: itemCount -> cartCount
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
                            '${ordersProvider.cartCount}', // ✅ PROMJENA: itemCount -> cartCount
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
                disabledBackgroundColor:
                    AppColors.surfaceVariant.withValues(alpha: 0.8),
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
                      _PricePill(
                          amount:
                              widget.product.price + _totalAccompanimentCharge),
                    ],
                  ),

                  const SizedBox(height: 8),

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
                          .map((ingredient) =>
                              IngredientChip(name: ingredient.storeProductName))
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
                      key: ValueKey(_selectorKey),
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
