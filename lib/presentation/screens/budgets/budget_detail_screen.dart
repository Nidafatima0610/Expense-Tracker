import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/budget_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../providers/app_state_scope.dart';
import '../../widgets/category_icon_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/transaction_tile.dart';

class BudgetDetailScreen extends StatelessWidget {
  final BudgetModel budget;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const BudgetDetailScreen({
    super.key,
    required this.budget,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencySymbol = appState.currencySymbol;

    // Fetch the latest budget instance from appState in case it was edited
    final currentBudget = appState.budgets.firstWhere(
      (b) => b.id == budget.id,
      orElse: () => budget,
    );

    final spent = appState.getSpentForBudget(currentBudget);
    final remaining = appState.getRemainingForBudget(currentBudget);
    final ratio = appState.getPercentageForBudget(currentBudget);
    final percent = (ratio * 100).clamp(0, 999).toStringAsFixed(0);
    final isExceeded = ratio >= 1.0;
    final isNear = ratio >= 0.8 && !isExceeded;

    Color statusColor = AppColors.income;
    String statusText = 'Healthy';
    IconData statusIcon = Icons.check_circle_outline_rounded;

    if (isExceeded) {
      statusColor = AppColors.expense;
      statusText = 'Over Budget';
      statusIcon = Icons.warning_rounded;
    } else if (isNear) {
      statusColor = AppColors.warning;
      statusText = 'Near Limit';
      statusIcon = Icons.info_outline_rounded;
    }

    final relatedTransactions = appState.getTransactionsForBudget(currentBudget);
    final monthDate = DateTime(currentBudget.year, currentBudget.month, 1);

    return Scaffold(
      appBar: AppBar(
        title: Text(currentBudget.isOverall ? 'Overall Budget' : '${currentBudget.category} Budget'),
        actions: [
          if (onEdit != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit Budget',
              onPressed: onEdit,
            ),
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.expense),
              tooltip: 'Delete Budget',
              onPressed: onDelete,
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header Overview Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        currentBudget.isOverall
                            ? Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.all_inclusive_rounded,
                                  color: AppColors.accent,
                                  size: 26,
                                ),
                              )
                            : CategoryIconWidget(
                                category: currentBudget.category,
                                isExpense: true,
                                size: 50,
                                iconSize: 26,
                              ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentBudget.isOverall
                                    ? 'Total Monthly Spending Limit'
                                    : '${currentBudget.category} Spending Target',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                DateFormatter.formatMonthYear(monthDate),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusIcon, size: 14, color: statusColor),
                              const SizedBox(width: 4),
                              Text(
                                statusText,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: statusColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (currentBudget.note != null && currentBudget.note!.trim().isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurfaceSecondary
                              : AppColors.lightSurfaceSecondary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.notes_rounded,
                              size: 16,
                              color: isDark
                                  ? AppColors.darkTextMuted
                                  : AppColors.lightTextMuted,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                currentBudget.note!,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),

                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: ratio.clamp(0.0, 1.0),
                        minHeight: 12,
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
                          '$percent% Used',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                        Text(
                          isExceeded
                              ? 'Exceeded by ${CurrencyFormatter.format(remaining.abs(), symbol: currencySymbol)}'
                              : '${CurrencyFormatter.format(remaining, symbol: currencySymbol)} remaining',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isExceeded
                                ? AppColors.expense
                                : (isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Divider(height: 1),
                    const SizedBox(height: 16),

                    // Metrics Grid (Budget, Spent, Remaining)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMetricCol(
                          label: 'Budget Limit',
                          amount: CurrencyFormatter.format(currentBudget.amount, symbol: currencySymbol),
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          isDark: isDark,
                        ),
                        _buildMetricCol(
                          label: 'Total Spent',
                          amount: CurrencyFormatter.format(spent, symbol: currencySymbol),
                          color: statusColor,
                          isDark: isDark,
                        ),
                        _buildMetricCol(
                          label: isExceeded ? 'Overspent' : 'Remaining',
                          amount: CurrencyFormatter.format(remaining.abs(), symbol: currencySymbol),
                          color: isExceeded ? AppColors.expense : AppColors.income,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // 2. Spending Trend Section (if there are transactions)
              if (relatedTransactions.isNotEmpty) ...[
                Text(
                  'SPENDING TREND',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                _buildSpendingTrendChart(relatedTransactions, currentBudget, isDark, currencySymbol),
                const SizedBox(height: 22),
              ],

              // 3. Related Transactions Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'RELATED TRANSACTIONS (${relatedTransactions.length})',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  if (relatedTransactions.isNotEmpty)
                    TextButton.icon(
                      icon: const Icon(Icons.filter_list_rounded, size: 16),
                      label: const Text('Filter in List', style: TextStyle(fontSize: 12)),
                      onPressed: () {
                        if (!currentBudget.isOverall) {
                          appState.setCategoryFilter(currentBudget.category);
                        }
                        appState.setTypeFilter(TransactionType.expense);
                        Navigator.of(context).pop();
                      },
                    ),
                ],
              ),
              const SizedBox(height: 10),

              if (relatedTransactions.isEmpty)
                EmptyStateWidget(
                  title: 'No Expenses Recorded',
                  description: 'No expenses have been recorded for this budget category in ${DateFormatter.formatMonthYear(monthDate)}.',
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: relatedTransactions.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final tx = relatedTransactions[index];
                    return TransactionTile(
                      transaction: tx,
                      currencySymbol: currencySymbol,
                    );
                  },
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCol({
    required String label,
    required String amount,
    required Color color,
    required bool isDark,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildSpendingTrendChart(
    List<TransactionModel> transactions,
    BudgetModel budget,
    bool isDark,
    String currencySymbol,
  ) {
    final daysInMonth = DateTime(budget.year, budget.month + 1, 0).day;
    final Map<int, double> dailyTotals = {};

    for (final tx in transactions) {
      dailyTotals[tx.date.day] = (dailyTotals[tx.date.day] ?? 0.0) + tx.amount;
    }

    double maxDaily = 0.0;
    for (final val in dailyTotals.values) {
      if (val > maxDaily) maxDaily = val;
    }
    if (maxDaily == 0) maxDaily = 100;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Daily Activity',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              Text(
                'Max: ${CurrencyFormatter.format(maxDaily, symbol: currencySymbol)}',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 130,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxDaily * 1.2,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => isDark ? AppColors.darkSurfaceSecondary : Colors.black87,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final day = group.x;
                      final amt = rod.toY;
                      return BarTooltipItem(
                        'Day $day\n${CurrencyFormatter.format(amt, symbol: currencySymbol)}',
                        const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        final day = val.toInt();
                        if (day == 1 || day == 10 || day == 20 || day == daysInMonth) {
                          return Text(
                            '$day',
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(daysInMonth, (i) {
                  final day = i + 1;
                  final spentDay = dailyTotals[day] ?? 0.0;
                  return BarChartGroupData(
                    x: day,
                    barRods: [
                      BarChartRodData(
                        toY: spentDay,
                        color: spentDay > 0 ? AppColors.accent : Colors.transparent,
                        width: daysInMonth > 30 ? 4 : 6,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
