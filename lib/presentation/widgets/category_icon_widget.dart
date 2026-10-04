import 'package:flutter/material.dart';
import '../../core/constants/app_categories.dart';
import '../../providers/app_state_scope.dart';

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
    IconData icon;
    Color color;

    final appState =
        context.dependOnInheritedWidgetOfExactType<AppStateScope>()?.notifier;
    final customCat = appState?.getCategoryByName(category);

    if (customCat != null) {
      icon = customCat.icon;
      color = customCat.color;
    } else {
      final meta =
          AppCategories.getCategoryMeta(category, isExpense: isExpense);
      icon = meta.icon;
      color = meta.color;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Center(
        child: Icon(
          icon,
          color: color,
          size: iconSize,
        ),
      ),
    );
  }
}
