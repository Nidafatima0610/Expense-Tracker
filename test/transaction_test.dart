import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expense_tracker/core/constants/app_categories.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/data/models/budget_model.dart';
import 'package:expense_tracker/data/models/category_model.dart';
import 'package:expense_tracker/data/models/transaction_model.dart';
import 'package:expense_tracker/data/repositories/budget_repository.dart';
import 'package:expense_tracker/data/repositories/category_repository.dart';
import 'package:expense_tracker/data/repositories/transaction_repository.dart';
import 'package:expense_tracker/data/services/preferences_service.dart';
import 'package:expense_tracker/providers/app_state.dart';

void main() {
  group('TransactionModel serialization', () {
    test('serializes to JSON and back cleanly', () {
      final now = DateTime(2026, 10, 4, 14, 30);
      final tx = TransactionModel(
        id: 'test-123',
        title: 'Freelance Design',
        amount: 550.75,
        type: TransactionType.income,
        category: AppCategories.freelance,
        date: now,
        note: 'Project milestone 1',
        createdAt: now,
      );

      final json = tx.toJson();
      final reconstituted = TransactionModel.fromJson(json);

      expect(reconstituted.id, 'test-123');
      expect(reconstituted.title, 'Freelance Design');
      expect(reconstituted.amount, 550.75);
      expect(reconstituted.type, TransactionType.income);
      expect(reconstituted.category, AppCategories.freelance);
      expect(reconstituted.note, 'Project milestone 1');
      expect(reconstituted.isIncome, isTrue);
      expect(reconstituted.isExpense, isFalse);
    });

    test('copyWith updates specified fields correctly', () {
      final now = DateTime(2026, 10, 4, 14, 30);
      final tx = TransactionModel(
        id: 'test-1',
        title: 'Original Title',
        amount: 100.0,
        type: TransactionType.expense,
        category: AppCategories.food,
        date: now,
        createdAt: now,
      );

      final updated = tx.copyWith(
        title: 'Updated Title',
        amount: 150.0,
        note: 'Added note',
      );

      expect(updated.id, 'test-1');
      expect(updated.title, 'Updated Title');
      expect(updated.amount, 150.0);
      expect(updated.category, AppCategories.food);
      expect(updated.note, 'Added note');
    });
  });

  group('CurrencyFormatter tests', () {
    test('formats standard amounts with custom symbols', () {
      expect(CurrencyFormatter.format(1250.50, symbol: r'$'), r'$1,250.50');
      expect(CurrencyFormatter.format(1250.50, symbol: '€'), '€1,250.50');
      expect(CurrencyFormatter.format(1250.50, symbol: '£'), '£1,250.50');
      expect(CurrencyFormatter.format(1250.50, symbol: '₹'), '₹1,250.50');
    });

    test('formats with signs', () {
      expect(CurrencyFormatter.format(200.0, symbol: r'$', includeSign: true), r'+$200.00');
      expect(CurrencyFormatter.format(-50.0, symbol: r'$', includeSign: true), r'-$50.00');
    });

    test('formats compact representations', () {
      expect(CurrencyFormatter.formatCompact(1500, symbol: r'$'), r'$1.5K');
      expect(CurrencyFormatter.formatCompact(2500000, symbol: r'$'), r'$2.5M');
    });
  });

  group('DateFormatter tests', () {
    test('relative date recognition for Today and Yesterday', () {
      final now = DateTime.now();
      expect(DateFormatter.formatFriendly(now), 'Today');

      final yesterday = now.subtract(const Duration(days: 1));
      expect(DateFormatter.formatFriendly(yesterday), 'Yesterday');
    });
  });

  group('AppState Search, Filter & Analytics', () {
    late SharedPreferences prefs;
    late PreferencesService prefService;
    late TransactionRepository repo;
    late AppState appState;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      prefService = PreferencesService(prefs);
      repo = TransactionRepository(prefs);
      final catRepo = CategoryRepository(prefs);
      final budgetRepo = BudgetRepository(prefs);
      appState = AppState(
        repository: repo,
        preferencesService: prefService,
        categoryRepository: catRepo,
        budgetRepository: budgetRepo,
      );
      await appState.isReady;
      await appState.clearAllTransactions();
    });

    test('search filters transactions by title, category, and note', () async {
      final now = DateTime.now();
      await appState.addTransaction(
        TransactionModel(
          id: '1',
          title: 'Grocery Store Trip',
          amount: 80.0,
          type: TransactionType.expense,
          category: AppCategories.food,
          date: now,
          note: 'bought fruits and veggies',
          createdAt: now,
        ),
      );
      await appState.addTransaction(
        TransactionModel(
          id: '2',
          title: 'Monthly Wifi Bill',
          amount: 60.0,
          type: TransactionType.expense,
          category: AppCategories.bills,
          date: now,
          note: 'Fiber optic internet',
          createdAt: now,
        ),
      );

      // Search by title
      appState.setSearchQuery('grocery');
      expect(appState.filteredTransactions.length, 1);
      expect(appState.filteredTransactions.first.id, '1');

      // Search by note
      appState.setSearchQuery('fiber');
      expect(appState.filteredTransactions.length, 1);
      expect(appState.filteredTransactions.first.id, '2');

      // Search by category
      appState.setSearchQuery('bills');
      expect(appState.filteredTransactions.length, 1);
      expect(appState.filteredTransactions.first.id, '2');

      // Reset
      appState.resetFilters();
      expect(appState.filteredTransactions.length, 2);
    });

    test('category breakdown calculates sums and percentages properly', () async {
      final now = DateTime.now();
      await appState.addTransaction(
        TransactionModel(
          id: '1',
          title: 'Dinner',
          amount: 60.0,
          type: TransactionType.expense,
          category: AppCategories.food,
          date: now,
          createdAt: now,
        ),
      );
      await appState.addTransaction(
        TransactionModel(
          id: '2',
          title: 'Lunch',
          amount: 40.0,
          type: TransactionType.expense,
          category: AppCategories.food,
          date: now,
          createdAt: now,
        ),
      );
      await appState.addTransaction(
        TransactionModel(
          id: '3',
          title: 'Train ticket',
          amount: 100.0,
          type: TransactionType.expense,
          category: AppCategories.transport,
          date: now,
          createdAt: now,
        ),
      );

      final breakdown = appState.getCategoryBreakdown(type: TransactionType.expense);
      expect(breakdown.length, 2);

      // Total expense = 200. Food = 100 (50%), Transport = 100 (50%)
      expect(breakdown[0].amount, 100.0);
      expect(breakdown[0].percentage, 50.0);
      expect(breakdown[1].amount, 100.0);
      expect(breakdown[1].percentage, 50.0);
    });

    test('updates and deletes transactions and recalculates totals', () async {
      final now = DateTime.now();
      final tx = TransactionModel(
        id: 'tx-1',
        title: 'Gas',
        amount: 50.0,
        type: TransactionType.expense,
        category: AppCategories.transport,
        date: now,
        createdAt: now,
      );
      await appState.addTransaction(tx);
      expect(appState.totalExpense, 50.0);

      // Update amount
      await appState.updateTransaction(tx.copyWith(amount: 70.0));
      expect(appState.totalExpense, 70.0);

      // Delete
      await appState.deleteTransaction('tx-1');
      expect(appState.totalExpense, 0.0);
      expect(appState.transactions.isEmpty, isTrue);
    });

    test('TransactionModel handles recurrence serialization correctly', () {
      final now = DateTime(2026, 10, 4);
      final tx = TransactionModel(
        id: 'rec-1',
        title: 'Netflix Subscription',
        amount: 15.99,
        type: TransactionType.expense,
        category: AppCategories.entertainment,
        date: now,
        createdAt: now,
        recurrence: RecurrenceFrequency.monthly,
      );

      final json = tx.toJson();
      expect(json['recurrence'], 'monthly');

      final deserialized = TransactionModel.fromJson(json);
      expect(deserialized.recurrence, RecurrenceFrequency.monthly);
      expect(deserialized.isRecurring, isTrue);
    });

    test('duplicateTransaction clones transaction with fresh ID and current date', () async {
      final oldDate = DateTime(2025, 1, 15);
      final original = TransactionModel(
        id: 'orig-999',
        title: 'Gym Membership',
        amount: 45.0,
        type: TransactionType.expense,
        category: AppCategories.health,
        date: oldDate,
        createdAt: oldDate,
        recurrence: RecurrenceFrequency.monthly,
      );
      await appState.addTransaction(original);
      expect(appState.transactions.length, 1);

      await appState.duplicateTransaction(original);
      expect(appState.transactions.length, 2);

      final dup = appState.transactions.firstWhere((t) => t.id != 'orig-999');
      expect(dup.title, 'Gym Membership');
      expect(dup.amount, 45.0);
      expect(dup.type, TransactionType.expense);
      expect(dup.category, AppCategories.health);
      expect(dup.recurrence, RecurrenceFrequency.monthly);
      expect(dup.date.year, DateTime.now().year);
    });
  });

  group('Category Management', () {
    late SharedPreferences prefs;
    late PreferencesService prefService;
    late TransactionRepository repo;
    late CategoryRepository catRepo;
    late BudgetRepository budgetRepo;
    late AppState appState;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      prefService = PreferencesService(prefs);
      repo = TransactionRepository(prefs);
      catRepo = CategoryRepository(prefs);
      budgetRepo = BudgetRepository(prefs);
      appState = AppState(
        repository: repo,
        preferencesService: prefService,
        categoryRepository: catRepo,
        budgetRepository: budgetRepo,
      );
      await appState.isReady;
      await appState.clearAllTransactions();
    });

    test('default categories are loaded and system categories cannot be deleted', () async {
      expect(appState.categories.isNotEmpty, isTrue);
      final foodCat = appState.categories.firstWhere((c) => c.name == 'Food');
      expect(foodCat.isSystem, isTrue);

      final deleted = await appState.deleteCategory(foodCat.id);
      expect(deleted, isFalse);
      expect(appState.getCategoryByName('Food'), isNotNull);
    });

    test('custom categories can be added, updated, and deleted when unused', () async {
      final now = DateTime.now();
      final custom = CategoryModel(
        id: 'custom-1',
        name: 'Pet Care',
        iconCodePoint: Icons.pets.codePoint,
        colorValue: 0xFF4CAF50,
        type: TransactionType.expense,
        isSystem: false,
        createdAt: now,
      );

      await appState.addCategory(custom);
      expect(appState.getCategoryByName('Pet Care'), isNotNull);

      // Edit category
      final updated = custom.copyWith(name: 'Pets & Vet');
      await appState.updateCategory(updated);
      expect(appState.getCategoryByName('Pets & Vet'), isNotNull);
      expect(appState.getCategoryByName('Pet Care'), isNull);

      // Delete unused custom category
      final deleted = await appState.deleteCategory('custom-1');
      expect(deleted, isTrue);
      expect(appState.getCategoryByName('Pets & Vet'), isNull);
    });

    test('custom category cannot be deleted if used in existing transactions', () async {
      final now = DateTime.now();
      final custom = CategoryModel(
        id: 'custom-hobby',
        name: 'Photography',
        iconCodePoint: Icons.camera_alt.codePoint,
        colorValue: 0xFF2196F3,
        type: TransactionType.expense,
        isSystem: false,
        createdAt: now,
      );
      await appState.addCategory(custom);

      // Create transaction using Photography
      await appState.addTransaction(
        TransactionModel(
          id: 'photo-tx',
          title: 'Lens Filter',
          amount: 35.0,
          type: TransactionType.expense,
          category: 'Photography',
          date: now,
          createdAt: now,
        ),
      );

      expect(appState.isCategoryUsed('Photography'), isTrue);
      final deleted = await appState.deleteCategory('custom-hobby');
      expect(deleted, isFalse);
      expect(appState.getCategoryByName('Photography'), isNotNull);
    });
  });

  group('Budget System & Dynamic Calculations', () {
    late SharedPreferences prefs;
    late PreferencesService prefService;
    late TransactionRepository repo;
    late CategoryRepository catRepo;
    late BudgetRepository budgetRepo;
    late AppState appState;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      prefService = PreferencesService(prefs);
      repo = TransactionRepository(prefs);
      catRepo = CategoryRepository(prefs);
      budgetRepo = BudgetRepository(prefs);
      appState = AppState(
        repository: repo,
        preferencesService: prefService,
        categoryRepository: catRepo,
        budgetRepository: budgetRepo,
      );
      await appState.isReady;
      await appState.clearAllTransactions();
    });

    test('calculates spent, remaining, and percentage for category budget', () async {
      final now = DateTime.now();
      final budget = BudgetModel(
        id: 'b-food',
        category: 'Food',
        amount: 200.0,
        month: now.month,
        year: now.year,
        createdAt: now,
      );
      await appState.addBudget(budget);

      // Add expense in same month
      await appState.addTransaction(
        TransactionModel(
          id: 'tx-food-1',
          title: 'Groceries',
          amount: 50.0,
          type: TransactionType.expense,
          category: 'Food',
          date: now,
          createdAt: now,
        ),
      );
      await appState.addTransaction(
        TransactionModel(
          id: 'tx-food-2',
          title: 'Dinner',
          amount: 50.0,
          type: TransactionType.expense,
          category: 'Food',
          date: now,
          createdAt: now,
        ),
      );

      // Spent = 100, Remaining = 100, Percentage = 0.5 (50%)
      expect(appState.getSpentForBudget(budget), 100.0);
      expect(appState.getRemainingForBudget(budget), 100.0);
      expect(appState.getPercentageForBudget(budget), 0.5);
    });

    test('calculates spent for overall monthly budget across all expense categories', () async {
      final now = DateTime.now();
      final overallBudget = BudgetModel(
        id: 'b-overall',
        category: 'Overall',
        amount: 500.0,
        month: now.month,
        year: now.year,
        createdAt: now,
      );
      await appState.addBudget(overallBudget);

      // Add various expenses
      await appState.addTransaction(
        TransactionModel(
          id: 'tx-1',
          title: 'Groceries',
          amount: 150.0,
          type: TransactionType.expense,
          category: 'Food',
          date: now,
          createdAt: now,
        ),
      );
      await appState.addTransaction(
        TransactionModel(
          id: 'tx-2',
          title: 'Bus Pass',
          amount: 50.0,
          type: TransactionType.expense,
          category: 'Transport',
          date: now,
          createdAt: now,
        ),
      );
      // Income should not affect budget spent
      await appState.addTransaction(
        TransactionModel(
          id: 'tx-3',
          title: 'Salary',
          amount: 3000.0,
          type: TransactionType.income,
          category: 'Salary',
          date: now,
          createdAt: now,
        ),
      );

      expect(appState.getSpentForBudget(overallBudget), 200.0);
      expect(appState.getRemainingForBudget(overallBudget), 300.0);
      expect(appState.getPercentageForBudget(overallBudget), 0.4);
    });

    test('generates budget warnings when spending reaches 80% and exceeds 100%', () async {
      final now = DateTime.now();
      final budget80 = BudgetModel(
        id: 'b-warn',
        category: 'Shopping',
        amount: 100.0,
        month: now.month,
        year: now.year,
        createdAt: now,
      );
      await appState.addBudget(budget80);

      // Spending 85 -> 85%
      await appState.addTransaction(
        TransactionModel(
          id: 'tx-shop',
          title: 'Shoes',
          amount: 85.0,
          type: TransactionType.expense,
          category: 'Shopping',
          date: now,
          createdAt: now,
        ),
      );

      var warnings = appState.getBudgetWarningsForMonth(now.year, now.month);
      expect(warnings.length, 1);
      expect(warnings.first.isExceeded, isFalse);
      expect(warnings.first.percentage, 0.85);
      expect(warnings.first.message, contains('85%'));

      // Exceed budget: add 20 more -> 105%
      await appState.addTransaction(
        TransactionModel(
          id: 'tx-shop-2',
          title: 'Shirt',
          amount: 20.0,
          type: TransactionType.expense,
          category: 'Shopping',
          date: now,
          createdAt: now,
        ),
      );

      warnings = appState.getBudgetWarningsForMonth(now.year, now.month);
      expect(warnings.length, 1);
      expect(warnings.first.isExceeded, isTrue);
      expect(warnings.first.message, contains('exceeded'));
    });
  });

  group('Month Selection and Multi-Filter Tests', () {
    late SharedPreferences prefs;
    late PreferencesService prefService;
    late TransactionRepository repo;
    late CategoryRepository catRepo;
    late BudgetRepository budgetRepo;
    late AppState appState;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      prefService = PreferencesService(prefs);
      repo = TransactionRepository(prefs);
      catRepo = CategoryRepository(prefs);
      budgetRepo = BudgetRepository(prefs);
      appState = AppState(
        repository: repo,
        preferencesService: prefService,
        categoryRepository: catRepo,
        budgetRepository: budgetRepo,
      );
      await appState.isReady;
      await appState.clearAllTransactions();
    });

    test('month selector accurately filters dashboard totals and transactions', () async {
      final thisMonth = DateTime(2026, 5, 10);
      final otherMonth = DateTime(2026, 4, 15);

      await appState.addTransaction(
        TransactionModel(
          id: 'm1',
          title: 'May Salary',
          amount: 4000.0,
          type: TransactionType.income,
          category: 'Salary',
          date: thisMonth,
          createdAt: thisMonth,
        ),
      );
      await appState.addTransaction(
        TransactionModel(
          id: 'm2',
          title: 'May Rent',
          amount: 1000.0,
          type: TransactionType.expense,
          category: 'Bills',
          date: thisMonth,
          createdAt: thisMonth,
        ),
      );
      await appState.addTransaction(
        TransactionModel(
          id: 'm3',
          title: 'April Expense',
          amount: 500.0,
          type: TransactionType.expense,
          category: 'Food',
          date: otherMonth,
          createdAt: otherMonth,
        ),
      );

      // Select May 2026
      appState.setSelectedDashboardMonth(DateTime(2026, 5, 1));
      expect(appState.selectedMonthIncome, 4000.0);
      expect(appState.selectedMonthExpense, 1000.0);
      expect(appState.selectedMonthBalance, 3000.0);
      expect(appState.selectedMonthTransactionCount, 2);

      // Switch to April 2026
      appState.setSelectedDashboardMonth(DateTime(2026, 4, 1));
      expect(appState.selectedMonthIncome, 0.0);
      expect(appState.selectedMonthExpense, 500.0);
      expect(appState.selectedMonthBalance, -500.0);
      expect(appState.selectedMonthTransactionCount, 1);
    });

    test('combines type, category, amount, and sort filters simultaneously', () async {
      final now = DateTime.now();
      await appState.addTransaction(
        TransactionModel(
          id: 'f1',
          title: 'Fast Food',
          amount: 15.0,
          type: TransactionType.expense,
          category: 'Food',
          date: now,
          createdAt: now,
        ),
      );
      await appState.addTransaction(
        TransactionModel(
          id: 'f2',
          title: 'Fine Dining',
          amount: 120.0,
          type: TransactionType.expense,
          category: 'Food',
          date: now,
          createdAt: now,
        ),
      );
      await appState.addTransaction(
        TransactionModel(
          id: 'f3',
          title: 'Groceries',
          amount: 60.0,
          type: TransactionType.expense,
          category: 'Food',
          date: now,
          createdAt: now,
        ),
      );
      await appState.addTransaction(
        TransactionModel(
          id: 'f4',
          title: 'Gas',
          amount: 40.0,
          type: TransactionType.expense,
          category: 'Transport',
          date: now,
          createdAt: now,
        ),
      );

      // Filter: Type = Expense, Category = Food, Min Amount = 30, Sort = Highest Amount
      appState.setTypeFilter(TransactionType.expense);
      appState.setCategoryFilter('Food');
      appState.setAmountFilter(min: 30.0, max: 200.0);
      appState.setSortOption(TransactionSortOption.highestAmount);

      expect(appState.hasActiveFilters, isTrue);
      final results = appState.filteredTransactions;
      expect(results.length, 2);
      expect(results[0].title, 'Fine Dining'); // 120
      expect(results[1].title, 'Groceries');   // 60

      // Reset
      appState.resetFilters();
      expect(appState.hasActiveFilters, isFalse);
      expect(appState.filteredTransactions.length, 4);
    });

    test('financial insights calculates top category, largest expense and fallback', () async {
      final now = DateTime.now();

      // Empty state returns neutral guidance
      final emptyInsights = appState.getFinancialInsights(now.year, now.month);
      expect(emptyInsights.insightMessages.first, contains('Log your everyday transactions'));

      // Add expenses
      await appState.addTransaction(
        TransactionModel(
          id: 'in-1',
          title: 'Dinner at Steakhouse',
          amount: 150.0,
          type: TransactionType.expense,
          category: 'Food',
          date: now,
          createdAt: now,
        ),
      );
      await appState.addTransaction(
        TransactionModel(
          id: 'in-2',
          title: 'Subway Ride',
          amount: 10.0,
          type: TransactionType.expense,
          category: 'Transport',
          date: now,
          createdAt: now,
        ),
      );

      final insights = appState.getFinancialInsights(now.year, now.month);
      expect(insights.topCategory, 'Food');
      expect(insights.largestExpense?.title, 'Dinner at Steakhouse');
      expect(insights.averageExpense, 80.0);
      expect(insights.insightMessages.any((m) => m.contains('highest spending category')), isTrue);
    });
  });
}
