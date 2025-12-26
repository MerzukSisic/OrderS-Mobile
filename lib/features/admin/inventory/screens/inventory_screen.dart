import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:orders_mobile/core/theme/app_colors.dart';
import 'package:orders_mobile/core/widgets/empty_state.dart';
import 'package:orders_mobile/core/widgets/error_display.dart';
import 'package:orders_mobile/core/widgets/loading_indicator.dart';
import 'package:orders_mobile/providers/auth_provider.dart';
import 'package:orders_mobile/providers/inventory_provider.dart';
import 'package:provider/provider.dart';

import '../widgets/inventory_card.dart';


class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);

    // Fetch products AFTER build is complete using SchedulerBinding
    SchedulerBinding.instance.addPostFrameCallback((_) {
      Provider.of<InventoryProvider>(context, listen: false).fetchStoreProducts();
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
      final provider = context.read<InventoryProvider>();
      switch (_tabController.index) {
        case 0:
          provider.setFilterType('all');
          break;
        case 1:
          provider.setFilterType('low-stock');
          break;
        case 2:
          provider.setFilterType('out-of-stock');
          break;
      }
    }
  }

  void _onSearchChanged(String query) {
    context.read<InventoryProvider>().setSearchQuery(query);
  }

  Future<void> _onRefresh() async {
    await context.read<InventoryProvider>().fetchStoreProducts();
  }

  void _navigateToDetail(String productId) {
    Navigator.pushNamed(
      context,
      '/inventory-detail',
      arguments: productId,
    );
  }

  void _showAddProductDialog() {
    // TODO: Implement add product dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Dodavanje proizvoda - u izradi'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isAdmin = authProvider.user?.role == 'Admin';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventar'),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Pretraži proizvode...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
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
                  Tab(text: 'Svi'),
                  Tab(text: 'Nisko stanje'),
                  Tab(text: 'Nema na stanju'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: Consumer<InventoryProvider>(
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

          final products = provider.storeProducts;

          if (products.isEmpty) {
            String emptyTitle;
            String emptyMessage;
            
            switch (provider.filterType) {
              case 'low-stock':
                emptyTitle = 'Sve OK!';
                emptyMessage = 'Nema proizvoda sa niskim stanjem';
                break;
              case 'out-of-stock':
                emptyTitle = 'Sve na stanju!';
                emptyMessage = 'Nema proizvoda bez stanja';
                break;
              default:
                if (provider.searchQuery.isNotEmpty) {
                  emptyTitle = 'Nema rezultata';
                  emptyMessage = 'Nema rezultata za "${provider.searchQuery}"';
                } else {
                  emptyTitle = 'Prazan inventar';
                  emptyMessage = 'Još nema proizvoda u inventaru';
                }
            }

            return EmptyState(
              icon: Icons.inventory_2_outlined,
              title: emptyTitle,
              message: emptyMessage,
              actionLabel: isAdmin && provider.filterType == 'all' && provider.searchQuery.isEmpty
                  ? 'Dodaj prvi proizvod'
                  : null,
              onAction: isAdmin && provider.filterType == 'all' && provider.searchQuery.isEmpty
                  ? _showAddProductDialog
                  : null,
            );
          }

          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 80),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return InventoryCard(
                  product: product,
                  onTap: () => _navigateToDetail(product.id),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: _showAddProductDialog,
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add),
              label: const Text('Dodaj proizvod'),
            )
          : null,
    );
  }
}