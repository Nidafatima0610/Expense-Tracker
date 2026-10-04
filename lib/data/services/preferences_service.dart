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
}
