import 'package:flutter/material.dart';
import '../../../models/category_model.dart';
import '../../../core/theme/app_colors.dart';

class CategoryFilter extends StatelessWidget {
  final List<CategoryModel> categories;
  final String? selectedCategory;
  final Function(String?) onCategorySelected;

  const CategoryFilter({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: PopupMenuButton<String?>(
        offset: const Offset(0, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        onSelected: onCategorySelected,
        itemBuilder: (context) {
          return [
            PopupMenuItem<String?>(
              value: null,
              child: Row(
                children: [
                  Icon(
                    selectedCategory == null
                        ? Icons.check_circle
                        : Icons.circle_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  const Text('All Categories'),
                ],
              ),
            ),
            ...categories.map((category) {
              return PopupMenuItem<String?>(
                value: category.id,
                child: Row(
                  children: [
                    Icon(
                      selectedCategory == category.id
                          ? Icons.check_circle
                          : Icons.circle_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(category.name),
                    ),
                    Text(
                      '',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ];
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.filter_list, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  selectedCategory == null
                      ? 'All Categories'
                      : categories
                          .firstWhere((c) => c.id == selectedCategory)
                          .name,
                  style: const TextStyle(fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.arrow_drop_down, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
