import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_categories.dart';
import '../models/transaction_model.dart';

class TransactionRepository {
  static const String _storageKey = 'expense_tracker_transactions';
  final SharedPreferences _prefs;

  TransactionRepository(this._prefs);

  SharedPreferences get prefs => _prefs;

  Future<List<TransactionModel>> getTransactions() async {
    final rawData = _prefs.getString(_storageKey);
    if (rawData == null || rawData.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> decoded = jsonDecode(rawData) as List<dynamic>;
      return decoded
          .map((item) => TransactionModel.fromJson(item as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date)); // Newest first
    } catch (e) {
      // In case of any corrupt data, return empty list safely
      return [];
    }
  }

  Future<void> saveTransactions(List<TransactionModel> transactions) async {
    final list = transactions.map((t) => t.toJson()).toList();
    await _prefs.setString(_storageKey, jsonEncode(list));
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    final current = await getTransactions();
    current.insert(0, transaction);
    await saveTransactions(current);
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    final current = await getTransactions();
    final index = current.indexWhere((t) => t.id == transaction.id);
    if (index != -1) {
      current[index] = transaction;
      await saveTransactions(current);
    }
  }

  Future<void> deleteTransaction(String id) async {
    final current = await getTransactions();
    current.removeWhere((t) => t.id == id);
    await saveTransactions(current);
  }

  Future<void> clearAllTransactions() async {
    await _prefs.remove(_storageKey);
  }

  List<TransactionModel> generateSampleTransactions() {
    const uuid = Uuid();
    final now = DateTime.now();

    return [
      TransactionModel(
        id: uuid.v4(),
        title: 'Monthly Salary',
        amount: 4500.00,
        type: TransactionType.income,
        category: AppCategories.salary,
        date: DateTime(now.year, now.month, 1, 9, 30),
        note: 'Direct deposit from TechCorp',
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      TransactionModel(
        id: uuid.v4(),
        title: 'Apartment Rent & Utilities',
        amount: 1200.00,
        type: TransactionType.expense,
        category: AppCategories.bills,
        date: DateTime(now.year, now.month, 2, 11, 00),
        note: 'October rent and high-speed internet',
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      TransactionModel(
        id: uuid.v4(),
        title: 'Weekly Grocery Shopping',
        amount: 145.50,
        type: TransactionType.expense,
        category: AppCategories.food,
        date: DateTime(now.year, now.month, now.day > 1 ? now.day - 1 : 1, 15, 20),
        note: 'Fresh produce, dairy, and pantry items',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      TransactionModel(
        id: uuid.v4(),
        title: 'Freelance Mobile App UI',
        amount: 850.00,
        type: TransactionType.income,
        category: AppCategories.freelance,
        date: DateTime(now.year, now.month, now.day > 2 ? now.day - 2 : 1, 14, 00),
        note: 'Milestone 2 payment from client',
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      TransactionModel(
        id: uuid.v4(),
        title: 'Uber Rides & Metro Pass',
        amount: 42.80,
        type: TransactionType.expense,
        category: AppCategories.transport,
        date: DateTime(now.year, now.month, now.day, 10, 15),
        note: 'Weekly transit commute pass',
        createdAt: now,
      ),
      TransactionModel(
        id: uuid.v4(),
        title: 'Cinema & Dinner with Friends',
        amount: 68.00,
        type: TransactionType.expense,
        category: AppCategories.entertainment,
        date: DateTime(now.year, now.month, now.day > 3 ? now.day - 3 : 1, 20, 30),
        note: 'Movie tickets and dinner',
        createdAt: now.subtract(const Duration(days: 3)),
      ),
    ];
  }
}
