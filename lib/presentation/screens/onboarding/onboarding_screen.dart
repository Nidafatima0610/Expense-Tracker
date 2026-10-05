import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/preferences_service.dart';
import '../../../providers/app_state.dart';
import '../../../providers/app_state_scope.dart';
import '../main_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();
  int _currentPage = 0;

  CurrencyInfo _selectedCurrency = PreferencesService.supportedCurrencies.first; // PKR default
  ThemeMode _selectedTheme = ThemeMode.system;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _onNextPressed(AppState appState) {
    if (_currentPage < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding(appState);
    }
  }

  Future<void> _finishOnboarding(AppState appState) async {
    // Save currency & theme if chosen
    await appState.setCurrency(_selectedCurrency);
    await appState.setThemeMode(_selectedTheme);
    if (_nameController.text.trim().isNotEmpty) {
      await appState.setDisplayName(_nameController.text.trim());
    }
    await appState.completeOnboarding();

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appState = AppStateScope.of(context);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_currentPage < 4)
            TextButton(
              onPressed: () => _finishOnboarding(appState),
              child: Text(
                'Skip',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _buildSlide(
                    isDark: isDark,
                    icon: Icons.account_balance_wallet_rounded,
                    iconColor: AppColors.accent,
                    title: 'Track Income & Expenses',
                    description:
                        'Effortlessly record daily earnings and spendings. Categorize transactions, add notes, and maintain full transparency over your personal cash flow.',
                  ),
                  _buildSlide(
                    isDark: isDark,
                    icon: Icons.track_changes_rounded,
                    iconColor: AppColors.warning,
                    title: 'Manage Monthly Budgets',
                    description:
                        'Set smart limits per category or overall monthly spending. Receive timely warnings at 50%, 75%, 90%, and over-budget states before exceeding limits.',
                  ),
                  _buildSlide(
                    isDark: isDark,
                    icon: Icons.bar_chart_rounded,
                    iconColor: AppColors.income,
                    title: 'Reports & Yearly Overview',
                    description:
                        'Gain crystal clarity with period breakdowns, dynamic donut charts, weekly/monthly spending trends, and a complete 12-month financial year overview.',
                  ),
                  _buildSlide(
                    isDark: isDark,
                    icon: Icons.repeat_rounded,
                    iconColor: AppColors.info,
                    title: 'Automated Recurring Rules',
                    description:
                        'Automate recurring bills, monthly salaries, and regular subscriptions with custom schedules and duplicate prevention.',
                  ),
                  _buildFinalSetupSlide(isDark: isDark, appState: appState),
                ],
              ),
            ),

            // Bottom Navigation & Page Indicators
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  // Smooth Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.accent
                              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),

                  // Continue / Get Started Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => _onNextPressed(appState),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        _currentPage == 4 ? 'Get Started' : 'Continue',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: iconColor.withValues(alpha: 0.25),
                width: 2,
              ),
            ),
            child: Icon(icon, size: 54, color: iconColor),
          ),
          const SizedBox(height: 36),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalSetupSlide({required bool isDark, required AppState appState}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.income.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.tune_rounded, size: 38, color: AppColors.income),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Personalize Your Experience',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              'Choose your defaults or adjust them anytime in Settings.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Display Name
          Text(
            'YOUR NAME (OPTIONAL)',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              hintText: 'e.g. Alex or Sarah',
              prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
            ),
          ),
          const SizedBox(height: 18),

          // Preferred Currency
          Text(
            'PREFERRED CURRENCY (DEFAULT: PKR)',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<CurrencyInfo>(
                value: _selectedCurrency,
                isExpanded: true,
                dropdownColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                items: PreferencesService.supportedCurrencies.map((c) {
                  return DropdownMenuItem(
                    value: c,
                    child: Row(
                      children: [
                        Text(
                          c.symbol,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(width: 10),
                        Text('${c.code} – ${c.name}'),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (c) {
                  if (c != null) setState(() => _selectedCurrency = c);
                },
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Theme Preference
          Text(
            'APP THEME',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildThemeOption(
                  label: 'System',
                  icon: Icons.brightness_auto_rounded,
                  isSelected: _selectedTheme == ThemeMode.system,
                  onTap: () => setState(() => _selectedTheme = ThemeMode.system),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildThemeOption(
                  label: 'Light',
                  icon: Icons.light_mode_rounded,
                  isSelected: _selectedTheme == ThemeMode.light,
                  onTap: () => setState(() => _selectedTheme = ThemeMode.light),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildThemeOption(
                  label: 'Dark',
                  icon: Icons.dark_mode_rounded,
                  isSelected: _selectedTheme == ThemeMode.dark,
                  onTap: () => setState(() => _selectedTheme = ThemeMode.dark),
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent.withValues(alpha: 0.15)
              : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.accent
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? AppColors.accent
                  : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? AppColors.accent
                    : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
