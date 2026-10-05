import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/budget_model.dart';
import '../models/category_model.dart';
import '../models/recurring_transaction_model.dart';
import '../models/transaction_model.dart';

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
  final Map<String, dynamic>? preferences;

  const RestoreResult({
    required this.success,
    required this.message,
    this.transactions,
    this.categories,
    this.budgets,
    this.recurringTransactions,
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
    // CSV Header
    buffer.writeln('Date,Time,Title,Type,Category,Amount,Currency,Note,Recurrence');

    final dateFormat = DateFormat('yyyy-MM-dd');
    final timeFormat = DateFormat('HH:mm');

    for (final tx in transactions) {
      final dateStr = dateFormat.format(tx.date);
      final timeStr = timeFormat.format(tx.date);
      final titleEscaped = _escapeCsvField(tx.title);
      final typeStr = tx.type.name.toUpperCase();
      final categoryEscaped = _escapeCsvField(tx.category);
      final amountStr = tx.amount.toStringAsFixed(2);
      final noteEscaped = _escapeCsvField(tx.note ?? '');
      final recurrenceStr = tx.recurrence.displayName;

      buffer.writeln(
        '$dateStr,$timeStr,$titleEscaped,$typeStr,$categoryEscaped,$amountStr,$currencySymbol,$noteEscaped,$recurrenceStr',
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

  /// Generates full structured JSON backup
  static String generateJsonBackup({
    required List<TransactionModel> transactions,
    required List<CategoryModel> categories,
    required List<BudgetModel> budgets,
    required List<RecurringTransactionModel> recurringTransactions,
    required Map<String, dynamic> preferences,
  }) {
    final backupData = {
      'app': 'ExpenseTracker',
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'transactions': transactions.map((t) => t.toJson()).toList(),
      'categories': categories.map((c) => c.toJson()).toList(),
      'budgets': budgets.map((b) => b.toJson()).toList(),
      'recurringTransactions': recurringTransactions.map((r) => r.toJson()).toList(),
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
    required Map<String, dynamic> preferences,
  }) async {
    final jsonContent = generateJsonBackup(
      transactions: transactions,
      categories: categories,
      budgets: budgets,
      recurringTransactions: recurringTransactions,
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
    required Map<String, dynamic> preferences,
  }) async {
    final file = await saveBackupToFile(
      transactions: transactions,
      categories: categories,
      budgets: budgets,
      recurringTransactions: recurringTransactions,
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

      // Validate schema/version field
      if (decoded.containsKey('version')) {
        final ver = decoded['version'];
        if (ver is! num || ver.toInt() < 1) {
          return RestoreResult.failure('Invalid backup schema version.');
        }
        if (ver.toInt() > 1) {
          return RestoreResult.failure(
            'Backup version $ver is newer than current app version (v1). Please update the application before restoring.',
          );
        }
      }

      final hasDataSections = decoded.containsKey('transactions') ||
          decoded.containsKey('categories') ||
          decoded.containsKey('budgets') ||
          decoded.containsKey('recurringTransactions') ||
          decoded.containsKey('preferences');

      if (!hasDataSections) {
        return RestoreResult.failure('Incompatible backup: file contains no recognized financial data sections.');
      }

      // Parse transactions
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
        preferences: parsedPreferences,
      );
    } catch (e) {
      return RestoreResult.failure('Malformed JSON: ${e.toString()}');
    }
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
