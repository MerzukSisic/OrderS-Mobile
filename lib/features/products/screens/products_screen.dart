import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/products_provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../routes/app_router.dart';
import '../../shared/widgets/bottom_nav_bar.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  String? _selectedCategory;
  String _sortMode = 'name'; // name | price_low | price_high

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductsProvider>().fetchProducts();
      context.read<ProductsProvider>().fetchCategories();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openFiltersSheet(List categories) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filters',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.layers_clear_rounded),
                  title: const Text('All categories'),
                  trailing: _selectedCategory == null
                      ? const Icon(Icons.check_rounded)
                      : null,
                  onTap: () {
                    setState(() => _selectedCategory = null);
                    context.read<ProductsProvider>().setSelectedCategory(null);
                    Navigator.pop(ctx);
                  },
                ),
                const Divider(height: 1),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: categories.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final c = categories[i];
                      final id = (c.id ?? '').toString();
                      final name = (c.name ?? '').toString();
                      final selected = _selectedCategory == id;

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(name),
                        trailing:
                            selected ? const Icon(Icons.check_rounded) : null,
                        onTap: () {
                          setState(() => _selectedCategory = id);
                          context
                              .read<ProductsProvider>()
                              .setSelectedCategory(id);
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<dynamic> _applySort(List<dynamic> input) {
    final list = [...input];
    switch (_sortMode) {
      case 'price_low':
        list.sort((a, b) => (a.price as num).compareTo(b.price as num));
        break;
      case 'price_high':
        list.sort((a, b) => (b.price as num).compareTo(a.price as num));
        break;
      case 'name':
      default:
        list.sort((a, b) => a.name
            .toString()
            .toLowerCase()
            .compareTo(b.name.toString().toLowerCase()));
        break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          // Cart icon with badge
          Consumer<CartProvider>(
            builder: (context, cart, _) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined),
                    onPressed: () {
                      Navigator.pushNamed(context, AppRouter.checkout);
                    },
                  ),
                  if (cart.itemCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          cart.itemCount.toString(),
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                            context
                                .read<ProductsProvider>()
                                .setSearchQuery('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: AppColors.textSecondary.withValues(alpha: 0.15),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: AppColors.textSecondary.withValues(alpha: 0.15),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                  context.read<ProductsProvider>().setSearchQuery(value);
                },
              ),
            ),

            // Filters + Sort
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Consumer<ProductsProvider>(
                builder: (context, provider, _) {
                  return Row(
                    children: [
                      Expanded(
                        child: _PillButton(
                          icon: Icons.tune_rounded,
                          label: 'Filters',
                          onTap: () => _openFiltersSheet(provider.categories),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: PopupMenuButton<String>(
                          onSelected: (value) {
                            setState(() => _sortMode = value);
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(value: 'name', child: Text('Name')),
                            PopupMenuItem(
                                value: 'price_low',
                                child: Text('Price: Low to High')),
                            PopupMenuItem(
                                value: 'price_high',
                                child: Text('Price: High to Low')),
                          ],
                          child: const _PillButton(
                            icon: Icons.sort_rounded,
                            label: 'Sort',
                            trailing: Icons.keyboard_arrow_down_rounded,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // List
            Expanded(
              child: Consumer<ProductsProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (provider.error != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: AppColors.error.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            provider.error!,
                            style:
                                const TextStyle(color: AppColors.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => provider.fetchProducts(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  final products = _applySort(provider.products);

                  if (products.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 64,
                            color: AppColors.textSecondary.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No products found',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () => provider.fetchProducts(),
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: products.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return _ProductRow(
                          product: product,
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              AppRouter.productDetail,
                              arguments: product,
                            );
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 1),
    );
  }
}

class _PillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final IconData? trailing;
  final VoidCallback? onTap;

  const _PillButton({
    required this.icon,
    required this.label,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.textSecondary.withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: AppColors.textPrimary),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 6),
              Icon(trailing!, size: 18, color: AppColors.textPrimary),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  final dynamic product;
  final VoidCallback onTap;

  const _ProductRow({
    required this.product,
    required this.onTap,
  });

  int _qtyFromCart(CartProvider cart, String productId) {
    try {
      for (final item in cart.items) {
        if (item.product.id == productId) return item.quantity;
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }

  String _safeCurrency(double value) {
    try {
      final s = Formatters.currency(value);
      if (s.trim().isNotEmpty) return s;
    } catch (_) {
      // ignore
    }
    // Fallback if formatter returns empty or throws
    return '${value.toStringAsFixed(2)} KM';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, _) {
        final qty = _qtyFromCart(cart, product.id);
        final int stock = (product.stock is int)
            ? product.stock as int
            : int.tryParse(product.stock.toString()) ?? 0;

        final isAvailableRaw = product.isAvailable;
        final bool isAvailable = (isAvailableRaw is bool)
            ? isAvailableRaw
            : (isAvailableRaw?.toString().toLowerCase() == 'true' ||
                isAvailableRaw?.toString() == '1');

        final bool canOrder = isAvailable && stock > 0;
        final double price = (product.price is num)
            ? (product.price as num).toDouble()
            : double.tryParse(product.price.toString()) ?? 0.0;

        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.textSecondary.withValues(alpha: 0.10),
              ),
            ),
            child: Row(
              children: [
                // Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 72,
                    height: 72,
                    color: AppColors.surfaceVariant,
                    child: (product.imageUrl != null)
                        ? Image.network(
                            product.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.restaurant,
                              color: AppColors.textDisabled,
                              size: 34,
                            ),
                          )
                        : const Icon(
                            Icons.restaurant,
                            color: AppColors.textDisabled,
                            size: 34,
                          ),
                  ),
                ),

                const SizedBox(width: 12),

                // Name + price
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _safeCurrency(price),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      if (!canOrder) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Out of stock',
                          style: TextStyle(
                            color: AppColors.textSecondary
                                .withValues(alpha: 0.85),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Qty stepper
                _QtyStepper(
                  quantity: qty,
                  enabled: canOrder,
                  canIncrease: canOrder && qty < stock,
                  onDecrease: qty > 0
                      ? () => cart.decreaseQuantity(product.id)
                      : null,
                  onIncrease: canOrder && qty < stock
                      ? () {
                          if (qty == 0) {
                            cart.addItem(product, 1, notes: '');
                          } else {
                            cart.increaseQuantity(product.id);
                          }
                        }
                      : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _QtyStepper extends StatelessWidget {
  final int quantity;
  final bool enabled;
  final bool canIncrease;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;

  const _QtyStepper({
    required this.quantity,
    required this.enabled,
    required this.canIncrease,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    final pillBg = AppColors.surfaceVariant;
    final border = AppColors.textSecondary.withValues(alpha: 0.18);
    final qtyColor = enabled ? AppColors.textPrimary : AppColors.textDisabled;

    return Container(
      height: 38,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: pillBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepIconButton(
            icon: Icons.remove_rounded,
            enabled: enabled && onDecrease != null,
            primary: false,
            onTap: onDecrease,
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 28,
            child: Text(
              quantity.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: qtyColor,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _StepIconButton(
            icon: Icons.add_rounded,
            enabled: enabled && canIncrease && onIncrease != null,
            primary: true,
            onTap: onIncrease,
          ),
        ],
      ),
    );
  }
}

class _StepIconButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final bool primary;
  final VoidCallback? onTap;

  const _StepIconButton({
    required this.icon,
    required this.enabled,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final border = AppColors.textSecondary.withValues(alpha: 0.22);

    final bg = !enabled
        ? AppColors.surfaceVariant
        : (primary ? AppColors.primary : AppColors.surface);

    final fg = !enabled
        ? AppColors.textDisabled
        : (primary ? AppColors.white : AppColors.textPrimary);

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: primary ? null : Border.all(color: border),
        ),
        child: Center(
          child: Icon(
            icon,
            size: 20,
            color: fg,
          ),
        ),
      ),
    );
  }
}
