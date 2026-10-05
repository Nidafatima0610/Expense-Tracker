import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expense_tracker/data/models/savings_goal_model.dart';
import 'package:expense_tracker/data/models/transaction_model.dart';
import 'package:expense_tracker/data/models/transaction_template_model.dart';
import 'package:expense_tracker/data/repositories/budget_repository.dart';
import 'package:expense_tracker/data/repositories/category_repository.dart';
import 'package:expense_tracker/data/repositories/recurring_transaction_repository.dart';
import 'package:expense_tracker/data/repositories/savings_goal_repository.dart';
import 'package:expense_tracker/data/repositories/transaction_repository.dart';
import 'package:expense_tracker/data/repositories/transaction_template_repository.dart';
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
  late SavingsGoalRepository goalsRepo;
  late TransactionTemplateRepository templateRepo;
  late AppState appState;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    prefService = PreferencesService(prefs);
    txRepo = TransactionRepository(prefs);
    catRepo = CategoryRepository(prefs);
    budgetRepo = BudgetRepository(prefs);
    recRepo = RecurringTransactionRepository(prefs);
    goalsRepo = SavingsGoalRepository(prefs);
    templateRepo = TransactionTemplateRepository(prefs);

    appState = AppState(
      repository: txRepo,
      preferencesService: prefService,
      categoryRepository: catRepo,
      budgetRepository: budgetRepo,
      recurringTransactionRepository: recRepo,
      savingsGoalRepository: goalsRepo,
      transactionTemplateRepository: templateRepo,
    );

    await appState.isReady;
    await appState.clearAllFinancialData();
  });

  group('1. Payment Methods Tests', () {
    test('PaymentMethod enum has 6 options with correct labels and icons', () {
      expect(PaymentMethod.values.length, 6);
      expect(PaymentMethod.cash.displayName, 'Cash');
      expect(PaymentMethod.bankAccount.displayName, 'Bank Account');
      expect(PaymentMethod.debitCard.displayName, 'Debit Card');
      expect(PaymentMethod.creditCard.displayName, 'Credit Card');
      expect(PaymentMethod.mobileWallet.displayName, 'Mobile Wallet');
      expect(PaymentMethod.other.displayName, 'Other');

      expect(PaymentMethod.fromString('cash'), PaymentMethod.cash);
      expect(PaymentMethod.fromString('bankAccount'), PaymentMethod.bankAccount);
      expect(PaymentMethod.fromString('debitCard'), PaymentMethod.debitCard);
      expect(PaymentMethod.fromString('creditCard'), PaymentMethod.creditCard);
      expect(PaymentMethod.fromString('mobileWallet'), PaymentMethod.mobileWallet);
      expect(PaymentMethod.fromString('other'), PaymentMethod.other);
      // Case-insensitive or unknown defaults to cash
      expect(PaymentMethod.fromString('unknown_method'), PaymentMethod.cash);
      expect(PaymentMethod.fromString(null), PaymentMethod.cash);
    });

    test('Backward compatibility: transaction without paymentMethod defaults safely to Cash', () {
      final json = {
        'id': 'legacy-tx-1',
        'title': 'Coffee',
        'amount': 5.0,
        'type': 'expense',
        'category': 'Food & Drinks',
        'date': '2026-10-01T12:00:00.000',
      };

      final tx = TransactionModel.fromJson(json);
      expect(tx.paymentMethod, PaymentMethod.cash);
    });

    test('Adding transactions with different payment methods and filtering by payment method', () async {
      await appState.addTransaction(
        title: 'Supermarket Groceries',
        amount: 80.0,
        type: TransactionType.expense,
        category: 'Food & Drinks',
        date: DateTime.now(),
        paymentMethod: PaymentMethod.creditCard,
      );

      await appState.addTransaction(
        title: 'Taxi Ride',
        amount: 20.0,
        type: TransactionType.expense,
        category: 'Transportation',
        date: DateTime.now(),
        paymentMethod: PaymentMethod.cash,
      );

      await appState.addTransaction(
        title: 'Salary Deposit',
        amount: 3000.0,
        type: TransactionType.income,
        category: 'Salary',
        date: DateTime.now(),
        paymentMethod: PaymentMethod.bankAccount,
      );

      expect(appState.transactions.length, 3);

      // Filter by Credit Card
      appState.setPaymentMethodFilter(PaymentMethod.creditCard);
      expect(appState.filteredTransactions.length, 1);
      expect(appState.filteredTransactions.first.title, 'Supermarket Groceries');

      // Filter by Bank Account
      appState.setPaymentMethodFilter(PaymentMethod.bankAccount);
      expect(appState.filteredTransactions.length, 1);
      expect(appState.filteredTransactions.first.title, 'Salary Deposit');

      // Clear filter
      appState.setPaymentMethodFilter(null);
      expect(appState.filteredTransactions.length, 3);
    });

    test('Payment method breakdown calculation', () async {
      await appState.addTransaction(
        title: 'Electronics',
        amount: 300.0,
        type: TransactionType.expense,
        category: 'Shopping',
        date: DateTime(2026, 10, 2),
        paymentMethod: PaymentMethod.creditCard,
      );
      await appState.addTransaction(
        title: 'Dinner',
        amount: 100.0,
        type: TransactionType.expense,
        category: 'Food & Drinks',
        date: DateTime(2026, 10, 3),
        paymentMethod: PaymentMethod.creditCard,
      );
      await appState.addTransaction(
        title: 'Bus Fare',
        amount: 50.0,
        type: TransactionType.expense,
        category: 'Transportation',
        date: DateTime(2026, 10, 4),
        paymentMethod: PaymentMethod.cash,
      );

      final breakdown = appState.getPaymentMethodBreakdown(
        type: TransactionType.expense,
        startDate: DateTime(2026, 10, 1),
        endDate: DateTime(2026, 10, 31),
      );

      expect(breakdown.length, 2);
      final creditCardItem = breakdown.firstWhere((b) => b.method == PaymentMethod.creditCard);
      expect(creditCardItem.amount, 400.0);
      expect(creditCardItem.count, 2);
      expect(creditCardItem.percentage, closeTo(88.88, 0.1));

      final cashItem = breakdown.firstWhere((b) => b.method == PaymentMethod.cash);
      expect(cashItem.amount, 50.0);
      expect(cashItem.count, 1);
    });
  });

  group('2. Savings Goals Tests', () {
    test('Savings Goal Model calculations', () {
      final goal = SavingsGoalModel(
        id: 'goal-1',
        name: 'Emergency Fund',
        targetAmount: 5000.0,
        currentAmount: 2500.0,
        deadline: DateTime.now().add(const Duration(days: 30)),
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      );

      expect(goal.remainingAmount, 2500.0);
      expect(goal.progressPercentage, 0.5);
      expect(goal.isCompleted, isFalse);
      expect(goal.statusDisplay, 'On Track');
      expect(goal.daysRemaining, greaterThan(25));
    });

    test('Savings Goal CRUD and auto-completion when target reached', () async {
      final goal = await appState.addSavingsGoal(
        name: 'New Laptop',
        targetAmount: 1500.0,
        category: 'New Laptop',
        note: 'For work and development',
        deadline: DateTime.now().add(const Duration(days: 60)),
      );

      expect(appState.savingsGoals.length, 1);
      expect(goal.currentAmount, 0.0);
      expect(goal.isCompleted, isFalse);

      // Add contribution
      final updated = await appState.addGoalContribution(
        goalId: goal.id,
        amount: 1500.0,
        note: 'Saved from bonus',
        paymentMethod: PaymentMethod.bankAccount,
      );

      expect(updated.currentAmount, 1500.0);
      expect(updated.isCompleted, isTrue);
      expect(updated.statusDisplay, 'Completed');
      expect(updated.contributions.length, 1);
      expect(updated.contributions.first.amount, 1500.0);
      expect(updated.contributions.first.paymentMethod, PaymentMethod.bankAccount);

      // Partial withdrawal
      final afterWithdraw = await appState.withdrawFromGoal(
        goalId: goal.id,
        amount: 200.0,
        note: 'Emergency expense',
      );

      expect(afterWithdraw.currentAmount, 1300.0);
      expect(afterWithdraw.isCompleted, isFalse);
      expect(afterWithdraw.contributions.length, 2);
      expect(afterWithdraw.contributions.last.amount, -200.0);

      // Delete goal
      await appState.deleteSavingsGoal(goal.id);
      expect(appState.savingsGoals.isEmpty, isTrue);
    });

    test('Savings Goal prevents invalid zero/negative contribution or excessive withdrawal', () async {
      final goal = await appState.addSavingsGoal(
        name: 'Vacation',
        targetAmount: 1000.0,
      );

      expect(
        () async => await appState.addGoalContribution(goalId: goal.id, amount: 0),
        throwsArgumentError,
      );

      expect(
        () async => await appState.addGoalContribution(goalId: goal.id, amount: -50),
        throwsArgumentError,
      );

      expect(
        () async => await appState.withdrawFromGoal(goalId: goal.id, amount: 100),
        throwsStateError,
      );
    });
  });

  group('3. Transaction Templates Tests', () {
    test('Template CRUD and duplicate functionality', () async {
      final template = await appState.addTemplate(
        title: 'Monthly Rent',
        type: TransactionType.expense,
        amount: 1200.0,
        category: 'Housing',
        paymentMethod: PaymentMethod.bankAccount,
        note: 'Apartment rent',
      );

      expect(appState.transactionTemplates.length, 1);
      expect(template.title, 'Monthly Rent');
      expect(template.paymentMethod, PaymentMethod.bankAccount);

      // Duplicate template
      final duplicated = await appState.duplicateTemplate(template.id);
      expect(appState.transactionTemplates.length, 2);
      expect(duplicated.title, 'Monthly Rent (Copy)');
      expect(duplicated.amount, 1200.0);

      // Update template
      await appState.updateTemplate(
        template.copyWith(amount: 1250.0),
      );
      final updated = appState.transactionTemplates.firstWhere((t) => t.id == template.id);
      expect(updated.amount, 1250.0);

      // Delete template
      await appState.deleteTemplate(duplicated.id);
      expect(appState.transactionTemplates.length, 1);
    });

    test('Using template creates a new independent transaction without modifying the template', () async {
      final template = await appState.addTemplate(
        title: 'Internet Bill',
        type: TransactionType.expense,
        amount: 60.0,
        category: 'Bills & Utilities',
        paymentMethod: PaymentMethod.creditCard,
      );

      expect(appState.transactions.isEmpty, isTrue);

      // Create transaction from template
      await appState.addTransaction(
        title: template.title,
        amount: template.amount,
        type: template.type,
        category: template.category,
        paymentMethod: template.paymentMethod,
        date: DateTime.now(),
      );

      expect(appState.transactions.length, 1);
      expect(appState.transactions.first.title, 'Internet Bill');
      expect(appState.transactions.first.amount, 60.0);
      expect(appState.transactions.first.paymentMethod, PaymentMethod.creditCard);

      // Verify template remains unchanged
      expect(appState.transactionTemplates.length, 1);
      expect(appState.transactionTemplates.first.amount, 60.0);
    });
  });

  group('4. Quick Add & Preferences Tests', () {
    test('Remember last used category and payment method in preferences', () async {
      expect(appState.getLastUsedPaymentMethod(), PaymentMethod.cash);

      await appState.setLastUsedCategory(TransactionType.expense, 'Groceries');
      await appState.setLastUsedCategory(TransactionType.income, 'Freelance');
      await appState.setLastUsedPaymentMethod(PaymentMethod.mobileWallet);

      expect(appState.getLastUsedCategory(TransactionType.expense), 'Groceries');
      expect(appState.getLastUsedCategory(TransactionType.income), 'Freelance');
      expect(appState.getLastUsedPaymentMethod(), PaymentMethod.mobileWallet);
    });
  });

  group('5. Shareable Financial Report Tests', () {
    test('Generates comprehensive text report with all metrics and sections', () async {
      await appState.addTransaction(
        title: 'Main Salary',
        amount: 4000.0,
        type: TransactionType.income,
        category: 'Salary',
        date: DateTime(2026, 10, 1),
        paymentMethod: PaymentMethod.bankAccount,
      );
      await appState.addTransaction(
        title: 'Apartment Rent',
        amount: 1200.0,
        type: TransactionType.expense,
        category: 'Housing',
        date: DateTime(2026, 10, 2),
        paymentMethod: PaymentMethod.bankAccount,
      );
      await appState.addTransaction(
        title: 'Weekly Groceries',
        amount: 250.0,
        type: TransactionType.expense,
        category: 'Food & Drinks',
        date: DateTime(2026, 10, 3),
        paymentMethod: PaymentMethod.creditCard,
      );

      await appState.addSavingsGoal(
        name: 'Emergency Fund',
        targetAmount: 10000.0,
        currentAmount: 4000.0,
      );

      final report = appState.getShareableFinancialReportText(
        startDate: DateTime(2026, 10, 1),
        endDate: DateTime(2026, 10, 31),
        periodTitle: 'October 2026',
      );

      expect(report.contains('FINANCIAL REPORT - October 2026'), isTrue);
      expect(report.contains('Total Income:'), isTrue);
      expect(report.contains('Total Expenses:'), isTrue);
      expect(report.contains('Net Savings / Surplus:'), isTrue);
      expect(report.contains('TOP SPENDING CATEGORIES:'), isTrue);
      expect(report.contains('Housing:'), isTrue);
      expect(report.contains('PAYMENT METHODS BREAKDOWN:'), isTrue);
      expect(report.contains('Bank Account:'), isTrue);
      expect(report.contains('SAVINGS GOALS PROGRESS:'), isTrue);
      expect(report.contains('Emergency Fund:'), isTrue);
    });
  });

  group('6. Backup & Restore Schema v2 Tests', () {
    test('Generates Schema v2 backup JSON with all new collections', () {
      final jsonString = DataExportService.generateBackupJson(
        transactions: [
          TransactionModel(
            id: 'tx-1',
            title: 'Coffee',
            amount: 4.5,
            type: TransactionType.expense,
            category: 'Food & Drinks',
            date: DateTime.now(),
            paymentMethod: PaymentMethod.mobileWallet,
          ),
        ],
        categories: [],
        budgets: [],
        recurringTransactions: [],
        savingsGoals: [
          SavingsGoalModel(
            id: 'goal-1',
            name: 'Emergency Fund',
            targetAmount: 5000.0,
            createdAt: DateTime.now(),
          ),
        ],
        transactionTemplates: [
          TransactionTemplateModel(
            id: 'template-1',
            title: 'Coffee Quick',
            type: TransactionType.expense,
            amount: 4.5,
            category: 'Food & Drinks',
            paymentMethod: PaymentMethod.mobileWallet,
            createdAt: DateTime.now(),
          ),
        ],
      );

      final result = DataExportService.parseAndValidateBackup(jsonString);
      expect(result.success, isTrue);
      expect(result.schemaVersion, 2);
      expect(result.transactions?.length, 1);
      expect(result.transactions?.first.paymentMethod, PaymentMethod.mobileWallet);
      expect(result.savingsGoals?.length, 1);
      expect(result.savingsGoals?.first.name, 'Emergency Fund');
      expect(result.transactionTemplates?.length, 1);
      expect(result.transactionTemplates?.first.title, 'Coffee Quick');
    });

    test('Backward compatibility: restores older schema v1 backup without errors', () async {
      const v1BackupJson = '''
      {
        "app": "ExpenseTracker",
        "version": 1,
        "createdAt": "2026-09-01T12:00:00.000",
        "transactions": [
          {
            "id": "old-tx-1",
            "title": "Legacy Transaction",
            "amount": 100.0,
            "type": "expense",
            "category": "Shopping",
            "date": "2026-09-01T12:00:00.000"
          }
        ],
        "categories": [],
        "budgets": [],
        "recurringTransactions": []
      }
      ''';

      final validation = DataExportService.parseAndValidateBackup(v1BackupJson);
      expect(validation.success, isTrue);
      expect(validation.schemaVersion, 1);
      expect(validation.transactions?.length, 1);
      expect(validation.transactions?.first.paymentMethod, PaymentMethod.cash);
      expect(validation.savingsGoals?.isEmpty, isTrue);
      expect(validation.transactionTemplates?.isEmpty, isTrue);

      // Restore v1 backup
      await appState.restoreBackup(jsonString: v1BackupJson, mode: RestoreMode.replace);
      expect(appState.transactions.length, 1);
      expect(appState.transactions.first.title, 'Legacy Transaction');
      expect(appState.transactions.first.paymentMethod, PaymentMethod.cash);
    });

    test('Corrupted backup rejection with user-friendly error message', () {
      final invalidResult = DataExportService.parseAndValidateBackup('invalid json string {');
      expect(invalidResult.success, isFalse);
      expect(invalidResult.message, contains('Invalid JSON formatting'));

      final nonExpenseTracker = DataExportService.parseAndValidateBackup('{"app": "OtherApp", "version": 1}');
      expect(nonExpenseTracker.success, isFalse);
      expect(nonExpenseTracker.message, contains('Unrecognized backup format'));
    });
  });
}
