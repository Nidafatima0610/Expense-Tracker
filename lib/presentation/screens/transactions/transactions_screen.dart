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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appState = AppStateScope.of(context);
    final filtered = appState.filteredTransactions;
    final hasActiveFilter = appState.hasActiveFilters;

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
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
              child: Column(
                children: [
                  // Search Bar
                  TextField(
                    controller: _searchController,
                    onChanged: (val) => appState.setSearchQuery(val),
                    decoration: InputDecoration(
                      hintText: 'Search title, category, or note...',
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

            // Summary line with count and active filter tags
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
                  Text(
                    'Sorted by: ${appState.sortOption.displayName}',
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

            // Active filters preview pill
            if (hasActiveFilter)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.filter_alt_rounded, size: 14, color: AppColors.accent),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Filters active: ${appState.dateFilter.displayName}'
                        '${appState.typeFilter != null ? ' • ${appState.typeFilter!.displayName}' : ''}'
                        '${appState.categoryFilter != null ? ' • ${appState.categoryFilter}' : ''}'
                        '${appState.minAmountFilter != null ? ' • Min: ${CurrencyFormatter.format(appState.minAmountFilter!, symbol: appState.currencySymbol)}' : ''}'
                        '${appState.maxAmountFilter != null ? ' • Max: ${CurrencyFormatter.format(appState.maxAmountFilter!, symbol: appState.currencySymbol)}' : ''}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accent,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        _searchController.clear();
                        appState.resetFilters();
                      },
                      child: const Icon(Icons.close_rounded, size: 16, color: AppColors.accent),
                    ),
                  ],
                ),
              ),

            // Transactions List or Empty State
            Expanded(
              child: filtered.isEmpty
                  ? EmptyStateWidget(
                      title: hasActiveFilter
                          ? 'No Matching Transactions'
                          : 'No Transactions Saved',
                      description: hasActiveFilter
                          ? 'Try adjusting your search criteria, amounts, or clearing active filters.'
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
                          onTap: () => TransactionDetailsSheet.show(context, tx),
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
