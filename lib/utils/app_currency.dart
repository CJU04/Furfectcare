import 'package:intl/intl.dart';

/// Single source of truth for Philippine peso formatting.
/// Use everywhere instead of hard-coded '\$' or manual toStringAsFixed.
class AppCurrency {
  AppCurrency._();

  static final NumberFormat _pesoFormat =
      NumberFormat.currency(locale: 'en_PH', symbol: '₱', decimalDigits: 2);

  static String peso(double amount) => _pesoFormat.format(amount);

  static String pesoFromNum(num amount) => _pesoFormat.format(amount);

  /// Parses user input safely for BVA-checked price/amount fields.
  static double? tryParse(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[₱,\s]'), '').trim();
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }
}
