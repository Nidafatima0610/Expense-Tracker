import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/services/data_export_service.dart';
import '../../providers/app_state.dart';
import '../../providers/app_state_scope.dart';

class BackupRestoreDialogs {
  /// Shows the Create Backup sheet with sharing and copying
  static Future<void> showCreateBackup(BuildContext context) async {
    final appState = AppStateScope.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final txCount = appState.transactions.length;
    final catCount = appState.categories.length;
    final budgetCount = appState.budgets.length;
    final recurringCount = appState.recurringTransactions.length;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        bool isBackingUp = false;

        return StatefulBuilder(
          builder: (ctx, setState) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(ctx).padding.bottom + 20,
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                            Icon(Icons.backup_rounded, color: AppColors.accent, size: 24),
                            SizedBox(width: 10),
                            Text(
                              'Create Local Backup',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your backup will contain all your transactions, custom categories, monthly budgets, recurring transactions, and user preferences formatted in structured JSON.',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Backup Items Summary
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfaceSecondary,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          _buildSummaryRow(Icons.receipt_long_rounded, 'Transactions', '$txCount records'),
                          const SizedBox(height: 8),
                          _buildSummaryRow(Icons.category_rounded, 'Categories', '$catCount items'),
                          const SizedBox(height: 8),
                          _buildSummaryRow(Icons.track_changes_rounded, 'Monthly Budgets', '$budgetCount rules'),
                          const SizedBox(height: 8),
                          _buildSummaryRow(Icons.repeat_rounded, 'Recurring Rules', '$recurringCount rules'),
                          const SizedBox(height: 8),
                          _buildSummaryRow(Icons.tune_rounded, 'Preferences', '${appState.currencyCode}, ${appState.themeMode.name}'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    if (isBackingUp)
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
                          label: const Text('Share Backup File', style: TextStyle(fontWeight: FontWeight.w700)),
                          onPressed: () async {
                            setState(() => isBackingUp = true);
                            try {
                              await DataExportService.shareBackup(
                                transactions: appState.transactions,
                                categories: appState.categories,
                                budgets: appState.budgets,
                                recurringTransactions: appState.recurringTransactions,
                                preferences: {
                                  'currencySymbol': appState.currencySymbol,
                                  'currencyCode': appState.currencyCode,
                                  'themeMode': appState.themeMode.name,
                                },
                              );
                              if (ctx.mounted) Navigator.pop(ctx);
                            } catch (e) {
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Backup failed: ${e.toString()}'),
                                    backgroundColor: AppColors.expense,
                                  ),
                                );
                              }
                            } finally {
                              if (ctx.mounted) setState(() => isBackingUp = false);
                            }
                          },
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
                              label: const Text('Save to Documents'),
                              onPressed: () async {
                                setState(() => isBackingUp = true);
                                try {
                                  final file = await DataExportService.saveBackupToFile(
                                    transactions: appState.transactions,
                                    categories: appState.categories,
                                    budgets: appState.budgets,
                                    recurringTransactions: appState.recurringTransactions,
                                    preferences: {
                                      'currencySymbol': appState.currencySymbol,
                                      'currencyCode': appState.currencyCode,
                                      'themeMode': appState.themeMode.name,
                                    },
                                  );
                                  if (ctx.mounted) {
                                    Navigator.pop(ctx);
                                    showDialog(
                                      context: context,
                                      builder: (alertCtx) => AlertDialog(
                                        title: const Text('Backup Saved'),
                                        content: Text('Backup file created at:\n\n${file.path}'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(alertCtx),
                                            child: const Text('OK'),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Save failed: ${e.toString()}'),
                                        backgroundColor: AppColors.expense,
                                      ),
                                    );
                                  }
                                } finally {
                                  if (ctx.mounted) setState(() => isBackingUp = false);
                                }
                              },
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
                              label: const Text('Copy JSON'),
                              onPressed: () async {
                                final json = DataExportService.generateJsonBackup(
                                  transactions: appState.transactions,
                                  categories: appState.categories,
                                  budgets: appState.budgets,
                                  recurringTransactions: appState.recurringTransactions,
                                  preferences: {
                                    'currencySymbol': appState.currencySymbol,
                                    'currencyCode': appState.currencyCode,
                                    'themeMode': appState.themeMode.name,
                                  },
                                );
                                await DataExportService.copyToClipboard(json);
                                if (ctx.mounted) {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Backup JSON copied to clipboard!'),
                                      backgroundColor: AppColors.income,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Shows the Restore Backup dialog where user can paste JSON or load backup
  static Future<void> showRestoreBackup(BuildContext context) async {
    final textController = TextEditingController();
    final appState = AppStateScope.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        bool isValidating = false;
        String? errorMessage;
        RestoreResult? validatedResult;

        return StatefulBuilder(
          builder: (ctx, setState) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + MediaQuery.of(ctx).padding.bottom + 20,
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                              Icon(Icons.settings_backup_restore_rounded, color: AppColors.accent, size: 24),
                              SizedBox(width: 10),
                              Text(
                                'Restore from Backup',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Paste your JSON backup data below to validate and restore.',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // JSON Input Box
                      TextField(
                        controller: textController,
                        maxLines: 5,
                        style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                        decoration: InputDecoration(
                          hintText: '{\n  "app": "ExpenseTracker",\n  "version": 1,\n  ...\n}',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                        onChanged: (_) {
                          if (validatedResult != null || errorMessage != null) {
                            setState(() {
                              validatedResult = null;
                              errorMessage = null;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),

                      // Validate button
                      if (validatedResult == null) ...[
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: isValidating
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.check_circle_outline_rounded, size: 18),
                                label: Text(isValidating ? 'Validating...' : 'Validate Backup Data'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: isValidating
                                    ? null
                                    : () {
                                  final input = textController.text.trim();
                                  if (input.isEmpty) {
                                    setState(() => errorMessage = 'Please paste backup JSON data first.');
                                    return;
                                  }

                                  setState(() => isValidating = true);
                                  final result = DataExportService.parseAndValidateBackup(input);
                                  setState(() {
                                    isValidating = false;
                                    if (result.success) {
                                      validatedResult = result;
                                      errorMessage = null;
                                    } else {
                                      validatedResult = null;
                                      errorMessage = result.message;
                                    }
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ],

                      // Error message banner
                      if (errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.expense.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.expense.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded, color: AppColors.expense, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  errorMessage!,
                                  style: const TextStyle(color: AppColors.expense, fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Validation Success Card & Options
                      if (validatedResult != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.income.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.income.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.check_circle_rounded, color: AppColors.income, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Valid Backup File Recognized',
                                    style: TextStyle(color: AppColors.income, fontWeight: FontWeight.w700, fontSize: 13),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text('• Transactions: ${validatedResult!.transactions?.length ?? 0}'),
                              Text('• Categories: ${validatedResult!.categories?.length ?? 0}'),
                              Text('• Budgets: ${validatedResult!.budgets?.length ?? 0}'),
                              Text('• Recurring Rules: ${validatedResult!.recurringTransactions?.length ?? 0}'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        const Text(
                          'RESTORE STRATEGY',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.1),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Choose whether you want to completely replace existing data or safely merge without duplicates:',
                          style: TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            // Replace Button
                            Expanded(
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.expense,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () => _confirmAndExecuteRestore(
                                  context: context,
                                  modalContext: ctx,
                                  appState: appState,
                                  jsonString: textController.text.trim(),
                                  mode: RestoreMode.replace,
                                ),
                                child: const Text(
                                  'Replace Data',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Merge Button
                            Expanded(
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.accent,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () => _confirmAndExecuteRestore(
                                  context: context,
                                  modalContext: ctx,
                                  appState: appState,
                                  jsonString: textController.text.trim(),
                                  mode: RestoreMode.merge,
                                ),
                                child: const Text(
                                  'Merge Data',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
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
          },
        );
      },
    );
  }

  static Future<void> _confirmAndExecuteRestore({
    required BuildContext context,
    required BuildContext modalContext,
    required AppState appState,
    required String jsonString,
    required RestoreMode mode,
  }) async {
    final modeTitle = mode == RestoreMode.replace ? 'Replace All Existing Data?' : 'Merge with Existing Data?';
    final modeDesc = mode == RestoreMode.replace
        ? 'This will overwrite your existing transactions, budgets, and recurring rules with the contents of this backup file. Are you sure you wish to proceed?'
        : 'This will add new transactions, categories, budgets, and recurring rules from the backup while preserving your existing records and avoiding duplicate IDs.';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(modeTitle),
        content: Text(modeDesc),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: mode == RestoreMode.replace ? AppColors.expense : AppColors.accent,
            ),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: Text(mode == RestoreMode.replace ? 'Confirm Replace' : 'Confirm Merge'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final res = await appState.restoreBackup(jsonString, mode);
      if (context.mounted) {
        Navigator.pop(modalContext);
        if (res.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Data successfully restored in ${mode == RestoreMode.replace ? 'Replace' : 'Merge'} mode!',
              ),
              backgroundColor: AppColors.income,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Restore failed: ${res.message}'),
              backgroundColor: AppColors.expense,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  static Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.accent),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
      ],
    );
  }
}
