import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/budget_model.dart';
import '../../../providers/app_state_scope.dart';
import '../../widgets/category_icon_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/primary_button.dart';
import 'budget_detail_screen.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month, 1);
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month - 1,
        1,
      );
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + 1,
        1,
      );
    });
  }

  void _showAddEditBudgetModal({BudgetModel? budgetToEdit}) {
    final isEditing = budgetToEdit != null;
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController(
      text: budgetToEdit != null ? budgetToEdit.amount.toStringAsFixed(2) : '',
    );
    final noteController =
        TextEditingController(text: budgetToEdit?.note ?? '');

    final appState = AppStateScope.of(context);
    final availableCategories = [
      'Overall',
      ...appState.expenseCategories.map((c) => c.name),
    ];

    String selectedCategory = budgetToEdit?.category ?? availableCategories.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final isDark = Theme.of(ctx).brightness == Brightness.dark;

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                ),
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isEditing ? 'Edit Budget' : 'Create Monthly Budget',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () => Navigator.pop(ctx),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Month info banner
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurfaceSecondary
                                : AppColors.lightSurfaceSecondary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_month_rounded,
                                size: 18,
                                color: AppColors.accent,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Budget for ${DateFormatter.formatMonthYear(_selectedMonth)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Category Dropdown
                        const Text(
                          'BUDGET TARGET',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: availableCategories.contains(selectedCategory)
                              ? selectedCategory
                              : availableCategories.first,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.category_rounded),
                          ),
                          items: availableCategories.map((cat) {
                            return DropdownMenuItem(
                              value: cat,
                              child: Text(
                                cat == 'Overall'
                                    ? 'Overall Monthly Budget'
                                    : '$cat Budget',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() => selectedCategory = val);
                            }
                          },
                        ),
                        const SizedBox(height: 16),

                        // Amount field
                        const Text(
                          'BUDGET AMOUNT',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: amountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            prefixIcon: Padding(
                              padding: const EdgeInsets.only(left: 16, right: 8),
                              child: Text(
                                appState.currencySymbol,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            prefixIconConstraints:
                                const BoxConstraints(minWidth: 0, minHeight: 0),
                            hintText: '0.00',
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Please enter a budget amount';
                            }
                            final numVal = double.tryParse(val.trim());
                            if (numVal == null || numVal <= 0) {
                              return 'Enter a valid amount greater than 0';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Optional Note
                        const Text(
                          'NOTE (OPTIONAL)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: noteController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            hintText: 'e.g. Monthly limit for dining out',
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Submit
                        PrimaryButton(
                          label: isEditing ? 'Update Budget' : 'Save Budget',
                          icon: isEditing
                              ? Icons.check_circle_rounded
                              : Icons.add_rounded,
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;

                            final amount =
                                double.parse(amountController.text.trim());
                            final note = noteController.text.trim().isEmpty
                                ? null
                                : noteController.text.trim();

                            if (isEditing) {
                              final updated = budgetToEdit.copyWith(
                                category: selectedCategory,
                                amount: amount,
                                note: note,
                              );
                              await appState.updateBudget(updated);
                            } else {
                              const uuid = Uuid();
                              final newBudget = BudgetModel(
                                id: uuid.v4(),
                                category: selectedCategory,
                                amount: amount,
                                month: _selectedMonth.month,
                                year: _selectedMonth.year,
                                note: note,
                                createdAt: DateTime.now(),
                              );
                              await appState.addBudget(newBudget);
                            }

                            if (!mounted) return;
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isEditing
                                      ? 'Budget updated'
                                      : 'Budget saved for $selectedCategory',
                                ),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
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

  Future<void> _handleDeleteBudget(BudgetModel budget) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Budget?'),
        content: Text(
          'Are you sure you want to delete the budget for "${budget.category}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expense,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final appState = AppStateScope.of(context);
      await appState.deleteBudget(budget.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Budget for "${budget.category}" deleted'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appState = AppStateScope.of(context);
    final currencySymbol = appState.currencySymbol;

    final budgets = appState.getBudgetsForMonth(
      _selectedMonth.year,
      _selectedMonth.month,
    );

    final warnings = appState.getBudgetWarningsForMonth(
      _selectedMonth.year,
      _selectedMonth.month,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Budgets'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditBudgetModal(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Budget'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
          children: [
            // Month Selector Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                    onPressed: _previousMonth,
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_month_rounded,
                        size: 18,
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormatter.formatMonthYear(_selectedMonth),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded),
                    tooltip: 'Next Month',
                    onPressed: _nextMonth,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Active Budget Warnings Card (if any)
            if (warnings.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (warnings.any((w) => w.isExceeded)
                          ? AppColors.expense
                          : AppColors.warning)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: warnings.any((w) => w.isExceeded)
                        ? AppColors.expense
                        : AppColors.warning,
                    width: 1.2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          warnings.any((w) => w.isExceeded)
                              ? Icons.error_outline_rounded
                              : Icons.warning_amber_rounded,
                          color: warnings.any((w) => w.isExceeded)
                              ? AppColors.expense
                              : AppColors.warning,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Budget Alert (${warnings.length})',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: warnings.any((w) => w.isExceeded)
                                ? AppColors.expense
                                : AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...warnings.map((w) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                            Expanded(
                              child: Text(
                                w.message,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
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
              const SizedBox(height: 16),
            ],

            // Budget list or Empty State
            if (budgets.isEmpty)
              EmptyStateWidget(
                title: 'No Budgets Configured',
                description:
                    'Set budget targets for ${DateFormatter.formatMonthYear(_selectedMonth)} to monitor your spending and stay within your financial goals.',
                icon: Icons.track_changes_rounded,
                actionLabel: 'Create Budget',
                onAction: () => _showAddEditBudgetModal(),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: budgets.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (ctx, index) {
                  final budget = budgets[index];
                  final spent = appState.getSpentForBudget(budget);
                  final remaining = appState.getRemainingForBudget(budget);
                  final ratio = appState.getPercentageForBudget(budget);
                  final isExceeded = ratio >= 1.0;
                  final isNear = ratio >= 0.8 && !isExceeded;

                  Color statusColor = AppColors.income;
                  String statusLabel = 'Under Budget';

                  if (isExceeded) {
                    statusColor = AppColors.expense;
                    statusLabel = 'Exceeded';
                  } else if (isNear) {
                    statusColor = AppColors.warning;
                    statusLabel = 'Near Limit';
                  }

                  return Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => BudgetDetailScreen(
                              budget: budget,
                              onEdit: () {
                                Navigator.of(context).pop();
                                _showAddEditBudgetModal(budgetToEdit: budget);
                              },
                              onDelete: () {
                                Navigator.of(context).pop();
                                _handleDeleteBudget(budget);
                              },
                            ),
                          ),
                        );
                      },
                      child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              budget.isOverall
                                  ? Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: AppColors.accent
                                            .withValues(alpha: 0.15),
                                        borderRadius:
                                            BorderRadius.circular(14),
                                      ),
                                      child: const Icon(
                                        Icons.all_inclusive_rounded,
                                        color: AppColors.accent,
                                        size: 22,
                                      ),
                                    )
                                  : CategoryIconWidget(
                                      category: budget.category,
                                      isExpense: true,
                                      size: 44,
                                      iconSize: 22,
                                    ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      budget.isOverall
                                          ? 'Overall Monthly Budget'
                                          : '${budget.category} Budget',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? AppColors.darkTextPrimary
                                            : AppColors.lightTextPrimary,
                                      ),
                                    ),
                                    if (budget.note != null &&
                                        budget.note!.trim().isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        budget.note!,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontStyle: FontStyle.italic,
                                          color: isDark
                                              ? AppColors.darkTextMuted
                                              : AppColors.lightTextMuted,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${(ratio * 100).toStringAsFixed(0)}% • $statusLabel',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Progress Bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: ratio.clamp(0.0, 1.0),
                              minHeight: 10,
                              backgroundColor: isDark
                                  ? AppColors.darkSurfaceSecondary
                                  : AppColors.lightSurfaceSecondary,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(statusColor),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Financial Breakdown Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Spent',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark
                                          ? AppColors.darkTextMuted
                                          : AppColors.lightTextMuted,
                                    ),
                                  ),
                                  Text(
                                    CurrencyFormatter.format(spent,
                                        symbol: currencySymbol),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: statusColor,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    isExceeded ? 'Overspent' : 'Remaining',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark
                                          ? AppColors.darkTextMuted
                                          : AppColors.lightTextMuted,
                                    ),
                                  ),
                                  Text(
                                    CurrencyFormatter.format(
                                      remaining.abs(),
                                      symbol: currencySymbol,
                                    ),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: isExceeded
                                          ? AppColors.expense
                                          : (isDark
                                              ? AppColors.darkTextPrimary
                                              : AppColors.lightTextPrimary),
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Limit',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark
                                          ? AppColors.darkTextMuted
                                          : AppColors.lightTextMuted,
                                    ),
                                  ),
                                  Text(
                                    CurrencyFormatter.format(budget.amount,
                                        symbol: currencySymbol),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? AppColors.darkTextPrimary
                                          : AppColors.lightTextPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Divider(height: 1),
                          const SizedBox(height: 6),

                          // Quick actions
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                icon: const Icon(Icons.edit_outlined, size: 16),
                                label: const Text('Edit', style: TextStyle(fontSize: 12)),
                                onPressed: () =>
                                    _showAddEditBudgetModal(budgetToEdit: budget),
                              ),
                              const SizedBox(width: 8),
                              TextButton.icon(
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 16,
                                  color: AppColors.expense,
                                ),
                                label: const Text(
                                  'Delete',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.expense,
                                  ),
                                ),
                                onPressed: () => _handleDeleteBudget(budget),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
                },
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
