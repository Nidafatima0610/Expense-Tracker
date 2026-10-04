import 'package:flutter/material.dart';

class CategoryMeta {
  final String name;
  final IconData icon;
  final Color color;

  const CategoryMeta({
    required this.name,
    required this.icon,
    required this.color,
  });
}

class AppCategories {
  // Expense Categories
  static const String food = 'Food';
  static const String transport = 'Transport';
  static const String shopping = 'Shopping';
  static const String bills = 'Bills';
  static const String health = 'Health';
  static const String education = 'Education';
  static const String entertainment = 'Entertainment';
  static const String otherExpense = 'Other';

  // Income Categories
  static const String salary = 'Salary';
  static const String freelance = 'Freelance';
  static const String business = 'Business';
  static const String gift = 'Gift';
  static const String otherIncome = 'Other';

  static const List<CategoryMeta> expenseCategories = [
    CategoryMeta(
      name: food,
      icon: Icons.restaurant_rounded,
      color: Color(0xFFF97316), // Orange
    ),
    CategoryMeta(
      name: transport,
      icon: Icons.directions_car_rounded,
      color: Color(0xFF0EA5E9), // Sky
    ),
    CategoryMeta(
      name: shopping,
      icon: Icons.shopping_bag_rounded,
      color: Color(0xFFEC4899), // Pink
    ),
    CategoryMeta(
      name: bills,
      icon: Icons.receipt_long_rounded,
      color: Color(0xFFEAB308), // Yellow
    ),
    CategoryMeta(
      name: health,
      icon: Icons.medical_services_rounded,
      color: Color(0xFFEF4444), // Red
    ),
    CategoryMeta(
      name: education,
      icon: Icons.school_rounded,
      color: Color(0xFF8B5CF6), // Purple
    ),
    CategoryMeta(
      name: entertainment,
      icon: Icons.sports_esports_rounded,
      color: Color(0xFF06B6D4), // Cyan
    ),
    CategoryMeta(
      name: otherExpense,
      icon: Icons.category_rounded,
      color: Color(0xFF64748B), // Slate
    ),
  ];

  static const List<CategoryMeta> incomeCategories = [
    CategoryMeta(
      name: salary,
      icon: Icons.payments_rounded,
      color: Color(0xFF10B981), // Emerald
    ),
    CategoryMeta(
      name: freelance,
      icon: Icons.laptop_mac_rounded,
      color: Color(0xFF6366F1), // Indigo
    ),
    CategoryMeta(
      name: business,
      icon: Icons.storefront_rounded,
      color: Color(0xFF3B82F6), // Blue
    ),
    CategoryMeta(
      name: gift,
      icon: Icons.card_giftcard_rounded,
      color: Color(0xFFA855F7), // Purple
    ),
    CategoryMeta(
      name: otherIncome,
      icon: Icons.account_balance_wallet_rounded,
      color: Color(0xFF14B8A6), // Teal
    ),
  ];

  static CategoryMeta getCategoryMeta(String categoryName, {bool isExpense = true}) {
    final list = isExpense ? expenseCategories : incomeCategories;
    for (final item in list) {
      if (item.name.toLowerCase() == categoryName.toLowerCase()) {
        return item;
      }
    }
    // Fallback search across both lists
    final all = [...expenseCategories, ...incomeCategories];
    for (final item in all) {
      if (item.name.toLowerCase() == categoryName.toLowerCase()) {
        return item;
      }
    }
    // Default fallback
    return CategoryMeta(
      name: categoryName,
      icon: isExpense ? Icons.category_rounded : Icons.account_balance_wallet_rounded,
      color: isExpense ? const Color(0xFF64748B) : const Color(0xFF10B981),
    );
  }
}
