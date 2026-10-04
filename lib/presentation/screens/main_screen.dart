import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'dashboard/dashboard_screen.dart';
import 'reports/reports_screen.dart';
import 'settings/settings_screen.dart';
import 'transactions/add_edit_transaction_screen.dart';
import 'transactions/transactions_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _openAddTransaction(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AddEditTransactionScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final screens = [
      DashboardScreen(
        onViewAllTransactions: () => _onTabSelected(1),
        onViewReports: () => _onTabSelected(2),
      ),
      const TransactionsScreen(),
      const ReportsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddTransaction(context),
        tooltip: 'Add Transaction',
        elevation: 4,
        child: const Icon(Icons.add_rounded, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        elevation: 8,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Dashboard Tab
              _buildNavItem(
                index: 0,
                icon: Icons.dashboard_rounded,
                label: 'Dashboard',
                isSelected: _currentIndex == 0,
                isDark: isDark,
              ),
              // Transactions Tab
              _buildNavItem(
                index: 1,
                icon: Icons.receipt_long_rounded,
                label: 'Transactions',
                isSelected: _currentIndex == 1,
                isDark: isDark,
              ),
              const SizedBox(width: 48), // Space for notched FAB
              // Reports Tab
              _buildNavItem(
                index: 2,
                icon: Icons.bar_chart_rounded,
                label: 'Reports',
                isSelected: _currentIndex == 2,
                isDark: isDark,
              ),
              // Settings Tab
              _buildNavItem(
                index: 3,
                icon: Icons.settings_rounded,
                label: 'Settings',
                isSelected: _currentIndex == 3,
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
    required bool isDark,
  }) {
    final activeColor = AppColors.accent;
    final inactiveColor =
        isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return InkWell(
      onTap: () => _onTabSelected(index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? activeColor : inactiveColor,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
