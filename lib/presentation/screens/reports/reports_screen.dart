import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../providers/app_state.dart';
import '../../../providers/app_state_scope.dart';
import '../../widgets/category_icon_widget.dart';

enum ReportPeriod {
  thisWeek,
  thisMonth,
  lastMonth,
  thisYear,
  customRange;

  String get displayName {
    switch (this) {
      case ReportPeriod.thisWeek:
        return 'This Week';
      case ReportPeriod.thisMonth:
        return 'This Month';
      case ReportPeriod.lastMonth:
        return 'Last Month';
      case ReportPeriod.thisYear:
        return 'This Year';
      case ReportPeriod.customRange:
        return 'Custom';
    }
  }
}

enum ReportViewMode {
  periodReports,
  yearlyOverview;
}

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  ReportViewMode _viewMode = ReportViewMode.periodReports;
  ReportPeriod _period = ReportPeriod.thisMonth;
  DateTimeRange? _customRange;
  TransactionType _breakdownType = TransactionType.expense;
  int _touchedPieIndex = -1;
  int _selectedYear = DateTime.now().year;

  DateTimeRange _getDateRangeForPeriod() {
    final now = DateTime.now();
    switch (_period) {
      case ReportPeriod.thisWeek:
        final startOfWeek = DateTime(
          now.year,
          now.month,
          now.day - (now.weekday - 1),
          0,
          0,
          0,
        );
        final endOfWeek = DateTime(
          startOfWeek.year,
          startOfWeek.month,
          startOfWeek.day + 6,
          23,
          59,
          59,
        );
        return DateTimeRange(start: startOfWeek, end: endOfWeek);
      case ReportPeriod.thisMonth:
        final start = DateTime(now.year, now.month, 1, 0, 0, 0);
        final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        return DateTimeRange(start: start, end: end);
      case ReportPeriod.lastMonth:
        final lastMonthYear = now.month == 1 ? now.year - 1 : now.year;
        final lastMonth = now.month == 1 ? 12 : now.month - 1;
        final start = DateTime(lastMonthYear, lastMonth, 1, 0, 0, 0);
        final end = DateTime(lastMonthYear, lastMonth + 1, 0, 23, 59, 59);
        return DateTimeRange(start: start, end: end);
      case ReportPeriod.thisYear:
        final start = DateTime(now.year, 1, 1, 0, 0, 0);
        final end = DateTime(now.year, 12, 31, 23, 59, 59);
        return DateTimeRange(start: start, end: end);
      case ReportPeriod.customRange:
        return _customRange ??
            DateTimeRange(
              start: DateTime(now.year, now.month, 1, 0, 0, 0),
              end: DateTime(now.year, now.month, now.day, 23, 59, 59),
            );
    }
  }

  Future<void> _pickCustomRange(BuildContext context) async {
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.accent,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _period = ReportPeriod.customRange;
        _customRange = picked;
      });
    }
  }

  void _changeYear(int delta) {
    setState(() {
      _selectedYear += delta;
    });
  }

  Future<void> _selectYearPicker(BuildContext context) async {
    final now = DateTime.now();
    final years = List.generate(10, (i) => now.year - 5 + i);

    final selected = await showDialog<int>(
      context: context,
      builder: (ctx) {
        return SimpleDialog(
          title: const Text('Select Year'),
          children: years.map((y) {
            final isCurrent = y == _selectedYear;
            return SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, y),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$y',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        color: isCurrent ? AppColors.accent : null,
                      ),
                    ),
                    if (isCurrent)
                      const Icon(Icons.check_circle, color: AppColors.accent, size: 20),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );

    if (selected != null) {
      setState(() {
        _selectedYear = selected;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appState = AppStateScope.of(context);
    final currencySymbol = appState.currencySymbol;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Reports'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Primary Segment: Period Reports vs. Yearly Overview
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: _buildTopModeSwitcher(isDark),
            ),

            Expanded(
              child: _viewMode == ReportViewMode.periodReports
                  ? _buildPeriodReportsView(context, appState, isDark, currencySymbol)
                  : _buildYearlyOverviewView(context, appState, isDark, currencySymbol),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopModeSwitcher(bool isDark) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfaceSecondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildModeTab(
              label: 'Period Reports',
              icon: Icons.date_range_rounded,
              isSelected: _viewMode == ReportViewMode.periodReports,
              isDark: isDark,
              onTap: () => setState(() => _viewMode = ReportViewMode.periodReports),
            ),
          ),
          Expanded(
            child: _buildModeTab(
              label: 'Yearly Overview',
              icon: Icons.calendar_view_month_rounded,
              isSelected: _viewMode == ReportViewMode.yearlyOverview,
              isDark: isDark,
              onTap: () => setState(() => _viewMode = ReportViewMode.yearlyOverview),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeTab({
    required String label,
    required IconData icon,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.darkSurface : AppColors.lightSurface)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? AppColors.accent
                  : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
                    : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // VIEW 1: PERIOD REPORTS
  // ==========================================

  Widget _buildPeriodReportsView(
    BuildContext context,
    AppState appState,
    bool isDark,
    String currencySymbol,
  ) {
    final range = _getDateRangeForPeriod();
    final allTransactions = appState.transactions;

    // Filter transactions within period
    final periodTransactions = allTransactions.where((t) {
      return !t.date.isBefore(range.start) && !t.date.isAfter(range.end);
    }).toList();

    // Financial Metrics
    final totalIncome = periodTransactions
        .where((t) => t.isIncome)
        .fold(0.0, (sum, t) => sum + t.amount);

    final expensesList = periodTransactions.where((t) => t.isExpense).toList();
    final totalExpense = expensesList.fold(0.0, (sum, t) => sum + t.amount);
    final netBalance = totalIncome - totalExpense;
    final totalTxCount = periodTransactions.length;

    // Days in period
    final int daysInRange = range.end.difference(range.start).inDays.abs() + 1;
    final double avgDailyExpense = daysInRange > 0 ? totalExpense / daysInRange : 0.0;
    final double avgExpensePerTx =
        expensesList.isNotEmpty ? totalExpense / expensesList.length : 0.0;

    // Largest Expense
    final TransactionModel? largestExpenseTx = expensesList.isNotEmpty
        ? expensesList.reduce((a, b) => a.amount > b.amount ? a : b)
        : null;

    // Category Breakdown
    final breakdown = appState.getCategoryBreakdown(
      type: _breakdownType,
      customRange: range,
    );
    final totalBreakdownAmount =
        breakdown.fold<double>(0.0, (sum, b) => sum + b.amount);

    // Target Year/Month for Month-Over-Month Comparison
    final int targetYear;
    final int targetMonth;
    if (_period == ReportPeriod.lastMonth) {
      final now = DateTime.now();
      targetYear = now.month == 1 ? now.year - 1 : now.year;
      targetMonth = now.month == 1 ? 12 : now.month - 1;
    } else if (_period == ReportPeriod.customRange) {
      targetYear = range.start.year;
      targetMonth = range.start.month;
    } else {
      final now = DateTime.now();
      targetYear = now.year;
      targetMonth = now.month;
    }
    final comparison = appState.getMonthOverMonthComparison(targetYear, targetMonth);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Period Selector (This Week, This Month, Last Month, This Year, Custom)
          _buildPeriodSelector(context, isDark),

          if (_period == ReportPeriod.customRange && _customRange != null) ...[
            const SizedBox(height: 8),
            Center(
              child: Text(
                '${DateFormatter.formatShort(_customRange!.start)} – ${DateFormatter.formatShort(_customRange!.end)} ($daysInRange days)',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),

          // 2. Comprehensive Financial Metrics Card
          _buildFinancialSummaryCard(
            isDark: isDark,
            income: totalIncome,
            expense: totalExpense,
            netBalance: netBalance,
            avgDaily: avgDailyExpense,
            avgExpensePerTx: avgExpensePerTx,
            largestExpense: largestExpenseTx,
            txCount: totalTxCount,
            currencySymbol: currencySymbol,
          ),
          const SizedBox(height: 20),

          // 3. Month-to-Month Comparison (Shown for monthly contexts)
          if (_period == ReportPeriod.thisMonth || _period == ReportPeriod.lastMonth) ...[
            _buildMonthOverMonthSection(
              context: context,
              isDark: isDark,
              comparison: comparison,
              currencySymbol: currencySymbol,
            ),
            const SizedBox(height: 20),
          ],

          // 4. Chart: Income vs Expense Comparison
          _buildIncomeVsExpenseChart(
            isDark: isDark,
            income: totalIncome,
            expense: totalExpense,
            currencySymbol: currencySymbol,
          ),
          const SizedBox(height: 20),

          // 5. Chart: Expense by Category
          _buildExpenseByCategoryChart(
            isDark: isDark,
            breakdown: breakdown,
            totalAmount: totalBreakdownAmount,
            currencySymbol: currencySymbol,
            categories: appState.categories,
          ),
          const SizedBox(height: 20),

          // 6. Chart: Spending Trend Over Period
          _buildSpendingTrendChart(
            isDark: isDark,
            transactions: periodTransactions,
            range: range,
            currencySymbol: currencySymbol,
          ),
          const SizedBox(height: 20),

          // 7. Category Breakdown List
          _buildCategoryBreakdownList(
            isDark: isDark,
            breakdown: breakdown,
            totalAmount: totalBreakdownAmount,
            currencySymbol: currencySymbol,
            categories: appState.categories,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector(BuildContext context, bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkSurfaceSecondary
              : AppColors.lightSurfaceSecondary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPeriodTab(
              label: 'This Week',
              isSelected: _period == ReportPeriod.thisWeek,
              isDark: isDark,
              onTap: () => setState(() => _period = ReportPeriod.thisWeek),
            ),
            _buildPeriodTab(
              label: 'This Month',
              isSelected: _period == ReportPeriod.thisMonth,
              isDark: isDark,
              onTap: () => setState(() => _period = ReportPeriod.thisMonth),
            ),
            _buildPeriodTab(
              label: 'Last Month',
              isSelected: _period == ReportPeriod.lastMonth,
              isDark: isDark,
              onTap: () => setState(() => _period = ReportPeriod.lastMonth),
            ),
            _buildPeriodTab(
              label: 'This Year',
              isSelected: _period == ReportPeriod.thisYear,
              isDark: isDark,
              onTap: () => setState(() => _period = ReportPeriod.thisYear),
            ),
            _buildPeriodTab(
              label: 'Custom Range',
              isSelected: _period == ReportPeriod.customRange,
              isDark: isDark,
              onTap: () => _pickCustomRange(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodTab({
    required String label,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.darkSurface : AppColors.lightSurface)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
                  : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFinancialSummaryCard({
    required bool isDark,
    required double income,
    required double expense,
    required double netBalance,
    required double avgDaily,
    required double avgExpensePerTx,
    required TransactionModel? largestExpense,
    required int txCount,
    required String currencySymbol,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'PERIOD FINANCIAL SUMMARY',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (netBalance >= 0 ? AppColors.income : AppColors.expense)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    netBalance >= 0 ? 'Surplus' : 'Deficit',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: netBalance >= 0 ? AppColors.income : AppColors.expense,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Income, Expense, Net Balance Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Income',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          CurrencyFormatter.format(income, symbol: currencySymbol),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.income,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Expense',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          CurrencyFormatter.format(expense, symbol: currencySymbol),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.expense,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Net Balance',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${netBalance >= 0 ? '+' : ''}${CurrencyFormatter.format(netBalance, symbol: currencySymbol)}',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: netBalance >= 0
                                ? AppColors.income
                                : AppColors.expense,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 14),

            // Secondary metrics: Average Expense, Largest Expense, Transaction Count
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.analytics_outlined, size: 14, color: AppColors.accent),
                          const SizedBox(width: 4),
                          Text(
                            'Avg Expense',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        CurrencyFormatter.format(avgExpensePerTx, symbol: currencySymbol),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${CurrencyFormatter.format(avgDaily, symbol: currencySymbol)}/day',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.arrow_upward_rounded, size: 14, color: AppColors.expense),
                          const SizedBox(width: 4),
                          Text(
                            'Largest Expense',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        largestExpense != null
                            ? CurrencyFormatter.format(largestExpense.amount, symbol: currencySymbol)
                            : 'None',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        largestExpense?.title ?? 'No expenses logged',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.receipt_long_rounded, size: 14, color: AppColors.accent),
                          const SizedBox(width: 4),
                          Text(
                            'Transactions',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$txCount',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'Total in period',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // VIEW 2: YEARLY OVERVIEW
  // ==========================================

  Widget _buildYearlyOverviewView(
    BuildContext context,
    AppState appState,
    bool isDark,
    String currencySymbol,
  ) {
    final yearlyData = appState.getYearlyOverview(_selectedYear);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Year Selector Header
          _buildYearSelectorBar(isDark),
          const SizedBox(height: 16),

          // Annual Summary Card
          _buildYearlySummaryCard(yearlyData, isDark, currencySymbol),
          const SizedBox(height: 20),

          // 12-Month Bar Chart
          _buildYearlyBarChart(yearlyData, isDark, currencySymbol),
          const SizedBox(height: 20),

          // Monthly Breakdown List
          _buildMonthlyBreakdownList(yearlyData, isDark, currencySymbol),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildYearSelectorBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfaceSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, size: 28),
            onPressed: () => _changeYear(-1),
            tooltip: 'Previous Year',
          ),
          InkWell(
            onTap: () => _selectYearPicker(context),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Text(
                    '$_selectedYear',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down, size: 20),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded, size: 28),
            onPressed: () => _changeYear(1),
            tooltip: 'Next Year',
          ),
        ],
      ),
    );
  }

  Widget _buildYearlySummaryCard(
    YearlyOverviewData data,
    bool isDark,
    String currencySymbol,
  ) {
    final savingsRate = data.totalIncome > 0
        ? ((data.totalIncome - data.totalExpense) / data.totalIncome) * 100
        : 0.0;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${data.year} ANNUAL SUMMARY',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (data.netBalance >= 0 ? AppColors.income : AppColors.expense)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    data.netBalance >= 0 ? 'Annual Surplus' : 'Annual Deficit',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: data.netBalance >= 0 ? AppColors.income : AppColors.expense,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Income',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          CurrencyFormatter.format(data.totalIncome, symbol: currencySymbol),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.income,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Expense',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          CurrencyFormatter.format(data.totalExpense, symbol: currencySymbol),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.expense,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Net Balance',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${data.netBalance >= 0 ? '+' : ''}${CurrencyFormatter.format(data.netBalance, symbol: currencySymbol)}',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: data.netBalance >= 0 ? AppColors.income : AppColors.expense,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.savings_outlined, size: 16, color: AppColors.accent),
                    const SizedBox(width: 6),
                    Text(
                      'Annual Savings Rate: ',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    Text(
                      data.totalIncome > 0
                          ? '${savingsRate.toStringAsFixed(1)}%'
                          : 'N/A',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: savingsRate >= 20
                            ? AppColors.income
                            : (savingsRate >= 0 ? AppColors.accent : AppColors.expense),
                      ),
                    ),
                  ],
                ),
                Text(
                  '${data.monthlyBreakdown.fold<int>(0, (sum, m) => sum + m.transactionCount)} entries',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYearlyBarChart(
    YearlyOverviewData data,
    bool isDark,
    String currencySymbol,
  ) {
    if (!data.hasData) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.bar_chart_rounded,
                  size: 48,
                  color: (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)
                      .withValues(alpha: 0.5),
                ),
                const SizedBox(height: 12),
                Text(
                  'No transactions found for ${data.year}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Transactions logged during this year will generate monthly charts.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    double maxY = 0;
    for (final m in data.monthlyBreakdown) {
      if (m.income > maxY) maxY = m.income;
      if (m.expense > maxY) maxY = m.expense;
    }
    if (maxY == 0) maxY = 100;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '12-MONTH INCOME VS EXPENSES',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
                Row(
                  children: [
                    _buildLegendDot(AppColors.income, 'Income'),
                    const SizedBox(width: 12),
                    _buildLegendDot(AppColors.expense, 'Expense'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY * 1.2,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) =>
                          isDark ? AppColors.darkSurface : AppColors.lightSurface,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final monthItem = data.monthlyBreakdown[group.x.toInt()];
                        final isIncome = rodIndex == 0;
                        return BarTooltipItem(
                          '${monthItem.monthName}\n${isIncome ? "Income" : "Expense"}: ${CurrencyFormatter.format(rod.toY, symbol: currencySymbol)}',
                          TextStyle(
                            color: isIncome ? AppColors.income : AppColors.expense,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 44,
                        getTitlesWidget: (value, meta) {
                          if (value == 0) return const SizedBox.shrink();
                          return Text(
                            CurrencyFormatter.formatCompact(value, symbol: currencySymbol),
                            style: TextStyle(
                              fontSize: 9,
                              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const monthNames = [
                            'J', 'F', 'M', 'A', 'M', 'J',
                            'J', 'A', 'S', 'O', 'N', 'D'
                          ];
                          final idx = value.toInt();
                          if (idx >= 0 && idx < monthNames.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                monthNames[idx],
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(12, (index) {
                    final item = data.monthlyBreakdown[index];
                    return BarChartGroupData(
                      x: index,
                      barsSpace: 3,
                      barRods: [
                        BarChartRodData(
                          toY: item.income,
                          color: AppColors.income,
                          width: 8,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                        BarChartRodData(
                          toY: item.expense,
                          color: AppColors.expense,
                          width: 8,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyBreakdownList(
    YearlyOverviewData data,
    bool isDark,
    String currencySymbol,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'MONTH-BY-MONTH BREAKDOWN',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 12),

        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: data.monthlyBreakdown.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = data.monthlyBreakdown[index];
            final hasActivity = item.income > 0 || item.expense > 0;

            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: hasActivity
                            ? (item.net >= 0 ? AppColors.income : AppColors.expense).withValues(alpha: 0.12)
                            : (isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfaceSecondary),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        item.monthName.substring(0, 3).toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: hasActivity
                              ? (item.net >= 0 ? AppColors.income : AppColors.expense)
                              : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.monthName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            hasActivity
                                ? '${item.transactionCount} transactions'
                                : 'No activity',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${item.net >= 0 ? '+' : ''}${CurrencyFormatter.format(item.net, symbol: currencySymbol)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: item.net >= 0 ? AppColors.income : AppColors.expense,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'In: ${CurrencyFormatter.formatCompact(item.income, symbol: currencySymbol)}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.income,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Ex: ${CurrencyFormatter.formatCompact(item.expense, symbol: currencySymbol)}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.expense,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ==========================================
  // SHARED REPORT CHARTS & WIDGETS
  // ==========================================

  Widget _buildIncomeVsExpenseChart({
    required bool isDark,
    required double income,
    required double expense,
    required String currencySymbol,
  }) {
    final hasData = income > 0 || expense > 0;
    final maxY = [income, expense].reduce((a, b) => a > b ? a : b);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'INCOME VS EXPENSE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
                Row(
                  children: [
                    _buildLegendDot(AppColors.income, 'Income'),
                    const SizedBox(width: 12),
                    _buildLegendDot(AppColors.expense, 'Expense'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (!hasData)
              _buildEmptyChartBox('No income or expense data for this period')
            else
              SizedBox(
                height: 180,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxY > 0 ? maxY * 1.25 : 100,
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => isDark
                            ? AppColors.darkSurface
                            : AppColors.lightSurface,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final isIncomeRod = groupIndex == 0;
                          return BarTooltipItem(
                            '${isIncomeRod ? "Income" : "Expense"}\n${CurrencyFormatter.format(rod.toY, symbol: currencySymbol)}',
                            TextStyle(
                              color: isIncomeRod
                                  ? AppColors.income
                                  : AppColors.expense,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 48,
                          getTitlesWidget: (value, meta) {
                            if (value == 0) return const SizedBox.shrink();
                            return Text(
                              CurrencyFormatter.formatCompact(value, symbol: currencySymbol),
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                              ),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            switch (value.toInt()) {
                              case 0:
                                return const Padding(
                                  padding: EdgeInsets.only(top: 8),
                                  child: Text('Income', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                );
                              case 1:
                                return const Padding(
                                  padding: EdgeInsets.only(top: 8),
                                  child: Text('Expense', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                );
                              default:
                                return const SizedBox.shrink();
                            }
                          },
                        ),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: [
                      BarChartGroupData(
                        x: 0,
                        barRods: [
                          BarChartRodData(
                            toY: income,
                            color: AppColors.income,
                            width: 32,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                          ),
                        ],
                      ),
                      BarChartGroupData(
                        x: 1,
                        barRods: [
                          BarChartRodData(
                            toY: expense,
                            color: AppColors.expense,
                            width: 32,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseByCategoryChart({
    required bool isDark,
    required List<CategoryBreakdown> breakdown,
    required double totalAmount,
    required String currencySymbol,
    required List<CategoryModel> categories,
  }) {
    final hasData = breakdown.isNotEmpty && totalAmount > 0;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'EXPENSE BY CATEGORY',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
                Text(
                  CurrencyFormatter.format(totalAmount, symbol: currencySymbol),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.expense,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (!hasData)
              _buildEmptyChartBox('No expenses logged for this period')
            else
              Column(
                children: [
                  SizedBox(
                    height: 200,
                    child: PieChart(
                      PieChartData(
                        pieTouchData: PieTouchData(
                          touchCallback: (event, pieTouchResponse) {
                            setState(() {
                              if (!event.isInterestedForInteractions ||
                                  pieTouchResponse == null ||
                                  pieTouchResponse.touchedSection == null) {
                                _touchedPieIndex = -1;
                                return;
                              }
                              _touchedPieIndex = pieTouchResponse
                                  .touchedSection!.touchedSectionIndex;
                            });
                          },
                        ),
                        borderData: FlBorderData(show: false),
                        sectionsSpace: 3,
                        centerSpaceRadius: 46,
                        sections: List.generate(breakdown.length, (i) {
                          final item = breakdown[i];
                          final isTouched = i == _touchedPieIndex;
                          final color = _getCategoryColor(item.category, categories);
                          final radius = isTouched ? 55.0 : 45.0;

                          return PieChartSectionData(
                            color: color,
                            value: item.amount,
                            title: isTouched
                                ? '${item.percentage.toStringAsFixed(0)}%'
                                : (item.percentage >= 10
                                    ? '${item.percentage.toStringAsFixed(0)}%'
                                    : ''),
                            radius: radius,
                            titleStyle: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: breakdown.take(6).map((item) {
                      final color = _getCategoryColor(item.category, categories);
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${item.category} (${item.percentage.toStringAsFixed(0)}%)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpendingTrendChart({
    required bool isDark,
    required List<TransactionModel> transactions,
    required DateTimeRange range,
    required String currencySymbol,
  }) {
    final expenses = transactions.where((t) => t.isExpense).toList();
    final hasData = expenses.isNotEmpty;

    final Map<int, double> dailySpending = {};
    for (final e in expenses) {
      final dayKey = e.date.day;
      dailySpending[dayKey] = (dailySpending[dayKey] ?? 0.0) + e.amount;
    }

    final daysList = dailySpending.keys.toList()..sort();
    final List<FlSpot> spots = [];

    if (hasData) {
      for (final day in daysList) {
        spots.add(FlSpot(day.toDouble(), dailySpending[day]!));
      }
    }

    final maxSpend = dailySpending.values.isNotEmpty
        ? dailySpending.values.reduce((a, b) => a > b ? a : b)
        : 100.0;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'DAILY SPENDING TREND',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 18),

            if (!hasData)
              _buildEmptyChartBox('No daily expense activity to display')
            else
              SizedBox(
                height: 180,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 46,
                          getTitlesWidget: (value, meta) {
                            if (value == 0) return const SizedBox.shrink();
                            return Text(
                              CurrencyFormatter.formatCompact(value, symbol: currencySymbol),
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                              ),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 5,
                          getTitlesWidget: (value, meta) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                'Day ${value.toInt()}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: daysList.first.toDouble(),
                    maxX: daysList.last.toDouble() > daysList.first.toDouble()
                        ? daysList.last.toDouble()
                        : daysList.first.toDouble() + 1,
                    minY: 0,
                    maxY: maxSpend * 1.25,
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        curveSmoothness: 0.25,
                        color: AppColors.expense,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: spots.length <= 15,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 3.5,
                              color: AppColors.expense,
                              strokeWidth: 1.5,
                              strokeColor: Colors.white,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppColors.expense.withValues(alpha: 0.25),
                              AppColors.expense.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBreakdownList({
    required bool isDark,
    required List<CategoryBreakdown> breakdown,
    required double totalAmount,
    required String currencySymbol,
    required List<CategoryModel> categories,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'CATEGORY BREAKDOWN',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceSecondary
                    : AppColors.lightSurfaceSecondary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () =>
                        setState(() => _breakdownType = TransactionType.expense),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _breakdownType == TransactionType.expense
                            ? AppColors.expense
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Expense',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _breakdownType == TransactionType.expense
                              ? Colors.white
                              : (isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary),
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () =>
                        setState(() => _breakdownType = TransactionType.income),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _breakdownType == TransactionType.income
                            ? AppColors.income
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Income',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _breakdownType == TransactionType.income
                              ? Colors.white
                              : (isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (breakdown.isEmpty)
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
              child: Center(
                child: Text(
                  'No ${_breakdownType.displayName.toLowerCase()} transactions logged for this period.',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: breakdown.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = breakdown[index];
              final isExpense = _breakdownType == TransactionType.expense;
              final color = _getCategoryColor(item.category, categories);

              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CategoryIconWidget(
                            category: item.category,
                            isExpense: isExpense,
                            size: 40,
                            iconSize: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.category,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.lightTextPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${item.count} ${item.count == 1 ? 'transaction' : 'transactions'}',
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
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                CurrencyFormatter.format(item.amount,
                                    symbol: currencySymbol),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isExpense
                                      ? AppColors.expense
                                      : AppColors.income,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${item.percentage.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppColors.darkTextMuted
                                      : AppColors.lightTextMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (item.percentage / 100).clamp(0.0, 1.0),
                          minHeight: 5,
                          backgroundColor: isDark
                              ? AppColors.darkSurfaceSecondary
                              : AppColors.lightSurfaceSecondary,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildEmptyChartBox(String message) {
    return Container(
      height: 140,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart_rounded,
            size: 38,
            color: Colors.grey.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Color _getCategoryColor(String name, List<CategoryModel> categories) {
    for (final c in categories) {
      if (c.name.toLowerCase() == name.toLowerCase()) {
        return c.color;
      }
    }
    return AppColors.accent;
  }

  Widget _buildMonthOverMonthSection({
    required BuildContext context,
    required bool isDark,
    required MonthOverMonthComparison comparison,
    required String currencySymbol,
  }) {
    final currentMonthLabel = DateFormat('MMMM y').format(DateTime(comparison.currentYear, comparison.currentMonth));
    final prevMonthLabel = DateFormat('MMMM y').format(DateTime(comparison.previousYear, comparison.previousMonth));

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'MONTH-OVER-MONTH COMPARISON',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$currentMonthLabel vs. $prevMonthLabel',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.compare_arrows_rounded, size: 14, color: AppColors.accent),
                      SizedBox(width: 4),
                      Text(
                        'MoM Shift',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (!comparison.hasPreviousData) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfaceSecondary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 20,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'No transactions recorded for $prevMonthLabel. Month-to-month percentage changes will calculate automatically as past records accumulate.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              _buildMoMRow(
                isDark: isDark,
                title: 'Income',
                currentAmount: comparison.currentIncome,
                previousAmount: comparison.previousIncome,
                change: comparison.incomeChange,
                percentChange: comparison.incomePercentChange,
                currencySymbol: currencySymbol,
                isPositiveGood: true,
              ),
              const SizedBox(height: 12),
              Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, height: 1),
              const SizedBox(height: 12),
              _buildMoMRow(
                isDark: isDark,
                title: 'Expenses',
                currentAmount: comparison.currentExpense,
                previousAmount: comparison.previousExpense,
                change: comparison.expenseChange,
                percentChange: comparison.expensePercentChange,
                currencySymbol: currencySymbol,
                isPositiveGood: false,
              ),
              const SizedBox(height: 12),
              Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, height: 1),
              const SizedBox(height: 12),
              _buildMoMRow(
                isDark: isDark,
                title: 'Net Savings',
                currentAmount: comparison.currentBalance,
                previousAmount: comparison.previousBalance,
                change: comparison.balanceChange,
                percentChange: comparison.balancePercentChange,
                currencySymbol: currencySymbol,
                isPositiveGood: true,
              ),
              const SizedBox(height: 14),
              _buildMoMHighlightCallout(comparison, prevMonthLabel, isDark),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMoMRow({
    required bool isDark,
    required String title,
    required double currentAmount,
    required double previousAmount,
    required double change,
    required double? percentChange,
    required String currencySymbol,
    required bool isPositiveGood,
  }) {
    final bool isUp = change > 0;
    final bool isZero = change == 0;

    final Color badgeColor;
    if (isZero) {
      badgeColor = Colors.grey;
    } else if (isPositiveGood) {
      badgeColor = isUp ? AppColors.income : AppColors.expense;
    } else {
      badgeColor = isUp ? AppColors.expense : AppColors.income;
    }

    final String percentText = percentChange != null
        ? '${percentChange >= 0 ? '+' : ''}${percentChange.toStringAsFixed(1)}%'
        : 'New';

    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Prev: ${CurrencyFormatter.format(previousAmount, symbol: currencySymbol)}',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 4,
          child: Text(
            CurrencyFormatter.format(currentAmount, symbol: currencySymbol),
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isZero)
                Icon(
                  isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                  size: 12,
                  color: badgeColor,
                ),
              const SizedBox(width: 2),
              Text(
                percentText,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: badgeColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMoMHighlightCallout(
    MonthOverMonthComparison comp,
    String prevMonthLabel,
    bool isDark,
  ) {
    final String text;
    final IconData icon;
    final Color color;

    if (comp.expensePercentChange != null && comp.expensePercentChange! > 0) {
      text = 'Your spending increased by ${comp.expensePercentChange!.toStringAsFixed(1)}% compared with $prevMonthLabel.';
      icon = Icons.warning_amber_rounded;
      color = AppColors.expense;
    } else if (comp.expensePercentChange != null && comp.expensePercentChange! < 0) {
      text = 'Your spending decreased by ${comp.expensePercentChange!.abs().toStringAsFixed(1)}% compared with $prevMonthLabel. Great job keeping expenses down!';
      icon = Icons.thumb_up_alt_rounded;
      color = AppColors.income;
    } else if (comp.incomePercentChange != null && comp.incomePercentChange! > 0) {
      text = 'Your income grew by ${comp.incomePercentChange!.toStringAsFixed(1)}% compared with $prevMonthLabel.';
      icon = Icons.trending_up_rounded;
      color = AppColors.income;
    } else {
      text = 'Spending and income are steady compared to $prevMonthLabel.';
      icon = Icons.insights_rounded;
      color = AppColors.accent;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
