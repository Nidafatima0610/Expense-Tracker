import 'package:flutter/material.dart';
import '../../../core/constants/app_categories.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/transaction_model.dart';
import '../../../providers/app_state.dart';
import '../../../providers/app_state_scope.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/transaction_tile.dart';
import 'add_edit_transaction_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openEditTransaction(BuildContext context, TransactionModel transaction) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddEditTransactionScreen(
          transactionToEdit: transaction,
        ),
      ),
    );
  }

  void _openAddTransaction(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AddEditTransactionScreen(),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, TransactionModel transaction) async {
    final appState = AppStateScope.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text('Delete Transaction?'),
          content: Text(
            'Are you sure you want to delete "${transaction.title}"? This action cannot be undone.',
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
                minimumSize: const Size(90, 42),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      await appState.deleteTransaction(transaction.id);
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Deleted "${transaction.title}"'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showCategoryFilterDialog(BuildContext context) {
    final appState = AppStateScope.of(context);
    final allCategories = {
      ...AppCategories.expenseCategories.map((c) => c.name),
      ...AppCategories.incomeCategories.map((c) => c.name),
    }.toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filter by Category',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    if (appState.categoryFilter != null)
                      TextButton(
                        onPressed: () {
                          appState.setCategoryFilter(null);
                          Navigator.pop(ctx);
                        },
                        child: const Text('Clear Filter'),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ActionChip(
                      label: const Text('All Categories'),
                      backgroundColor: appState.categoryFilter == null
                          ? AppColors.accent.withValues(alpha: 0.15)
                          : null,
                      onPressed: () {
                        appState.setCategoryFilter(null);
                        Navigator.pop(ctx);
                      },
                    ),
                    ...allCategories.map((cat) {
                      final isSelected = appState.categoryFilter == cat;
                      return ActionChip(
                        label: Text(cat),
                        backgroundColor: isSelected
                            ? AppColors.accent.withValues(alpha: 0.15)
                            : null,
                        side: BorderSide(
                          color: isSelected ? AppColors.accent : Colors.transparent,
                        ),
                        onPressed: () {
                          appState.setCategoryFilter(cat);
                          Navigator.pop(ctx);
                        },
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appState = AppStateScope.of(context);
    final filtered = appState.filteredTransactions;
    final hasActiveFilter = appState.searchQuery.isNotEmpty ||
        appState.typeFilter != null ||
        appState.categoryFilter != null ||
        appState.dateFilter != DateFilterPreset.allTime;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add Transaction',
            onPressed: () => _openAddTransaction(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar & Filter Options
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
              child: Column(
                children: [
                  // Search Field
                  TextField(
                    controller: _searchController,
                    onChanged: (val) => appState.setSearchQuery(val),
                    decoration: InputDecoration(
                      hintText: 'Search title, category, or notes...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                appState.setSearchQuery('');
                              },
                            )
                          : null,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Horizontal Filters: Type Selector & Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // Type: All
                        ChoiceChip(
                          label: const Text('All'),
                          selected: appState.typeFilter == null,
                          onSelected: (_) => appState.setTypeFilter(null),
                        ),
                        const SizedBox(width: 8),
                        // Type: Income
                        ChoiceChip(
                          label: const Text('Income'),
                          selected: appState.typeFilter == TransactionType.income,
                          selectedColor: AppColors.income.withValues(alpha: 0.2),
                          onSelected: (_) => appState.setTypeFilter(
                            appState.typeFilter == TransactionType.income
                                ? null
                                : TransactionType.income,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Type: Expense
                        ChoiceChip(
                          label: const Text('Expense'),
                          selected: appState.typeFilter == TransactionType.expense,
                          selectedColor: AppColors.expense.withValues(alpha: 0.2),
                          onSelected: (_) => appState.setTypeFilter(
                            appState.typeFilter == TransactionType.expense
                                ? null
                                : TransactionType.expense,
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Date Preset Filter Dropdown
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurfaceSecondary
                                : AppColors.lightSurfaceSecondary,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder,
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<DateFilterPreset>(
                              value: appState.dateFilter,
                              isDense: true,
                              icon: const Icon(Icons.arrow_drop_down_rounded, size: 20),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                              ),
                              dropdownColor: isDark
                                  ? AppColors.darkSurface
                                  : AppColors.lightSurface,
                              items: DateFilterPreset.values.map((preset) {
                                return DropdownMenuItem(
                                  value: preset,
                                  child: Text(preset.displayName),
                                );
                              }).toList(),
                              onChanged: (preset) {
                                if (preset != null) {
                                  appState.setDateFilter(preset);
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Category Filter ActionChip
                        ActionChip(
                          avatar: Icon(
                            Icons.tune_rounded,
                            size: 16,
                            color: appState.categoryFilter != null
                                ? AppColors.accent
                                : (isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary),
                          ),
                          label: Text(
                            appState.categoryFilter ?? 'Category',
                            style: TextStyle(
                              color: appState.categoryFilter != null
                                  ? AppColors.accent
                                  : null,
                              fontWeight: appState.categoryFilter != null
                                  ? FontWeight.w700
                                  : FontWeight.normal,
                            ),
                          ),
                          backgroundColor: appState.categoryFilter != null
                              ? AppColors.accent.withValues(alpha: 0.15)
                              : null,
                          onPressed: () => _showCategoryFilterDialog(context),
                        ),

                        if (hasActiveFilter) ...[
                          const SizedBox(width: 8),
                          TextButton.icon(
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: const Text('Reset', style: TextStyle(fontSize: 12)),
                            onPressed: () {
                              _searchController.clear();
                              appState.resetFilters();
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Summary line
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${filtered.length} ${filtered.length == 1 ? 'transaction' : 'transactions'} found',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Transactions List
            Expanded(
              child: filtered.isEmpty
                  ? EmptyStateWidget(
                      title: hasActiveFilter
                          ? 'No Matching Transactions'
                          : 'No Transactions Saved',
                      description: hasActiveFilter
                          ? 'Try changing your search term or clearing the active filters.'
                          : 'Tap below to add your first transaction and start tracking.',
                      actionLabel: hasActiveFilter ? 'Clear Filters' : 'Add Transaction',
                      onAction: () {
                        if (hasActiveFilter) {
                          _searchController.clear();
                          appState.resetFilters();
                        } else {
                          _openAddTransaction(context);
                        }
                      },
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final tx = filtered[index];
                        return TransactionTile(
                          transaction: tx,
                          currencySymbol: appState.currencySymbol,
                          onTap: () => _openEditTransaction(context, tx),
                          onDelete: () => _confirmDelete(context, tx),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
