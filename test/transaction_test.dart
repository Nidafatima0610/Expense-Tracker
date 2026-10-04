import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expense_tracker/core/constants/app_categories.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/data/models/transaction_model.dart';
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
      appState = AppState(repository: repo, preferencesService: prefService);
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
  });
}
