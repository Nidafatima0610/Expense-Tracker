import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/recurring_transaction_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../providers/app_state_scope.dart';
import '../../widgets/primary_button.dart';

import '../categories/manage_categories_screen.dart';

class AddEditTransactionScreen extends StatefulWidget {
  final TransactionModel? transactionToEdit;
  final TransactionType initialType;
  final DateTime? prefilledDate;
  final String? prefilledCategory;
  final PaymentMethod? prefilledPaymentMethod;
  final double? prefilledAmount;
  final String? prefilledTitle;
  final String? prefilledNote;

  const AddEditTransactionScreen({
    super.key,
    this.transactionToEdit,
    this.initialType = TransactionType.expense,
    this.prefilledDate,
    this.prefilledCategory,
    this.prefilledPaymentMethod,
    this.prefilledAmount,
    this.prefilledTitle,
    this.prefilledNote,
  });

  @override
  State<AddEditTransactionScreen> createState() =>
      _AddEditTransactionScreenState();
}

class _AddEditTransactionScreenState extends State<AddEditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();

  late TransactionType _type;
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  late DateTime _selectedDate;
  late String _selectedCategory;
  late PaymentMethod _selectedPaymentMethod;
  late RecurrenceFrequency _recurrence;
  bool _isSaving = false;
  bool _hasInitializedPreferences = false;

  bool get _isEditing => widget.transactionToEdit != null;

  @override
  void initState() {
    super.initState();
    final edit = widget.transactionToEdit;
    if (edit != null) {
      _type = edit.type;
      _titleController = TextEditingController(text: edit.title);
      _amountController =
          TextEditingController(text: edit.amount.toStringAsFixed(2));
      _noteController = TextEditingController(text: edit.note ?? '');
      _selectedDate = edit.date;
      _selectedCategory = edit.category;
      _selectedPaymentMethod = edit.paymentMethod;
      _recurrence = edit.recurrence;
    } else {
      _type = widget.initialType;
      _titleController =
          TextEditingController(text: widget.prefilledTitle ?? '');
      _amountController = TextEditingController(
        text: widget.prefilledAmount != null
            ? widget.prefilledAmount!.toStringAsFixed(2)
            : '',
      );
      _noteController = TextEditingController(text: widget.prefilledNote ?? '');
      _selectedDate = widget.prefilledDate ?? DateTime.now();
      _selectedCategory = widget.prefilledCategory ?? '';
      _selectedPaymentMethod =
          widget.prefilledPaymentMethod ?? PaymentMethod.cash;
      _recurrence = RecurrenceFrequency.none;
    }

    _titleController.addListener(_onFieldChanged);
    _amountController.addListener(_onFieldChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitializedPreferences && widget.transactionToEdit == null) {
      _hasInitializedPreferences = true;
      final appState = AppStateScope.of(context);
      if (widget.prefilledPaymentMethod == null) {
        _selectedPaymentMethod = appState.getLastUsedPaymentMethod();
      }
      if (_selectedCategory.isEmpty && widget.prefilledCategory == null) {
        final lastUsed = _type == TransactionType.expense
            ? appState.getLastUsedExpenseCategory()
            : appState.getLastUsedIncomeCategory();
        if (lastUsed != null && lastUsed.isNotEmpty) {
          _selectedCategory = lastUsed;
        }
      }
    }
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onTypeChanged(TransactionType newType) {
    if (_type == newType) return;
    setState(() {
      _type = newType;
      _selectedCategory = ''; // Will reset to first available of new type in build
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 2),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: _type == TransactionType.income
                      ? AppColors.income
                      : AppColors.expense,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDate.hour,
          _selectedDate.minute,
        );
      });
    }
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount greater than 0'),
          backgroundColor: AppColors.expense,
        ),
      );
      return;
    }

    final appState = AppStateScope.of(context);
    final title = _titleController.text.trim();
    final note = _noteController.text.trim().isEmpty
        ? null
        : _noteController.text.trim();

    // Duplicate detection warning (does not block legitimate duplicates)
    final isDuplicate = appState.hasDuplicateTransaction(
      title: title,
      amount: amount,
      date: _selectedDate,
      category: _selectedCategory,
      excludeId: widget.transactionToEdit?.id,
    );

    if (isDuplicate) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.warning),
              SizedBox(width: 8),
              Text('Duplicate Warning'),
            ],
          ),
          content: Text(
            'A transaction with the title "$title", amount, category, and date already exists.\n\nDo you want to save this transaction anyway?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Review Entry'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save Anyway'),
            ),
          ],
        ),
      );

      if (proceed != true) {
        return;
      }
    }

    setState(() => _isSaving = true);

    try {
      if (_isEditing) {
        final updated = widget.transactionToEdit!.copyWith(
          title: title,
          amount: amount,
          type: _type,
          category: _selectedCategory,
          paymentMethod: _selectedPaymentMethod,
          date: _selectedDate,
          note: note,
          recurrence: _recurrence,
        );
        await appState.updateTransaction(updated);
      } else {
        const uuid = Uuid();
        final newTx = TransactionModel(
          id: uuid.v4(),
          title: title,
          amount: amount,
          type: _type,
          category: _selectedCategory,
          paymentMethod: _selectedPaymentMethod,
          date: _selectedDate,
          note: note,
          createdAt: DateTime.now(),
          recurrence: _recurrence,
        );
        await appState.addTransaction(newTx);

        // Remember user's last selected category & payment method for quick add
        if (_type == TransactionType.expense) {
          await appState.rememberLastUsed(
            expenseCategory: _selectedCategory,
            paymentMethod: _selectedPaymentMethod,
          );
        } else {
          await appState.rememberLastUsed(
            incomeCategory: _selectedCategory,
            paymentMethod: _selectedPaymentMethod,
          );
        }

        // If marked with recurrence, also create recurring schedule
        if (_recurrence != RecurrenceFrequency.none) {
          final recRule = RecurringTransactionModel(
            id: uuid.v4(),
            title: title,
            amount: amount,
            type: _type,
            category: _selectedCategory,
            note: note,
            startDate: _selectedDate,
            frequency: _recurrence,
            isActive: true,
            lastGeneratedDate: _selectedDate,
            createdAt: DateTime.now(),
          );
          await appState.addRecurringTransaction(recRule);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Transaction updated successfully'
                  : 'Transaction added successfully',
            ),
            backgroundColor: _type == TransactionType.income
                ? AppColors.income
                : AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appState = AppStateScope.of(context);
    final currencySymbol = appState.currencySymbol;

    final categories = _type == TransactionType.expense
        ? appState.expenseCategories
        : appState.incomeCategories;

    // Ensure _selectedCategory points to a valid category
    if (_selectedCategory.isEmpty ||
        !categories.any((c) => c.name.toLowerCase() == _selectedCategory.toLowerCase())) {
      if (categories.isNotEmpty) {
        _selectedCategory = categories.first.name;
      }
    }

    final themeColor = _type == TransactionType.income
        ? AppColors.income
        : AppColors.expense;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Transaction' : 'Add Transaction'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (!_isEditing && appState.transactionTemplates.isNotEmpty)
            TextButton.icon(
              icon: const Icon(Icons.flash_on_rounded, size: 16),
              label: const Text('Template'),
              onPressed: () => _showTemplatePicker(context, appState),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!_isEditing && appState.transactionTemplates.isNotEmpty) ...[
                  InkWell(
                    onTap: () => _showTemplatePicker(context, appState),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.flash_on_rounded, color: AppColors.accent, size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Quick Add from Template',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded, color: AppColors.accent, size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Income / Expense Type Selector
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceSecondary
                        : AppColors.lightSurfaceSecondary,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              _onTypeChanged(TransactionType.expense),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _type == TransactionType.expense
                                  ? AppColors.expense
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: _type == TransactionType.expense
                                  ? [
                                      BoxShadow(
                                        color: AppColors.expense
                                            .withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.arrow_upward_rounded,
                                  size: 18,
                                  color: _type == TransactionType.expense
                                      ? Colors.white
                                      : (isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.lightTextSecondary),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Expense',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: _type == TransactionType.expense
                                        ? Colors.white
                                        : (isDark
                                            ? AppColors.darkTextSecondary
                                            : AppColors.lightTextSecondary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _onTypeChanged(TransactionType.income),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _type == TransactionType.income
                                  ? AppColors.income
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: _type == TransactionType.income
                                  ? [
                                      BoxShadow(
                                        color: AppColors.income
                                            .withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.arrow_downward_rounded,
                                  size: 18,
                                  color: _type == TransactionType.income
                                      ? Colors.white
                                      : (isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.lightTextSecondary),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Income',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: _type == TransactionType.income
                                        ? Colors.white
                                        : (isDark
                                            ? AppColors.darkTextSecondary
                                            : AppColors.lightTextSecondary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Amount Field
                Text(
                  'AMOUNT',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: themeColor,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 16, right: 8),
                      child: Text(
                        currencySymbol,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: themeColor,
                        ),
                      ),
                    ),
                    prefixIconConstraints:
                        const BoxConstraints(minWidth: 0, minHeight: 0),
                    hintText: '0.00',
                    hintStyle: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.darkTextMuted
                          : AppColors.lightTextMuted,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter an amount';
                    }
                    final numVal = double.tryParse(value.trim());
                    if (numVal == null || numVal <= 0) {
                      return 'Enter a valid amount greater than 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Title Field
                Text(
                  'TITLE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.edit_note_rounded),
                    hintText: _type == TransactionType.expense
                        ? 'e.g. Grocery shopping, Electricity bill'
                        : 'e.g. Monthly salary, UI design gig',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Category Selection
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'CATEGORY',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ManageCategoriesScreen(
                              initialType: _type,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text(
                        'New / Manage',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: categories.map((cat) {
                    final isSelected = _selectedCategory.toLowerCase() == cat.name.toLowerCase();
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategory = cat.name;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? cat.color.withValues(alpha: 0.18)
                              : (isDark
                                  ? AppColors.darkSurface
                                  : AppColors.lightSurface),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? cat.color
                                : (isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder),
                            width: isSelected ? 1.8 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              cat.icon,
                              size: 16,
                              color: isSelected
                                  ? cat.color
                                  : (isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              cat.name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? cat.color
                                    : (isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.lightTextPrimary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Recurrence Frequency Selector
                Text(
                  'FREQUENCY / RECURRENCE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: RecurrenceFrequency.values.map((freq) {
                    final isSelected = _recurrence == freq;
                    return ChoiceChip(
                      avatar: isSelected
                          ? const Icon(Icons.check_rounded, size: 14)
                          : null,
                      label: Text(freq.displayName),
                      selected: isSelected,
                      selectedColor: AppColors.accent.withValues(alpha: 0.2),
                      onSelected: (val) {
                        if (val) {
                          setState(() => _recurrence = freq);
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Payment Method Selector
                Text(
                  'PAYMENT METHOD',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: PaymentMethod.values.map((method) {
                      final isSelected = _selectedPaymentMethod == method;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          avatar: Icon(method.icon, size: 16),
                          label: Text(method.displayName),
                          selected: isSelected,
                          selectedColor:
                              AppColors.accent.withValues(alpha: 0.2),
                          onSelected: (val) {
                            if (val) {
                              setState(() => _selectedPaymentMethod = method);
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),

                // Date Picker Tile
                Text(
                  'DATE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurfaceSecondary
                          : AppColors.lightSurfaceSecondary,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              size: 18,
                              color: AppColors.accent,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              DateFormatter.formatFull(_selectedDate),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                              ),
                            ),
                          ],
                        ),
                        Icon(
                          Icons.arrow_drop_down_rounded,
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Optional Note Field
                Text(
                  'NOTE (OPTIONAL)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _noteController,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Add additional context or notes...',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 24),

                // Non-blocking duplicate detection warning
                if (_titleController.text.trim().isNotEmpty &&
                    (double.tryParse(_amountController.text.trim()) ?? 0.0) > 0 &&
                    _selectedCategory.isNotEmpty &&
                    appState.hasDuplicateTransaction(
                      title: _titleController.text.trim(),
                      amount: double.tryParse(_amountController.text.trim()) ?? 0.0,
                      date: _selectedDate,
                      category: _selectedCategory,
                      excludeId: widget.transactionToEdit?.id,
                    ))
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline_rounded, size: 20, color: AppColors.warning),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Note: A transaction with this title, amount, and date already exists.',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.warning,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Save Button
                PrimaryButton(
                  label: _isEditing ? 'Update Transaction' : 'Save Transaction',
                  icon: _isEditing ? Icons.check_circle_rounded : Icons.add_rounded,
                  isLoading: _isSaving,
                  backgroundColor: themeColor,
                  onPressed: _saveTransaction,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTemplatePicker(BuildContext context, dynamic appState) {
    final templates = appState.transactionTemplates;
    if (templates.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        final isDark = Theme.of(modalCtx).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Select a Template',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(modalCtx),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: templates.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (ctx, index) {
                      final t = templates[index];
                      final isExp = t.isExpense;
                      final col = isExp ? AppColors.expense : AppColors.income;
                      return ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                        ),
                        leading: CircleAvatar(
                          backgroundColor: col.withValues(alpha: 0.12),
                          child: Icon(
                            isExp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                            color: col,
                            size: 18,
                          ),
                        ),
                        title: Text(t.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(
                          '${t.category} • ${t.paymentMethod.displayName}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Text(
                          '${appState.currencySymbol} ${t.amount.toStringAsFixed(2)}',
                          style: TextStyle(fontWeight: FontWeight.w800, color: col),
                        ),
                        onTap: () {
                          Navigator.pop(modalCtx);
                          setState(() {
                            _type = t.type;
                            _titleController.text = t.title;
                            _amountController.text = t.amount.toStringAsFixed(2);
                            _selectedCategory = t.category;
                            _selectedPaymentMethod = t.paymentMethod;
                            if (t.note != null && t.note!.isNotEmpty) {
                              _noteController.text = t.note!;
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }
}
