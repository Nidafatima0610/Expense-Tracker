import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/budget_repository.dart';
import 'data/repositories/category_repository.dart';
import 'data/repositories/recurring_transaction_repository.dart';
import 'data/repositories/transaction_repository.dart';
import 'data/services/preferences_service.dart';
import 'presentation/screens/main_screen.dart';
import 'providers/app_state.dart';
import 'providers/app_state_scope.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style for smooth edge-to-edge look
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  final prefs = await SharedPreferences.getInstance();
  final preferencesService = PreferencesService(prefs);
  final transactionRepository = TransactionRepository(prefs);
  final categoryRepository = CategoryRepository(prefs);
  final budgetRepository = BudgetRepository(prefs);
  final recurringTransactionRepository = RecurringTransactionRepository(prefs);

  final appState = AppState(
    repository: transactionRepository,
    preferencesService: preferencesService,
    categoryRepository: categoryRepository,
    budgetRepository: budgetRepository,
    recurringTransactionRepository: recurringTransactionRepository,
  );

  runApp(
    AppStateScope(
      notifier: appState,
      child: const ExpenseTrackerApp(),
    ),
  );
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);

    return MaterialApp(
      title: 'Expense Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: appState.themeMode,
      home: appState.isLoading
          ? const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            )
          : const MainScreen(),
    );
  }
}
