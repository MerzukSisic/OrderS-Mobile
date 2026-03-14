import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/products_provider.dart';
import '../../../providers/categories_provider.dart';
import '../../../providers/orders_provider.dart';
import '../../../providers/notification_recommendation_providers.dart';
import '../../../providers/auth_provider.dart';
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
  String _sortMode = 'name';

  int _recTabIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final isAdmin = context.read<AuthProvider>().isAdmin;
      final ordersProvider = context.read<OrdersProvider>();
      final isTakeAway = ordersProvider.orderType == 'TakeAway';
      final hasTable = ordersProvider.selectedTableId != null;

      if (!isAdmin && !isTakeAway && !hasTable) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a table first.'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pushReplacementNamed(AppRouter.tables);
        return;
      }

      context.read<ProductsProvider>().fetchProducts();
      context.read<CategoriesProvider>().fetchCategories();
      final rec = context.read<RecommendationsProvider>();
      rec.fetchPopularProducts(count: 5);
      rec.fetchTimeBasedRecommendations(count: 4);
      rec.fetchRecommendedProducts(count: 4);

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
                    context.read<ProductsProvider>().fetchProducts();
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
                        trailing: selected ? const Icon(Icons.check_rounded) : null,
                        onTap: () {
                          setState(() => _selectedCategory = id);
                          context.read<ProductsProvider>().fetchProducts(categoryId: id);
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
          Consumer<OrdersProvider>(
            builder: (context, ordersProvider, _) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined),
                    onPressed: () {
                      Navigator.pushNamed(context, AppRouter.checkout);
                    },
                  ),
                  if (ordersProvider.cartCount > 0)
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
                          ordersProvider.cartCount.toString(),
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
            // ✅ FILTERS & SORT - Fixed at top
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Consumer<CategoriesProvider>(
                builder: (context, categoriesProvider, _) {
                  return Row(
                    children: [
                      Expanded(
                        child: _PillButton(
                          icon: Icons.tune_rounded,
                          label: 'Filters',
                          onTap: () => _openFiltersSheet(categoriesProvider.categories),
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
                            PopupMenuItem(value: 'price_low', child: Text('Price: Low to High')),
                            PopupMenuItem(value: 'price_high', child: Text('Price: High to Low')),
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

            // ✅ SEARCH - Fixed at top
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
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
                            context.read<ProductsProvider>().searchProducts('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                  if (value.isNotEmpty) {
                    context.read<ProductsProvider>().searchProducts(value);
                  } else {
                    context.read<ProductsProvider>().fetchProducts();
                  }
                },
              ),
            ),

            // ✅ SCROLLABLE CONTENT - Carousel + Products together!
            Expanded(
              child: Consumer2<ProductsProvider, RecommendationsProvider>(
                builder: (context, productsProvider, recProvider, _) {
                  if (productsProvider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (productsProvider.error != null) {
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
                            productsProvider.error!,
                            style: const TextStyle(color: AppColors.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => productsProvider.fetchProducts(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  final products = _applySort(productsProvider.products);

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

                  // ✅ EVERYTHING IN ONE SCROLLABLE LIST!
                  return RefreshIndicator(
                    onRefresh: () => productsProvider.fetchProducts(),
                    child: CustomScrollView(
                      slivers: [
                        // ✅ UNIFIED RECOMMENDATIONS SECTION
                        if (recProvider.popularProducts.isNotEmpty ||
                            recProvider.timeBasedProducts.isNotEmpty ||
                            recProvider.recommendedProducts.isNotEmpty)
                          SliverToBoxAdapter(
                            child: _RecommendationsSection(
                              popularProducts: recProvider.popularProducts,
                              timeBasedProducts: recProvider.timeBasedProducts,
                              recommendedProducts: recProvider.recommendedProducts,
                              selectedTab: _recTabIndex,
                              onTabChanged: (i) => setState(() => _recTabIndex = i),
                            ),
                          ),

                        // ✅ PRODUCT LIST
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final product = products[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _ProductRow(
                                    product: product,
                                    onTap: () {
                                      Navigator.pushNamed(
                                        context,
                                        AppRouter.productDetail,
                                        arguments: product,
                                      );
                                    },
                                  ),
                                );
                              },
                              childCount: products.length,
                            ),
                          ),
                        ),
                      ],
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

class _RecommendationsSection extends StatelessWidget {
  final List popularProducts;
  final List timeBasedProducts;
  final List recommendedProducts;
  final int selectedTab;
  final void Function(int) onTabChanged;

  const _RecommendationsSection({
    required this.popularProducts,
    required this.timeBasedProducts,
    required this.recommendedProducts,
    required this.selectedTab,
    required this.onTabChanged,
  });

  static const _tabs = [
    (icon: Icons.local_fire_department_rounded, label: 'Popular',   color: AppColors.primary),
    (icon: Icons.access_time_rounded,           label: 'Right Now', color: Colors.teal),
    (icon: Icons.recommend_rounded,             label: 'For You',   color: Colors.deepPurple),
  ];

  List _productsForTab(int i) => switch (i) {
    0 => popularProducts,
    1 => timeBasedProducts,
    _ => recommendedProducts,
  };

  @override
  Widget build(BuildContext context) {
    // Determine first tab with data
    final visibleTabs = [0, 1, 2].where((i) => _productsForTab(i).isNotEmpty).toList();
    if (visibleTabs.isEmpty) return const SizedBox.shrink();

    final activeTab = visibleTabs.contains(selectedTab) ? selectedTab : visibleTabs.first;
    final products = _productsForTab(activeTab);
    final accent = _tabs[activeTab].color;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tab row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: visibleTabs.map((i) {
                final tab = _tabs[i];
                final selected = i == activeTab;
                return GestureDetector(
                  onTap: () => onTabChanged(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: selected
                          ? tab.color.withValues(alpha: 0.15)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? tab.color.withValues(alpha: 0.5)
                            : AppColors.textSecondary.withValues(alpha: 0.15),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(tab.icon,
                            size: 14,
                            color: selected ? tab.color : AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          tab.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                            color: selected ? tab.color : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          // Product cards
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: products.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final p = products[index];
                return GestureDetector(
                  onTap: () => Navigator.pushNamed(
                      context, AppRouter.productDetail, arguments: p),
                  child: Container(
                    width: 130,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: accent.withValues(alpha: 0.25)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          p.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${(p.price as num).toStringAsFixed(2)} KM',
                          style: TextStyle(
                              color: accent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
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

  int _qtyFromCart(OrdersProvider ordersProvider, String productId) {
    try {
      for (final item in ordersProvider.cartItems) {
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
    } catch (_) {}
    return '${value.toStringAsFixed(2)} KM';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OrdersProvider>(
      builder: (context, ordersProvider, _) {
        final qty = _qtyFromCart(ordersProvider, product.id);
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
                            color: AppColors.textSecondary.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (canOrder && qty == 0)
                  _AddButton(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        AppRouter.productDetail,
                        arguments: product,
                      );
                    },
                  )
                else if (qty > 0)
                  _QtyStepper(
                    quantity: qty,
                    enabled: canOrder,
                    canIncrease: canOrder && qty < stock,
                    onDecrease: () {
                      final cartItem = ordersProvider.cartItems.firstWhere(
                        (item) => item.product.id == product.id,
                      );
                      ordersProvider.removeFromCart(cartItem.uniqueKey);
                    },
                    onIncrease: () {
                      Navigator.pushNamed(
                        context,
                        AppRouter.productDetail,
                        arguments: product,
                      );
                    },
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
          child: Icon(icon, size: 20, color: fg),
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 38,
        height: 38,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Icon(
            Icons.add_rounded,
            size: 22,
            color: AppColors.white,
          ),
        ),
      ),
    );
  }
}