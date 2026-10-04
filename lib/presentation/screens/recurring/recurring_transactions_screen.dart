import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/recurring_transaction_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../providers/app_state.dart';
import '../../../providers/app_state_scope.dart';
import '../../widgets/category_icon_widget.dart';

class RecurringTransactionsScreen extends StatefulWidget {
  const RecurringTransactionsScreen({super.key});

  @override
  State<RecurringTransactionsScreen> createState() =>
      _RecurringTransactionsScreenState();
}

class _RecurringTransactionsScreenState
    extends State<RecurringTransactionsScreen> {
  bool _isGenerating = false;

  void _generateDueNow(AppState appState) async {
    setState(() => _isGenerating = true);
    final count = await appState.generateDueRecurringTransactions();
    setState(() => _isGenerating = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          count > 0
              ? 'Successfully generated $count due transaction${count > 1 ? 's' : ''}!'
              : 'All recurring transactions are currently up to date.',
        ),
        backgroundColor: count > 0 ? AppColors.income : AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openAddEditDialog(
    BuildContext context,
    AppState appState, {
    RecurringTransactionModel? existing,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddEditRecurringSheet(
        appState: appState,
        existing: existing,
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    AppState appState,
    RecurringTransactionModel rule,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Recurring Rule?'),
        content: Text(
          'Are you sure you want to delete "${rule.title}"? Previously generated transactions will not be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
            onPressed: () async {
              Navigator.pop(ctx);
              await appState.deleteRecurringTransaction(rule.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showRuleDetails(
    BuildContext context,
    AppState appState,
    RecurringTransactionModel rule,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nextDate = rule.getNextOccurrence();
    final nextDateFormatted = nextDate != null
        ? DateFormat('EEEE, MMMM d, yyyy').format(nextDate)
        : 'Ended / None';
    final startDateFormatted = DateFormat('MMMM d, yyyy').format(rule.startDate);
    final endDateFormatted = rule.endDate != null
        ? DateFormat('MMMM d, yyyy').format(rule.endDate!)
        : 'No expiration date';
    final lastGenFormatted = rule.lastGeneratedDate != null
        ? DateFormat('MMMM d, yyyy').format(rule.lastGeneratedDate!)
        : 'Not yet generated';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(ctx).padding.bottom + 20,
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    CategoryIconWidget(
                      category: rule.category,
                      isExpense: rule.isExpense,
                      size: 48,
                      iconSize: 24,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rule.title,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${rule.type.displayName} • ${rule.category}',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (rule.isActive ? AppColors.income : AppColors.warning).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        rule.isActive ? 'Active' : 'Paused',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: rule.isActive ? AppColors.income : AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(height: 1),
                const SizedBox(height: 16),
                _buildDetailRow('Amount', CurrencyFormatter.format(rule.amount, symbol: appState.currencySymbol), isDark),
                const SizedBox(height: 10),
                _buildDetailRow('Recurrence', rule.frequency.displayName, isDark),
                const SizedBox(height: 10),
                _buildDetailRow('Next Occurrence', nextDateFormatted, isDark),
                const SizedBox(height: 10),
                _buildDetailRow('Last Generated', lastGenFormatted, isDark),
                const SizedBox(height: 10),
                _buildDetailRow('Start Date', startDateFormatted, isDark),
                const SizedBox(height: 10),
                _buildDetailRow('End Date', endDateFormatted, isDark),
                if (rule.note != null && rule.note!.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _buildDetailRow('Note', rule.note!, isDark),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: Icon(rule.isActive ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 18),
                        label: Text(rule.isActive ? 'Pause' : 'Resume'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          appState.toggleRecurringTransactionStatus(rule.id);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Edit Rule'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _openAddEditDialog(context, appState, existing: rule);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.expense),
                      tooltip: 'Delete Rule',
                      onPressed: () {
                        Navigator.pop(ctx);
                        _confirmDelete(context, appState, rule);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final recurringList = appState.recurringTransactions;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recurring Transactions'),
        actions: [
          IconButton(
            icon: _isGenerating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync_rounded),
            tooltip: 'Check & Generate Due Now',
            onPressed: _isGenerating ? null : () => _generateDueNow(appState),
          ),
        ],
      ),
      body: recurringList.isEmpty
          ? _buildEmptyState(context, appState)
          : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: recurringList.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (ctx, index) {
                final rule = recurringList[index];
                return _buildRecurringCard(ctx, appState, rule, isDark);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddEditDialog(context, appState),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Rule'),
        backgroundColor: AppColors.accent,
      ),
    );
  }

  Widget _buildRecurringCard(
    BuildContext context,
    AppState appState,
    RecurringTransactionModel rule,
    bool isDark,
  ) {
    final nextDate = rule.getNextOccurrence();
    final nextDateFormatted = nextDate != null
        ? DateFormat('EEE, MMM d, yyyy').format(nextDate)
        : 'Ended / None';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: rule.isActive
              ? (isDark ? AppColors.darkBorder : AppColors.lightBorder)
              : (isDark ? Colors.white10 : Colors.black12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showRuleDetails(context, appState, rule),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Category icon, Title, Active Switch
                Row(
                  children: [
                    CategoryIconWidget(
                      category: rule.category,
                      isExpense: rule.isExpense,
                      size: 40,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rule.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              decoration: rule.isActive
                                  ? null
                                  : TextDecoration.lineThrough,
                              color: rule.isActive
                                  ? (isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary)
                                  : (isDark
                                      ? AppColors.darkTextMuted
                                      : AppColors.lightTextMuted),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  rule.frequency.displayName,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.accent,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                rule.category,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Amount
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          CurrencyFormatter.format(
                            rule.amount,
                            symbol: appState.currencySymbol,
                            includeSign: true,
                          ),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: rule.isIncome
                                ? AppColors.income
                                : AppColors.expense,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Switch.adaptive(
                          value: rule.isActive,
                          activeTrackColor: AppColors.accent,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          onChanged: (_) {
                            appState.toggleRecurringTransactionStatus(rule.id);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 20),
                // Bottom row: Next occurrence and Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.event_repeat_rounded,
                            size: 16,
                            color: isDark
                                ? AppColors.darkTextMuted
                                : AppColors.lightTextMuted,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Next: $nextDateFormatted',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          tooltip: 'Edit Rule',
                          visualDensity: VisualDensity.compact,
                          onPressed: () => _openAddEditDialog(
                            context,
                            appState,
                            existing: rule,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            size: 20,
                            color: AppColors.expense.withValues(alpha: 0.8),
                          ),
                          tooltip: 'Delete Rule',
                          visualDensity: VisualDensity.compact,
                          onPressed: () =>
                              _confirmDelete(context, appState, rule),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppState appState) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.repeat_rounded,
                size: 56,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Recurring Transactions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Automate recurring bills, rent, subscriptions, or regular salary income. Transactions will be logged automatically on their due dates without duplicates.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _openAddEditDialog(context, appState),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create First Rule'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddEditRecurringSheet extends StatefulWidget {
  final AppState appState;
  final RecurringTransactionModel? existing;

  const _AddEditRecurringSheet({
    required this.appState,
    this.existing,
  });

  @override
  State<_AddEditRecurringSheet> createState() => _AddEditRecurringSheetState();
}

class _AddEditRecurringSheetState extends State<_AddEditRecurringSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _noteController;

  late TransactionType _type;
  late String _category;
  late RecurrenceFrequency _frequency;
  late DateTime _startDate;
  DateTime? _endDate;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;
    _titleController = TextEditingController(text: ex?.title ?? '');
    _amountController =
        TextEditingController(text: ex != null ? ex.amount.toString() : '');
    _noteController = TextEditingController(text: ex?.note ?? '');

    _type = ex?.type ?? TransactionType.expense;
    _category = ex?.category ??
        (_type == TransactionType.income ? 'Salary' : 'Bills');
    _frequency = ex?.frequency ?? RecurrenceFrequency.monthly;
    _startDate = ex?.startDate ?? DateTime.now();
    _endDate = ex?.endDate;
    _isActive = ex?.isActive ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    final title = _titleController.text.trim();
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final note = _noteController.text.trim();

    if (widget.existing != null) {
      final updated = widget.existing!.copyWith(
        title: title,
        amount: amount,
        type: _type,
        category: _category,
        note: note.isNotEmpty ? note : null,
        startDate: _startDate,
        endDate: _endDate,
        frequency: _frequency,
        isActive: _isActive,
      );
      await widget.appState.updateRecurringTransaction(updated);
    } else {
      final rule = RecurringTransactionModel(
        id: const Uuid().v4(),
        title: title,
        amount: amount,
        type: _type,
        category: _category,
        note: note.isNotEmpty ? note : null,
        startDate: _startDate,
        endDate: _endDate,
        frequency: _frequency,
        isActive: _isActive,
        createdAt: DateTime.now(),
      );
      await widget.appState.addRecurringTransaction(rule);
    }

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final availableCategories = _type == TransactionType.income
        ? widget.appState.incomeCategories
        : widget.appState.expenseCategories;

    // Ensure category is valid for type
    if (!availableCategories.any((c) => c.name == _category)) {
      if (availableCategories.isNotEmpty) {
        _category = availableCategories.first.name;
      }
    }

    return Container(
      margin: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.existing != null
                    ? 'Edit Recurring Rule'
                    : 'New Recurring Transaction',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // Type Segmented Switch (Income vs Expense)
              SegmentedButton<TransactionType>(
                segments: const [
                  ButtonSegment(
                    value: TransactionType.expense,
                    label: Text('Expense'),
                    icon: Icon(Icons.arrow_upward_rounded),
                  ),
                  ButtonSegment(
                    value: TransactionType.income,
                    label: Text('Income'),
                    icon: Icon(Icons.arrow_downward_rounded),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (set) {
                  setState(() {
                    _type = set.first;
                    final list = _type == TransactionType.income
                        ? widget.appState.incomeCategories
                        : widget.appState.expenseCategories;
                    if (list.isNotEmpty) {
                      _category = list.first.name;
                    }
                  });
                },
              ),
              const SizedBox(height: 14),
              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title / Description *',
                  hintText: 'e.g. Netflix, Apartment Rent, Salary',
                  prefixIcon: Icon(Icons.title_rounded),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Title is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              // Amount
              TextFormField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Amount *',
                  prefixText: '${widget.appState.currencySymbol} ',
                  prefixIcon: const Icon(Icons.attach_money_rounded),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Amount is required';
                  }
                  final parsed = double.tryParse(val.trim());
                  if (parsed == null || parsed <= 0) {
                    return 'Enter a valid positive number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              // Category Dropdown
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category_rounded),
                ),
                items: availableCategories.map((c) {
                  return DropdownMenuItem(
                    value: c.name,
                    child: Row(
                      children: [
                        Icon(c.icon, size: 18, color: c.color),
                        const SizedBox(width: 8),
                        Text(c.name),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _category = val);
                },
              ),
              const SizedBox(height: 12),
              // Frequency Selector
              DropdownButtonFormField<RecurrenceFrequency>(
                initialValue: _frequency,
                decoration: const InputDecoration(
                  labelText: 'Repeat Frequency',
                  prefixIcon: Icon(Icons.repeat_rounded),
                ),
                items: [
                  RecurrenceFrequency.daily,
                  RecurrenceFrequency.weekly,
                  RecurrenceFrequency.monthly,
                  RecurrenceFrequency.yearly,
                ].map((f) {
                  return DropdownMenuItem(
                    value: f,
                    child: Text(f.displayName),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _frequency = val);
                },
              ),
              const SizedBox(height: 12),
              // Dates Row (Start Date & Optional End Date)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today_rounded, size: 16),
                      label: Text(
                        'Start: ${DateFormat('MMM d, yyyy').format(_startDate)}',
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _startDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2040),
                        );
                        if (picked != null) {
                          setState(() => _startDate = picked);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.event_busy_rounded, size: 16),
                      label: Text(
                        _endDate != null
                            ? 'End: ${DateFormat('MMM d, yyyy').format(_endDate!)}'
                            : 'No End Date',
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _endDate ?? _startDate.add(const Duration(days: 365)),
                          firstDate: _startDate,
                          lastDate: DateTime(2040),
                        );
                        if (picked != null) {
                          setState(() => _endDate = picked);
                        }
                      },
                    ),
                  ),
                  if (_endDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      tooltip: 'Clear End Date',
                      onPressed: () => setState(() => _endDate = null),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // Note
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Note (Optional)',
                  hintText: 'e.g. Account number, contract reference',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  widget.existing != null ? 'Update Rule' : 'Create Recurring Rule',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
