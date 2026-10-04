import 'package:flutter/material.dart';
import '../../core/constants/app_categories.dart';

class CategoryIconWidget extends StatelessWidget {
  final String category;
  final bool isExpense;
  final double size;
  final double iconSize;

  const CategoryIconWidget({
    super.key,
    required this.category,
    this.isExpense = true,
    this.size = 46.0,
    this.iconSize = 22.0,
  });

  @override
  Widget build(BuildContext context) {
    final meta = AppCategories.getCategoryMeta(category, isExpense: isExpense);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: meta.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Center(
        child: Icon(
          meta.icon,
          color: meta.color,
          size: iconSize,
        ),
      ),
    );
  }
}
