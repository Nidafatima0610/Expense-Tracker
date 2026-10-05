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
import '../goals/savings_goals_screen.dart';
import '../recurring/recurring_transactions_screen.dart';
import '../reports/reports_screen.dart';
import '../templates/transaction_templates_screen.dart';
import '../transactions/add_edit_transaction_screen.dart';
import '../../widgets/share_report_dialog.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback onViewAllTransactions;
  final VoidCallback? onViewReports;

  const DashboardScreen({
    super.key,
    required this.onViewAllTransactions,
    this.onViewReports,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isProcessingAction = false;

  String _getGreeting(String? displayName) {
    final hour = DateTime.now().hour;
    final timeGreeting = hour < 12
        ? 'Good morning'
        : (hour < 17 ? 'Good afternoon' : 'Good evening');

    if (displayName != null && displayName.trim().isNotEmpty) {
      return '$timeGreeting, ${displayName.trim()}';
    }
    return timeGreeting;
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
    if (widget.onViewReports != null) {
      widget.onViewReports!();
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const ReportsScreen(),
        ),
      );
    }
  }

  void _openSavingsGoals(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SavingsGoalsScreen(),
      ),
    );
  }

  void _openTemplates(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const TransactionTemplatesScreen(),
      ),
    );
  }

  void _applyTemplate(BuildContext context, dynamic template) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddEditTransactionScreen(
          initialType: template.type,
          prefilledTitle: template.title,
          prefilledAmount: template.amount > 0 ? template.amount : null,
          prefilledCategory: template.category,
          prefilledPaymentMethod: template.paymentMethod,
          prefilledNote: template.note,
        ),
      ),
    );
  }

  Future<void> _safeAction(Future<void> Function() action) async {
    if (_isProcessingAction) return;
    setState(() => _isProcessingAction = true);
    try {
      await action();
    } finally {
      if (mounted) {
        setState(() => _isProcessingAction = false);
      }
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

    // Active Budget Warnings for selected month (Prioritized)
    final budgetWarnings = appState.getBudgetWarningsForMonth(
      selectedMonth.year,
      selectedMonth.month,
    );

    // Financial Health Summary (Calculated from actual data)
    final healthSummary = appState.getFinancialHealthSummary(
      selectedMonth.year,
      selectedMonth.month,
    );

    // Upcoming Recurring transactions for in-app reminders
    final dueRecurring = appState.reminderUpcomingRecurring
        ? appState.recurringTransactions.where((r) => r.isActive).take(2).toList()
        : <dynamic>[];

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            // Instant reactive refresh
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Personalized Header with Greeting & Display Name
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getGreeting(appState.displayName),
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

                // 2. In-App Reminder Banner (if enabled and applicable)
                if (dueRecurring.isNotEmpty) ...[
                  _buildRecurringReminderCard(dueRecurring.first, isDark, currencySymbol),
                  const SizedBox(height: 14),
                ],

                // 3. Dynamic Month Selector Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
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
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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

                // 4. Dynamic Balance Card (All-Time Financial Overview)
                BalanceCard(
                  totalBalance: appState.totalBalance,
                  totalIncome: appState.totalIncome,
                  totalExpense: appState.totalExpense,
                  currencySymbol: currencySymbol,
                ),
                const SizedBox(height: 16),

                // 5. Quick Actions: Add Income & Add Expense
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _openAddTransaction(context, TransactionType.income),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
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
                        onTap: () => _openAddTransaction(context, TransactionType.expense),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
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

                // 6. Quick Templates / Quick Add Bar
                _buildQuickTemplatesBar(context, appState, isDark, currencySymbol),
                const SizedBox(height: 12),

                // 7. Secondary Quick Actions
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildQuickActionChip(
                        context: context,
                        isDark: isDark,
                        icon: Icons.savings_rounded,
                        label: 'Savings Goals',
                        onTap: () => _openSavingsGoals(context),
                      ),
                      const SizedBox(width: 8),
                      _buildQuickActionChip(
                        context: context,
                        isDark: isDark,
                        icon: Icons.bolt_rounded,
                        label: 'Templates',
                        onTap: () => _openTemplates(context),
                      ),
                      const SizedBox(width: 8),
                      _buildQuickActionChip(
                        context: context,
                        isDark: isDark,
                        icon: Icons.share_rounded,
                        label: 'Share Report',
                        onTap: () => showDialog(
                          context: context,
                          builder: (_) => const ShareReportDialog(),
                        ),
                      ),
                      const SizedBox(width: 8),
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
                        onTap: () => _safeAction(() async {
                          await ExportTransactionsSheet.show(context);
                        }),
                      ),
                      const SizedBox(width: 8),
                      _buildQuickActionChip(
                        context: context,
                        isDark: isDark,
                        icon: Icons.settings_backup_restore_rounded,
                        label: 'Restore Backup',
                        onTap: () => _safeAction(() async {
                          await BackupRestoreDialogs.showRestoreBackup(context);
                        }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // 7. FINANCIAL HEALTH SUMMARY (Actual Data Insight)
                _buildFinancialHealthCard(healthSummary, isDark),
                const SizedBox(height: 18),

                // 8. MULTI-TIER BUDGET ALERTS (Prioritized warnings: 50%, 75%, 90%, 100%, Over)
                if (budgetWarnings.isNotEmpty) ...[
                  _buildBudgetAlertsBanner(budgetWarnings, isDark),
                  const SizedBox(height: 18),
                ],

                // 9. CURRENT / SELECTED MONTH SUMMARY CARD
                Card(
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
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: (monthBalance >= 0 ? AppColors.income : AppColors.expense)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                monthBalance >= 0 ? 'Surplus' : 'Deficit',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: monthBalance >= 0 ? AppColors.income : AppColors.expense,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Stats Grid: Income, Expenses, Balance
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
                                      CurrencyFormatter.format(monthIncome, symbol: currencySymbol),
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
                                      CurrencyFormatter.format(monthExpense, symbol: currencySymbol),
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
                                        color: monthBalance >= 0 ? AppColors.income : AppColors.expense,
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
                              onTap: widget.onViewAllTransactions,
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

                // 10. BUDGET PROGRESS SECTION
                _buildBudgetProgressCard(
                  context: context,
                  isDark: isDark,
                  appState: appState,
                  selectedMonth: selectedMonth,
                  currencySymbol: currencySymbol,
                ),
                const SizedBox(height: 16),

                // 11. SAVINGS GOALS SUMMARY CARD
                _buildSavingsGoalsSummaryCard(
                  context: context,
                  isDark: isDark,
                  appState: appState,
                  currencySymbol: currencySymbol,
                ),
                const SizedBox(height: 16),

                // 12. SPENDING OVERVIEW & PIE CHART
                Card(
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
                              'SPENDING OVERVIEW',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.1,
                              ),
                            ),
                            Text(
                              CurrencyFormatter.format(monthExpense, symbol: currencySymbol),
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
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
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
                                sections: List.generate(expenseBreakdown.length, (i) {
                                  final item = expenseBreakdown[i];
                                  final color = _getCategoryColor(item.category, appState.categories);
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
                            final color = _getCategoryColor(item.category, appState.categories);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 12. Recent Transactions Header & List
                SectionHeader(
                  title: 'Recent Transactions',
                  actionText: recentTransactions.isNotEmpty ? 'View All' : null,
                  onActionTap: widget.onViewAllTransactions,
                ),
                const SizedBox(height: 12),

                if (recentTransactions.isEmpty)
                  EmptyStateWidget(
                    title: 'No Recent Activity',
                    description:
                        'Tap the buttons above to log your first income or expense transaction.',
                    actionLabel: 'Add Expense',
                    onAction: () => _openAddTransaction(context, TransactionType.expense),
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
                        onTap: () => TransactionDetailsSheet.show(context, item),
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

  // --- Financial Health Summary Card Component ---

  Widget _buildFinancialHealthCard(FinancialHealthSummary health, bool isDark) {
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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.health_and_safety_rounded,
                        color: AppColors.accent,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'FINANCIAL HEALTH',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    health.generalHealthStatus,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            if (!health.hasSufficientData) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Not enough data yet. Log income and expense transactions to see your savings rate, budget adherence, and spending trends.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    height: 1.3,
                  ),
                ),
              ),
            ] else ...[
              // Grid of 4 Health Metrics
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Savings Rate',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          health.savingsRate != null
                              ? '${health.savingsRate!.toStringAsFixed(1)}%'
                              : 'N/A',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: (health.savingsRate ?? 0) >= 20
                                ? AppColors.income
                                : ((health.savingsRate ?? 0) >= 0 ? AppColors.accent : AppColors.expense),
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
                          'Budget Adherence',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          health.budgetStatus,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, height: 1),
              const SizedBox(height: 10),

              // Spending trend & Income vs Expense
              Row(
                children: [
                  const Icon(Icons.trending_up_rounded, size: 14, color: AppColors.accent),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      health.spendingTrend,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.compare_arrows_rounded, size: 14, color: AppColors.accent),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      health.incomeVsExpense,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Informational analysis based on actual records, not professional financial advice.',
              style: TextStyle(
                fontSize: 10,
                fontStyle: FontStyle.italic,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Multi-tier Budget Alerts Banner ---

  Widget _buildBudgetAlertsBanner(List<BudgetWarning> warnings, bool isDark) {
    final highestWarning = warnings.first;
    final isCritical = highestWarning.isOverBudget || highestWarning.percentage >= 100;

    return InkWell(
      onTap: () => _openBudgets(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: (isCritical ? AppColors.expense : AppColors.warning).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCritical ? AppColors.expense : AppColors.warning,
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
                      isCritical ? Icons.error_outline_rounded : Icons.warning_amber_rounded,
                      color: isCritical ? AppColors.expense : AppColors.warning,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Budget Warnings (${warnings.length})',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: isCritical ? AppColors.expense : AppColors.warning,
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
            ...warnings.take(3).map((w) {
              final String badgeText;
              final Color badgeColor;
              if (w.isOverBudget) {
                badgeText = 'Over Budget';
                badgeColor = AppColors.expense;
              } else if (w.percentage >= 100) {
                badgeText = '100% Reached';
                badgeColor = AppColors.expense;
              } else if (w.percentage >= 90) {
                badgeText = '${w.percentage.toStringAsFixed(0)}% Used';
                badgeColor = AppColors.warning;
              } else if (w.percentage >= 75) {
                badgeText = '75% Used';
                badgeColor = AppColors.warning;
              } else {
                badgeText = '50% Used';
                badgeColor = AppColors.accent;
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: badgeColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        w.message,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
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
    );
  }

  // --- In-App Recurring Reminder Card ---

  Widget _buildRecurringReminderCard(dynamic recurring, bool isDark, String currencySymbol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.alarm_on_rounded, size: 18, color: AppColors.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Upcoming recurring: ${recurring.title} (${CurrencyFormatter.format(recurring.amount, symbol: currencySymbol)})',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
          ),
          InkWell(
            onTap: () => _openRecurring(context),
            child: const Text(
              'View',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.accent,
              ),
            ),
          ),
        ],
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

  Widget _buildSavingsGoalsSummaryCard({
    required BuildContext context,
    required bool isDark,
    required AppState appState,
    required String currencySymbol,
  }) {
    final goals = appState.savingsGoals;
    final activeGoals = goals.where((g) => !g.isCompleted).toList();
    final completedGoals = goals.where((g) => g.isCompleted).toList();

    final totalTarget = goals.fold<double>(0.0, (sum, g) => sum + g.targetAmount);
    final totalSaved = goals.fold<double>(0.0, (sum, g) => sum + g.currentAmount);
    final overallProgress = totalTarget > 0 ? (totalSaved / totalTarget).clamp(0.0, 1.0) : 0.0;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _openSavingsGoals(context),
        borderRadius: BorderRadius.circular(16),
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
                          color: AppColors.income.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.savings_rounded,
                          size: 18,
                          color: AppColors.income,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SAVINGS GOALS',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.1,
                            ),
                          ),
                          Text(
                            goals.isEmpty
                                ? 'No active targets'
                                : '${activeGoals.length} Active · ${completedGoals.length} Completed',
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.income.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(overallProgress * 100).toStringAsFixed(0)}% Saved',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.income,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 10,
                          color: AppColors.income,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (goals.isEmpty) ...[
                Text(
                  'Set targets for emergency fund, vacation, or big purchases to track your progress.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => _openSavingsGoals(context),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Create a Goal'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ] else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Saved: ${CurrencyFormatter.format(totalSaved, symbol: currencySymbol)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.income,
                      ),
                    ),
                    Text(
                      'Target: ${CurrencyFormatter.format(totalTarget, symbol: currencySymbol)}',
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
                    value: overallProgress,
                    minHeight: 8,
                    backgroundColor: isDark
                        ? AppColors.darkSurfaceSecondary
                        : AppColors.lightSurfaceSecondary,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.income),
                  ),
                ),
                if (activeGoals.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ...activeGoals.take(2).map((goal) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        children: [
                          Icon(goal.icon, size: 14, color: goal.statusColor),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              goal.name,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${(goal.progressPercentage * 100).toStringAsFixed(0)}%  (${CurrencyFormatter.format(goal.currentAmount, symbol: currencySymbol)})',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
                const SizedBox(height: 12),
                Divider(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  height: 1,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'View All Goals',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accent,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 10,
                        color: AppColors.accent,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickTemplatesBar(
    BuildContext context,
    AppState appState,
    bool isDark,
    String currencySymbol,
  ) {
    final templates = appState.transactionTemplates;

    if (templates.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bolt_rounded,
                size: 16,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick Add Templates',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Save frequent transactions for 1-tap entry',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => _openTemplates(context),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              ),
              child: const Text(
                'Set Up',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.bolt_rounded,
                  size: 15,
                  color: AppColors.accent,
                ),
                SizedBox(width: 5),
                Text(
                  'QUICK ADD',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            InkWell(
              onTap: () => _openTemplates(context),
              borderRadius: BorderRadius.circular(6),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  'Manage →',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              ...templates.map((template) {
                final isExp = template.type == TransactionType.expense;
                final color = isExp ? AppColors.expense : AppColors.income;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => _applyTemplate(context, template),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            template.paymentMethod.icon,
                            size: 13,
                            color: color,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            template.title,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (template.amount > 0) ...[
                            const SizedBox(width: 4),
                            Text(
                              '(${CurrencyFormatter.format(template.amount, symbol: currencySymbol)})',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: color,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }),
              InkWell(
                onTap: () => _openTemplates(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, size: 14, color: AppColors.accent),
                      SizedBox(width: 4),
                      Text(
                        'Template',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
