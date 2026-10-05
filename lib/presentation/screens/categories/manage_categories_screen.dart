import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../providers/app_state_scope.dart';
import '../../widgets/category_icon_widget.dart';
import '../../widgets/primary_button.dart';
import 'category_detail_screen.dart';

class ManageCategoriesScreen extends StatefulWidget {
  final TransactionType initialType;

  const ManageCategoriesScreen({
    super.key,
    this.initialType = TransactionType.expense,
  });

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const List<IconData> availableIcons = [
    Icons.restaurant_rounded,
    Icons.fastfood_rounded,
    Icons.local_cafe_rounded,
    Icons.local_grocery_store_rounded,
    Icons.directions_car_rounded,
    Icons.local_gas_station_rounded,
    Icons.flight_rounded,
    Icons.directions_subway_rounded,
    Icons.shopping_bag_rounded,
    Icons.shopping_cart_rounded,
    Icons.devices_rounded,
    Icons.receipt_long_rounded,
    Icons.home_rounded,
    Icons.bolt_rounded,
    Icons.wifi_rounded,
    Icons.medical_services_rounded,
    Icons.fitness_center_rounded,
    Icons.healing_rounded,
    Icons.school_rounded,
    Icons.menu_book_rounded,
    Icons.sports_esports_rounded,
    Icons.movie_rounded,
    Icons.music_note_rounded,
    Icons.pets_rounded,
    Icons.payments_rounded,
    Icons.account_balance_rounded,
    Icons.account_balance_wallet_rounded,
    Icons.trending_up_rounded,
    Icons.laptop_mac_rounded,
    Icons.work_rounded,
    Icons.storefront_rounded,
    Icons.card_giftcard_rounded,
    Icons.savings_rounded,
    Icons.category_rounded,
  ];

  static const List<Color> availableColors = [
    Color(0xFFF97316), // Orange
    Color(0xFF0EA5E9), // Sky
    Color(0xFFEC4899), // Pink
    Color(0xFFEAB308), // Yellow
    Color(0xFFEF4444), // Red
    Color(0xFF8B5CF6), // Purple
    Color(0xFF06B6D4), // Cyan
    Color(0xFF10B981), // Emerald
    Color(0xFF6366F1), // Indigo
    Color(0xFF3B82F6), // Blue
    Color(0xFFA855F7), // Purple
    Color(0xFF14B8A6), // Teal
    Color(0xFFF43F5E), // Rose
    Color(0xFF84CC16), // Lime
    Color(0xFF64748B), // Slate
    Color(0xFFD97706), // Amber
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialType == TransactionType.expense ? 0 : 1,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddEditCategoryModal({CategoryModel? categoryToEdit}) {
    final isEditing = categoryToEdit != null;
    final formKey = GlobalKey<FormState>();
    final nameController =
        TextEditingController(text: categoryToEdit?.name ?? '');

    TransactionType selectedType = categoryToEdit?.type ??
        (_tabController.index == 0
            ? TransactionType.expense
            : TransactionType.income);

    int selectedIconCodePoint = categoryToEdit?.iconCodePoint ??
        (selectedType == TransactionType.expense
            ? Icons.shopping_bag_rounded.codePoint
            : Icons.payments_rounded.codePoint);

    int selectedColorValue = categoryToEdit?.colorValue ??
        (selectedType == TransactionType.expense
            ? availableColors[0].toARGB32()
            : availableColors[7].toARGB32());

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
                              isEditing
                                  ? 'Edit Category'
                                  : 'Create Custom Category',
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

                        // Type Toggle (only when adding new)
                        if (!isEditing) ...[
                          Row(
                            children: [
                              Expanded(
                                child: ChoiceChip(
                                  label: const Center(child: Text('Expense')),
                                  selected:
                                      selectedType == TransactionType.expense,
                                  selectedColor:
                                      AppColors.expense.withValues(alpha: 0.2),
                                  onSelected: (_) {
                                    setModalState(() {
                                      selectedType = TransactionType.expense;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ChoiceChip(
                                  label: const Center(child: Text('Income')),
                                  selected:
                                      selectedType == TransactionType.income,
                                  selectedColor:
                                      AppColors.income.withValues(alpha: 0.2),
                                  onSelected: (_) {
                                    setModalState(() {
                                      selectedType = TransactionType.income;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Name input
                        TextFormField(
                          controller: nameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Category Name',
                            hintText: 'e.g. Gym, Subscriptions, Freelance',
                            prefixIcon: Icon(Icons.label_outline_rounded),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a category name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Icon Selector
                        const Text(
                          'SELECT ICON',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 130,
                          child: GridView.builder(
                            scrollDirection: Axis.horizontal,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                            ),
                            itemCount: availableIcons.length,
                            itemBuilder: (gridCtx, index) {
                              final icon = availableIcons[index];
                              final isSelected =
                                  icon.codePoint == selectedIconCodePoint;
                              final currentColor = Color(selectedColorValue);

                              return InkWell(
                                onTap: () {
                                  setModalState(() {
                                    selectedIconCodePoint = icon.codePoint;
                                  });
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? currentColor.withValues(alpha: 0.2)
                                        : (isDark
                                            ? AppColors.darkSurfaceSecondary
                                            : AppColors.lightSurfaceSecondary),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? currentColor
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    icon,
                                    color: isSelected
                                        ? currentColor
                                        : (isDark
                                            ? AppColors.darkTextSecondary
                                            : AppColors.lightTextSecondary),
                                    size: 24,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Color Selector
                        const Text(
                          'SELECT COLOR',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 48,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: availableColors.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 10),
                            itemBuilder: (listCtx, index) {
                              final color = availableColors[index];
                              final isSelected =
                                  color.toARGB32() == selectedColorValue;

                              return GestureDetector(
                                onTap: () {
                                  setModalState(() {
                                    selectedColorValue = color.toARGB32();
                                  });
                                },
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.transparent,
                                      width: 3,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: color.withValues(alpha: 0.5),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: isSelected
                                      ? const Icon(
                                          Icons.check_rounded,
                                          color: Colors.white,
                                          size: 20,
                                        )
                                      : null,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Save Button
                        PrimaryButton(
                          label: isEditing
                              ? 'Update Category'
                              : 'Create Category',
                          icon: isEditing
                              ? Icons.check_circle_rounded
                              : Icons.add_rounded,
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;

                            final appState = AppStateScope.of(context);
                            final name = nameController.text.trim();

                            if (isEditing) {
                              final updated = categoryToEdit.copyWith(
                                name: name,
                                iconCodePoint: selectedIconCodePoint,
                                colorValue: selectedColorValue,
                              );
                              await appState.updateCategory(updated);
                            } else {
                              const uuid = Uuid();
                              final newCat = CategoryModel(
                                id: uuid.v4(),
                                name: name,
                                iconCodePoint: selectedIconCodePoint,
                                colorValue: selectedColorValue,
                                type: selectedType,
                                isSystem: false,
                                createdAt: DateTime.now(),
                              );
                              await appState.addCategory(newCat);
                            }

                            if (!mounted) return;
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isEditing
                                      ? 'Category "$name" updated'
                                      : 'Category "$name" created successfully',
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

  Future<void> _handleDeleteCategory(CategoryModel category) async {
    final appState = AppStateScope.of(context);

    if (category.isSystem) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Default Category'),
          content: Text(
            '"${category.name}" is a default system category and cannot be deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final isUsed = appState.isCategoryUsed(category.name);
    if (isUsed) {
      final usedCount = appState.transactions
          .where((t) =>
              t.category.toLowerCase() == category.name.toLowerCase())
          .length;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Category In Use'),
          content: Text(
            'Cannot delete "${category.name}" because it is currently used by $usedCount transaction${usedCount == 1 ? '' : 's'}.\n\nPlease edit or delete those transactions first to keep your financial records accurate.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Understood'),
            ),
          ],
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category?'),
        content: Text(
          'Are you sure you want to delete custom category "${category.name}"?',
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
      await appState.deleteCategory(category.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Category "${category.name}" deleted'),
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

    final expenses = appState.expenseCategories;
    final incomes = appState.incomeCategories;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Categories'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.accent,
          unselectedLabelColor:
              isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          indicatorColor: AppColors.accent,
          indicatorWeight: 3,
          tabs: [
            Tab(text: 'Expense (${expenses.length})'),
            Tab(text: 'Income (${incomes.length})'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditCategoryModal(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Category'),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCategoryList(expenses, true),
          _buildCategoryList(incomes, false),
        ],
      ),
    );
  }

  Widget _buildCategoryList(List<CategoryModel> categories, bool isExpense) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appState = AppStateScope.of(context);

    if (categories.isEmpty) {
      return Center(
        child: Text(
          'No categories found',
          style: TextStyle(
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: categories.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (ctx, index) {
        final cat = categories[index];
        final txCount = appState.transactions
            .where((t) => t.category.toLowerCase() == cat.name.toLowerCase())
            .length;

        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CategoryDetailScreen(category: cat),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
              children: [
                // Icon
                CategoryIconWidget(
                  category: cat.name,
                  isExpense: isExpense,
                  size: 46,
                  iconSize: 22,
                ),
                const SizedBox(width: 14),
                // Title & Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              cat.name,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
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
                              color: cat.isSystem
                                  ? (isDark
                                      ? AppColors.darkSurfaceSecondary
                                      : AppColors.lightSurfaceSecondary)
                                  : AppColors.accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              cat.isSystem ? 'Default' : 'Custom',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: cat.isSystem
                                    ? (isDark
                                        ? AppColors.darkTextMuted
                                        : AppColors.lightTextMuted)
                                    : AppColors.accent,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        txCount == 0
                            ? 'No transactions'
                            : '$txCount ${txCount == 1 ? 'transaction' : 'transactions'} logged',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Actions
                if (cat.isSystem)
                  Tooltip(
                    message: 'Default system category (protected)',
                    child: Icon(
                      Icons.lock_outline_rounded,
                      size: 18,
                      color: isDark
                          ? AppColors.darkTextMuted
                          : AppColors.lightTextMuted,
                    ),
                  )
                else ...[
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    tooltip: 'Edit category',
                    onPressed: () =>
                        _showAddEditCategoryModal(categoryToEdit: cat),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 20,
                      color: AppColors.expense,
                    ),
                    tooltip: 'Delete category',
                    onPressed: () => _handleDeleteCategory(cat),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    },
  );
  }
}
