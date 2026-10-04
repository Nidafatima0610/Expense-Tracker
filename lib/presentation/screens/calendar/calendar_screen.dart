import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/transaction_model.dart';
import '../../../providers/app_state.dart';
import '../../../providers/app_state_scope.dart';
import '../../widgets/transaction_tile.dart';
import '../transactions/add_edit_transaction_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _displayedMonth;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayedMonth = DateTime(now.year, now.month, 1);
    _selectedDay = DateTime(now.year, now.month, now.day);
  }

  void _previousMonth() {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month - 1,
        1,
      );
    });
  }

  void _nextMonth() {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month + 1,
        1,
      );
    });
  }

  void _jumpToToday() {
    final now = DateTime.now();
    setState(() {
      _displayedMonth = DateTime(now.year, now.month, 1);
      _selectedDay = DateTime(now.year, now.month, now.day);
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filter transactions for displayed month to show dots
    final monthTransactions = appState.transactions.where((t) {
      return t.date.year == _displayedMonth.year &&
          t.date.month == _displayedMonth.month;
    }).toList();

    // Group transactions by day of month
    final Map<int, List<TransactionModel>> dayMap = {};
    for (final t in monthTransactions) {
      dayMap.putIfAbsent(t.date.day, () => []).add(t);
    }

    // Transactions for the currently selected day
    final selectedDayTransactions = appState.transactions.where((t) {
      return t.date.year == _selectedDay.year &&
          t.date.month == _selectedDay.month &&
          t.date.day == _selectedDay.day;
    }).toList();

    final dailyIncome = selectedDayTransactions
        .where((t) => t.isIncome)
        .fold(0.0, (s, t) => s + t.amount);
    final dailyExpense = selectedDayTransactions
        .where((t) => t.isExpense)
        .fold(0.0, (s, t) => s + t.amount);
    final dailyBalance = dailyIncome - dailyExpense;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Calendar'),
        actions: [
          TextButton.icon(
            onPressed: _jumpToToday,
            icon: const Icon(Icons.today_rounded, size: 18),
            label: const Text('Today'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Month Navigator Bar
          _buildMonthNavigator(context, isDark),
          // Weekday header
          _buildWeekdayHeader(isDark),
          // Days Grid
          _buildCalendarGrid(dayMap, isDark),
          const Divider(height: 1),
          // Selected Day Summary & Transactions
          Expanded(
            child: _buildSelectedDaySection(
              context,
              appState,
              selectedDayTransactions,
              dailyIncome,
              dailyExpense,
              dailyBalance,
              isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthNavigator(BuildContext context, bool isDark) {
    final monthStr = DateFormat('MMMM yyyy').format(_displayedMonth);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: _previousMonth,
            tooltip: 'Previous Month',
          ),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _displayedMonth,
                firstDate: DateTime(2020),
                lastDate: DateTime(2040),
                initialDatePickerMode: DatePickerMode.year,
              );
              if (picked != null) {
                setState(() {
                  _displayedMonth = DateTime(picked.year, picked.month, 1);
                });
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  Text(
                    monthStr,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down, size: 20),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: _nextMonth,
            tooltip: 'Next Month',
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayHeader(bool isDark) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: weekdays.map((day) {
          final isWeekend = day == 'Sat' || day == 'Sun';
          return SizedBox(
            width: 40,
            child: Text(
              day,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isWeekend
                    ? AppColors.accent
                    : (isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCalendarGrid(
    Map<int, List<TransactionModel>> dayMap,
    bool isDark,
  ) {
    final year = _displayedMonth.year;
    final month = _displayedMonth.month;
    final firstDayOfMonth = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;

    // Weekday 1 is Monday, 7 is Sunday
    final leadingSpaces = firstDayOfMonth.weekday - 1;
    final totalCells = ((leadingSpaces + daysInMonth + 6) ~/ 7) * 7;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: totalCells,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          childAspectRatio: 1.15,
        ),
        itemBuilder: (context, index) {
          final dayNumber = index - leadingSpaces + 1;
          if (dayNumber < 1 || dayNumber > daysInMonth) {
            return const SizedBox.shrink();
          }

          final cellDate = DateTime(year, month, dayNumber);
          final isSelected = cellDate.year == _selectedDay.year &&
              cellDate.month == _selectedDay.month &&
              cellDate.day == _selectedDay.day;

          final now = DateTime.now();
          final isToday = cellDate.year == now.year &&
              cellDate.month == now.month &&
              cellDate.day == now.day;

          final txs = dayMap[dayNumber] ?? [];
          final hasIncome = txs.any((t) => t.isIncome);
          final hasExpense = txs.any((t) => t.isExpense);

          return InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              setState(() {
                _selectedDay = cellDate;
              });
            },
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.accent
                    : (isToday
                        ? AppColors.accent.withValues(alpha: 0.12)
                        : Colors.transparent),
                borderRadius: BorderRadius.circular(10),
                border: isToday && !isSelected
                    ? Border.all(color: AppColors.accent, width: 1.2)
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$dayNumber',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected || isToday
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? Colors.white
                          : (isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary),
                    ),
                  ),
                  const SizedBox(height: 3),
                  // Visual Indicators for Income / Expense / Both
                  if (hasIncome || hasExpense)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (hasIncome)
                          Container(
                            width: 5,
                            height: 5,
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white : AppColors.income,
                              shape: BoxShape.circle,
                            ),
                          ),
                        if (hasExpense)
                          Container(
                            width: 5,
                            height: 5,
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white : AppColors.expense,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    )
                  else
                    const SizedBox(height: 5),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSelectedDaySection(
    BuildContext context,
    AppState appState,
    List<TransactionModel> transactions,
    double income,
    double expense,
    double balance,
    bool isDark,
  ) {
    final dateFormatted =
        DateFormat('EEEE, MMMM d, yyyy').format(_selectedDay);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Daily Summary Strip
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dateFormatted,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddEditTransactionScreen(
                            prefilledDate: _selectedDay,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_circle_outline,
                              size: 16, color: AppColors.accent),
                          const SizedBox(width: 4),
                          Text(
                            'Add',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryPill(
                      label: 'Income',
                      amount: income,
                      symbol: appState.currencySymbol,
                      color: AppColors.income,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildSummaryPill(
                      label: 'Expense',
                      amount: expense,
                      symbol: appState.currencySymbol,
                      color: AppColors.expense,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildSummaryPill(
                      label: 'Balance',
                      amount: balance,
                      symbol: appState.currencySymbol,
                      color: balance >= 0 ? AppColors.income : AppColors.expense,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Transactions List
        Expanded(
          child: transactions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_note_outlined,
                        size: 48,
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No transactions on this date',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount: transactions.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (ctx, index) {
                    final tx = transactions[index];
                    return TransactionTile(
                      transaction: tx,
                      currencySymbol: appState.currencySymbol,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSummaryPill({
    required String label,
    required double amount,
    required String symbol,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            CurrencyFormatter.format(amount, symbol: symbol),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
