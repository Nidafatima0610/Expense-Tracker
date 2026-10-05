import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expense_tracker/data/models/transaction_model.dart';
import 'package:expense_tracker/data/repositories/budget_repository.dart';
import 'package:expense_tracker/data/repositories/category_repository.dart';
import 'package:expense_tracker/data/repositories/recurring_transaction_repository.dart';
import 'package:expense_tracker/data/repositories/transaction_repository.dart';
import 'package:expense_tracker/data/services/preferences_service.dart';
import 'package:expense_tracker/providers/app_state.dart';
import 'package:expense_tracker/providers/app_state_scope.dart';
import 'package:expense_tracker/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('ExpenseTrackerApp smoke test', (WidgetTester tester) async {
    final prefs = await SharedPreferences.getInstance();
    final prefService = PreferencesService(prefs);
    final repo = TransactionRepository(prefs);
    final catRepo = CategoryRepository(prefs);
    final budgetRepo = BudgetRepository(prefs);
    final recRepo = RecurringTransactionRepository(prefs);
    final appState = AppState(
      repository: repo,
      preferencesService: prefService,
      categoryRepository: catRepo,
      budgetRepository: budgetRepo,
      recurringTransactionRepository: recRepo,
    );
    await appState.isReady;

    await tester.pumpWidget(
      AppStateScope(
        notifier: appState,
        child: const ExpenseTrackerApp(),
      ),
    );

    // Verify first-run onboarding is displayed
    expect(find.text('Track Income & Expenses'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);

    // Complete onboarding and verify MainScreen
    await appState.completeOnboarding();
    await tester.pumpAndSettle();

    // Verify main screen elements
    expect(find.text('TOTAL BALANCE'), findsOneWidget);
    expect(find.text('Expense Tracker'), findsOneWidget);
    expect(find.text('Add Income'), findsOneWidget);
    expect(find.text('Add Expense'), findsOneWidget);
  });

  test('Transaction calculations in AppState', () async {
    final prefs = await SharedPreferences.getInstance();
    final prefService = PreferencesService(prefs);
    final repo = TransactionRepository(prefs);
    final catRepo = CategoryRepository(prefs);
    final budgetRepo = BudgetRepository(prefs);
    final recRepo = RecurringTransactionRepository(prefs);
    final appState = AppState(
      repository: repo,
      preferencesService: prefService,
      categoryRepository: catRepo,
      budgetRepository: budgetRepo,
      recurringTransactionRepository: recRepo,
    );
    await appState.isReady;

    // Clear initial seeded data
    await appState.clearAllTransactions();
    expect(appState.totalBalance, 0.0);
    expect(appState.totalIncome, 0.0);
    expect(appState.totalExpense, 0.0);

    // Add Income
    final now = DateTime.now();
    await appState.addTransaction(
      TransactionModel(
        id: '1',
        title: 'Salary',
        amount: 3000.0,
        type: TransactionType.income,
        category: 'Salary',
        date: now,
        createdAt: now,
      ),
    );

    // Add Expense
    await appState.addTransaction(
      TransactionModel(
        id: '2',
        title: 'Groceries',
        amount: 250.0,
        type: TransactionType.expense,
        category: 'Food',
        date: now,
        createdAt: now,
      ),
    );

    expect(appState.totalIncome, 3000.0);
    expect(appState.totalExpense, 250.0);
    expect(appState.totalBalance, 2750.0);
    expect(appState.transactions.length, 2);
  });
}
