import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String format(double amount, {String symbol = r'$', bool includeSign = false}) {
    final formatter = NumberFormat('#,##0.00', 'en_US');
    final formattedValue = formatter.format(amount.abs());

    if (includeSign) {
      if (amount > 0) {
        return '+$symbol$formattedValue';
      } else if (amount < 0) {
        return '-$symbol$formattedValue';
      }
    }

    if (amount < 0) {
      return '-$symbol$formattedValue';
    }
    return '$symbol$formattedValue';
  }

  static String formatCompact(double amount, {String symbol = r'$'}) {
    if (amount.abs() >= 1000000) {
      return '$symbol${(amount / 1000000).toStringAsFixed(1)}M';
    }
    if (amount.abs() >= 1000) {
      return '$symbol${(amount / 1000).toStringAsFixed(1)}K';
    }
    return format(amount, symbol: symbol);
  }
}
