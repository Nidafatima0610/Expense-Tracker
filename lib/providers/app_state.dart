import 'package:flutter/material.dart';
import '../data/models/transaction_model.dart';
import '../data/repositories/transaction_repository.dart';
import '../data/services/preferences_service.dart';

enum DateFilterPreset {
  allTime,
  thisMonth,
  lastMonth,
  thisYear;

  String get displayName {
    switch (this) {
      case DateFilterPreset.allTime:
        return 'All Time';
      case DateFilterPreset.thisMonth:
        return 'This Month';
      case DateFilterPreset.lastMonth:
        return 'Last Month';
      case DateFilterPreset.thisYear:
        return 'This Year';
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

class AppState extends ChangeNotifier {
  final TransactionRepository repository;
  final PreferencesService preferencesService;

  List<TransactionModel> _transactions = [];
  bool _isLoading = true;

  // Search & Filter state for Transactions tab
  String _searchQuery = '';
  TransactionType? _typeFilter; // null means All
  String? _categoryFilter;
  DateFilterPreset _dateFilter = DateFilterPreset.allTime;

  // Preferences
  late ThemeMode _themeMode;
  late String _currencySymbol;
  late String _currencyCode;

  late final Future<void> isReady;

  AppState({
    required this.repository,
    required this.preferencesService,
  }) {
    _themeMode = preferencesService.getThemeMode();
    _currencySymbol = preferencesService.getCurrencySymbol();
    _currencyCode = preferencesService.getCurrencyCode();
    isReady = _init();
  }

  // Getters
  bool get isLoading => _isLoading;
  List<TransactionModel> get transactions => List.unmodifiable(_transactions);
  ThemeMode get themeMode => _themeMode;
  String get currencySymbol => _currencySymbol;
  String get currencyCode => _currencyCode;

  String get searchQuery => _searchQuery;
  TransactionType? get typeFilter => _typeFilter;
  String? get categoryFilter => _categoryFilter;
  DateFilterPreset get dateFilter => _dateFilter;

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    _transactions = await repository.getTransactions();

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

  // --- Financial Totals ---

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

  // Current Month Stats
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

  // --- Filtering & Search Logic ---

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

  void setDateFilter(DateFilterPreset preset) {
    _dateFilter = preset;
    notifyListeners();
  }

  void resetFilters() {
    _searchQuery = '';
    _typeFilter = null;
    _categoryFilter = null;
    _dateFilter = DateFilterPreset.allTime;
    notifyListeners();
  }

  List<TransactionModel> get filteredTransactions {
    final now = DateTime.now();

    return _transactions.where((t) {
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

      // 4. Date Filter
      switch (_dateFilter) {
        case DateFilterPreset.thisMonth:
          if (t.date.year != now.year || t.date.month != now.month) {
            return false;
          }
          break;
        case DateFilterPreset.lastMonth:
          final lastMonth = now.month == 1 ? 12 : now.month - 1;
          final lastMonthYear = now.month == 1 ? now.year - 1 : now.year;
          if (t.date.year != lastMonthYear || t.date.month != lastMonth) {
            return false;
          }
          break;
        case DateFilterPreset.thisYear:
          if (t.date.year != now.year) {
            return false;
          }
          break;
        case DateFilterPreset.allTime:
          break;
      }

      return true;
    }).toList();
  }

  // --- Category Breakdown for Reports ---

  List<CategoryBreakdown> getCategoryBreakdown({
    required TransactionType type,
    bool currentMonthOnly = false,
  }) {
    final now = DateTime.now();
    final items = _transactions.where((t) {
      if (t.type != type) return false;
      if (currentMonthOnly) {
        return t.date.year == now.year && t.date.month == now.month;
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

  // --- CRUD Operations ---

  Future<void> addTransaction(TransactionModel transaction) async {
    _transactions.insert(0, transaction);
    _sortTransactions();
    notifyListeners();
    await repository.saveTransactions(_transactions);
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    final index = _transactions.indexWhere((t) => t.id == transaction.id);
    if (index != -1) {
      _transactions[index] = transaction;
      _sortTransactions();
      notifyListeners();
      await repository.saveTransactions(_transactions);
    }
  }

  Future<void> deleteTransaction(String id) async {
    _transactions.removeWhere((t) => t.id == id);
    notifyListeners();
    await repository.saveTransactions(_transactions);
  }

  Future<void> clearAllTransactions() async {
    _transactions.clear();
    notifyListeners();
    await repository.clearAllTransactions();
  }

  Future<void> loadSampleData() async {
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
