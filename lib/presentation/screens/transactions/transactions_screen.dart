import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/transaction_model.dart';
import '../../../providers/app_state.dart';
import '../../../providers/app_state_scope.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/export_transactions_sheet.dart';
import '../../widgets/transaction_details_sheet.dart';
import '../../widgets/transaction_tile.dart';
import '../calendar/calendar_screen.dart';
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

  void _openAddTransaction(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AddEditTransactionScreen(),
      ),
    );
  }

  void _showAdvancedFilterSheet(BuildContext context) {
    final appState = AppStateScope.of(context);
    final minCtrl = TextEditingController(
      text: appState.minAmountFilter != null
          ? appState.minAmountFilter!.toStringAsFixed(0)
          : '',
    );
    final maxCtrl = TextEditingController(
      text: appState.maxAmountFilter != null
          ? appState.maxAmountFilter!.toStringAsFixed(0)
          : '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setSheetState) {
            final isDark = Theme.of(modalCtx).brightness == Brightness.dark;
            final categories = appState.categories;

            return Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 20,
                    bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 20,
                  ),
                  child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.tune_rounded, color: AppColors.accent),
                              const SizedBox(width: 8),
                              const Text(
                                'Filter & Sort',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          if (appState.hasActiveFilters)
                            TextButton(
                              onPressed: () {
                                _searchController.clear();
                                appState.resetFilters();
                                Navigator.pop(modalCtx);
                              },
                              child: const Text('Reset All'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 1. Sort Options
                      const Text(
                        'SORT BY',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: TransactionSortOption.values.map((sort) {
                          final isSelected = appState.sortOption == sort;
                          return ChoiceChip(
                            label: Text(sort.displayName),
                            selected: isSelected,
                            selectedColor: AppColors.accent.withValues(alpha: 0.2),
                            onSelected: (val) {
                              if (val) {
                                appState.setSortOption(sort);
                                setSheetState(() {});
                              }
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),

                      // 2. Date Filter
                      const Text(
                        'DATE RANGE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: TransactionDateFilter.values.map((df) {
                          final isSelected = appState.dateFilter == df;
                          return ChoiceChip(
                            label: Text(df.displayName),
                            selected: isSelected,
                            selectedColor: AppColors.accent.withValues(alpha: 0.2),
                            onSelected: (val) async {
                              if (df == TransactionDateFilter.customRange) {
                                final now = DateTime.now();
                                final range = await showDateRangePicker(
                                  context: context,
                                  firstDate: DateTime(now.year - 5),
                                  lastDate: DateTime(now.year + 2),
                                  initialDateRange: appState.customDateRange ??
                                      DateTimeRange(
                                        start: DateTime(now.year, now.month, 1),
                                        end: now,
                                      ),
                                );
                                if (range != null) {
                                  appState.setDateFilter(
                                    TransactionDateFilter.customRange,
                                    range: range,
                                  );
                                  setSheetState(() {});
                                }
                              } else {
                                appState.setDateFilter(df);
                                setSheetState(() {});
                              }
                            },
                          );
                        }).toList(),
                      ),
                      if (appState.dateFilter == TransactionDateFilter.customRange &&
                          appState.customDateRange != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Selected: ${DateFormatter.formatShort(appState.customDateRange!.start)} – ${DateFormatter.formatShort(appState.customDateRange!.end)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),

                      // 3. Category Filter
                      const Text(
                        'CATEGORY',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('All Categories'),
                            selected: appState.categoryFilter == null,
                            onSelected: (_) {
                              appState.setCategoryFilter(null);
                              setSheetState(() {});
                            },
                          ),
                          ...categories.map((c) {
                            final isSelected = appState.categoryFilter == c.name;
                            return ChoiceChip(
                              label: Text(c.name),
                              selected: isSelected,
                              selectedColor: c.color.withValues(alpha: 0.2),
                              onSelected: (_) {
                                appState.setCategoryFilter(isSelected ? null : c.name);
                                setSheetState(() {});
                              },
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // 4. Amount Range Filter
                      const Text(
                        'AMOUNT RANGE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: minCtrl,
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              decoration: InputDecoration(
                                prefixText: '${appState.currencySymbol} ',
                                hintText: 'Min Amount',
                                isDense: true,
                              ),
                              onChanged: (val) {
                                final min = double.tryParse(val.trim());
                                appState.setAmountFilter(
                                  min: min,
                                  max: appState.maxAmountFilter,
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text('to', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: maxCtrl,
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              decoration: InputDecoration(
                                prefixText: '${appState.currencySymbol} ',
                                hintText: 'Max Amount',
                                isDense: true,
                              ),
                              onChanged: (val) {
                                final max = double.tryParse(val.trim());
                                appState.setAmountFilter(
                                  min: appState.minAmountFilter,
                                  max: max,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Apply button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(modalCtx),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Apply Filters',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

  void _openEditTransaction(BuildContext context, TransactionModel transaction) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddEditTransactionScreen(transactionToEdit: transaction),
      ),
    );
  }

  void _handleDeleteTransaction(BuildContext context, AppState appState, TransactionModel tx) async {
    final deleted = await appState.deleteTransaction(tx.id);
    if (deleted != null && context.mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deleted "${tx.title}"'),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appState = AppStateScope.of(context);
    final currencySymbol = appState.currencySymbol;
    final groups = appState.groupedFilteredTransactions;
    final filtered = appState.filteredTransactions;
    final hasActiveFilter = appState.hasActiveFilters;
    final hasSearch = appState.searchQuery.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded),
            tooltip: 'Financial Calendar',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CalendarScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.file_upload_outlined),
            tooltip: 'Export CSV',
            onPressed: () => ExportTransactionsSheet.show(context),
          ),
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
            // Top Controls: Search Bar & Quick Filters
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
              child: Column(
                children: [
                  // Search Bar
                  TextField(
                    controller: _searchController,
                    onChanged: (val) => appState.setSearchQuery(val),
                    decoration: InputDecoration(
                      hintText: 'Search title, category, note, or amount...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18),
                              tooltip: 'Clear search',
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

                  // Horizontal Quick Filter Row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // Advanced Filter Trigger Button
                        ActionChip(
                          avatar: Icon(
                            Icons.tune_rounded,
                            size: 16,
                            color: hasActiveFilter ? AppColors.accent : null,
                          ),
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Filter & Sort',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: hasActiveFilter
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: hasActiveFilter ? AppColors.accent : null,
                                ),
                              ),
                              if (hasActiveFilter) ...[
                                const SizedBox(width: 4),
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: AppColors.accent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          side: BorderSide(
                            color: hasActiveFilter
                                ? AppColors.accent
                                : (isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder),
                          ),
                          backgroundColor: hasActiveFilter
                              ? AppColors.accent.withValues(alpha: 0.12)
                              : null,
                          onPressed: () => _showAdvancedFilterSheet(context),
                        ),
                        const SizedBox(width: 8),

                        // Type: All
                        ChoiceChip(
                          label: const Text('All'),
                          selected: appState.typeFilter == null,
                          onSelected: (_) => appState.setTypeFilter(null),
                        ),
                        const SizedBox(width: 6),
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
                        const SizedBox(width: 6),
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
                            child: DropdownButton<TransactionDateFilter>(
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
                              items: TransactionDateFilter.values.map((preset) {
                                return DropdownMenuItem(
                                  value: preset,
                                  child: Text(preset.displayName),
                                );
                              }).toList(),
                              onChanged: (preset) {
                                if (preset != null) {
                                  if (preset == TransactionDateFilter.customRange) {
                                    _showAdvancedFilterSheet(context);
                                  } else {
                                    appState.setDateFilter(preset);
                                  }
                                }
                              },
                            ),
                          ),
                        ),

                        if (hasActiveFilter) ...[
                          const SizedBox(width: 8),
                          TextButton.icon(
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: const Text('Clear All', style: TextStyle(fontSize: 12)),
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

            // Active Filter Removable Chips (Requirement 15)
            if (hasActiveFilter)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      if (appState.typeFilter != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: InputChip(
                            label: Text('Type: ${appState.typeFilter!.displayName}'),
                            onDeleted: () => appState.setTypeFilter(null),
                            deleteIconColor: AppColors.accent,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      if (appState.categoryFilter != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: InputChip(
                            label: Text('Category: ${appState.categoryFilter}'),
                            onDeleted: () => appState.setCategoryFilter(null),
                            deleteIconColor: AppColors.accent,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      if (appState.dateFilter != TransactionDateFilter.all)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: InputChip(
                            label: Text('Date: ${appState.dateFilter.displayName}'),
                            onDeleted: () => appState.setDateFilter(TransactionDateFilter.all),
                            deleteIconColor: AppColors.accent,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      if (appState.minAmountFilter != null || appState.maxAmountFilter != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: InputChip(
                            label: Text(
                              'Amount: ${appState.minAmountFilter != null ? CurrencyFormatter.format(appState.minAmountFilter!, symbol: currencySymbol) : '0'} – ${appState.maxAmountFilter != null ? CurrencyFormatter.format(appState.maxAmountFilter!, symbol: currencySymbol) : '∞'}',
                            ),
                            onDeleted: () => appState.setAmountFilter(),
                            deleteIconColor: AppColors.accent,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      if (appState.sortOption != TransactionSortOption.newest)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: InputChip(
                            label: Text('Sort: ${appState.sortOption.displayName}'),
                            onDeleted: () => appState.setSortOption(TransactionSortOption.newest),
                            deleteIconColor: AppColors.accent,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ActionChip(
                        label: const Text('Clear All', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          _searchController.clear();
                          appState.resetFilters();
                        },
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),
              ),

            // Summary line with count and sort status (Requirement 14)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    hasSearch
                        ? 'Found ${filtered.length} ${filtered.length == 1 ? 'transaction' : 'transactions'} for "${appState.searchQuery.trim()}"'
                        : '${filtered.length} ${filtered.length == 1 ? 'transaction' : 'transactions'} found',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  Text(
                    appState.sortOption.displayName,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppColors.darkTextMuted
                          : AppColors.lightTextMuted,
                    ),
                  ),
                ],
              ),
            ),

            // Grouped Transactions List or Empty State (Requirements 3, 4, 5, 6, 24)
            Expanded(
              child: filtered.isEmpty
                  ? EmptyStateWidget(
                      title: hasSearch
                          ? 'No Results for "${appState.searchQuery.trim()}"'
                          : (hasActiveFilter
                              ? 'No Matching Transactions'
                              : 'No Transactions Saved'),
                      description: hasSearch
                          ? 'No transactions matched your search query. Try checking for typos or clear your search.'
                          : (hasActiveFilter
                              ? 'Try adjusting your filter criteria, amounts, or clearing active filters.'
                              : 'Tap below to log your first income or expense transaction.'),
                      actionLabel: hasSearch
                          ? 'Clear Search'
                          : (hasActiveFilter ? 'Clear All Filters' : 'Add Transaction'),
                      onAction: () {
                        if (hasSearch) {
                          _searchController.clear();
                          appState.setSearchQuery('');
                        } else if (hasActiveFilter) {
                          _searchController.clear();
                          appState.resetFilters();
                        } else {
                          _openAddTransaction(context);
                        }
                      },
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                      itemCount: groups.length,
                      itemBuilder: (context, groupIndex) {
                        final group = groups[groupIndex];

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Date Group Header with Daily Subtotals (Requirement 4)
                            Padding(
                              padding: const EdgeInsets.only(top: 14, bottom: 8, left: 4, right: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 4,
                                        height: 14,
                                        decoration: BoxDecoration(
                                          color: AppColors.accent,
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        group.headerTitle,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.8,
                                          color: isDark
                                              ? AppColors.darkTextPrimary
                                              : AppColors.lightTextPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Daily Subtotal Badges
                                  Row(
                                    children: [
                                      if (group.totalIncome > 0)
                                        Container(
                                          margin: const EdgeInsets.only(right: 6),
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.income.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            '+${CurrencyFormatter.format(group.totalIncome, symbol: currencySymbol)}',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.income,
                                            ),
                                          ),
                                        ),
                                      if (group.totalExpense > 0)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.expense.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            '-${CurrencyFormatter.format(group.totalExpense, symbol: currencySymbol)}',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.expense,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Items in this date group with Swipe Actions (Requirements 5 & 6)
                            ...group.transactions.map((tx) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Dismissible(
                                  key: ValueKey(tx.id),
                                  direction: DismissDirection.horizontal,
                                  confirmDismiss: (direction) async {
                                    if (direction == DismissDirection.startToEnd) {
                                      // Swipe right -> Edit
                                      _openEditTransaction(context, tx);
                                      return false; // Do not dismiss
                                    } else {
                                      // Swipe left -> Delete with immediate Undo SnackBar
                                      return true;
                                    }
                                  },
                                  onDismissed: (direction) {
                                    if (direction == DismissDirection.endToStart) {
                                      _handleDeleteTransaction(context, appState, tx);
                                    }
                                  },
                                  // Background for Edit (Swipe Right)
                                  background: Container(
                                    alignment: Alignment.centerLeft,
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    decoration: BoxDecoration(
                                      color: AppColors.accent,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.edit_rounded, color: Colors.white, size: 22),
                                        SizedBox(width: 8),
                                        Text(
                                          'Edit',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Secondary Background for Delete (Swipe Left)
                                  secondaryBackground: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    decoration: BoxDecoration(
                                      color: AppColors.expense,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          'Delete',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
                                      ],
                                    ),
                                  ),
                                  child: TransactionTile(
                                    transaction: tx,
                                    currencySymbol: currencySymbol,
                                    onTap: () => TransactionDetailsSheet.show(context, tx),
                                    onDelete: () => _handleDeleteTransaction(context, appState, tx),
                                  ),
                                ),
                              );
                            }),
                          ],
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
