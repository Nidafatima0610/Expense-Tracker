import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recurring_transaction_model.dart';
import '../models/transaction_model.dart';

class RecurringTransactionRepository {
  static const String _keyRecurring = 'app_recurring_transactions';
  final SharedPreferences _prefs;

  RecurringTransactionRepository(this._prefs);

  Future<List<RecurringTransactionModel>> getRecurringTransactions() async {
    final jsonString = _prefs.getString(_keyRecurring);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList
          .map((item) => RecurringTransactionModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveRecurringTransactions(List<RecurringTransactionModel> list) async {
    final jsonList = list.map((item) => item.toJson()).toList();
    await _prefs.setString(_keyRecurring, json.encode(jsonList));
  }

  Future<void> addRecurringTransaction(RecurringTransactionModel item) async {
    final current = await getRecurringTransactions();
    current.insert(0, item);
    await saveRecurringTransactions(current);
  }

  Future<void> updateRecurringTransaction(RecurringTransactionModel item) async {
    final current = await getRecurringTransactions();
    final index = current.indexWhere((r) => r.id == item.id);
    if (index != -1) {
      current[index] = item;
      await saveRecurringTransactions(current);
    }
  }

  Future<void> deleteRecurringTransaction(String id) async {
    final current = await getRecurringTransactions();
    current.removeWhere((r) => r.id == id);
    await saveRecurringTransactions(current);
  }

  Future<void> clearAll() async {
    await _prefs.remove(_keyRecurring);
  }

  List<RecurringTransactionModel> generateSampleRecurringTransactions() {
    final now = DateTime.now();
    return [
      RecurringTransactionModel(
        id: 'rec-sample-salary',
        title: 'Monthly Salary',
        amount: 250000.0,
        type: TransactionType.income,
        category: 'Salary',
        note: 'Direct company deposit',
        startDate: DateTime(now.year, now.month, 1),
        frequency: RecurrenceFrequency.monthly,
        isActive: true,
        lastGeneratedDate: DateTime(now.year, now.month, 1),
        createdAt: now,
      ),
      RecurringTransactionModel(
        id: 'rec-sample-rent',
        title: 'Apartment Rent',
        amount: 45000.0,
        type: TransactionType.expense,
        category: 'Bills',
        note: 'Landlord transfer',
        startDate: DateTime(now.year, now.month, 5),
        frequency: RecurrenceFrequency.monthly,
        isActive: true,
        lastGeneratedDate: DateTime(now.year, now.month, 5),
        createdAt: now,
      ),
      RecurringTransactionModel(
        id: 'rec-sample-internet',
        title: 'Fiber Internet Subscription',
        amount: 4500.0,
        type: TransactionType.expense,
        category: 'Bills',
        note: 'Monthly broadband bill',
        startDate: DateTime(now.year, now.month, 10),
        frequency: RecurrenceFrequency.monthly,
        isActive: true,
        lastGeneratedDate: DateTime(now.year, now.month, 10),
        createdAt: now,
      ),
    ];
  }
}
