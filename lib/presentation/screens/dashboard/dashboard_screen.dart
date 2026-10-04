import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../providers/app_state.dart';
import '../../../providers/app_state_scope.dart';
import '../../widgets/backup_restore_dialogs.dart';
import '../../widgets/balance_card.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/export_transactions_sheet.dart';
import '../../widgets/section_header.dart';
import '../../widgets/transaction_details_sheet.dart';
import '../../widgets/transaction_tile.dart';
import '../budgets/budgets_screen.dart';
import '../calendar/calendar_screen.dart';
import '../categories/manage_categories_screen.dart';
import '../recurring/recurring_transactions_screen.dart';
import '../reports/reports_screen.dart';
import '../transactions/add_edit_transaction_screen.dart';

class DashboardScreen extends StatelessWidget {
  final VoidCallback onViewAllTransactions;
  final VoidCallback? onViewReports;

  const DashboardScreen({
    super.key,
    required this.onViewAllTransactions,
    this.onViewReports,
  });

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  void _openAddTransaction(BuildContext context, TransactionType type) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddEditTransactionScreen(initialType: type),
      ),
    );
  }

  void _openBudgets(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const BudgetsScreen(),
      ),
    );
  }

  void _openCategories(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ManageCategoriesScreen(),
      ),
    );
  }

  void _openCalendar(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const CalendarScreen(),
      ),
    );
  }

  void _openRecurring(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const RecurringTransactionsScreen(),
      ),
    );
  }

  void _openReports(BuildContext context) {
    if (onViewReports != null) {
      onViewReports!();
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const ReportsScreen(),
        ),
      );
    }
  }

  Future<void> _selectMonth(BuildContext context, AppState appState) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: appState.selectedDashboardMonth,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 2),
      helpText: 'Select Month',
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) {
      appState.setSelectedDashboardMonth(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appState = AppStateScope.of(context);
    final currencySymbol = appState.currencySymbol;
    final selectedMonth = appState.selectedDashboardMonth;

    // Selected Month Totals
    final monthIncome = appState.selectedMonthIncome;
    final monthExpense = appState.selectedMonthExpense;
    final monthBalance = appState.selectedMonthBalance;
    final monthTxCount = appState.selectedMonthTransactionCount;
    final monthTransactions = appState.selectedMonthTransactions;

    // Recent transactions for the selected month (or all-time latest if month is empty)
    final recentTransactions = monthTransactions.isNotEmpty
        ? (monthTransactions.length <= 5
            ? monthTransactions
            : monthTransactions.sublist(0, 5))
        : appState.getRecentTransactions(limit: 5);

    // Spending breakdown for selected month
    final expenseBreakdown = appState.getCategoryBreakdown(
      type: TransactionType.expense,
      year: selectedMonth.year,
      month: selectedMonth.month,
    );

    // Active Budget Warnings for selected month
    final budgetWarnings = appState.getBudgetWarningsForMonth(
      selectedMonth.year,
      selectedMonth.month,
    );

    // Financial Insights
    final insights = appState.getFinancialInsights(
      selectedMonth.year,
      selectedMonth.month,
    );

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            // Instant reactive update
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header with greeting and Quick Navigation Icons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getGreeting(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Expense Tracker',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Manage Budgets',
                          icon: const Icon(Icons.track_changes_rounded),
                          onPressed: () => _openBudgets(context),
                        ),
                        IconButton(
                          tooltip: 'Manage Categories',
                          icon: const Icon(Icons.category_rounded),
                          onPressed: () => _openCategories(context),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // 2. Dynamic Month Selector Bar
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurface
                        : AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded),
                        tooltip: 'Previous Month',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => appState.previousDashboardMonth(),
                      ),
                      InkWell(
                        onTap: () => _selectMonth(context, appState),
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.calendar_month_rounded,
                                size: 16,
                                color: AppColors.accent,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                DateFormatter.formatMonthYear(selectedMonth),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_drop_down_rounded,
                                size: 20,
                                color: isDark
                                    ? AppColors.darkTextMuted
                                    : AppColors.lightTextMuted,
                              ),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right_rounded),
                        tooltip: 'Next Month',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => appState.nextDashboardMonth(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Dynamic Balance Card (All-Time Financial Overview)
                BalanceCard(
                  totalBalance: appState.totalBalance,
                  totalIncome: appState.totalIncome,
                  totalExpense: appState.totalExpense,
                  currencySymbol: currencySymbol,
                ),
                const SizedBox(height: 16),

                // 4. Quick Actions: Add Income & Add Expense
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () =>
                            _openAddTransaction(context, TransactionType.income),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurface
                                : AppColors.lightSurface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.income.withValues(alpha: 0.3),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.income.withValues(alpha: 0.06),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.income.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.add_rounded,
                                  color: AppColors.income,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'Add Income',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.income,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () =>
                            _openAddTransaction(context, TransactionType.expense),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurface
                                : AppColors.lightSurface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.expense.withValues(alpha: 0.3),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.expense.withValues(alpha: 0.06),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.expense.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.remove_rounded,
                                  color: AppColors.expense,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'Add Expense',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.expense,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Secondary Quick Actions (Reports, Budgets, Calendar, Recurring, Export, Restore)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildQuickActionChip(
                        context: context,
                        isDark: isDark,
                        icon: Icons.bar_chart_rounded,
                        label: 'Reports',
                        onTap: () => _openReports(context),
                      ),
                      const SizedBox(width: 8),
                      _buildQuickActionChip(
                        context: context,
                        isDark: isDark,
                        icon: Icons.track_changes_rounded,
                        label: 'Budgets',
                        onTap: () => _openBudgets(context),
                      ),
                      const SizedBox(width: 8),
                      _buildQuickActionChip(
                        context: context,
                        isDark: isDark,
                        icon: Icons.calendar_month_rounded,
                        label: 'Calendar',
                        onTap: () => _openCalendar(context),
                      ),
                      const SizedBox(width: 8),
                      _buildQuickActionChip(
                        context: context,
                        isDark: isDark,
                        icon: Icons.repeat_rounded,
                        label: 'Recurring',
                        onTap: () => _openRecurring(context),
                      ),
                      const SizedBox(width: 8),
                      _buildQuickActionChip(
                        context: context,
                        isDark: isDark,
                        icon: Icons.file_upload_outlined,
                        label: 'Export CSV',
                        onTap: () => ExportTransactionsSheet.show(context),
                      ),
                      const SizedBox(width: 8),
                      _buildQuickActionChip(
                        context: context,
                        isDark: isDark,
                        icon: Icons.settings_backup_restore_rounded,
                        label: 'Restore Backup',
                        onTap: () => BackupRestoreDialogs.showRestoreBackup(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // 5. CURRENT / SELECTED MONTH SUMMARY CARD
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.analytics_rounded,
                                    size: 18,
                                    color: AppColors.accent,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Monthly Summary',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      DateFormatter.formatMonthYear(selectedMonth),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark
                                            ? AppColors.darkTextSecondary
                                            : AppColors.lightTextSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: (monthBalance >= 0
                                        ? AppColors.income
                                        : AppColors.expense)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                monthBalance >= 0 ? 'Surplus' : 'Deficit',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: monthBalance >= 0
                                      ? AppColors.income
                                      : AppColors.expense,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Stats Grid: Income, Expenses, Balance, Transactions
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Income',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      CurrencyFormatter.format(monthIncome,
                                          symbol: currencySymbol),
                                      style: const TextStyle(
                                        fontSize: 16,
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
                                    'Expenses',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      CurrencyFormatter.format(monthExpense,
                                          symbol: currencySymbol),
                                      style: const TextStyle(
                                        fontSize: 16,
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
                                  const SizedBox(height: 2),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      '${monthBalance >= 0 ? '+' : ''}${CurrencyFormatter.format(monthBalance, symbol: currencySymbol)}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: monthBalance >= 0
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
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 8),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Transactions Logged: $monthTxCount',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                            InkWell(
                              onTap: onViewAllTransactions,
                              child: const Text(
                                'View in Transactions →',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.accent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 6. BUDGET PROGRESS SECTION
                _buildBudgetProgressCard(
                  context: context,
                  isDark: isDark,
                  appState: appState,
                  selectedMonth: selectedMonth,
                  currencySymbol: currencySymbol,
                ),
                const SizedBox(height: 16),

                // 7. BUDGET WARNINGS BANNER (Goal 4)
                if (budgetWarnings.isNotEmpty) ...[
                  InkWell(
                    onTap: () => _openBudgets(context),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: (budgetWarnings.any((w) => w.isExceeded)
                                ? AppColors.expense
                                : AppColors.warning)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: budgetWarnings.any((w) => w.isExceeded)
                              ? AppColors.expense
                              : AppColors.warning,
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    budgetWarnings.any((w) => w.isExceeded)
                                        ? Icons.error_outline_rounded
                                        : Icons.warning_amber_rounded,
                                    color: budgetWarnings.any((w) => w.isExceeded)
                                        ? AppColors.expense
                                        : AppColors.warning,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Budget Warning (${budgetWarnings.length})',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: budgetWarnings.any((w) => w.isExceeded)
                                          ? AppColors.expense
                                          : AppColors.warning,
                                    ),
                                  ),
                                ],
                              ),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 12,
                                color: AppColors.accent,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...budgetWarnings.take(2).map((w) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Text(
                                '• ${w.message}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary,
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 7. SPENDING OVERVIEW & PIE CHART (Goal 1)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'SPENDING OVERVIEW',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.1,
                              ),
                            ),
                            Text(
                              CurrencyFormatter.format(monthExpense,
                                  symbol: currencySymbol),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppColors.expense,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        if (expenseBreakdown.isEmpty)
                          Container(
                            height: 120,
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.pie_chart_outline_rounded,
                                  size: 36,
                                  color: Colors.grey.withValues(alpha: 0.4),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'No expenses logged for this month',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        else ...[
                          // Donut Chart
                          SizedBox(
                            height: 160,
                            child: PieChart(
                              PieChartData(
                                borderData: FlBorderData(show: false),
                                sectionsSpace: 2,
                                centerSpaceRadius: 38,
                                sections: List.generate(
                                    expenseBreakdown.length, (i) {
                                  final item = expenseBreakdown[i];
                                  final color = _getCategoryColor(
                                      item.category, appState.categories);
                                  return PieChartSectionData(
                                    color: color,
                                    value: item.amount,
                                    title: item.percentage >= 15
                                        ? '${item.percentage.toStringAsFixed(0)}%'
                                        : '',
                                    radius: 38,
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
                          const SizedBox(height: 14),

                          // Top Categories Breakdown Progress Bars
                          ...expenseBreakdown.take(4).map((item) {
                            final color = _getCategoryColor(
                                item.category, appState.categories);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: color,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            item.category,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: isDark
                                                  ? AppColors.darkTextPrimary
                                                  : AppColors.lightTextPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        '${item.percentage.toStringAsFixed(0)}%  (${CurrencyFormatter.format(item.amount, symbol: currencySymbol)})',
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
                                  const SizedBox(height: 4),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: (item.percentage / 100)
                                          .clamp(0.0, 1.0),
                                      minHeight: 5,
                                      backgroundColor: isDark
                                          ? AppColors.darkSurfaceSecondary
                                          : AppColors.lightSurfaceSecondary,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(color),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 8. FINANCIAL INSIGHTS SECTION (Goal 10)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.lightbulb_rounded,
                                color: AppColors.accent,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'FINANCIAL INSIGHTS',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        ...insights.insightMessages.map((msg) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('• ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.accent,
                                    )),
                                Expanded(
                                  child: Text(
                                    msg,
                                    style: TextStyle(
                                      fontSize: 13,
                                      height: 1.4,
                                      color: isDark
                                          ? AppColors.darkTextPrimary
                                          : AppColors.lightTextPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 9. Recent Transactions Header & List
                SectionHeader(
                  title: 'Recent Transactions',
                  actionText:
                      recentTransactions.isNotEmpty ? 'View All' : null,
                  onActionTap: onViewAllTransactions,
                ),
                const SizedBox(height: 12),

                if (recentTransactions.isEmpty)
                  EmptyStateWidget(
                    title: 'No Recent Activity',
                    description:
                        'Tap the buttons above to log your first income or expense transaction.',
                    actionLabel: 'Add Expense',
                    onAction: () =>
                        _openAddTransaction(context, TransactionType.expense),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: recentTransactions.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = recentTransactions[index];
                      return TransactionTile(
                        transaction: item,
                        currencySymbol: currencySymbol,
                        onTap: () =>
                            TransactionDetailsSheet.show(context, item),
                      );
                    },
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
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

  Widget _buildQuickActionChip({
    required BuildContext context,
    required bool isDark,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: AppColors.accent),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBudgetProgressCard({
    required BuildContext context,
    required bool isDark,
    required AppState appState,
    required DateTime selectedMonth,
    required String currencySymbol,
  }) {
    final monthBudgets = appState
        .getBudgetsForMonth(selectedMonth.year, selectedMonth.month)
        .where((b) => b.isEnabled)
        .toList();

    final totalBudgeted =
        monthBudgets.fold<double>(0.0, (sum, b) => sum + b.amount);
    final totalSpent = monthBudgets.fold<double>(
        0.0, (sum, b) => sum + appState.getSpentForBudget(b));
    final usage = totalBudgeted > 0 ? (totalSpent / totalBudgeted) : 0.0;
    final remaining = totalBudgeted - totalSpent;

    final Color statusColor;
    final String statusLabel;
    if (totalBudgeted == 0) {
      statusColor = Colors.grey;
      statusLabel = 'Not Set';
    } else if (usage >= 1.0) {
      statusColor = AppColors.expense;
      statusLabel = 'Over Budget';
    } else if (usage >= 0.8) {
      statusColor = AppColors.warning;
      statusLabel = 'Near Limit';
    } else {
      statusColor = AppColors.income;
      statusLabel = 'Healthy';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.track_changes_rounded,
                        size: 18,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'BUDGET PROGRESS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                          ),
                        ),
                        Text(
                          DateFormatter.formatMonthYear(selectedMonth),
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (monthBudgets.isEmpty) ...[
              Text(
                'No budgets configured for ${DateFormatter.formatMonthYear(selectedMonth)}.',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => _openBudgets(context),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Set Up Budgets'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Spent: ${CurrencyFormatter.format(totalSpent, symbol: currencySymbol)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Limit: ${CurrencyFormatter.format(totalBudgeted, symbol: currencySymbol)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: usage.clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: isDark
                      ? AppColors.darkSurfaceSecondary
                      : AppColors.lightSurfaceSecondary,
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(usage * 100).toStringAsFixed(1)}% used',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                  Text(
                    remaining >= 0
                        ? '${CurrencyFormatter.format(remaining, symbol: currencySymbol)} left'
                        : '${CurrencyFormatter.format(remaining.abs(), symbol: currencySymbol)} over limit',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: remaining >= 0
                          ? (isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary)
                          : AppColors.expense,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                height: 1,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: InkWell(
                  onTap: () => _openBudgets(context),
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Manage Budgets',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accent,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_ios_rounded,
                            size: 10, color: AppColors.accent),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
