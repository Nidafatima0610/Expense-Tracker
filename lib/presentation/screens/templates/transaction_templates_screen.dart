import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/models/transaction_template_model.dart';
import '../../../providers/app_state.dart';
import '../../../providers/app_state_scope.dart';
import '../transactions/add_edit_transaction_screen.dart';

class TransactionTemplatesScreen extends StatefulWidget {
  const TransactionTemplatesScreen({super.key});

  @override
  State<TransactionTemplatesScreen> createState() =>
      _TransactionTemplatesScreenState();
}

class _TransactionTemplatesScreenState
    extends State<TransactionTemplatesScreen> {
  int _selectedTypeIndex = 0; // 0: All, 1: Expenses, 2: Incomes

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allTemplates = appState.transactionTemplates;

    List<TransactionTemplateModel> displayed;
    if (_selectedTypeIndex == 1) {
      displayed = allTemplates.where((t) => t.isExpense).toList();
    } else if (_selectedTypeIndex == 2) {
      displayed = allTemplates.where((t) => t.isIncome).toList();
    } else {
      displayed = allTemplates;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Templates'),
        actions: [
          IconButton(
            tooltip: 'New Template',
            icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: () => _openAddEditTemplateDialog(context, appState),
          ),
        ],
      ),
      body: allTemplates.isEmpty
          ? _buildEmptyState(context, isDark, appState)
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: SegmentedButton<int>(
                    segments: [
                      ButtonSegment(
                        value: 0,
                        label: Text('All (${allTemplates.length})'),
                      ),
                      ButtonSegment(
                        value: 1,
                        label: Text(
                          'Expenses (${allTemplates.where((t) => t.isExpense).length})',
                        ),
                      ),
                      ButtonSegment(
                        value: 2,
                        label: Text(
                          'Incomes (${allTemplates.where((t) => t.isIncome).length})',
                        ),
                      ),
                    ],
                    selected: {_selectedTypeIndex},
                    onSelectionChanged: (set) {
                      setState(() => _selectedTypeIndex = set.first);
                    },
                  ),
                ),
                Expanded(
                  child: displayed.isEmpty
                      ? Center(
                          child: Text(
                            'No templates in this category.',
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                          itemCount: displayed.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final template = displayed[index];
                            return _buildTemplateCard(
                              context,
                              isDark,
                              appState,
                              template,
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'New Template',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        onPressed: () => _openAddEditTemplateDialog(context, appState),
      ),
    );
  }

  Widget _buildTemplateCard(
    BuildContext context,
    bool isDark,
    AppState appState,
    TransactionTemplateModel template,
  ) {
    final isExpense = template.isExpense;
    final color = isExpense ? AppColors.expense : AppColors.income;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.12),
                  child: Icon(
                    isExpense ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        template.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            template.category,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            template.paymentMethod.icon,
                            size: 13,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            template.paymentMethod.displayName,
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
                ),
                Text(
                  '${isExpense ? '-' : '+'}${appState.currencySymbol} ${NumberFormat('#,##0.00').format(template.amount)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, size: 20),
                  onSelected: (val) {
                    if (val == 'edit') {
                      _openAddEditTemplateDialog(context, appState, existingTemplate: template);
                    } else if (val == 'duplicate') {
                      appState.duplicateTransactionTemplate(template.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Duplicated "${template.title}".'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } else if (val == 'delete') {
                      _confirmDeleteTemplate(context, appState, template);
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Edit Template'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'duplicate',
                      child: Row(
                        children: [
                          Icon(Icons.copy_rounded, size: 18),
                          SizedBox(width: 8),
                          Text('Duplicate'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded, color: AppColors.expense, size: 18),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: AppColors.expense)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (template.note != null && template.note!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Note: ${template.note}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            const SizedBox(height: 10),
            // "Use Template" 1-tap button
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                icon: const Icon(Icons.flash_on_rounded, size: 16),
                label: const Text('Use Template (Quick Add)', style: TextStyle(fontWeight: FontWeight.w700)),
                onPressed: () => _useTemplate(context, template),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark, AppState appState) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.bookmark_add_rounded, color: AppColors.accent, size: 54),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Templates Yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Save reusable templates for frequent expenses like Rent, Bills, Fuel, or regular Salary to log transactions with a single tap!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create Template', style: TextStyle(fontWeight: FontWeight.w700)),
              onPressed: () => _openAddEditTemplateDialog(context, appState),
            ),
          ],
        ),
      ),
    );
  }

  void _useTemplate(BuildContext context, TransactionTemplateModel template) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => AddEditTransactionScreen(
          initialType: template.type,
          prefilledTitle: template.title,
          prefilledAmount: template.amount,
          prefilledCategory: template.category,
          prefilledPaymentMethod: template.paymentMethod,
          prefilledNote: template.note,
        ),
      ),
    );
  }

  void _openAddEditTemplateDialog(
    BuildContext context,
    AppState appState, {
    TransactionTemplateModel? existingTemplate,
  }) {
    final isEditing = existingTemplate != null;
    TransactionType selectedType = existingTemplate?.type ?? TransactionType.expense;
    final titleCtrl = TextEditingController(text: existingTemplate?.title ?? '');
    final amountCtrl = TextEditingController(
      text: existingTemplate != null ? existingTemplate.amount.toStringAsFixed(2) : '',
    );
    final noteCtrl = TextEditingController(text: existingTemplate?.note ?? '');

    final availableCategories = appState.categories
        .where((c) => c.isExpense == (selectedType == TransactionType.expense))
        .map((c) => c.name)
        .toList();

    String selectedCategory = existingTemplate?.category ??
        (availableCategories.isNotEmpty ? availableCategories.first : 'Other');
    PaymentMethod selectedPayment = existingTemplate?.paymentMethod ?? PaymentMethod.cash;

    final presetTitles = [
      'Monthly Rent',
      'Internet Bill',
      'Grocery Shopping',
      'Fuel',
      'Salary',
      'Freelance Payment',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final isDark = Theme.of(modalCtx).brightness == Brightness.dark;

            final catList = appState.categories
                .where((c) => c.isExpense == (selectedType == TransactionType.expense))
                .map((c) => c.name)
                .toList();

            if (!catList.contains(selectedCategory) && catList.isNotEmpty) {
              selectedCategory = catList.first;
            }

            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 16,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEditing ? 'Edit Template' : 'New Template',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(modalCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Type Toggle (Expense / Income)
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
                      selected: {selectedType},
                      onSelectionChanged: (set) {
                        setModalState(() {
                          selectedType = set.first;
                        });
                      },
                    ),
                    const SizedBox(height: 14),

                    // Preset Quick Suggestions
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: presetTitles.map((preset) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ActionChip(
                              label: Text(preset),
                              onPressed: () {
                                setModalState(() {
                                  titleCtrl.text = preset;
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Title
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Template Title',
                        hintText: 'e.g. Monthly Rent',
                        prefixIcon: Icon(Icons.title_rounded),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Amount
                    TextField(
                      controller: amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Default Amount',
                        prefixText: '${appState.currencySymbol} ',
                        prefixIcon: const Icon(Icons.attach_money_rounded),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Category Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: catList.contains(selectedCategory) ? selectedCategory : (catList.isNotEmpty ? catList.first : null),
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        prefixIcon: Icon(Icons.category_rounded),
                      ),
                      items: catList.map((cat) {
                        return DropdownMenuItem(value: cat, child: Text(cat));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedCategory = val);
                      },
                    ),
                    const SizedBox(height: 14),

                    // Payment Method Chips
                    const Text('Payment Method', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: PaymentMethod.values.map((method) {
                          final isSelected = selectedPayment == method;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              avatar: Icon(method.icon, size: 16),
                              label: Text(method.displayName),
                              selected: isSelected,
                              onSelected: (_) => setModalState(() => selectedPayment = method),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Note
                    TextField(
                      controller: noteCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Default Note (Optional)',
                        hintText: 'e.g. Due 1st of every month',
                        prefixIcon: Icon(Icons.edit_note_rounded),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Submit
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          isEditing ? 'Save Template' : 'Create Template',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        onPressed: () async {
                          final title = titleCtrl.text.trim();
                          final amount = double.tryParse(amountCtrl.text.trim()) ?? 0.0;

                          if (title.isEmpty) {
                            ScaffoldMessenger.of(modalCtx).showSnackBar(
                              const SnackBar(content: Text('Please enter a template title.')),
                            );
                            return;
                          }
                          if (amount <= 0) {
                            ScaffoldMessenger.of(modalCtx).showSnackBar(
                              const SnackBar(content: Text('Amount must be greater than zero.')),
                            );
                            return;
                          }

                          if (isEditing) {
                            final updated = existingTemplate.copyWith(
                              title: title,
                              type: selectedType,
                              amount: amount,
                              category: selectedCategory,
                              paymentMethod: selectedPayment,
                              note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
                            );
                            await appState.updateTransactionTemplate(updated);
                          } else {
                            final newTemplate = TransactionTemplateModel(
                              id: const Uuid().v4(),
                              title: title,
                              type: selectedType,
                              amount: amount,
                              category: selectedCategory,
                              paymentMethod: selectedPayment,
                              note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
                              createdAt: DateTime.now(),
                            );
                            await appState.addTransactionTemplate(newTemplate);
                          }

                          if (modalCtx.mounted) Navigator.pop(modalCtx);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDeleteTemplate(
    BuildContext context,
    AppState appState,
    TransactionTemplateModel template,
  ) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Template?'),
        content: Text('Are you sure you want to delete template "${template.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await appState.deleteTransactionTemplate(template.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Template "${template.title}" deleted.')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
