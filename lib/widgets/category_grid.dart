import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../models/transaction.dart';
import '../services/category_service.dart';

class CategoryGrid extends StatelessWidget {
  final List<Category> categories;
  final String? selectedCategory;
  final Function(String) onCategorySelected;
  final TransactionType type;

  const CategoryGrid({
    Key? key,
    required this.categories,
    this.selectedCategory,
    required this.onCategorySelected,
    required this.type,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final isSelected = selectedCategory == category.name;
        final categoryColor = CategoryService.getCategoryColor(category.name);

        return GestureDetector(
          onTap: () => onCategorySelected(category.name),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? type == TransactionType.income
                  ? AppColors.success
                  : AppColors.primaryBlue
                  : AppColors.lightGray,
              borderRadius: BorderRadius.circular(16),
              border: !isSelected
                  ? Border.all(color: Colors.transparent)
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  category.icon,
                  style: const TextStyle(fontSize: 28),
                ),
                const SizedBox(height: 4),
                Text(
                  category.name.split(' ')[0],
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class CategoryChip extends StatelessWidget {
  final String category;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryChip({
    Key? key,
    required this.category,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final icon = CategoryService.getCategoryIcon(category);
    final color = CategoryService.getCategoryColor(category);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : color.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(
              category,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryIcon extends StatelessWidget {
  final String category;
  final double size;

  const CategoryIcon({
    Key? key,
    required this.category,
    this.size = 40,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final icon = CategoryService.getCategoryIcon(category);
    final color = CategoryService.getCategoryColor(category);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          icon,
          style: TextStyle(fontSize: size * 0.5),
        ),
      ),
    );
  }
}