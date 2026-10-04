import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/budget_model.dart';

class BudgetRepository {
  static const String _storageKey = 'expense_tracker_budgets';
  final SharedPreferences _prefs;

  BudgetRepository(this._prefs);

  List<BudgetModel> generateSampleBudgets() {
    const uuid = Uuid();
    final now = DateTime.now();

    return [
      BudgetModel(
        id: uuid.v4(),
        category: 'Overall',
        amount: 2500.00,
        month: now.month,
        year: now.year,
        note: 'Target total expense limit for the month',
        createdAt: now,
      ),
      BudgetModel(
        id: uuid.v4(),
        category: 'Food',
        amount: 400.00,
        month: now.month,
        year: now.year,
        note: 'Groceries and dining out budget',
        createdAt: now,
      ),
      BudgetModel(
        id: uuid.v4(),
        category: 'Transport',
        amount: 150.00,
        month: now.month,
        year: now.year,
        note: 'Fuel, transit pass, and ride sharing',
        createdAt: now,
      ),
      BudgetModel(
        id: uuid.v4(),
        category: 'Entertainment',
        amount: 100.00,
        month: now.month,
        year: now.year,
        note: 'Movies, outings, and subscriptions',
        createdAt: now,
      ),
    ];
  }

  Future<List<BudgetModel>> getBudgets() async {
    final rawData = _prefs.getString(_storageKey);
    if (rawData == null || rawData.isEmpty) {
      final sample = generateSampleBudgets();
      await saveBudgets(sample);
      return sample;
    }

    try {
      final List<dynamic> decoded = jsonDecode(rawData) as List<dynamic>;
      return decoded
          .map((item) => BudgetModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return generateSampleBudgets();
    }
  }

  Future<void> saveBudgets(List<BudgetModel> budgets) async {
    final list = budgets.map((b) => b.toJson()).toList();
    await _prefs.setString(_storageKey, jsonEncode(list));
  }

  Future<void> addBudget(BudgetModel budget) async {
    final current = await getBudgets();
    // If a budget already exists for this category, month, and year, replace it
    final existingIndex = current.indexWhere(
      (b) =>
          b.category.toLowerCase() == budget.category.toLowerCase() &&
          b.month == budget.month &&
          b.year == budget.year,
    );
    if (existingIndex != -1) {
      current[existingIndex] = budget;
    } else {
      current.add(budget);
    }
    await saveBudgets(current);
  }

  Future<void> updateBudget(BudgetModel budget) async {
    final current = await getBudgets();
    final index = current.indexWhere((b) => b.id == budget.id);
    if (index != -1) {
      current[index] = budget;
      await saveBudgets(current);
    }
  }

  Future<void> deleteBudget(String id) async {
    final current = await getBudgets();
    current.removeWhere((b) => b.id == id);
    await saveBudgets(current);
  }

  Future<void> clearAll() async {
    await _prefs.remove(_storageKey);
  }
}
