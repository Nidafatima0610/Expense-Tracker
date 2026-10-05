import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/savings_goal_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../providers/app_state.dart';
import '../../../providers/app_state_scope.dart';

class SavingsGoalsScreen extends StatefulWidget {
  const SavingsGoalsScreen({super.key});

  @override
  State<SavingsGoalsScreen> createState() => _SavingsGoalsScreenState();
}

class _SavingsGoalsScreenState extends State<SavingsGoalsScreen> {
  int _selectedFilterIndex = 0; // 0: All, 1: Active, 2: Completed

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allGoals = appState.savingsGoals;

    final activeGoals = allGoals.where((g) => !g.isCompleted).toList();
    final completedGoals = allGoals.where((g) => g.isCompleted).toList();

    List<SavingsGoalModel> displayedGoals;
    if (_selectedFilterIndex == 1) {
      displayedGoals = activeGoals;
    } else if (_selectedFilterIndex == 2) {
      displayedGoals = completedGoals;
    } else {
      displayedGoals = allGoals;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Savings Goals'),
        actions: [
          IconButton(
            tooltip: 'Add Savings Goal',
            icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: () => _openAddEditGoalDialog(context, appState),
          ),
        ],
      ),
      body: allGoals.isEmpty
          ? _buildEmptyState(context, isDark, appState)
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: _buildOverallSummaryCard(
                      context,
                      isDark,
                      appState,
                      allGoals,
                      activeGoals,
                      completedGoals,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: SegmentedButton<int>(
                      segments: [
                        ButtonSegment(
                          value: 0,
                          label: Text('All (${allGoals.length})'),
                        ),
                        ButtonSegment(
                          value: 1,
                          label: Text('Active (${activeGoals.length})'),
                        ),
                        ButtonSegment(
                          value: 2,
                          label: Text('Completed (${completedGoals.length})'),
                        ),
                      ],
                      selected: {_selectedFilterIndex},
                      onSelectionChanged: (set) {
                        setState(() => _selectedFilterIndex = set.first);
                      },
                    ),
                  ),
                ),
                if (displayedGoals.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          _selectedFilterIndex == 2
                              ? 'No completed goals yet.\nKeep contributing to reach your targets!'
                              : 'No active goals in this view.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final goal = displayedGoals[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildGoalCard(context, isDark, appState, goal),
                          );
                        },
                        childCount: displayedGoals.length,
                      ),
                    ),
                  ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Goal', style: TextStyle(fontWeight: FontWeight.w700)),
        onPressed: () => _openAddEditGoalDialog(context, appState),
      ),
    );
  }

  Widget _buildOverallSummaryCard(
    BuildContext context,
    bool isDark,
    AppState appState,
    List<SavingsGoalModel> allGoals,
    List<SavingsGoalModel> activeGoals,
    List<SavingsGoalModel> completedGoals,
  ) {
    final totalTarget = appState.totalSavingsGoalTarget;
    final totalSaved = appState.totalSavingsGoalSaved;
    final progress = appState.overallSavingsGoalProgress;
    final remaining = (totalTarget - totalSaved).clamp(0.0, double.infinity);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: isDark ? AppColors.balanceGradientDark : AppColors.balanceGradientLight,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.savings_rounded, color: Colors.amberAccent, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Overall Savings Progress',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(progress * 100).toStringAsFixed(0)}% Saved',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${appState.currencySymbol} ${NumberFormat('#,##0').format(totalSaved)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'of ${appState.currencySymbol} ${NumberFormat('#,##0').format(totalTarget)}',
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.income),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Remaining: ${appState.currencySymbol} ${NumberFormat('#,##0').format(remaining)}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                '${completedGoals.length} completed • ${activeGoals.length} in progress',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(
    BuildContext context,
    bool isDark,
    AppState appState,
    SavingsGoalModel goal,
  ) {
    final statusColor = goal.statusColor;
    final progress = goal.progressPercentage;
    final isDone = goal.isCompleted;

    final dateFormat = DateFormat('MMM d, yyyy');
    final deadlineStr = goal.deadline != null ? dateFormat.format(goal.deadline!) : null;
    final daysRemaining = goal.daysRemaining;

    String timelineText;
    if (isDone) {
      timelineText = 'Target Achieved!';
    } else if (goal.deadline == null) {
      timelineText = 'Ongoing Goal';
    } else if (daysRemaining != null && daysRemaining > 0) {
      timelineText = '$daysRemaining days left (Due $deadlineStr)';
    } else if (daysRemaining == 0) {
      timelineText = 'Deadline is today!';
    } else {
      timelineText = 'Deadline passed on $deadlineStr';
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDone
              ? AppColors.income.withValues(alpha: 0.5)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: isDone ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openGoalDetailsSheet(context, appState, goal),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(goal.icon, color: statusColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          timelineText,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDone
                                ? AppColors.income
                                : ((daysRemaining != null && daysRemaining < 0)
                                    ? AppColors.expense
                                    : (isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary)),
                            fontWeight: isDone ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      goal.statusDisplay,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded, size: 20),
                    onSelected: (val) {
                      if (val == 'edit') {
                        _openAddEditGoalDialog(context, appState, existingGoal: goal);
                      } else if (val == 'delete') {
                        _confirmDeleteGoal(context, appState, goal);
                      } else if (val == 'details') {
                        _openGoalDetailsSheet(context, appState, goal);
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'details',
                        child: Row(
                          children: [
                            Icon(Icons.receipt_long_rounded, size: 18),
                            SizedBox(width: 8),
                            Text('View Contributions'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Edit Goal'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline_rounded, color: AppColors.expense, size: 18),
                            SizedBox(width: 8),
                            Text('Delete Goal', style: TextStyle(color: AppColors.expense)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfaceSecondary,
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                ),
              ),
              const SizedBox(height: 10),
              // Amounts Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        fontSize: 13,
                      ),
                      children: [
                        TextSpan(
                          text: '${appState.currencySymbol} ${NumberFormat('#,##0').format(goal.currentAmount)} ',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(
                          text: 'saved of ${appState.currencySymbol} ${NumberFormat('#,##0').format(goal.targetAmount)}',
                          style: TextStyle(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Quick action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.remove_circle_outline_rounded, size: 16),
                      label: const Text('Withdraw', style: TextStyle(fontSize: 12)),
                      onPressed: goal.currentAmount <= 0
                          ? null
                          : () => _openWithdrawDialog(context, appState, goal),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: isDone ? AppColors.income : AppColors.accent,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: Icon(
                        isDone ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                        size: 16,
                      ),
                      label: Text(
                        isDone ? 'Completed' : 'Contribute',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      onPressed: () => _openContributeDialog(context, appState, goal),
                    ),
                  ),
                ],
              ),
            ],
          ),
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
              child: const Icon(Icons.savings_rounded, color: AppColors.accent, size: 54),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Savings Goals Yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Set targets for an Emergency Fund, a New Laptop, Car, Vacation, or custom dreams and watch your money grow!',
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
              label: const Text('Create First Goal', style: TextStyle(fontWeight: FontWeight.w700)),
              onPressed: () => _openAddEditGoalDialog(context, appState),
            ),
          ],
        ),
      ),
    );
  }

  void _openAddEditGoalDialog(
    BuildContext context,
    AppState appState, {
    SavingsGoalModel? existingGoal,
  }) {
    final isEditing = existingGoal != null;
    final nameCtrl = TextEditingController(text: existingGoal?.name ?? '');
    final targetCtrl = TextEditingController(
      text: existingGoal != null ? existingGoal.targetAmount.toStringAsFixed(0) : '',
    );
    final initialCtrl = TextEditingController(
      text: existingGoal != null ? existingGoal.currentAmount.toStringAsFixed(0) : '',
    );
    final noteCtrl = TextEditingController(text: existingGoal?.note ?? '');

    DateTime selectedDeadline = existingGoal?.deadline ??
        DateTime.now().add(const Duration(days: 180));
    String selectedCategory = existingGoal?.category ?? 'Emergency Fund';

    final presetChips = [
      'Emergency Fund',
      'New Laptop',
      'Car',
      'Education',
      'Vacation',
      'Wedding',
      'Custom Goal',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final isDark = Theme.of(modalCtx).brightness == Brightness.dark;

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
                          isEditing ? 'Edit Savings Goal' : 'New Savings Goal',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(modalCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Preset Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: presetChips.map((chip) {
                          final isSelected = selectedCategory == chip;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(chip),
                              selected: isSelected,
                              onSelected: (_) {
                                setModalState(() {
                                  selectedCategory = chip;
                                  if (nameCtrl.text.trim().isEmpty ||
                                      presetChips.contains(nameCtrl.text.trim())) {
                                    nameCtrl.text = chip;
                                  }
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Goal Name
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Goal Name',
                        hintText: 'e.g. Emergency Fund',
                        prefixIcon: Icon(Icons.drive_file_rename_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Target Amount
                    TextField(
                      controller: targetCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Target Amount',
                        prefixText: '${appState.currencySymbol} ',
                        prefixIcon: const Icon(Icons.flag_rounded),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Initial Amount (only if creating new)
                    if (!isEditing) ...[
                      TextField(
                        controller: initialCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Initial Saved Amount (Optional)',
                          prefixText: '${appState.currencySymbol} ',
                          prefixIcon: const Icon(Icons.savings_rounded),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Deadline Selector
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.event_rounded, color: AppColors.accent),
                      title: const Text('Target Deadline'),
                      subtitle: Text(DateFormat('EEEE, MMMM d, yyyy').format(selectedDeadline)),
                      trailing: TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: modalCtx,
                            initialDate: selectedDeadline,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                          );
                          if (picked != null) {
                            setModalState(() => selectedDeadline = picked);
                          }
                        },
                        child: const Text('Change Date'),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Note
                    TextField(
                      controller: noteCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Optional Note / Description',
                        prefixIcon: Icon(Icons.notes_rounded),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          isEditing ? 'Save Changes' : 'Create Goal',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        onPressed: () async {
                          final name = nameCtrl.text.trim();
                          final target = double.tryParse(targetCtrl.text.trim()) ?? 0.0;
                          final initial = double.tryParse(initialCtrl.text.trim()) ?? 0.0;

                          if (name.isEmpty) {
                            ScaffoldMessenger.of(modalCtx).showSnackBar(
                              const SnackBar(content: Text('Please enter a goal name.')),
                            );
                            return;
                          }
                          if (target <= 0) {
                            ScaffoldMessenger.of(modalCtx).showSnackBar(
                              const SnackBar(content: Text('Target amount must be greater than zero.')),
                            );
                            return;
                          }

                          if (isEditing) {
                            final updated = existingGoal.copyWith(
                              name: name,
                              targetAmount: target,
                              deadline: selectedDeadline,
                              category: selectedCategory,
                              note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
                            );
                            await appState.updateSavingsGoal(updated);
                          } else {
                            final newGoal = SavingsGoalModel(
                              id: const Uuid().v4(),
                              name: name,
                              targetAmount: target,
                              currentAmount: initial > 0 ? initial : 0.0,
                              deadline: selectedDeadline,
                              category: selectedCategory,
                              note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
                              createdAt: DateTime.now(),
                              contributions: initial > 0
                                  ? [
                                      GoalContribution(
                                        id: const Uuid().v4(),
                                        amount: initial,
                                        date: DateTime.now(),
                                        note: 'Initial deposit',
                                        paymentMethod: PaymentMethod.cash,
                                      ),
                                    ]
                                  : [],
                            );
                            await appState.addSavingsGoal(newGoal);
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

  void _openContributeDialog(
    BuildContext context,
    AppState appState,
    SavingsGoalModel goal,
  ) {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    PaymentMethod selectedMethod = appState.getLastUsedPaymentMethod();
    DateTime selectedDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final isDark = Theme.of(modalCtx).brightness == Brightness.dark;

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
                      children: [
                        const Icon(Icons.add_circle_rounded, color: AppColors.income, size: 24),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Add Contribution: ${goal.name}',
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Remaining to reach goal: ${appState.currencySymbol} ${NumberFormat('#,##0').format(goal.remainingAmount)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Amount input
                    TextField(
                      controller: amountCtrl,
                      autofocus: true,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Contribution Amount',
                        prefixText: '${appState.currencySymbol} ',
                        prefixIcon: const Icon(Icons.attach_money_rounded),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Payment Method selector
                    const Text('Payment Method', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: PaymentMethod.values.map((method) {
                          final isSelected = selectedMethod == method;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              avatar: Icon(method.icon, size: 16),
                              label: Text(method.displayName),
                              selected: isSelected,
                              onSelected: (_) => setModalState(() => selectedMethod = method),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Optional Note
                    TextField(
                      controller: noteCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Note (Optional)',
                        hintText: 'e.g. Monthly savings allotment',
                        prefixIcon: Icon(Icons.edit_note_rounded),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.income,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Add Contribution', style: TextStyle(fontWeight: FontWeight.w700)),
                        onPressed: () async {
                          final amount = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
                          if (amount <= 0) {
                            ScaffoldMessenger.of(modalCtx).showSnackBar(
                              const SnackBar(content: Text('Contribution amount must be greater than zero.')),
                            );
                            return;
                          }

                          await appState.addGoalContribution(
                            goal.id,
                            amount,
                            note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
                            paymentMethod: selectedMethod,
                            date: selectedDate,
                          );

                          await appState.rememberLastUsed(paymentMethod: selectedMethod);

                          if (modalCtx.mounted) Navigator.pop(modalCtx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Added ${appState.currencySymbol} ${amount.toStringAsFixed(0)} to "${goal.name}"!'),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: AppColors.income,
                              ),
                            );
                          }
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

  void _openWithdrawDialog(
    BuildContext context,
    AppState appState,
    SavingsGoalModel goal,
  ) {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;

        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
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
                  children: [
                    const Icon(Icons.remove_circle_rounded, color: AppColors.expense, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Withdraw from: ${goal.name}',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Currently saved: ${appState.currencySymbol} ${NumberFormat('#,##0').format(goal.currentAmount)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 16),

                // Amount
                TextField(
                  controller: amountCtrl,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Withdrawal Amount',
                    prefixText: '${appState.currencySymbol} ',
                    prefixIcon: const Icon(Icons.money_off_rounded),
                  ),
                ),
                const SizedBox(height: 14),

                // Note
                TextField(
                  controller: noteCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Reason / Note (Optional)',
                    hintText: 'e.g. Urgent expense transfer',
                    prefixIcon: Icon(Icons.edit_note_rounded),
                  ),
                ),
                const SizedBox(height: 20),

                // Submit
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.expense,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Confirm Withdrawal', style: TextStyle(fontWeight: FontWeight.w700)),
                    onPressed: () async {
                      final amount = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
                      if (amount <= 0) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('Amount must be greater than zero.')),
                        );
                        return;
                      }
                      if (amount > goal.currentAmount) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('Withdrawal cannot exceed currently saved balance.')),
                        );
                        return;
                      }

                      await appState.withdrawGoalContribution(
                        goal.id,
                        amount,
                        note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
                      );

                      if (ctx.mounted) Navigator.pop(ctx);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Withdrew ${appState.currencySymbol} ${amount.toStringAsFixed(0)} from "${goal.name}".'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openGoalDetailsSheet(
    BuildContext context,
    AppState appState,
    SavingsGoalModel goal,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final contributions = goal.contributions;

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
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
                    Expanded(
                      child: Text(
                        '${goal.name} Details',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    // Status overview
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfaceSecondary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Saved: ${appState.currencySymbol} ${NumberFormat('#,##0').format(goal.currentAmount)}',
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              Text(
                                'Target: ${appState.currencySymbol} ${NumberFormat('#,##0').format(goal.targetAmount)}',
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: goal.progressPercentage,
                              minHeight: 6,
                              valueColor: AlwaysStoppedAnimation<Color>(goal.statusColor),
                            ),
                          ),
                          if (goal.note != null && goal.note!.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Note: ${goal.note}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Contribution History',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    if (contributions.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            'No contributions recorded yet.',
                            style: TextStyle(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ),
                      )
                    else
                      ...contributions.map((c) {
                        final isWithdrawal = c.isWithdrawal;
                        final dateStr = DateFormat('MMM d, yyyy HH:mm').format(c.date);
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: isWithdrawal
                                ? AppColors.expense.withValues(alpha: 0.12)
                                : AppColors.income.withValues(alpha: 0.12),
                            child: Icon(
                              isWithdrawal ? Icons.remove_rounded : Icons.add_rounded,
                              color: isWithdrawal ? AppColors.expense : AppColors.income,
                            ),
                          ),
                          title: Text(
                            '${isWithdrawal ? '-' : '+'}${appState.currencySymbol} ${NumberFormat('#,##0').format(c.amount)}',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: isWithdrawal ? AppColors.expense : AppColors.income,
                            ),
                          ),
                          subtitle: Text(
                            '${c.note ?? (isWithdrawal ? 'Withdrawal' : 'Deposit')} • $dateStr',
                            style: const TextStyle(fontSize: 11),
                          ),
                          trailing: Chip(
                            visualDensity: VisualDensity.compact,
                            label: Text(c.paymentMethod.displayName, style: const TextStyle(fontSize: 10)),
                            avatar: Icon(c.paymentMethod.icon, size: 12),
                          ),
                        );
                      }),
                  ],
                ),
              ),
              // Bottom Action Row
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _openAddEditGoalDialog(context, appState, existingGoal: goal);
                        },
                        child: const Text('Edit Goal'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: AppColors.income),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _openContributeDialog(context, appState, goal);
                        },
                        child: const Text('Contribute'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteGoal(
    BuildContext context,
    AppState appState,
    SavingsGoalModel goal,
  ) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text('Delete Savings Goal?'),
          content: Text('Are you sure you want to delete "${goal.name}"? All recorded contributions for this goal will be removed.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
              onPressed: () async {
                Navigator.pop(dialogCtx);
                await appState.deleteSavingsGoal(goal.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Goal "${goal.name}" deleted.')),
                  );
                }
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
