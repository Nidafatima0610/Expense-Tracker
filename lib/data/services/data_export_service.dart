import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/budget_model.dart';
import '../models/category_model.dart';
import '../models/recurring_transaction_model.dart';
import '../models/savings_goal_model.dart';
import '../models/transaction_model.dart';
import '../models/transaction_template_model.dart';

enum RestoreMode {
  replace,
  merge,
}

class RestoreResult {
  final bool success;
  final String message;
  final List<TransactionModel>? transactions;
  final List<CategoryModel>? categories;
  final List<BudgetModel>? budgets;
  final List<RecurringTransactionModel>? recurringTransactions;
  final List<SavingsGoalModel>? savingsGoals;
  final List<TransactionTemplateModel>? transactionTemplates;
  final Map<String, dynamic>? preferences;

  const RestoreResult({
    required this.success,
    required this.message,
    this.transactions,
    this.categories,
    this.budgets,
    this.recurringTransactions,
    this.savingsGoals,
    this.transactionTemplates,
    this.preferences,
  });

  factory RestoreResult.failure(String message) {
    return RestoreResult(success: false, message: message);
  }
}

class DataExportService {
  /// Converts a list of transactions to standard CSV format
  static String generateTransactionsCsv(
    List<TransactionModel> transactions, {
    String currencySymbol = '₨',
  }) {
    final buffer = StringBuffer();
    // CSV Header with PaymentMethod
    buffer.writeln('Date,Time,Title,Type,Category,Amount,Currency,PaymentMethod,Note,Recurrence');

    final dateFormat = DateFormat('yyyy-MM-dd');
    final timeFormat = DateFormat('HH:mm');

    for (final tx in transactions) {
      final dateStr = dateFormat.format(tx.date);
      final timeStr = timeFormat.format(tx.date);
      final titleEscaped = _escapeCsvField(tx.title);
      final typeStr = tx.type.name.toUpperCase();
      final categoryEscaped = _escapeCsvField(tx.category);
      final amountStr = tx.amount.toStringAsFixed(2);
      final paymentMethodStr = _escapeCsvField(tx.paymentMethod.displayName);
      final noteEscaped = _escapeCsvField(tx.note ?? '');
      final recurrenceStr = tx.recurrence.displayName;

      buffer.writeln(
        '$dateStr,$timeStr,$titleEscaped,$typeStr,$categoryEscaped,$amountStr,$currencySymbol,$paymentMethodStr,$noteEscaped,$recurrenceStr',
      );
    }

    return buffer.toString();
  }

  /// Exports transactions to a CSV file and saves to local cache/documents
  static Future<File> saveCsvToFile(
    List<TransactionModel> transactions, {
    String currencySymbol = '₨',
    String? filePrefix,
  }) async {
    final csvContent = generateTransactionsCsv(transactions, currencySymbol: currencySymbol);
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = '${filePrefix ?? 'transactions'}_$timestamp.csv';
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(csvContent, flush: true);
    return file;
  }

  /// Shares transactions CSV via platform share sheet
  static Future<void> shareTransactionsCsv(
    List<TransactionModel> transactions, {
    String currencySymbol = '₨',
    String title = 'Exported Transactions',
  }) async {
    final file = await saveCsvToFile(transactions, currencySymbol: currencySymbol);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path, mimeType: 'text/csv')], text: title, subject: title),
    );
  }

  /// Generates full structured JSON backup (Schema Version 2)
  static String generateJsonBackup({
    required List<TransactionModel> transactions,
    required List<CategoryModel> categories,
    required List<BudgetModel> budgets,
    required List<RecurringTransactionModel> recurringTransactions,
    List<SavingsGoalModel> savingsGoals = const [],
    List<TransactionTemplateModel> transactionTemplates = const [],
    required Map<String, dynamic> preferences,
  }) {
    final backupData = {
      'app': 'ExpenseTracker',
      'version': 2,
      'exportedAt': DateTime.now().toIso8601String(),
      'transactions': transactions.map((t) => t.toJson()).toList(),
      'categories': categories.map((c) => c.toJson()).toList(),
      'budgets': budgets.map((b) => b.toJson()).toList(),
      'recurringTransactions': recurringTransactions.map((r) => r.toJson()).toList(),
      'savingsGoals': savingsGoals.map((g) => g.toJson()).toList(),
      'transactionTemplates': transactionTemplates.map((t) => t.toJson()).toList(),
      'preferences': preferences,
    };

    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(backupData);
  }

  /// Saves JSON backup to file
  static Future<File> saveBackupToFile({
    required List<TransactionModel> transactions,
    required List<CategoryModel> categories,
    required List<BudgetModel> budgets,
    required List<RecurringTransactionModel> recurringTransactions,
    List<SavingsGoalModel> savingsGoals = const [],
    List<TransactionTemplateModel> transactionTemplates = const [],
    required Map<String, dynamic> preferences,
  }) async {
    final jsonContent = generateJsonBackup(
      transactions: transactions,
      categories: categories,
      budgets: budgets,
      recurringTransactions: recurringTransactions,
      savingsGoals: savingsGoals,
      transactionTemplates: transactionTemplates,
      preferences: preferences,
    );

    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'expense_tracker_backup_$timestamp.json';
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(jsonContent, flush: true);
    return file;
  }

  /// Shares backup JSON file
  static Future<void> shareBackup({
    required List<TransactionModel> transactions,
    required List<CategoryModel> categories,
    required List<BudgetModel> budgets,
    required List<RecurringTransactionModel> recurringTransactions,
    List<SavingsGoalModel> savingsGoals = const [],
    List<TransactionTemplateModel> transactionTemplates = const [],
    required Map<String, dynamic> preferences,
  }) async {
    final file = await saveBackupToFile(
      transactions: transactions,
      categories: categories,
      budgets: budgets,
      recurringTransactions: recurringTransactions,
      savingsGoals: savingsGoals,
      transactionTemplates: transactionTemplates,
      preferences: preferences,
    );

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/json')],
        text: 'Expense Tracker Backup Data',
        subject: 'Expense Tracker Backup',
      ),
    );
  }

  /// Parses and validates a JSON backup string with full error checking and schema versioning
  static RestoreResult parseAndValidateBackup(String jsonString) {
    if (jsonString.trim().isEmpty) {
      return RestoreResult.failure('Backup data is empty.');
    }

    try {
      final dynamic decoded = json.decode(jsonString);
      if (decoded is! Map<String, dynamic>) {
        return RestoreResult.failure('Invalid backup format: root must be a JSON object.');
      }

      // Check app identifier if present
      if (decoded.containsKey('app') && decoded['app'] != 'ExpenseTracker') {
        return RestoreResult.failure('Incompatible backup file: not an Expense Tracker backup.');
      }

      // Validate schema/version field (Supports v1 and v2)
      if (decoded.containsKey('version')) {
        final ver = decoded['version'];
        if (ver is! num || ver.toInt() < 1) {
          return RestoreResult.failure('Invalid backup schema version.');
        }
        if (ver.toInt() > 2) {
          return RestoreResult.failure(
            'Backup version $ver is newer than current app version (v2). Please update the application before restoring.',
          );
        }
      }

      final hasDataSections = decoded.containsKey('transactions') ||
          decoded.containsKey('categories') ||
          decoded.containsKey('budgets') ||
          decoded.containsKey('recurringTransactions') ||
          decoded.containsKey('savingsGoals') ||
          decoded.containsKey('transactionTemplates') ||
          decoded.containsKey('preferences');

      if (!hasDataSections) {
        return RestoreResult.failure('Incompatible backup: file contains no recognized financial data sections.');
      }

      // Parse transactions (handles missing paymentMethod gracefully in TransactionModel.fromJson)
      final List<TransactionModel> parsedTransactions = [];
      if (decoded['transactions'] is List) {
        for (final item in decoded['transactions']) {
          if (item is Map<String, dynamic>) {
            try {
              parsedTransactions.add(TransactionModel.fromJson(item));
            } catch (_) {
              // Ignore malformed individual transactions without crashing
            }
          }
        }
      }

      // Parse categories
      final List<CategoryModel> parsedCategories = [];
      if (decoded['categories'] is List) {
        for (final item in decoded['categories']) {
          if (item is Map<String, dynamic>) {
            try {
              parsedCategories.add(CategoryModel.fromJson(item));
            } catch (_) {}
          }
        }
      }

      // Parse budgets
      final List<BudgetModel> parsedBudgets = [];
      if (decoded['budgets'] is List) {
        for (final item in decoded['budgets']) {
          if (item is Map<String, dynamic>) {
            try {
              parsedBudgets.add(BudgetModel.fromJson(item));
            } catch (_) {}
          }
        }
      }

      // Parse recurring transactions
      final List<RecurringTransactionModel> parsedRecurring = [];
      if (decoded['recurringTransactions'] is List) {
        for (final item in decoded['recurringTransactions']) {
          if (item is Map<String, dynamic>) {
            try {
              parsedRecurring.add(RecurringTransactionModel.fromJson(item));
            } catch (_) {}
          }
        }
      }

      // Parse savings goals (v2 feature - defaults to empty list on v1)
      final List<SavingsGoalModel> parsedGoals = [];
      if (decoded['savingsGoals'] is List) {
        for (final item in decoded['savingsGoals']) {
          if (item is Map<String, dynamic>) {
            try {
              parsedGoals.add(SavingsGoalModel.fromJson(item));
            } catch (_) {}
          }
        }
      }

      // Parse transaction templates (v2 feature - defaults to empty list on v1)
      final List<TransactionTemplateModel> parsedTemplates = [];
      if (decoded['transactionTemplates'] is List) {
        for (final item in decoded['transactionTemplates']) {
          if (item is Map<String, dynamic>) {
            try {
              parsedTemplates.add(TransactionTemplateModel.fromJson(item));
            } catch (_) {}
          }
        }
      }

      Map<String, dynamic>? parsedPreferences;
      if (decoded['preferences'] is Map<String, dynamic>) {
        parsedPreferences = decoded['preferences'] as Map<String, dynamic>;
      }

      return RestoreResult(
        success: true,
        message: 'Successfully validated backup file.',
        transactions: parsedTransactions,
        categories: parsedCategories,
        budgets: parsedBudgets,
        recurringTransactions: parsedRecurring,
        savingsGoals: parsedGoals,
        transactionTemplates: parsedTemplates,
        preferences: parsedPreferences,
      );
    } catch (e) {
      return RestoreResult.failure('Malformed JSON: ${e.toString()}');
    }
  }

  /// Generates a clean, readable, professional shareable financial summary text
  static String generateShareableReportText({
    required String periodTitle,
    required String dateRangeStr,
    required double totalIncome,
    required double totalExpenses,
    required double netBalance,
    required int transactionCount,
    required double averageDailySpending,
    required TransactionModel? highestExpense,
    required List<MapEntry<String, double>> topCategories,
    required List<MapEntry<PaymentMethod, double>> paymentMethodBreakdown,
    String? budgetSummary,
    String? savingsGoalsSummary,
    String currencySymbol = '₨',
  }) {
    final buffer = StringBuffer();
    buffer.writeln('📊 FINANCIAL REPORT');
    buffer.writeln('Period: $periodTitle ($dateRangeStr)');
    buffer.writeln('Generated: ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.now())}');
    buffer.writeln('────────────────────────────────────────');
    buffer.writeln('💵 SUMMARY');
    buffer.writeln('• Total Income: $currencySymbol ${totalIncome.toStringAsFixed(2)}');
    buffer.writeln('• Total Expenses: $currencySymbol ${totalExpenses.toStringAsFixed(2)}');
    final netPrefix = netBalance >= 0 ? '+' : '';
    buffer.writeln('• Net Balance: $netPrefix$currencySymbol ${netBalance.toStringAsFixed(2)}');
    buffer.writeln('• Total Transactions: $transactionCount');
    buffer.writeln('• Avg Daily Spending: $currencySymbol ${averageDailySpending.toStringAsFixed(2)}');
    if (highestExpense != null) {
      buffer.writeln('• Highest Expense: "${highestExpense.title}" ($currencySymbol ${highestExpense.amount.toStringAsFixed(2)})');
    }

    if (topCategories.isNotEmpty) {
      buffer.writeln('────────────────────────────────────────');
      buffer.writeln('🏷️ TOP EXPENSE CATEGORIES');
      for (final entry in topCategories.take(5)) {
        final pct = totalExpenses > 0 ? (entry.value / totalExpenses * 100).toStringAsFixed(1) : '0.0';
        buffer.writeln('• ${entry.key}: $currencySymbol ${entry.value.toStringAsFixed(2)} ($pct%)');
      }
    }

    if (paymentMethodBreakdown.isNotEmpty) {
      buffer.writeln('────────────────────────────────────────');
      buffer.writeln('💳 PAYMENT METHOD BREAKDOWN');
      for (final entry in paymentMethodBreakdown) {
        final pct = totalExpenses > 0 ? (entry.value / totalExpenses * 100).toStringAsFixed(1) : '0.0';
        buffer.writeln('• ${entry.key.displayName}: $currencySymbol ${entry.value.toStringAsFixed(2)} ($pct%)');
      }
    }

    if (budgetSummary != null && budgetSummary.trim().isNotEmpty) {
      buffer.writeln('────────────────────────────────────────');
      buffer.writeln('🎯 BUDGET STATUS');
      buffer.writeln(budgetSummary.trim());
    }

    if (savingsGoalsSummary != null && savingsGoalsSummary.trim().isNotEmpty) {
      buffer.writeln('────────────────────────────────────────');
      buffer.writeln('🌱 SAVINGS GOALS');
      buffer.writeln(savingsGoalsSummary.trim());
    }

    buffer.writeln('────────────────────────────────────────');
    buffer.writeln('Report generated by Expense Tracker App');
    return buffer.toString();
  }

  /// Copies text to system clipboard
  static Future<void> copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }

  static String _escapeCsvField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n') || field.contains('\r')) {
      final escaped = field.replaceAll('"', '""');
      return '"$escaped"';
    }
    return field;
  }
}
