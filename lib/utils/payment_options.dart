import 'package:flutter/material.dart';

/// Payment availability until a server-verified gateway is integrated.
///
/// [methods] holds the canonical stored values (see [Sales.paymentMethod]);
/// user-facing titles come from [titleOf] so the stored value stays stable.
class PaymentOptions {
  PaymentOptions._();

  /// Canonical stored value for pay-at-clinic orders.
  static const cash = 'Cash';

  /// User-facing title for the cash method.
  static const cashTitle = 'Cash / Pay at Clinic';
  static const cashSubtitle = 'Pay when you pick up your order';

  static const List<String> methods = [cash];

  /// Placeholder for future gateway methods. Must stay empty until a
  /// server-side gateway verifies payments (see QrCheckoutSheet).
  static const List<String> onlineOptions = [];

  static const Map<String, String> _titles = {cash: cashTitle};
  static const Map<String, String> _subtitles = {cash: cashSubtitle};
  static const Map<String, IconData> _icons = {cash: Icons.money};

  static String titleOf(String method) => _titles[method] ?? method;
  static String subtitleOf(String method) =>
      _subtitles[method] ?? 'Unavailable until online payments are configured';
  static IconData iconOf(String method) => _icons[method] ?? Icons.payment;

  /// Unknown methods must not silently fall back to cash.
  static bool isOnline(String method) => method != cash;
}
