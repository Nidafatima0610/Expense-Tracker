import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/category_model.dart';
import '../../../providers/app_state_scope.dart';
import '../../widgets/category_icon_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/transaction_details_sheet.dart';
import '../../widgets/transaction_tile.dart';
import '../transactions/add_edit_transaction_screen.dart';

class CategoryDetailScreen extends StatelessWidget {
  final CategoryModel category;

  const CategoryDetailScreen({
    super.key,
    required this.category,
  });

  void _addTransactionInCategory(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddEditTransactionScreen(
          initialType: category.type,
          prefilledCategory: category.name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appState = AppStateScope.of(context);
    final currencySymbol = appState.currencySymbol;
    final isExpense = category.isExpense;

    final insights = appState.getCategoryInsights(
      category.name,
      type: category.type,
    );

    final related = insights.relatedTransactions;

    return Scaffold(
      appBar: AppBar(
        title: Text(category.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add Transaction in ${category.name}',
            onPressed: () => _addTransactionInCategory(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addTransactionInCategory(context),
        icon: const Icon(Icons.add_rounded),
        label: Text('Add ${isExpense ? 'Expense' : 'Income'}'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Category Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: category.color.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: category.color.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CategoryIconWidget(
                      category: category.name,
                      isExpense: isExpense,
                      size: 58,
                      iconSize: 28,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  category.name,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.lightTextPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (isExpense ? AppColors.expense : AppColors.income)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isExpense ? 'Expense' : 'Income',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isExpense ? AppColors.expense : AppColors.income,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isExpense ? 'Total Spent' : 'Total Earned',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                          Text(
                            CurrencyFormatter.format(insights.totalAmount, symbol: currencySymbol),
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: isExpense ? AppColors.expense : AppColors.income,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // 2. Metrics Grid (Count, Average, Largest)
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      isDark: isDark,
                      icon: Icons.receipt_long_rounded,
                      label: 'Transactions',
                      value: '${insights.count}',
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricTile(
                      isDark: isDark,
                      icon: Icons.calculate_rounded,
                      label: 'Average',
                      value: CurrencyFormatter.format(insights.averageAmount, symbol: currencySymbol),
                      color: AppColors.info,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricTile(
                      isDark: isDark,
                      icon: Icons.vertical_align_top_rounded,
                      label: 'Largest',
                      value: CurrencyFormatter.format(insights.largestAmount, symbol: currencySymbol),
                      color: isExpense ? AppColors.expense : AppColors.income,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // 3. Monthly Trend Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.trending_up_rounded,
                            size: 18,
                            color: category.color,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '6-MONTH TREND',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (insights.totalAmount == 0)
                        Container(
                          height: 100,
                          alignment: Alignment.center,
                          child: Text(
                            'No trend data available for this category.',
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.darkTextMuted
                                  : AppColors.lightTextMuted,
                              fontSize: 12,
                            ),
                          ),
                        )
                      else ...[
                        SizedBox(
                          height: 140,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: (insights.monthlyTrend.values.fold<double>(
                                          0.0, (m, v) => v > m ? v : m) *
                                      1.2)
                                  .clamp(10.0, double.infinity),
                              barTouchData: BarTouchData(
                                touchTooltipData: BarTouchTooltipData(
                                  getTooltipColor: (_) => isDark
                                      ? AppColors.darkSurfaceSecondary
                                      : AppColors.lightSurfaceSecondary,
                                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                    final monthKeys = insights.monthlyTrend.keys.toList();
                                    final month = monthKeys[groupIndex];
                                    return BarTooltipItem(
                                      '$month\n${CurrencyFormatter.format(rod.toY, symbol: currencySymbol)}',
                                      TextStyle(
                                        color: isDark ? Colors.white : Colors.black87,
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
                                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (val, meta) {
                                      final index = val.toInt();
                                      final keys = insights.monthlyTrend.keys.toList();
                                      if (index >= 0 && index < keys.length) {
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 6),
                                          child: Text(
                                            keys[index],
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: isDark
                                                  ? AppColors.darkTextSecondary
                                                  : AppColors.lightTextSecondary,
                                            ),
                                          ),
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    },
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              gridData: const FlGridData(show: false),
                              barGroups: List.generate(insights.monthlyTrend.length, (i) {
                                final values = insights.monthlyTrend.values.toList();
                                return BarChartGroupData(
                                  x: i,
                                  barRods: [
                                    BarChartRodData(
                                      toY: values[i],
                                      color: category.color,
                                      width: 14,
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                    ),
                                  ],
                                );
                              }),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 4. Related Transactions List
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Related Transactions (${related.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (related.isEmpty)
                EmptyStateWidget(
                  title: 'No Transactions Found',
                  description:
                      'There are no transactions logged under the "${category.name}" category.',
                  actionLabel: 'Log Transaction',
                  onAction: () => _addTransactionInCategory(context),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: related.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final tx = related[index];
                    return TransactionTile(
                      transaction: tx,
                      currencySymbol: currencySymbol,
                      onTap: () => TransactionDetailsSheet.show(context, tx),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required bool isDark,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
