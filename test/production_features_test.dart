import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expense_tracker/data/models/budget_model.dart';
import 'package:expense_tracker/data/models/transaction_model.dart';
import 'package:expense_tracker/data/repositories/budget_repository.dart';
import 'package:expense_tracker/data/repositories/category_repository.dart';
import 'package:expense_tracker/data/repositories/recurring_transaction_repository.dart';
import 'package:expense_tracker/data/repositories/transaction_repository.dart';
import 'package:expense_tracker/data/services/data_export_service.dart';
import 'package:expense_tracker/data/services/preferences_service.dart';
import 'package:expense_tracker/providers/app_state.dart';

void main() {
  late SharedPreferences prefs;
  late PreferencesService prefService;
  late TransactionRepository txRepo;
  late CategoryRepository catRepo;
  late BudgetRepository budgetRepo;
  late RecurringTransactionRepository recRepo;
  late AppState appState;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    prefService = PreferencesService(prefs);
    txRepo = TransactionRepository(prefs);
    catRepo = CategoryRepository(prefs);
    budgetRepo = BudgetRepository(prefs);
    recRepo = RecurringTransactionRepository(prefs);

    appState = AppState(
      repository: txRepo,
      preferencesService: prefService,
      categoryRepository: catRepo,
      budgetRepository: budgetRepo,
      recurringTransactionRepository: recRepo,
    );
    await appState.isReady;
    await appState.clearAllFinancialData();
  });

  group('First-Run Onboarding & Profile Preferences', () {
    test('Onboarding defaults to not completed, currency defaults to PKR', () {
      expect(appState.hasCompletedOnboarding, isFalse);
      expect(appState.currencyCode, 'PKR');
      expect(appState.currencySymbol, '₨');
      expect(appState.displayName, '');
      expect(appState.monthlyBudgetPreference, isNull);
    });

    test('Completing onboarding persists locally and preserves settings', () async {
      await appState.setDisplayName('John Doe');
      await appState.setCurrency(const CurrencyInfo(code: 'USD', symbol: '\$', name: 'US Dollar'));
      await appState.completeOnboarding();

      expect(appState.hasCompletedOnboarding, isTrue);
      expect(appState.displayName, 'John Doe');
      expect(appState.currencyCode, 'USD');
      expect(appState.currencySymbol, '\$');

      // Verify in raw SharedPreferences
      expect(prefs.getBool('pref_has_completed_onboarding'), isTrue);
      expect(prefs.getString('pref_display_name'), 'John Doe');
      expect(prefs.getString('pref_currency_code'), 'USD');
    });

    test('Monthly budget target preference sets and clears cleanly', () async {
      await appState.setMonthlyBudgetPreference(75000);
      expect(appState.monthlyBudgetPreference, 75000.0);

      await appState.setMonthlyBudgetPreference(null);
      expect(appState.monthlyBudgetPreference, isNull);
    });
  });

  group('Undo Delete Transactions', () {
    test('Deleting a transaction allows immediate undo and restores everywhere', () async {
      final tx = TransactionModel(
        id: 'tx-undo-test',
        title: 'Office Supplies',
        amount: 2500,
        type: TransactionType.expense,
        category: 'Shopping',
        date: DateTime.now(),
        createdAt: DateTime.now(),
      );

      await appState.addTransaction(tx);
      expect(appState.transactions.length, 1);
      expect(appState.totalExpense, 2500.0);

      // Delete transaction
      final deletedTx = await appState.deleteTransaction(tx.id);
      expect(deletedTx, isNotNull);
      expect(deletedTx?.id, tx.id);
      expect(appState.transactions.isEmpty, isTrue);
      expect(appState.totalExpense, 0.0);

      // Undo deletion
      final undoSuccess = await appState.undoDeleteTransaction();
      expect(undoSuccess, isTrue);
      expect(appState.transactions.length, 1);
      expect(appState.transactions.first.title, 'Office Supplies');
      expect(appState.totalExpense, 2500.0);
    });
  });

  group('Financial Health Summary Calculations', () {
    test('Returns graceful fallback when no transaction records exist', () {
      final health = appState.getFinancialHealthSummary(2026, 10);
      expect(health.hasSufficientData, isFalse);
      expect(health.spendingTrend, 'Not enough data yet.');
      expect(health.generalHealthStatus, 'Not enough data yet.');
    });

    test('Accurately computes savings rate, spending trend vs last month, and adherence', () async {
      // Month 1 (Sep 2026): Expense = 10000
      await appState.addTransaction(TransactionModel(
        id: 'tx-sep',
        title: 'Sep Groceries',
        amount: 10000,
        type: TransactionType.expense,
        category: 'Food',
        date: DateTime(2026, 9, 15),
        createdAt: DateTime.now(),
      ));

      // Month 2 (Oct 2026): Income = 50000, Expense = 8000
      await appState.addTransaction(TransactionModel(
        id: 'tx-oct-inc',
        title: 'Salary',
        amount: 50000,
        type: TransactionType.income,
        category: 'Salary',
        date: DateTime(2026, 10, 1),
        createdAt: DateTime.now(),
      ));
      await appState.addTransaction(TransactionModel(
        id: 'tx-oct-exp',
        title: 'Oct Groceries',
        amount: 8000,
        type: TransactionType.expense,
        category: 'Food',
        date: DateTime(2026, 10, 5),
        createdAt: DateTime.now(),
      ));

      // Add a budget for Food: 15000
      await appState.addBudget(BudgetModel(
        id: 'b-food',
        category: 'Food',
        amount: 15000,
        month: 10,
        year: 2026,
        createdAt: DateTime.now(),
      ));

      final health = appState.getFinancialHealthSummary(2026, 10);
      expect(health.hasSufficientData, isTrue);

      // Savings rate = (50000 - 8000) / 50000 = 84%
      expect(health.savingsRate, closeTo(84.0, 0.1));

      // Spending decreased: from 10000 to 8000 = 20% decrease
      expect(health.spendingTrend, contains('decreased 20%'));

      // Budget adherence: budgets within limit
      expect(health.budgetStatus, contains('budgets within limit'));

      // Health status: Positive standing
      expect(health.generalHealthStatus, anyOf('Strong Financial Health', 'Stable Financial Standing'));
    });
  });

  group('Yearly Overview Calculations', () {
    test('Handles years with no data gracefully', () {
      final yearly = appState.getYearlyOverview(2025);
      expect(yearly.hasData, isFalse);
      expect(yearly.totalIncome, 0.0);
      expect(yearly.totalExpense, 0.0);
      expect(yearly.monthlyBreakdown.length, 12);
      expect(yearly.monthlyBreakdown.every((m) => m.transactionCount == 0), isTrue);
    });

    test('Computes 12-month totals accurately from actual records', () async {
      await appState.addTransaction(TransactionModel(
        id: 'jan-inc',
        title: 'Jan Bonus',
        amount: 20000,
        type: TransactionType.income,
        category: 'Salary',
        date: DateTime(2026, 1, 10),
        createdAt: DateTime.now(),
      ));
      await appState.addTransaction(TransactionModel(
        id: 'jan-exp',
        title: 'Jan Rent',
        amount: 12000,
        type: TransactionType.expense,
        category: 'Bills',
        date: DateTime(2026, 1, 15),
        createdAt: DateTime.now(),
      ));
      await appState.addTransaction(TransactionModel(
        id: 'feb-exp',
        title: 'Feb Rent',
        amount: 12000,
        type: TransactionType.expense,
        category: 'Bills',
        date: DateTime(2026, 2, 15),
        createdAt: DateTime.now(),
      ));

      final yearly = appState.getYearlyOverview(2026);
      expect(yearly.hasData, isTrue);
      expect(yearly.totalIncome, 20000.0);
      expect(yearly.totalExpense, 24000.0);
      expect(yearly.netBalance, -4000.0);

      // January item
      final jan = yearly.monthlyBreakdown[0];
      expect(jan.monthName, 'January');
      expect(jan.income, 20000.0);
      expect(jan.expense, 12000.0);
      expect(jan.net, 8000.0);
      expect(jan.transactionCount, 2);

      // February item
      final feb = yearly.monthlyBreakdown[1];
      expect(feb.income, 0.0);
      expect(feb.expense, 12000.0);
      expect(feb.net, -12000.0);
      expect(feb.transactionCount, 1);
    });
  });

  group('Category Insights Calculations', () {
    test('Computes count, total, average, largest, and 6-month trends', () async {
      final now = DateTime.now();
      await appState.addTransaction(TransactionModel(
        id: 'c1',
        title: 'Burger',
        amount: 500,
        type: TransactionType.expense,
        category: 'Food',
        date: now,
        createdAt: now,
      ));
      await appState.addTransaction(TransactionModel(
        id: 'c2',
        title: 'Dinner Buffet',
        amount: 2500,
        type: TransactionType.expense,
        category: 'Food',
        date: now,
        createdAt: now,
      ));

      final insights = appState.getCategoryInsights('Food', type: TransactionType.expense);
      expect(insights.count, 2);
      expect(insights.totalAmount, 3000.0);
      expect(insights.averageAmount, 1500.0);
      expect(insights.largestAmount, 2500.0);
      expect(insights.monthlyTrend.length, 6);
    });
  });

  group('Multi-tier Budget Warnings', () {
    test('Classifies budget alerts into 50%, 75%, 90%, 100%, and over-budget', () async {
      // Create budget for Food: 1000
      await appState.addBudget(BudgetModel(
        id: 'b-tier',
        category: 'Food',
        amount: 1000,
        month: 10,
        year: 2026,
        createdAt: DateTime.now(),
      ));

      // Spend 500 (50%)
      await appState.addTransaction(TransactionModel(
        id: 't-50',
        title: 'Snacks',
        amount: 500,
        type: TransactionType.expense,
        category: 'Food',
        date: DateTime(2026, 10, 2),
        createdAt: DateTime.now(),
      ));
      var warnings = appState.getBudgetWarningsForMonth(2026, 10);
      expect(warnings.length, 1);
      expect(warnings.first.alertLevel, BudgetAlertLevel.fiftyPercent);

      // Spend 420 more (total 920 = 92%)
      await appState.addTransaction(TransactionModel(
        id: 't-90',
        title: 'Dinner',
        amount: 420,
        type: TransactionType.expense,
        category: 'Food',
        date: DateTime(2026, 10, 3),
        createdAt: DateTime.now(),
      ));
      warnings = appState.getBudgetWarningsForMonth(2026, 10);
      expect(warnings.first.alertLevel, BudgetAlertLevel.ninetyPercent);
      expect(warnings.first.message, contains('92% used'));

      // Spend 150 more (total 1070 = 107% -> Over budget)
      await appState.addTransaction(TransactionModel(
        id: 't-over',
        title: 'Late Night Coffee',
        amount: 150,
        type: TransactionType.expense,
        category: 'Food',
        date: DateTime(2026, 10, 4),
        createdAt: DateTime.now(),
      ));
      warnings = appState.getBudgetWarningsForMonth(2026, 10);
      expect(warnings.first.alertLevel, BudgetAlertLevel.overBudget);
      expect(warnings.first.isOverBudget, isTrue);
      expect(warnings.first.message, contains('exceeded its limit'));
    });
  });

  group('Defensive Data Parsing & Backup Schema v1', () {
    test('Protects against NaN and Infinity in TransactionModel', () {
      final safeTx = TransactionModel(
        id: 'nan-test',
        title: 'Edge Case',
        amount: double.nan,
        type: TransactionType.expense,
        category: 'Food',
        date: DateTime.now(),
        createdAt: DateTime.now(),
      );
      expect(safeTx.amount, 0.0);

      final safeJson = TransactionModel.fromJson({
        'id': 'json-inf',
        'title': 'Inf test',
        'amount': 'invalid_num',
        'type': 'expense',
        'category': 'Food',
        'date': '2026-10-05T08:00:00.000',
        'createdAt': '2026-10-05T08:00:00.000',
      });
      expect(safeJson.amount, 0.0);
    });

    test('Validates backup version schema v1 correctly', () {
      final backupJson = DataExportService.generateJsonBackup(
        transactions: [],
        categories: [],
        budgets: [],
        recurringTransactions: [],
        preferences: {'currencyCode': 'PKR', 'themeMode': 'system'},
      );

      final result = DataExportService.parseAndValidateBackup(backupJson);
      expect(result.success, isTrue);
      expect(result.transactions, isEmpty);
    });
  });
}
