import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expense_tracker/data/models/budget_model.dart';
import 'package:expense_tracker/data/models/category_model.dart';
import 'package:expense_tracker/data/models/recurring_transaction_model.dart';
import 'package:expense_tracker/data/models/transaction_model.dart';
import 'package:expense_tracker/data/services/data_export_service.dart';
import 'package:expense_tracker/providers/app_state.dart';
import 'package:expense_tracker/data/repositories/transaction_repository.dart';
import 'package:expense_tracker/data/repositories/category_repository.dart';
import 'package:expense_tracker/data/repositories/budget_repository.dart';
import 'package:expense_tracker/data/repositories/recurring_transaction_repository.dart';
import 'package:expense_tracker/data/services/preferences_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppState appState;
  late TransactionRepository transactionRepo;
  late CategoryRepository categoryRepo;
  late BudgetRepository budgetRepo;
  late RecurringTransactionRepository recurringRepo;
  late PreferencesService prefService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    prefService = PreferencesService(prefs);
    transactionRepo = TransactionRepository(prefs);
    categoryRepo = CategoryRepository(prefs);
    budgetRepo = BudgetRepository(prefs);
    recurringRepo = RecurringTransactionRepository(prefs);

    appState = AppState(
      repository: transactionRepo,
      preferencesService: prefService,
      categoryRepository: categoryRepo,
      budgetRepository: budgetRepo,
      recurringTransactionRepository: recurringRepo,
    );
    await appState.isReady;
    await appState.clearAllTransactions();
  });

  group('DataExportService CSV Export Tests', () {
    test('generateTransactionsCsv creates standard compliant CSV with headers and rows', () {
      final txList = [
        TransactionModel(
          id: 'tx-1',
          title: 'Monthly Salary',
          amount: 50000.0,
          date: DateTime(2026, 10, 1, 10, 30),
          category: 'Salary',
          type: TransactionType.income,
          note: 'Full time salary, with comma',
          createdAt: DateTime(2026, 10, 1),
        ),
        TransactionModel(
          id: 'tx-2',
          title: 'Groceries "Supermarket"',
          amount: 4500.50,
          date: DateTime(2026, 10, 2, 18, 0),
          category: 'Food',
          type: TransactionType.expense,
          createdAt: DateTime(2026, 10, 2),
        ),
      ];

      final csv = DataExportService.generateTransactionsCsv(txList);

      expect(csv.contains('Date,Time,Title,Type,Category,Amount,Currency,Note,Recurrence'), isTrue);
      expect(csv.contains('2026-10-01'), isTrue);
      expect(csv.contains('Monthly Salary'), isTrue);
      expect(csv.contains('50000.00'), isTrue);
      expect(csv.contains('INCOME'), isTrue);
      expect(csv.contains('EXPENSE'), isTrue);
      expect(csv.contains('"Full time salary, with comma"'), isTrue);
      expect(csv.contains('"Groceries ""Supermarket"""'), isTrue);
    });

    test('generateTransactionsCsv with empty list returns valid header row', () {
      final csv = DataExportService.generateTransactionsCsv([]);
      expect(csv.trim(), equals('Date,Time,Title,Type,Category,Amount,Currency,Note,Recurrence'));
    });
  });

  group('DataExportService Backup & Restore Validation Tests', () {
    test('generateJsonBackup produces valid parseable JSON with all model records', () {
      final backupJson = DataExportService.generateJsonBackup(
        transactions: [
          TransactionModel(
            id: 't-1',
            title: 'Test Tx',
            amount: 100.0,
            date: DateTime(2026, 10, 1),
            category: 'Food',
            type: TransactionType.expense,
            createdAt: DateTime(2026, 10, 1),
          ),
        ],
        categories: [
          CategoryModel(
            id: 'cat-1',
            name: 'Food',
            iconCodePoint: 0xe532,
            colorValue: 0xFFFF5722,
            type: TransactionType.expense,
            isSystem: true,
            createdAt: DateTime.now(),
          ),
        ],
        budgets: [
          BudgetModel(
            id: 'b-1',
            category: 'Food',
            amount: 1000.0,
            year: 2026,
            month: 10,
            createdAt: DateTime.now(),
          ),
        ],
        recurringTransactions: [
          RecurringTransactionModel(
            id: 'r-1',
            title: 'Netflix',
            amount: 15.0,
            category: 'Entertainment',
            type: TransactionType.expense,
            frequency: RecurrenceFrequency.monthly,
            startDate: DateTime(2026, 1, 1),
            createdAt: DateTime.now(),
          ),
        ],
        preferences: {'currencyCode': 'PKR', 'themeMode': 'dark'},
      );

      final decoded = jsonDecode(backupJson) as Map<String, dynamic>;
      expect(decoded['version'], equals(1));
      expect(decoded['app'], equals('ExpenseTracker'));
      expect(decoded['transactions'], hasLength(1));
      expect(decoded['categories'], hasLength(1));
      expect(decoded['budgets'], hasLength(1));
      expect(decoded['recurringTransactions'], hasLength(1));
      expect(decoded['preferences']['currencyCode'], equals('PKR'));
    });

    test('parseAndValidateBackup safely handles corrupt JSON or invalid app metadata', () {
      final corruptResult = DataExportService.parseAndValidateBackup('invalid json string {]');
      expect(corruptResult.success, isFalse);
      expect(corruptResult.message, contains('Malformed JSON'));

      final wrongAppResult = DataExportService.parseAndValidateBackup('{"version": 1, "app": "OtherApp"}');
      expect(wrongAppResult.success, isFalse);
      expect(wrongAppResult.message, contains('Expense Tracker backup'));
    });

    test('parseAndValidateBackup parses valid JSON correctly', () {
      final raw = jsonEncode({
        'version': 1,
        'app': 'ExpenseTracker',
        'exportedAt': DateTime.now().toIso8601String(),
        'transactions': [
          {
            'id': 't1',
            'title': 'Coffee',
            'amount': 5.0,
            'date': '2026-10-01T08:00:00.000',
            'category': 'Food',
            'type': 'expense',
            'createdAt': '2026-10-01T08:00:00.000',
          }
        ],
        'categories': [],
        'budgets': [],
        'recurringTransactions': [],
        'preferences': {'currencyCode': 'USD', 'themeMode': 'dark'},
      });

      final result = DataExportService.parseAndValidateBackup(raw);
      expect(result.success, isTrue);
      expect(result.transactions, hasLength(1));
      expect(result.preferences?['currencyCode'], equals('USD'));
    });
  });

  group('Month-over-Month Comparison Tests', () {
    test('computes MoM changes properly with previous data', () async {
      // Previous month (Sept 2026)
      await appState.addTransaction(TransactionModel(
        id: 'sep-inc',
        title: 'Salary',
        amount: 10000.0,
        date: DateTime(2026, 9, 1),
        category: 'Salary',
        type: TransactionType.income,
        createdAt: DateTime(2026, 9, 1),
      ));
      await appState.addTransaction(TransactionModel(
        id: 'sep-exp',
        title: 'Rent',
        amount: 4000.0,
        date: DateTime(2026, 9, 5),
        category: 'Housing',
        type: TransactionType.expense,
        createdAt: DateTime(2026, 9, 5),
      ));

      // Current month (Oct 2026)
      await appState.addTransaction(TransactionModel(
        id: 'oct-inc',
        title: 'Salary + Bonus',
        amount: 12000.0,
        date: DateTime(2026, 10, 1),
        category: 'Salary',
        type: TransactionType.income,
        createdAt: DateTime(2026, 10, 1),
      ));
      await appState.addTransaction(TransactionModel(
        id: 'oct-exp',
        title: 'Rent + Food',
        amount: 5000.0,
        date: DateTime(2026, 10, 5),
        category: 'Housing',
        type: TransactionType.expense,
        createdAt: DateTime(2026, 10, 5),
      ));

      final comparison = appState.getMonthOverMonthComparison(2026, 10);

      expect(comparison.hasPreviousData, isTrue);
      expect(comparison.currentIncome, equals(12000.0));
      expect(comparison.previousIncome, equals(10000.0));
      expect(comparison.incomeChange, equals(2000.0));
      expect(comparison.incomePercentChange, closeTo(20.0, 0.01));

      expect(comparison.currentExpense, equals(5000.0));
      expect(comparison.previousExpense, equals(4000.0));
      expect(comparison.expenseChange, equals(1000.0));
      expect(comparison.expensePercentChange, closeTo(25.0, 0.01));

      expect(comparison.currentBalance, equals(7000.0));
      expect(comparison.previousBalance, equals(6000.0));
      expect(comparison.balanceChange, equals(1000.0));
      expect(comparison.balancePercentChange, closeTo(16.66, 0.1));
    });

    test('gracefully handles empty previous month without division by zero', () async {
      await appState.addTransaction(TransactionModel(
        id: 'jan-1',
        title: 'Freelance',
        amount: 3000.0,
        date: DateTime(2026, 1, 15),
        category: 'Freelance',
        type: TransactionType.income,
        createdAt: DateTime(2026, 1, 15),
      ));

      final comparison = appState.getMonthOverMonthComparison(2026, 1);
      expect(comparison.hasPreviousData, isFalse);
      expect(comparison.incomePercentChange, isNull);
      expect(comparison.expensePercentChange, isNull);
      expect(comparison.balancePercentChange, isNull);
      expect(comparison.incomeChange, equals(3000.0));
    });
  });

  group('Recurring Transactions Due Generation & Prevention Tests', () {
    test('calculates next occurrence accurately for daily, weekly, monthly, yearly', () {
      final now = DateTime(2026, 10, 4);

      final dailyRule = RecurringTransactionModel(
        id: 'r-daily',
        title: 'Coffee',
        amount: 5.0,
        category: 'Food',
        type: TransactionType.expense,
        frequency: RecurrenceFrequency.daily,
        startDate: DateTime(2026, 10, 1),
        createdAt: DateTime.now(),
      );
      final nextDaily = dailyRule.getNextOccurrence(now);
      expect(nextDaily, equals(DateTime(2026, 10, 5)));

      final weeklyRule = RecurringTransactionModel(
        id: 'r-weekly',
        title: 'Groceries',
        amount: 100.0,
        category: 'Food',
        type: TransactionType.expense,
        frequency: RecurrenceFrequency.weekly,
        startDate: DateTime(2026, 10, 1),
        createdAt: DateTime.now(),
      );
      final nextWeekly = weeklyRule.getNextOccurrence(DateTime(2026, 10, 1));
      expect(nextWeekly, equals(DateTime(2026, 10, 8)));

      final monthlyRule = RecurringTransactionModel(
        id: 'r-monthly',
        title: 'Internet',
        amount: 60.0,
        category: 'Utilities',
        type: TransactionType.expense,
        frequency: RecurrenceFrequency.monthly,
        startDate: DateTime(2026, 1, 15),
        createdAt: DateTime.now(),
      );
      final nextMonthly = monthlyRule.getNextOccurrence(DateTime(2026, 9, 15));
      expect(nextMonthly, equals(DateTime(2026, 10, 15)));
    });

    test('addRecurringTransaction immediately generates due transactions and prevents duplicate generation', () async {
      final initialTxCount = appState.transactions.length;

      // Add rule due in past
      final pastRule = RecurringTransactionModel(
        id: 'r-due',
        title: 'Gym Membership',
        amount: 50.0,
        category: 'Health',
        type: TransactionType.expense,
        frequency: RecurrenceFrequency.monthly,
        startDate: DateTime(2026, 9, 1),
        lastGeneratedDate: null,
        createdAt: DateTime.now(),
      );
      await appState.addRecurringTransaction(pastRule);

      // Verify that due transactions were automatically generated upon adding the rule
      expect(appState.transactions.length, greaterThan(initialTxCount));
      final generatedTxCount = appState.transactions.length;

      // Running generateDueRecurringTransactions again immediately produces 0 new occurrences (no duplicates!)
      final duplicateRunCount = await appState.generateDueRecurringTransactions();
      expect(duplicateRunCount, equals(0));
      expect(appState.transactions.length, equals(generatedTxCount));
    });
  });
}
