import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../data/models/budget_model.dart';
import '../data/models/category_model.dart';
import '../data/models/transaction_model.dart';
import '../data/repositories/budget_repository.dart';
import '../data/repositories/category_repository.dart';
import '../data/repositories/transaction_repository.dart';
import '../data/services/preferences_service.dart';

enum TransactionDateFilter {
  all,
  today,
  thisWeek,
  thisMonth,
  lastMonth,
  customRange;

  String get displayName {
    switch (this) {
      case TransactionDateFilter.all:
        return 'All Time';
      case TransactionDateFilter.today:
        return 'Today';
      case TransactionDateFilter.thisWeek:
        return 'This Week';
      case TransactionDateFilter.thisMonth:
        return 'This Month';
      case TransactionDateFilter.lastMonth:
        return 'Last Month';
      case TransactionDateFilter.customRange:
        return 'Custom Range';
    }
  }
}

enum TransactionSortOption {
  newest,
  oldest,
  highestAmount,
  lowestAmount;

  String get displayName {
    switch (this) {
      case TransactionSortOption.newest:
        return 'Newest First';
      case TransactionSortOption.oldest:
        return 'Oldest First';
      case TransactionSortOption.highestAmount:
        return 'Highest Amount';
      case TransactionSortOption.lowestAmount:
        return 'Lowest Amount';
    }
  }
}

class CategoryBreakdown {
  final String category;
  final double amount;
  final double percentage;
  final int count;

  const CategoryBreakdown({
    required this.category,
    required this.amount,
    required this.percentage,
    required this.count,
  });
}

class BudgetWarning {
  final BudgetModel budget;
  final double spent;
  final double percentage;
  final bool isExceeded;

  const BudgetWarning({
    required this.budget,
    required this.spent,
    required this.percentage,
    required this.isExceeded,
  });

  String get message {
    if (isExceeded) {
      return 'You have exceeded your ${budget.category} budget!';
    }
    return 'You have used ${(percentage * 100).toStringAsFixed(0)}% of your ${budget.category} budget.';
  }
}

class FinancialInsights {
  final String? topCategory;
  final double topCategoryAmount;
  final double topCategoryPercentage;
  final TransactionModel? largestExpense;
  final double averageExpense;
  final double? monthOverMonthPercentChange;
  final bool hasPreviousMonthData;
  final List<String> insightMessages;

  const FinancialInsights({
    this.topCategory,
    this.topCategoryAmount = 0.0,
    this.topCategoryPercentage = 0.0,
    this.largestExpense,
    this.averageExpense = 0.0,
    this.monthOverMonthPercentChange,
    this.hasPreviousMonthData = false,
    this.insightMessages = const [],
  });
}

class AppState extends ChangeNotifier {
  final TransactionRepository repository;
  final PreferencesService preferencesService;
  final CategoryRepository categoryRepository;
  final BudgetRepository budgetRepository;

  List<TransactionModel> _transactions = [];
  List<CategoryModel> _categories = [];
  List<BudgetModel> _budgets = [];
  bool _isLoading = true;

  // Dashboard Month selection
  DateTime _selectedDashboardMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );

  // Advanced Search & Filter state for Transactions tab
  String _searchQuery = '';
  TransactionType? _typeFilter; // null means All
  String? _categoryFilter;
  TransactionDateFilter _dateFilter = TransactionDateFilter.all;
  DateTimeRange? _customDateRange;
  double? _minAmountFilter;
  double? _maxAmountFilter;
  TransactionSortOption _sortOption = TransactionSortOption.newest;

  // Preferences
  late ThemeMode _themeMode;
  late String _currencySymbol;
  late String _currencyCode;

  late final Future<void> isReady;

  AppState({
    required this.repository,
    required this.preferencesService,
    required this.categoryRepository,
    required this.budgetRepository,
  }) {
    _themeMode = preferencesService.getThemeMode();
    _currencySymbol = preferencesService.getCurrencySymbol();
    _currencyCode = preferencesService.getCurrencyCode();
    isReady = _init();
  }

  // Getters
  bool get isLoading => _isLoading;
  List<TransactionModel> get transactions => List.unmodifiable(_transactions);
  List<CategoryModel> get categories => List.unmodifiable(_categories);
  List<BudgetModel> get budgets => List.unmodifiable(_budgets);
  ThemeMode get themeMode => _themeMode;
  String get currencySymbol => _currencySymbol;
  String get currencyCode => _currencyCode;

  DateTime get selectedDashboardMonth => _selectedDashboardMonth;

  String get searchQuery => _searchQuery;
  TransactionType? get typeFilter => _typeFilter;
  String? get categoryFilter => _categoryFilter;
  TransactionDateFilter get dateFilter => _dateFilter;
  DateTimeRange? get customDateRange => _customDateRange;
  double? get minAmountFilter => _minAmountFilter;
  double? get maxAmountFilter => _maxAmountFilter;
  TransactionSortOption get sortOption => _sortOption;

  bool get hasActiveFilters =>
      _searchQuery.trim().isNotEmpty ||
      _typeFilter != null ||
      _categoryFilter != null ||
      _dateFilter != TransactionDateFilter.all ||
      _minAmountFilter != null ||
      _maxAmountFilter != null ||
      _sortOption != TransactionSortOption.newest;

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    _transactions = await repository.getTransactions();
    _categories = await categoryRepository.getCategories();
    _budgets = await budgetRepository.getBudgets();

    // If first time opening app and has never seeded, seed sample transactions
    if (_transactions.isEmpty && !preferencesService.getHasSeeded()) {
      final sample = repository.generateSampleTransactions();
      await repository.saveTransactions(sample);
      await preferencesService.setHasSeeded(true);
      _transactions = sample;
    }

    _sortTransactions();
    _isLoading = false;
    notifyListeners();
  }

  void _sortTransactions() {
    _transactions.sort((a, b) => b.date.compareTo(a.date));
  }

  // --- Dashboard Month Selector ---

  void setSelectedDashboardMonth(DateTime month) {
    _selectedDashboardMonth = DateTime(month.year, month.month, 1);
    notifyListeners();
  }

  void previousDashboardMonth() {
    _selectedDashboardMonth = DateTime(
      _selectedDashboardMonth.year,
      _selectedDashboardMonth.month - 1,
      1,
    );
    notifyListeners();
  }

  void nextDashboardMonth() {
    _selectedDashboardMonth = DateTime(
      _selectedDashboardMonth.year,
      _selectedDashboardMonth.month + 1,
      1,
    );
    notifyListeners();
  }

  // --- Financial Totals (All Time) ---

  double get totalIncome {
    return _transactions
        .where((t) => t.isIncome)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get totalExpense {
    return _transactions
        .where((t) => t.isExpense)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get totalBalance => totalIncome - totalExpense;

  // --- Selected Dashboard Month Stats ---

  List<TransactionModel> get selectedMonthTransactions {
    final y = _selectedDashboardMonth.year;
    final m = _selectedDashboardMonth.month;
    return _transactions
        .where((t) => t.date.year == y && t.date.month == m)
        .toList();
  }

  double get selectedMonthIncome {
    return selectedMonthTransactions
        .where((t) => t.isIncome)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get selectedMonthExpense {
    return selectedMonthTransactions
        .where((t) => t.isExpense)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get selectedMonthBalance => selectedMonthIncome - selectedMonthExpense;

  int get selectedMonthTransactionCount => selectedMonthTransactions.length;

  // Real-time Current Month Stats (calendar month)
  double get currentMonthIncome {
    final now = DateTime.now();
    return _transactions
        .where((t) => t.isIncome && t.date.year == now.year && t.date.month == now.month)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get currentMonthExpense {
    final now = DateTime.now();
    return _transactions
        .where((t) => t.isExpense && t.date.year == now.year && t.date.month == now.month)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get currentMonthBalance => currentMonthIncome - currentMonthExpense;

  List<TransactionModel> getRecentTransactions({int limit = 5}) {
    if (_transactions.length <= limit) {
      return _transactions;
    }
    return _transactions.sublist(0, limit);
  }

  // --- Advanced Filtering & Search Logic ---

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setTypeFilter(TransactionType? type) {
    _typeFilter = type;
    notifyListeners();
  }

  void setCategoryFilter(String? category) {
    _categoryFilter = category;
    notifyListeners();
  }

  void setDateFilter(TransactionDateFilter filter, {DateTimeRange? range}) {
    _dateFilter = filter;
    _customDateRange = range;
    notifyListeners();
  }

  void setAmountFilter({double? min, double? max}) {
    _minAmountFilter = min;
    _maxAmountFilter = max;
    notifyListeners();
  }

  void setSortOption(TransactionSortOption option) {
    _sortOption = option;
    notifyListeners();
  }

  void resetFilters() {
    _searchQuery = '';
    _typeFilter = null;
    _categoryFilter = null;
    _dateFilter = TransactionDateFilter.all;
    _customDateRange = null;
    _minAmountFilter = null;
    _maxAmountFilter = null;
    _sortOption = TransactionSortOption.newest;
    notifyListeners();
  }

  List<TransactionModel> get filteredTransactions {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final filtered = _transactions.where((t) {
      // 1. Search Query
      if (_searchQuery.trim().isNotEmpty) {
        final query = _searchQuery.toLowerCase().trim();
        final titleMatch = t.title.toLowerCase().contains(query);
        final categoryMatch = t.category.toLowerCase().contains(query);
        final noteMatch = t.note?.toLowerCase().contains(query) ?? false;
        final amountMatch = t.amount.toString().contains(query);
        if (!titleMatch && !categoryMatch && !noteMatch && !amountMatch) {
          return false;
        }
      }

      // 2. Type Filter
      if (_typeFilter != null && t.type != _typeFilter) {
        return false;
      }

      // 3. Category Filter
      if (_categoryFilter != null &&
          _categoryFilter!.isNotEmpty &&
          t.category != _categoryFilter) {
        return false;
      }

      // 4. Amount Range Filter
      if (_minAmountFilter != null && t.amount < _minAmountFilter!) {
        return false;
      }
      if (_maxAmountFilter != null && t.amount > _maxAmountFilter!) {
        return false;
      }

      // 5. Date Filter
      final txDate = DateTime(t.date.year, t.date.month, t.date.day);
      switch (_dateFilter) {
        case TransactionDateFilter.all:
          break;
        case TransactionDateFilter.today:
          if (txDate != today) return false;
          break;
        case TransactionDateFilter.thisWeek:
          final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
          final endOfWeek = startOfWeek.add(const Duration(days: 7));
          if (txDate.isBefore(startOfWeek) || txDate.isAfter(endOfWeek)) {
            return false;
          }
          break;
        case TransactionDateFilter.thisMonth:
          if (t.date.year != now.year || t.date.month != now.month) {
            return false;
          }
          break;
        case TransactionDateFilter.lastMonth:
          final lastMonth = now.month == 1 ? 12 : now.month - 1;
          final lastMonthYear = now.month == 1 ? now.year - 1 : now.year;
          if (t.date.year != lastMonthYear || t.date.month != lastMonth) {
            return false;
          }
          break;
        case TransactionDateFilter.customRange:
          if (_customDateRange != null) {
            final start = DateTime(
              _customDateRange!.start.year,
              _customDateRange!.start.month,
              _customDateRange!.start.day,
            );
            final end = DateTime(
              _customDateRange!.end.year,
              _customDateRange!.end.month,
              _customDateRange!.end.day,
              23,
              59,
              59,
            );
            if (t.date.isBefore(start) || t.date.isAfter(end)) {
              return false;
            }
          }
          break;
      }

      return true;
    }).toList();

    // Sorting
    switch (_sortOption) {
      case TransactionSortOption.newest:
        filtered.sort((a, b) => b.date.compareTo(a.date));
        break;
      case TransactionSortOption.oldest:
        filtered.sort((a, b) => a.date.compareTo(b.date));
        break;
      case TransactionSortOption.highestAmount:
        filtered.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case TransactionSortOption.lowestAmount:
        filtered.sort((a, b) => a.amount.compareTo(b.amount));
        break;
    }

    return filtered;
  }

  // --- Category Breakdown Calculations ---

  List<CategoryBreakdown> getCategoryBreakdown({
    required TransactionType type,
    int? year,
    int? month,
    DateTimeRange? customRange,
  }) {
    final items = _transactions.where((t) {
      if (t.type != type) return false;
      if (customRange != null) {
        final start = DateTime(
          customRange.start.year,
          customRange.start.month,
          customRange.start.day,
        );
        final end = DateTime(
          customRange.end.year,
          customRange.end.month,
          customRange.end.day,
          23,
          59,
          59,
        );
        return !t.date.isBefore(start) && !t.date.isAfter(end);
      }
      if (year != null && month != null) {
        return t.date.year == year && t.date.month == month;
      }
      return true;
    }).toList();

    if (items.isEmpty) return [];

    final Map<String, double> categorySums = {};
    final Map<String, int> categoryCounts = {};
    double total = 0.0;

    for (final t in items) {
      categorySums[t.category] = (categorySums[t.category] ?? 0.0) + t.amount;
      categoryCounts[t.category] = (categoryCounts[t.category] ?? 0) + 1;
      total += t.amount;
    }

    final List<CategoryBreakdown> result = [];
    categorySums.forEach((category, sum) {
      final percentage = total > 0 ? (sum / total) * 100 : 0.0;
      result.add(CategoryBreakdown(
        category: category,
        amount: sum,
        percentage: percentage,
        count: categoryCounts[category] ?? 0,
      ));
    });

    result.sort((a, b) => b.amount.compareTo(a.amount));
    return result;
  }

  // --- Budget Calculations & Warnings ---

  List<BudgetModel> getBudgetsForMonth(int year, int month) {
    return _budgets.where((b) => b.year == year && b.month == month).toList();
  }

  double getSpentForBudget(BudgetModel budget) {
    if (budget.isOverall) {
      return _transactions
          .where((t) =>
              t.isExpense &&
              t.date.year == budget.year &&
              t.date.month == budget.month)
          .fold(0.0, (sum, t) => sum + t.amount);
    }

    return _transactions
        .where((t) =>
            t.isExpense &&
            t.date.year == budget.year &&
            t.date.month == budget.month &&
            t.category.toLowerCase() == budget.category.toLowerCase())
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double getRemainingForBudget(BudgetModel budget) {
    final spent = getSpentForBudget(budget);
    return budget.amount - spent;
  }

  double getPercentageForBudget(BudgetModel budget) {
    if (budget.amount <= 0) return 0.0;
    final spent = getSpentForBudget(budget);
    return spent / budget.amount;
  }

  List<BudgetWarning> getBudgetWarningsForMonth(int year, int month) {
    final monthBudgets = getBudgetsForMonth(year, month);
    final List<BudgetWarning> warnings = [];

    for (final b in monthBudgets) {
      final spent = getSpentForBudget(b);
      final ratio = b.amount > 0 ? spent / b.amount : 0.0;
      if (ratio >= 0.8) {
        warnings.add(BudgetWarning(
          budget: b,
          spent: spent,
          percentage: ratio,
          isExceeded: ratio >= 1.0,
        ));
      }
    }

    // Sort: exceeded first, then highest percentage
    warnings.sort((a, b) {
      if (a.isExceeded && !b.isExceeded) return -1;
      if (!a.isExceeded && b.isExceeded) return 1;
      return b.percentage.compareTo(a.percentage);
    });

    return warnings;
  }

  Future<void> addBudget(BudgetModel budget) async {
    await budgetRepository.addBudget(budget);
    _budgets = await budgetRepository.getBudgets();
    notifyListeners();
  }

  Future<void> updateBudget(BudgetModel budget) async {
    await budgetRepository.updateBudget(budget);
    _budgets = await budgetRepository.getBudgets();
    notifyListeners();
  }

  Future<void> deleteBudget(String id) async {
    await budgetRepository.deleteBudget(id);
    _budgets.removeWhere((b) => b.id == id);
    notifyListeners();
  }

  // --- Category Management ---

  List<CategoryModel> get expenseCategories =>
      _categories.where((c) => c.isExpense).toList();

  List<CategoryModel> get incomeCategories =>
      _categories.where((c) => c.isIncome).toList();

  CategoryModel? getCategoryByName(String name) {
    for (final cat in _categories) {
      if (cat.name.toLowerCase() == name.toLowerCase()) {
        return cat;
      }
    }
    return null;
  }

  bool isCategoryUsed(String categoryName) {
    return _transactions.any(
      (t) => t.category.toLowerCase() == categoryName.toLowerCase(),
    );
  }

  Future<void> addCategory(CategoryModel category) async {
    await categoryRepository.addCategory(category);
    _categories = await categoryRepository.getCategories();
    notifyListeners();
  }

  Future<void> updateCategory(CategoryModel category) async {
    await categoryRepository.updateCategory(category);
    _categories = await categoryRepository.getCategories();
    notifyListeners();
  }

  Future<bool> deleteCategory(String id) async {
    final catIndex = _categories.indexWhere((c) => c.id == id);
    if (catIndex == -1) return false;

    final cat = _categories[catIndex];
    if (cat.isSystem) return false;
    if (isCategoryUsed(cat.name)) return false;

    await categoryRepository.deleteCategory(id);
    _categories.removeAt(catIndex);
    notifyListeners();
    return true;
  }

  // --- Financial Insights Engine ---

  FinancialInsights getFinancialInsights(int year, int month) {
    final monthTx = _transactions
        .where((t) => t.date.year == year && t.date.month == month)
        .toList();

    final monthExpenses = monthTx.where((t) => t.isExpense).toList();
    final double totalMonthExpense =
        monthExpenses.fold(0.0, (sum, t) => sum + t.amount);

    final breakdown = getCategoryBreakdown(
      type: TransactionType.expense,
      year: year,
      month: month,
    );

    String? topCat;
    double topCatAmount = 0.0;
    double topCatPercentage = 0.0;

    if (breakdown.isNotEmpty) {
      topCat = breakdown.first.category;
      topCatAmount = breakdown.first.amount;
      topCatPercentage = breakdown.first.percentage;
    }

    TransactionModel? largest;
    if (monthExpenses.isNotEmpty) {
      largest = monthExpenses.reduce((a, b) => a.amount > b.amount ? a : b);
    }

    final double avgExpense = monthExpenses.isNotEmpty
        ? totalMonthExpense / monthExpenses.length
        : 0.0;

    // Previous month comparison
    final prevMonth = month == 1 ? 12 : month - 1;
    final prevYear = month == 1 ? year - 1 : year;
    final prevMonthExpenses = _transactions
        .where((t) =>
            t.isExpense &&
            t.date.year == prevYear &&
            t.date.month == prevMonth)
        .fold(0.0, (sum, t) => sum + t.amount);

    double? momPercentChange;
    final bool hasPrev = prevMonthExpenses > 0;
    if (hasPrev) {
      momPercentChange =
          ((totalMonthExpense - prevMonthExpenses) / prevMonthExpenses) * 100;
    }

    final List<String> messages = [];

    if (topCat != null && topCatPercentage > 0) {
      messages.add(
        '$topCat is your highest spending category (${topCatPercentage.toStringAsFixed(0)}% of total expenses).',
      );
    }

    if (hasPrev && momPercentChange != null) {
      final isUp = momPercentChange > 0;
      final absChange = momPercentChange.abs().toStringAsFixed(0);
      messages.add(
        'Your spending is $absChange% ${isUp ? 'higher' : 'lower'} than last month.',
      );
    }

    if (largest != null) {
      messages.add(
        'Largest expense was ${largest.title} ($_currencySymbol${largest.amount.toStringAsFixed(2)}).',
      );
    }

    final monthBudgets = getBudgetsForMonth(year, month);
    final overallBudget = monthBudgets.firstWhere(
      (b) => b.isOverall,
      orElse: () => BudgetModel(
        id: '',
        category: '',
        amount: 0,
        month: month,
        year: year,
        createdAt: DateTime.now(),
      ),
    );

    if (overallBudget.amount > 0 && totalMonthExpense > 0) {
      final spentRatio = (totalMonthExpense / overallBudget.amount) * 100;
      messages.add(
        'You have spent ${spentRatio.toStringAsFixed(0)}% of your overall monthly budget.',
      );
    }

    if (messages.isEmpty) {
      messages.add(
        'Log your everyday transactions to generate dynamic financial insights.',
      );
    }

    return FinancialInsights(
      topCategory: topCat,
      topCategoryAmount: topCatAmount,
      topCategoryPercentage: topCatPercentage,
      largestExpense: largest,
      averageExpense: avgExpense,
      monthOverMonthPercentChange: momPercentChange,
      hasPreviousMonthData: hasPrev,
      insightMessages: messages,
    );
  }

  // --- CRUD Operations ---

  Future<void> addTransaction(TransactionModel transaction) async {
    await isReady;
    _transactions.insert(0, transaction);
    _sortTransactions();
    notifyListeners();
    await repository.saveTransactions(_transactions);
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    await isReady;
    final index = _transactions.indexWhere((t) => t.id == transaction.id);
    if (index != -1) {
      _transactions[index] = transaction;
      _sortTransactions();
      notifyListeners();
      await repository.saveTransactions(_transactions);
    }
  }

  Future<void> deleteTransaction(String id) async {
    await isReady;
    _transactions.removeWhere((t) => t.id == id);
    notifyListeners();
    await repository.saveTransactions(_transactions);
  }

  Future<void> duplicateTransaction(TransactionModel original) async {
    await isReady;
    const uuid = Uuid();
    final now = DateTime.now();
    final duplicate = original.copyWith(
      id: uuid.v4(),
      createdAt: now,
      date: DateTime(
        now.year,
        now.month,
        now.day,
        original.date.hour,
        original.date.minute,
      ),
    );
    await addTransaction(duplicate);
  }

  Future<void> clearAllTransactions() async {
    await isReady;
    _transactions.clear();
    notifyListeners();
    await repository.clearAllTransactions();
  }

  Future<void> loadSampleData() async {
    await isReady;
    final sample = repository.generateSampleTransactions();
    _transactions = sample;
    _sortTransactions();
    notifyListeners();
    await repository.saveTransactions(_transactions);
  }

  // --- Preferences ---

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    await preferencesService.setThemeMode(mode);
  }

  Future<void> setCurrency(CurrencyInfo currency) async {
    _currencySymbol = currency.symbol;
    _currencyCode = currency.code;
    notifyListeners();
    await preferencesService.setCurrency(currency);
  }
}
