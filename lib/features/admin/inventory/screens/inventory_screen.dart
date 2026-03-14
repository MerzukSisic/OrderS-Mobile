import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:orders_mobile/core/theme/app_colors.dart';
import 'package:orders_mobile/core/widgets/custom_text_field.dart';
import 'package:orders_mobile/core/widgets/empty_state.dart';
import 'package:orders_mobile/core/widgets/error_display.dart';
import 'package:orders_mobile/core/widgets/loading_indicator.dart';
import 'package:orders_mobile/core/widgets/admin_scaffold.dart';
import 'package:orders_mobile/models/inventory/store_model.dart';
import 'package:orders_mobile/providers/auth_provider.dart';
import 'package:orders_mobile/providers/business_providers.dart';
import 'package:orders_mobile/routes/app_router.dart';
import 'package:provider/provider.dart';

import '../widgets/inventory_card.dart';
import 'inventory_detail_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  String _filterType = 'all';
  String _searchQuery = '';
  String? _selectedStoreId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);

    SchedulerBinding.instance.addPostFrameCallback((_) {
      Provider.of<InventoryProvider>(context, listen: false)
          .fetchStoreProducts();
      Provider.of<StoresProvider>(context, listen: false).fetchStores();
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        switch (_tabController.index) {
          case 0:
            _filterType = 'all';
            break;
          case 1:
            _filterType = 'low-stock';
            break;
          case 2:
            _filterType = 'out-of-stock';
            break;
        }
      });
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  Future<void> _onRefresh() async {
    await context.read<InventoryProvider>().fetchStoreProducts(storeId: _selectedStoreId);
  }

  void _onStoreFilterChanged(String? storeId) {
    setState(() => _selectedStoreId = storeId);
    context.read<InventoryProvider>().fetchStoreProducts(storeId: storeId);
  }

  void _navigateToDetail(dynamic product) {
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InventoryDetailScreen(product: product),
      ),
    );
  }

  void _showAddProductDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add product – in progress'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  String _getProductName(dynamic product) {
    try {
      final v = (product as dynamic).productName;
      if (v != null) return v.toString();
    } catch (_) {}

    try {
      final v = (product as dynamic).name;
      if (v != null) return v.toString();
    } catch (_) {}

    return '';
  }

  int _getCurrentStock(dynamic product) {
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

  int _getMinStockLevel(dynamic product) {
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

  List<dynamic> _getFilteredProducts(List<dynamic> allProducts) {
    var filtered = allProducts;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((product) {
        final name = _getProductName(product).toLowerCase();
        return name.contains(query);
      }).toList();
    }

    // Apply stock filter
    switch (_filterType) {
      case 'low-stock':
        filtered = filtered.where((product) {
          final currentStock = _getCurrentStock(product);
          final minStockLevel = _getMinStockLevel(product);
          return currentStock > 0 && currentStock <= minStockLevel;
        }).toList();
        break;
      case 'out-of-stock':
        filtered = filtered.where((product) {
          final currentStock = _getCurrentStock(product);
          return currentStock == 0;
        }).toList();
        break;
    }

    return filtered;
  }

  Widget _storeChip(String label, String? storeId) {
    final isSelected = _selectedStoreId == storeId;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _onStoreFilterChanged(storeId),
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.primary.withValues(alpha: 0.15),
      checkmarkColor: AppColors.primary,
      side: BorderSide(
        color: isSelected ? AppColors.primary : Colors.grey.withValues(alpha: 0.3),
      ),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : null,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        fontSize: 13,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isAdmin = authProvider.currentUser?.role == 'Admin';

    return AdminScaffold(
      title: 'Inventory',
      currentRoute: AppRouter.inventory,
      backgroundColor: AppColors.background,
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: _showAddProductDialog,
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add),
              label: const Text('Add product'),
            )
          : null,
      body: Column(
        children: [
          // Search Bar + Tabs Header
          Container(
            color: AppColors.surface,
            child: Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: CustomTextField(
                    controller: _searchController,
                    hint: 'Search products...',
                    prefixIcon:
                        Icon(Icons.search, color: Colors.grey[400]),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon:
                                Icon(Icons.clear, color: Colors.grey[400]),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                    onChanged: _onSearchChanged,
                  ),
                ),

                // Store Filter
                Consumer<StoresProvider>(
                  builder: (context, storesProvider, _) {
                    final stores = storesProvider.stores;
                    if (stores.isEmpty) return const SizedBox.shrink();
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Row(
                        children: [
                          _storeChip('All Stores', null),
                          ...stores.map((Store s) => Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: _storeChip(s.name, s.id),
                          )),
                        ],
                      ),
                    );
                  },
                ),

                // Filter Tabs
                TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.primary,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: Colors.grey[600],
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  tabs: const [
                    Tab(text: 'All'),
                    Tab(text: 'Low stock'),
                    Tab(text: 'Out of stock'),
                  ],
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: Consumer<InventoryProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.storeProducts.isEmpty) {
                  return const LoadingIndicator();
                }

                if (provider.error != null) {
                  return ErrorDisplay(
                    message: provider.error!,
                    onRetry: () => provider.fetchStoreProducts(),
                  );
                }

                final products =
                    _getFilteredProducts(provider.storeProducts);

                if (products.isEmpty) {
                  String emptyTitle;
                  String emptyMessage;

                  switch (_filterType) {
                    case 'low-stock':
                      emptyTitle = 'All good!';
                      emptyMessage =
                          'There are no products with low stock';
                      break;
                    case 'out-of-stock':
                      emptyTitle = 'Everything in stock!';
                      emptyMessage =
                          'There are no products that are out of stock';
                      break;
                    default:
                      if (_searchQuery.isNotEmpty) {
                        emptyTitle = 'No results';
                        emptyMessage =
                            'No results for "$_searchQuery"';
                      } else {
                        emptyTitle = 'Empty inventory';
                        emptyMessage =
                            'There are no products in inventory yet';
                      }
                  }

                  return EmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: emptyTitle,
                    message: emptyMessage,
                    actionLabel: isAdmin &&
                            _filterType == 'all' &&
                            _searchQuery.isEmpty
                        ? 'Add first product'
                        : null,
                    onAction: isAdmin &&
                            _filterType == 'all' &&
                            _searchQuery.isEmpty
                        ? _showAddProductDialog
                        : null,
                  );
                }

                return RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: ListView.builder(
                    padding:
                        const EdgeInsets.only(top: 8, bottom: 80),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return InventoryCard(
                        product: product,
                        onTap: () => _navigateToDetail(product),
                      );
                    },
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
