import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:orders_mobile/core/theme/app_colors.dart';
import 'package:orders_mobile/core/widgets/admin_scaffold.dart';
import 'package:orders_mobile/core/widgets/loading_indicator.dart';
import 'package:orders_mobile/models/products/category_model.dart';
import 'package:orders_mobile/providers/categories_provider.dart';
import 'package:orders_mobile/routes/app_router.dart';

class CategoriesListScreen extends StatefulWidget {
  const CategoriesListScreen({super.key});

  @override
  State<CategoriesListScreen> createState() => _CategoriesListScreenState();
}

class _CategoriesListScreenState extends State<CategoriesListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoriesProvider>().fetchCategories();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CategoryModel> _getFilteredCategories(List<CategoryModel> categories) {
    if (_searchController.text.isEmpty) {
      return categories;
    }

    final query = _searchController.text.toLowerCase();
    return categories.where((cat) {
      return cat.name.toLowerCase().contains(query) ||
          (cat.description?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  Future<void> _deleteCategory(CategoryModel category) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Obriši kategoriju'),
        content: Text('Da li ste sigurni da želite obrisati "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Otkaži'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Obriši', style: TextStyle(color: AppColors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await context.read<CategoriesProvider>().deleteCategory(category.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${category.name} obrisana'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Greška: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Kategorije',
      currentRoute: AppRouter.categoriesList,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, AppRouter.categoryCreate).then((_) {
            context.read<CategoriesProvider>().fetchCategories();
          });
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Dodaj kategoriju'),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.surface,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Pretraži kategorije...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    context.read<CategoriesProvider>().fetchCategories();
                  },
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.background,
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),

          // Categories Grid
          Expanded(
            child: Consumer<CategoriesProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const LoadingIndicator();
                }

                if (provider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: AppColors.error),
                        const SizedBox(height: 16),
                        Text(provider.error!, style: TextStyle(color: AppColors.error)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => provider.fetchCategories(),
                          child: const Text('Pokušaj ponovo'),
                        ),
                      ],
                    ),
                  );
                }

                final filteredCategories = _getFilteredCategories(provider.categories);

                if (filteredCategories.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.category_outlined,
                          size: 64,
                          color: AppColors.textSecondary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nema kategorija',
                          style: TextStyle(
                            fontSize: 18,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => provider.fetchCategories(),
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75, // ✅ Povećana visina kartice (0.85 → 0.75)
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: filteredCategories.length,
                    itemBuilder: (context, index) {
                      final category = filteredCategories[index];
                      return _buildCategoryCard(category);
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

  Widget _buildCategoryCard(CategoryModel category) {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRouter.categoryEdit,
          arguments: category.id,
        ).then((_) {
          context.read<CategoriesProvider>().fetchCategories();
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.textSecondary.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Icon Section
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withValues(alpha: 0.15),
                      AppColors.primary.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Center(
                  child: Icon(
                    _getCategoryIcon(category.name),
                    size: 40,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),

            // Info Section
            Expanded(
              flex: 4, // ✅ Povećano sa 3 na 4
              child: Padding(
                padding: const EdgeInsets.all(10), // ✅ Smanjeno sa 12 na 10
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Naziv i opis
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.name,
                            style: const TextStyle(
                              fontSize: 15, // ✅ Smanjeno sa 16 na 15
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (category.description != null) ...[
                            const SizedBox(height: 3), // ✅ Smanjeno sa 4 na 3
                            Text(
                              category.description!,
                              style: TextStyle(
                                fontSize: 10, // ✅ Smanjeno sa 11 na 10
                                color: AppColors.textSecondary.withValues(alpha: 0.7),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Product Count & Actions
                    Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 13, // ✅ Smanjeno sa 14 na 13
                              color: AppColors.textSecondary.withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${category.productCount} proizvoda',
                              style: TextStyle(
                                fontSize: 10, // ✅ Smanjeno sa 11 na 10
                                color: AppColors.textSecondary.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6), // ✅ Smanjeno sa 8 na 6
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    AppRouter.categoryEdit,
                                    arguments: category.id,
                                  ).then((_) {
                                    context.read<CategoriesProvider>().fetchCategories();
                                  });
                                },
                                icon: const Icon(Icons.edit, size: 13), // ✅ Smanjeno sa 14 na 13
                                label: const Text('Uredi', style: TextStyle(fontSize: 10)), // ✅ Smanjeno sa 11 na 10
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  side: BorderSide(
                                    color: AppColors.primary.withValues(alpha: 0.5),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 4), // ✅ Smanjeno sa 6 na 4
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            IconButton(
                              onPressed: () => _deleteCategory(category),
                              icon: const Icon(Icons.delete, size: 16), // ✅ Smanjeno sa 18 na 16
                              color: AppColors.error,
                              style: IconButton.styleFrom(
                                backgroundColor: AppColors.error.withValues(alpha: 0.1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.all(4), // ✅ Smanjeno sa 6 na 4
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String name) {
    final lowercaseName = name.toLowerCase();
    if (lowercaseName.contains('food') ||
        lowercaseName.contains('jelo') ||
        lowercaseName.contains('hrana')) {
      return Icons.restaurant;
    } else if (lowercaseName.contains('drink') ||
        lowercaseName.contains('piće') ||
        lowercaseName.contains('pice')) {
      return Icons.local_bar;
    } else if (lowercaseName.contains('coffee') || lowercaseName.contains('kafa')) {
      return Icons.coffee;
    } else if (lowercaseName.contains('dessert') || lowercaseName.contains('desert')) {
      return Icons.cake;
    } else if (lowercaseName.contains('breakfast') || lowercaseName.contains('doručak')) {
      return Icons.free_breakfast;
    }
    return Icons.category;
  }
}