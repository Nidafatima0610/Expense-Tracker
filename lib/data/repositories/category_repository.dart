import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';

class CategoryRepository {
  static const String _storageKey = 'expense_tracker_categories';
  final SharedPreferences _prefs;

  CategoryRepository(this._prefs);

  List<CategoryModel> getDefaultCategories() {
    final now = DateTime(2026, 1, 1);

    return [
      // Expense Defaults
      CategoryModel(
        id: 'sys_exp_food',
        name: 'Food',
        iconCodePoint: Icons.restaurant_rounded.codePoint,
        colorValue: const Color(0xFFF97316).toARGB32(),
        type: TransactionType.expense,
        isSystem: true,
        createdAt: now,
      ),
      CategoryModel(
        id: 'sys_exp_transport',
        name: 'Transport',
        iconCodePoint: Icons.directions_car_rounded.codePoint,
        colorValue: const Color(0xFF0EA5E9).toARGB32(),
        type: TransactionType.expense,
        isSystem: true,
        createdAt: now,
      ),
      CategoryModel(
        id: 'sys_exp_shopping',
        name: 'Shopping',
        iconCodePoint: Icons.shopping_bag_rounded.codePoint,
        colorValue: const Color(0xFFEC4899).toARGB32(),
        type: TransactionType.expense,
        isSystem: true,
        createdAt: now,
      ),
      CategoryModel(
        id: 'sys_exp_bills',
        name: 'Bills',
        iconCodePoint: Icons.receipt_long_rounded.codePoint,
        colorValue: const Color(0xFFEAB308).toARGB32(),
        type: TransactionType.expense,
        isSystem: true,
        createdAt: now,
      ),
      CategoryModel(
        id: 'sys_exp_health',
        name: 'Health',
        iconCodePoint: Icons.medical_services_rounded.codePoint,
        colorValue: const Color(0xFFEF4444).toARGB32(),
        type: TransactionType.expense,
        isSystem: true,
        createdAt: now,
      ),
      CategoryModel(
        id: 'sys_exp_education',
        name: 'Education',
        iconCodePoint: Icons.school_rounded.codePoint,
        colorValue: const Color(0xFF8B5CF6).toARGB32(),
        type: TransactionType.expense,
        isSystem: true,
        createdAt: now,
      ),
      CategoryModel(
        id: 'sys_exp_entertainment',
        name: 'Entertainment',
        iconCodePoint: Icons.sports_esports_rounded.codePoint,
        colorValue: const Color(0xFF06B6D4).toARGB32(),
        type: TransactionType.expense,
        isSystem: true,
        createdAt: now,
      ),
      CategoryModel(
        id: 'sys_exp_other',
        name: 'Other',
        iconCodePoint: Icons.category_rounded.codePoint,
        colorValue: const Color(0xFF64748B).toARGB32(),
        type: TransactionType.expense,
        isSystem: true,
        createdAt: now,
      ),

      // Income Defaults
      CategoryModel(
        id: 'sys_inc_salary',
        name: 'Salary',
        iconCodePoint: Icons.payments_rounded.codePoint,
        colorValue: const Color(0xFF10B981).toARGB32(),
        type: TransactionType.income,
        isSystem: true,
        createdAt: now,
      ),
      CategoryModel(
        id: 'sys_inc_freelance',
        name: 'Freelance',
        iconCodePoint: Icons.laptop_mac_rounded.codePoint,
        colorValue: const Color(0xFF6366F1).toARGB32(),
        type: TransactionType.income,
        isSystem: true,
        createdAt: now,
      ),
      CategoryModel(
        id: 'sys_inc_business',
        name: 'Business',
        iconCodePoint: Icons.storefront_rounded.codePoint,
        colorValue: const Color(0xFF3B82F6).toARGB32(),
        type: TransactionType.income,
        isSystem: true,
        createdAt: now,
      ),
      CategoryModel(
        id: 'sys_inc_gift',
        name: 'Gift',
        iconCodePoint: Icons.card_giftcard_rounded.codePoint,
        colorValue: const Color(0xFFA855F7).toARGB32(),
        type: TransactionType.income,
        isSystem: true,
        createdAt: now,
      ),
      CategoryModel(
        id: 'sys_inc_other',
        name: 'Other',
        iconCodePoint: Icons.account_balance_wallet_rounded.codePoint,
        colorValue: const Color(0xFF14B8A6).toARGB32(),
        type: TransactionType.income,
        isSystem: true,
        createdAt: now,
      ),
    ];
  }

  Future<List<CategoryModel>> getCategories() async {
    final rawData = _prefs.getString(_storageKey);
    if (rawData == null || rawData.isEmpty) {
      final defaults = getDefaultCategories();
      await saveCategories(defaults);
      return defaults;
    }

    try {
      final List<dynamic> decoded = jsonDecode(rawData) as List<dynamic>;
      final list = decoded
          .map((item) => CategoryModel.fromJson(item as Map<String, dynamic>))
          .toList();
      return list;
    } catch (e) {
      return getDefaultCategories();
    }
  }

  Future<void> saveCategories(List<CategoryModel> categories) async {
    final list = categories.map((c) => c.toJson()).toList();
    await _prefs.setString(_storageKey, jsonEncode(list));
  }

  Future<void> addCategory(CategoryModel category) async {
    final current = await getCategories();
    current.add(category);
    await saveCategories(current);
  }

  Future<void> updateCategory(CategoryModel category) async {
    final current = await getCategories();
    final index = current.indexWhere((c) => c.id == category.id);
    if (index != -1) {
      current[index] = category;
      await saveCategories(current);
    }
  }

  Future<void> deleteCategory(String id) async {
    final current = await getCategories();
    current.removeWhere((c) => c.id == id);
    await saveCategories(current);
  }
}
