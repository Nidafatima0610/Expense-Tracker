import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/savings_goal_model.dart';
import '../models/transaction_model.dart';

class SavingsGoalRepository {
  static const String _storageKey = 'expense_tracker_savings_goals';
  final SharedPreferences _prefs;

  SavingsGoalRepository(this._prefs);

  List<SavingsGoalModel> generateSampleGoals() {
    const uuid = Uuid();
    final now = DateTime.now();

    return [
      SavingsGoalModel(
        id: uuid.v4(),
        name: 'Emergency Fund',
        targetAmount: 100000.0,
        currentAmount: 45000.0,
        deadline: DateTime(now.year, now.month + 6, 1),
        category: 'Emergency Fund',
        note: '6 months of essential living expenses reserve',
        createdAt: now.subtract(const Duration(days: 30)),
        contributions: [
          GoalContribution(
            id: uuid.v4(),
            amount: 25000.0,
            date: now.subtract(const Duration(days: 25)),
            note: 'Initial deposit',
            paymentMethod: PaymentMethod.bankAccount,
          ),
          GoalContribution(
            id: uuid.v4(),
            amount: 20000.0,
            date: now.subtract(const Duration(days: 10)),
            note: 'Monthly savings transfer',
            paymentMethod: PaymentMethod.bankAccount,
          ),
        ],
      ),
      SavingsGoalModel(
        id: uuid.v4(),
        name: 'New Laptop',
        targetAmount: 150000.0,
        currentAmount: 95000.0,
        deadline: DateTime(now.year, now.month + 3, 15),
        category: 'New Laptop',
        note: 'High-performance laptop for programming & design',
        createdAt: now.subtract(const Duration(days: 45)),
        contributions: [
          GoalContribution(
            id: uuid.v4(),
            amount: 50000.0,
            date: now.subtract(const Duration(days: 40)),
            note: 'Savings from bonus',
            paymentMethod: PaymentMethod.mobileWallet,
          ),
          GoalContribution(
            id: uuid.v4(),
            amount: 45000.0,
            date: now.subtract(const Duration(days: 12)),
            note: 'Monthly contribution',
            paymentMethod: PaymentMethod.bankAccount,
          ),
        ],
      ),
      SavingsGoalModel(
        id: uuid.v4(),
        name: 'Vacation Trip',
        targetAmount: 60000.0,
        currentAmount: 20000.0,
        deadline: DateTime(now.year, now.month + 4, 20),
        category: 'Vacation',
        note: 'Summer holiday getaway',
        createdAt: now.subtract(const Duration(days: 20)),
        contributions: [
          GoalContribution(
            id: uuid.v4(),
            amount: 20000.0,
            date: now.subtract(const Duration(days: 5)),
            note: 'First savings allotment',
            paymentMethod: PaymentMethod.cash,
          ),
        ],
      ),
    ];
  }

  Future<List<SavingsGoalModel>> getGoals() async {
    final rawData = _prefs.getString(_storageKey);
    if (rawData == null || rawData.isEmpty) {
      final sample = generateSampleGoals();
      await saveGoals(sample);
      return sample;
    }

    try {
      final List<dynamic> decoded = jsonDecode(rawData) as List<dynamic>;
      return decoded
          .map((item) => SavingsGoalModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      final sample = generateSampleGoals();
      await saveGoals(sample);
      return sample;
    }
  }

  Future<void> saveGoals(List<SavingsGoalModel> goals) async {
    final encoded = jsonEncode(goals.map((g) => g.toJson()).toList());
    await _prefs.setString(_storageKey, encoded);
  }

  Future<void> addGoal(SavingsGoalModel goal) async {
    final current = await getGoals();
    current.insert(0, goal);
    await saveGoals(current);
  }

  Future<void> updateGoal(SavingsGoalModel goal) async {
    final current = await getGoals();
    final index = current.indexWhere((g) => g.id == goal.id);
    if (index != -1) {
      current[index] = goal;
      await saveGoals(current);
    }
  }

  Future<void> deleteGoal(String id) async {
    final current = await getGoals();
    current.removeWhere((g) => g.id == id);
    await saveGoals(current);
  }

  Future<void> clearAll() async {
    await _prefs.remove(_storageKey);
  }
}
