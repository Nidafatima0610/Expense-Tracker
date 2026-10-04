import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/transaction_model.dart';
import '../../data/services/data_export_service.dart';
import '../../providers/app_state.dart';
import '../../providers/app_state_scope.dart';

enum ExportScope {
  all,
  currentMonth,
  customRange,
}

class ExportTransactionsSheet extends StatefulWidget {
  const ExportTransactionsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ExportTransactionsSheet(),
    );
  }

  @override
  State<ExportTransactionsSheet> createState() => _ExportTransactionsSheetState();
}

class _ExportTransactionsSheetState extends State<ExportTransactionsSheet> {
  ExportScope _scope = ExportScope.all;
  DateTimeRange? _customRange;
  bool _isExporting = false;

  List<TransactionModel> _getExportTransactions(AppState appState) {
    final now = DateTime.now();
    switch (_scope) {
      case ExportScope.all:
        return appState.transactions;
      case ExportScope.currentMonth:
        return appState.transactions.where((t) {
          return t.date.year == now.year && t.date.month == now.month;
        }).toList();
      case ExportScope.customRange:
        if (_customRange == null) return appState.transactions;
        final start = DateTime(
          _customRange!.start.year,
          _customRange!.start.month,
          _customRange!.start.day,
        );
        final end = DateTime(
          _customRange!.end.year,
          _customRange!.end.month,
          _customRange!.end.day,
          23,
          59,
          59,
        );
        return appState.transactions.where((t) {
          return !t.date.isBefore(start) && !t.date.isAfter(end);
        }).toList();
    }
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 2),
      initialDateRange: _customRange ??
          DateTimeRange(
            start: DateTime(now.year, now.month, 1),
            end: now,
          ),
    );
    if (picked != null) {
      setState(() {
        _scope = ExportScope.customRange;
        _customRange = picked;
      });
    }
  }

  Future<void> _shareCsv(AppState appState, List<TransactionModel> transactions) async {
    if (transactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No transactions to export for the selected filter.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isExporting = true);
    try {
      final file = await DataExportService.saveCsvToFile(
        transactions,
        currencySymbol: appState.currencySymbol,
        filePrefix: 'transactions_${_scope.name}',
      );

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'text/csv')],
          text: 'Expense Tracker CSV Export (${transactions.length} items)',
          subject: 'Transactions Export',
        ),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported ${transactions.length} transactions to CSV!'),
            backgroundColor: AppColors.income,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: ${e.toString()}'),
            backgroundColor: AppColors.expense,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _saveToDevice(AppState appState, List<TransactionModel> transactions) async {
    if (transactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No transactions to export for the selected filter.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isExporting = true);
    try {
      final file = await DataExportService.saveCsvToFile(
        transactions,
        currencySymbol: appState.currencySymbol,
        filePrefix: 'transactions_${_scope.name}',
      );

      if (mounted) {
        Navigator.pop(context);
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: AppColors.income),
                SizedBox(width: 8),
                Text('File Saved Successfully'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Exported ${transactions.length} transactions to:'),
                const SizedBox(height: 8),
                SelectableText(
                  file.path,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
              FilledButton.icon(
                icon: const Icon(Icons.share_rounded, size: 16),
                label: const Text('Share File'),
                onPressed: () {
                  Navigator.pop(ctx);
                  SharePlus.instance.share(
                    ShareParams(
                      files: [XFile(file.path, mimeType: 'text/csv')],
                      text: 'Expense Tracker CSV Export',
                      subject: 'Transactions Export',
                    ),
                  );
                },
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: ${e.toString()}'),
            backgroundColor: AppColors.expense,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _copyCsv(AppState appState, List<TransactionModel> transactions) async {
    final csv = DataExportService.generateTransactionsCsv(
      transactions,
      currencySymbol: appState.currencySymbol,
    );
    await DataExportService.copyToClipboard(csv);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${transactions.length} transactions copied to clipboard as CSV!'),
          backgroundColor: AppColors.income,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final transactions = _getExportTransactions(appState);
    final totalCount = transactions.length;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.file_download_outlined, color: AppColors.accent, size: 24),
                      SizedBox(width: 10),
                      Text(
                        'Export Transactions',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Generate a standard CSV file including date, time, title, type, category, amount, currency, and note.',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 20),

              // Export Range Selector
              const Text(
                'SELECT DATA RANGE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 10),

              // Option 1: All
              _buildScopeCard(
                scope: ExportScope.all,
                title: 'All Transactions',
                subtitle: '${appState.transactions.length} records in database',
                isDark: isDark,
              ),

              // Option 2: Current Month
              _buildScopeCard(
                scope: ExportScope.currentMonth,
                title: 'Current Month (${DateFormat('MMMM yyyy').format(DateTime.now())})',
                subtitle: '${appState.transactions.where((t) => t.date.year == DateTime.now().year && t.date.month == DateTime.now().month).length} records',
                isDark: isDark,
              ),

              // Option 3: Custom Date Range
              _buildScopeCard(
                scope: ExportScope.customRange,
                title: 'Custom Date Range',
                subtitle: _customRange != null
                    ? '${DateFormatter.formatShort(_customRange!.start)} – ${DateFormatter.formatShort(_customRange!.end)}'
                    : 'Tap to choose date range',
                isDark: isDark,
                trailing: IconButton(
                  icon: const Icon(Icons.date_range_rounded, color: AppColors.accent, size: 20),
                  onPressed: _pickCustomRange,
                  tooltip: 'Pick date range',
                ),
                onTapExtra: () {
                  if (_customRange == null) _pickCustomRange();
                },
              ),
              const SizedBox(height: 16),

              // Summary Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: AppColors.accent, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Ready to export $totalCount transaction${totalCount == 1 ? '' : 's'} as CSV format.',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons
              if (_isExporting)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(),
                  ),
                )
              else ...[
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: const Text('Share CSV File', style: TextStyle(fontWeight: FontWeight.w700)),
                    onPressed: totalCount == 0 ? null : () => _shareCsv(appState, transactions),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.save_alt_rounded, size: 18),
                        label: const Text('Save to File'),
                        onPressed: totalCount == 0 ? null : () => _saveToDevice(appState, transactions),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        label: const Text('Copy CSV'),
                        onPressed: totalCount == 0 ? null : () => _copyCsv(appState, transactions),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScopeCard({
    required ExportScope scope,
    required String title,
    required String subtitle,
    required bool isDark,
    Widget? trailing,
    VoidCallback? onTapExtra,
  }) {
    final isSelected = _scope == scope;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.accent.withValues(alpha: 0.08)
            : (isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfaceSecondary),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? AppColors.accent
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            setState(() => _scope = scope);
            if (onTapExtra != null) onTapExtra();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(
                  isSelected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: isSelected
                      ? AppColors.accent
                      : (isDark ? Colors.white38 : Colors.black38),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
