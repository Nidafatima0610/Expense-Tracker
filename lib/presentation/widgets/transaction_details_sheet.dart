import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/transaction_model.dart';
import '../../providers/app_state_scope.dart';
import '../screens/transactions/add_edit_transaction_screen.dart';
import 'category_icon_widget.dart';

class TransactionDetailsSheet extends StatelessWidget {
  final TransactionModel transaction;

  const TransactionDetailsSheet({
    super.key,
    required this.transaction,
  });

  static Future<void> show(BuildContext context, TransactionModel transaction) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TransactionDetailsSheet(transaction: transaction),
    );
  }

  void _handleShare(BuildContext context) async {
    final appState = AppStateScope.of(context);
    final isIncome = transaction.isIncome;
    final dateStr = DateFormat('MMMM d, yyyy').format(transaction.date);
    final amountStr = CurrencyFormatter.format(transaction.amount, symbol: appState.currencySymbol);

    final summary = StringBuffer();
    summary.writeln('${isIncome ? 'Income' : 'Expense'} Details:');
    summary.writeln('• Title: ${transaction.title}');
    summary.writeln('• Type: ${transaction.type.displayName}');
    summary.writeln('• Category: ${transaction.category}');
    summary.writeln('• Amount: $amountStr');
    summary.writeln('• Date: $dateStr');
    if (transaction.isRecurring) {
      summary.writeln('• Recurrence: ${transaction.recurrence.displayName}');
    }
    if (transaction.note != null && transaction.note!.trim().isNotEmpty) {
      summary.writeln('• Note: ${transaction.note}');
    }

    try {
      await SharePlus.instance.share(
        ShareParams(
          text: summary.toString(),
          subject: '${transaction.title} Details',
        ),
      );
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: summary.toString()));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaction details copied to clipboard!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Transaction?'),
        content: Text(
          'Are you sure you want to delete "${transaction.title}"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expense,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final appState = AppStateScope.of(context);
      await appState.deleteTransaction(transaction.id);
      if (context.mounted) {
        Navigator.of(context).pop(); // Close bottom sheet
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted "${transaction.title}"'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'UNDO',
              textColor: AppColors.accent,
              onPressed: () {
                appState.undoDeleteTransaction();
              },
            ),
          ),
        );
      }
    }
  }

  Future<void> _handleDuplicate(BuildContext context) async {
    final appState = AppStateScope.of(context);
    await appState.duplicateTransaction(transaction);
    if (context.mounted) {
      Navigator.of(context).pop(); // Close bottom sheet
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Duplicated "${transaction.title}" successfully'),
          backgroundColor: AppColors.income,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleEdit(BuildContext context) {
    Navigator.of(context).pop(); // Close bottom sheet first
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddEditTransactionScreen(
          transactionToEdit: transaction,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appState = AppStateScope.of(context);
    final currencySymbol = appState.currencySymbol;
    final isIncome = transaction.isIncome;
    final color = isIncome ? AppColors.income : AppColors.expense;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
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
          const SizedBox(height: 18),

          // Header: Category Icon + Amount & Type
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CategoryIconWidget(
                category: transaction.category,
                isExpense: !isIncome,
                size: 54,
                iconSize: 28,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${isIncome ? '+' : '-'}${CurrencyFormatter.format(transaction.amount, symbol: currencySymbol)}',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: color,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isIncome ? 'Income' : 'Expense',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ),
                        if (transaction.isRecurring) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.repeat_rounded,
                                  size: 11,
                                  color: AppColors.accent,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  transaction.recurrence.displayName,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.accent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Divider(height: 1),
          const SizedBox(height: 18),

          // Details List
          _buildDetailRow(
            context,
            icon: Icons.title_rounded,
            label: 'Title',
            value: transaction.title,
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          _buildDetailRow(
            context,
            icon: Icons.category_rounded,
            label: 'Category',
            value: transaction.category,
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          _buildDetailRow(
            context,
            icon: Icons.calendar_today_rounded,
            label: 'Date',
            value: DateFormatter.formatFull(transaction.date),
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          _buildDetailRow(
            context,
            icon: Icons.repeat_rounded,
            label: 'Frequency',
            value: transaction.recurrence.displayName,
            isDark: isDark,
          ),
          if (transaction.note != null &&
              transaction.note!.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            _buildDetailRow(
              context,
              icon: Icons.notes_rounded,
              label: 'Note',
              value: transaction.note!,
              isDark: isDark,
            ),
          ],
          const SizedBox(height: 14),
          _buildDetailRow(
            context,
            icon: Icons.history_rounded,
            label: 'Logged At',
            value: DateFormatter.formatFull(transaction.createdAt),
            isDark: isDark,
            isMuted: true,
          ),

          const SizedBox(height: 24),

          // Action Buttons: Share, Duplicate, Edit, Delete
          Row(
            children: [
              // Share Button
              IconButton(
                onPressed: () => _handleShare(context),
                icon: const Icon(Icons.share_rounded),
                color: AppColors.accent,
                tooltip: 'Share Details',
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.accent.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(width: 8),

              // Duplicate Button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _handleDuplicate(context),
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text('Duplicate'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Edit Button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _handleEdit(context),
                  icon: const Icon(Icons.edit_rounded, size: 16),
                  label: const Text('Edit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Delete Button
              IconButton(
                onPressed: () => _handleDelete(context),
                icon: const Icon(Icons.delete_outline_rounded),
                color: AppColors.expense,
                tooltip: 'Delete',
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.expense.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
    bool isMuted = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 85,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isMuted ? FontWeight.w400 : FontWeight.w600,
              color: isMuted
                  ? (isDark
                      ? AppColors.darkTextMuted
                      : AppColors.lightTextMuted)
                  : (isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary),
            ),
          ),
        ),
      ],
    );
  }
}
