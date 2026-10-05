import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyInfo {
  final String symbol;
  final String code;
  final String name;

  const CurrencyInfo({
    required this.symbol,
    required this.code,
    required this.name,
  });
}

class PreferencesService {
  static const String _keyThemeMode = 'pref_theme_mode';
  static const String _keyCurrencySymbol = 'pref_currency_symbol';
  static const String _keyCurrencyCode = 'pref_currency_code';
  static const String _keyHasSeeded = 'pref_has_seeded_sample_data';
  static const String _keyHasCompletedOnboarding = 'pref_has_completed_onboarding';
  static const String _keyDisplayName = 'pref_display_name';
  static const String _keyMonthlyBudgetPreference = 'pref_monthly_budget_target';
  static const String _keyReminderUpcomingRecurring = 'pref_reminder_upcoming_recurring';
  static const String _keyReminderBudgetWarnings = 'pref_reminder_budget_warnings';
  static const String _keyReminderMonthlyReview = 'pref_reminder_monthly_review';

  static const List<CurrencyInfo> supportedCurrencies = [
    CurrencyInfo(symbol: '₨', code: 'PKR', name: 'Pakistani Rupee'),
    CurrencyInfo(symbol: r'$', code: 'USD', name: 'US Dollar'),
    CurrencyInfo(symbol: '€', code: 'EUR', name: 'Euro'),
    CurrencyInfo(symbol: '£', code: 'GBP', name: 'British Pound'),
    CurrencyInfo(symbol: 'AED ', code: 'AED', name: 'UAE Dirham'),
    CurrencyInfo(symbol: 'SAR ', code: 'SAR', name: 'Saudi Riyal'),
    CurrencyInfo(symbol: '₹', code: 'INR', name: 'Indian Rupee'),
    CurrencyInfo(symbol: r'C$', code: 'CAD', name: 'Canadian Dollar'),
    CurrencyInfo(symbol: r'A$', code: 'AUD', name: 'Australian Dollar'),
    CurrencyInfo(symbol: '¥', code: 'JPY', name: 'Japanese Yen'),
  ];

  final SharedPreferences _prefs;

  PreferencesService(this._prefs);

  ThemeMode getThemeMode() {
    final value = _prefs.getString(_keyThemeMode);
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    switch (mode) {
      case ThemeMode.light:
        await _prefs.setString(_keyThemeMode, 'light');
        break;
      case ThemeMode.dark:
        await _prefs.setString(_keyThemeMode, 'dark');
        break;
      case ThemeMode.system:
        await _prefs.setString(_keyThemeMode, 'system');
        break;
    }
  }

  String getCurrencySymbol() {
    return _prefs.getString(_keyCurrencySymbol) ?? '₨';
  }

  String getCurrencyCode() {
    return _prefs.getString(_keyCurrencyCode) ?? 'PKR';
  }

  Future<void> setCurrency(CurrencyInfo currency) async {
    await _prefs.setString(_keyCurrencySymbol, currency.symbol);
    await _prefs.setString(_keyCurrencyCode, currency.code);
  }

  bool getHasSeeded() {
    return _prefs.getBool(_keyHasSeeded) ?? false;
  }

  Future<void> setHasSeeded(bool value) async {
    await _prefs.setBool(_keyHasSeeded, value);
  }

  bool getHasCompletedOnboarding() {
    return _prefs.getBool(_keyHasCompletedOnboarding) ?? false;
  }

  Future<void> setHasCompletedOnboarding(bool value) async {
    await _prefs.setBool(_keyHasCompletedOnboarding, value);
  }

  String getDisplayName() {
    return _prefs.getString(_keyDisplayName) ?? '';
  }

  Future<void> setDisplayName(String name) async {
    await _prefs.setString(_keyDisplayName, name.trim());
  }

  double? getMonthlyBudgetPreference() {
    return _prefs.getDouble(_keyMonthlyBudgetPreference);
  }

  Future<void> setMonthlyBudgetPreference(double? amount) async {
    if (amount == null) {
      await _prefs.remove(_keyMonthlyBudgetPreference);
    } else {
      await _prefs.setDouble(_keyMonthlyBudgetPreference, amount);
    }
  }

  bool getReminderUpcomingRecurring() {
    return _prefs.getBool(_keyReminderUpcomingRecurring) ?? true;
  }

  Future<void> setReminderUpcomingRecurring(bool enabled) async {
    await _prefs.setBool(_keyReminderUpcomingRecurring, enabled);
  }

  bool getReminderBudgetWarnings() {
    return _prefs.getBool(_keyReminderBudgetWarnings) ?? true;
  }

  Future<void> setReminderBudgetWarnings(bool enabled) async {
    await _prefs.setBool(_keyReminderBudgetWarnings, enabled);
  }

  bool getReminderMonthlyReview() {
    return _prefs.getBool(_keyReminderMonthlyReview) ?? true;
  }

  Future<void> setReminderMonthlyReview(bool enabled) async {
    await _prefs.setBool(_keyReminderMonthlyReview, enabled);
  }
}
