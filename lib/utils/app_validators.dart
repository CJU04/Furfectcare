import 'package:flutter/material.dart';

/// Shared, boundary-value-aware validators used across every form.
/// Each validator returns a human-readable error message (never null-safe
/// silent failures) so developers/users immediately know what to fix.
class AppValidators {
  AppValidators._();

  static String? requiredField(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter $fieldName.';
    }
    return null;
  }

  static String? name(String? value, String fieldName,
      {int min = 2, int max = 60}) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter $fieldName.';
    }
    final v = value.trim();
    if (v.length < min) return '$fieldName must be at least $min characters.';
    if (v.length > max) {
      return '$fieldName must not exceed $max characters.';
    }
    if (!RegExp(r"^[A-Za-z .'\-]+$").hasMatch(v)) {
      return '$fieldName contains invalid characters.';
    }
    return null;
  }

  /// Philippine-first phone validation (BVA):
  /// accepts 09XXXXXXXXX (11 digits), +639XXXXXXXXX, or 639XXXXXXXXX.
  /// Also allows generic 10-13 digit international numbers.
  static String? phoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a contact number.';
    }
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    String normalized = digitsOnly;
    if (digitsOnly.startsWith('63') && digitsOnly.length == 12) {
      normalized = digitsOnly.substring(2);
    } else if (digitsOnly.startsWith('63') && digitsOnly.length == 13) {
      return 'Contact number is too long. Use +63 + 10 digits or 11-digit 09XXXXXXXXX.';
    }
    if (normalized.length < 10) {
      return 'Contact number is too short. Enter 11 digits (09XXXXXXXXX) or +63 + 10 digits.';
    }
    if (normalized.length > 11) {
      return 'Contact number is too long. Enter at most 11 digits.';
    }
    if (normalized.length == 11 && !normalized.startsWith('09')) {
      return 'Philippine mobile numbers must start with 09.';
    }
    if (normalized.length == 10 && normalized.startsWith('0')) {
      return 'Remove the leading 0 when using +63 (example: +639171234567).';
    }
    if (!RegExp(r'^\d+$').hasMatch(normalized)) {
      return 'Contact number must contain digits only.';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Please enter an email.';
    final v = value.trim();
    if (v.length > 254) return 'Email is too long.';
    if (!RegExp(r'^[\w\-.]+@([\w\-]+\.)+[\w\-]{2,4}$').hasMatch(v)) {
      return 'Please enter a valid email address.';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Please enter a password.';
    if (value.length < 6) return 'Password must be at least 6 characters.';
    if (value.length > 128) return 'Password must not exceed 128 characters.';
    return null;
  }

  static String? age(String? value, {int min = 0, int max = 40}) {
    if (value == null || value.trim().isEmpty) return 'Please enter age.';
    final parsed = int.tryParse(value.trim());
    if (parsed == null) return 'Age must be a whole number.';
    if (parsed < min) return 'Age cannot be below $min.';
    if (parsed > max) return 'Age seems too high (max $max). Please check.';
    return null;
  }

  static String? quantity(String? value, {int min = 0, int max = 100000}) {
    if (value == null || value.trim().isEmpty)
      return 'Please enter a quantity.';
    final parsed = int.tryParse(value.trim());
    if (parsed == null) return 'Quantity must be a whole number.';
    if (parsed < min) return 'Quantity cannot be below $min.';
    if (parsed > max) return 'Quantity exceeds the allowed maximum ($max).';
    return null;
  }

  static String? price(String? value,
      {double min = 0.01, double max = 1000000}) {
    if (value == null || value.trim().isEmpty) return 'Please enter a price.';
    final cleaned = value.replaceAll(RegExp(r'[₱,\s]'), '');
    final parsed = double.tryParse(cleaned);
    if (parsed == null) return 'Price must be a number (example: ₱250.00).';
    if (parsed < min)
      return 'Price must be at least ₱${min.toStringAsFixed(2)}.';
    if (parsed > max) {
      return 'Price exceeds the allowed maximum (₱${max.toStringAsFixed(0)}).';
    }
    return null;
  }

  static String? dateNotFuture(String? value, {String field = 'Date'}) {
    if (value == null || value.trim().isEmpty) return 'Please select $field.';
    final parsed = DateTime.tryParse(value.trim());
    if (parsed == null) return '$field format is invalid.';
    final today = DateTime.now();
    final dayOnly = DateTime(today.year, today.month, today.day);
    if (parsed.isAfter(dayOnly.add(const Duration(days: 365 * 5)))) {
      return '$field is too far in the future.';
    }
    return null;
  }

  /// Shared modal/form spacing: roomy, scrollable, never clips actions.
  static EdgeInsets modalPadding(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return EdgeInsets.fromLTRB(20, 16, 20, 16 + bottom);
  }

  static double modalMaxWidth(BoxConstraints constraints) =>
      constraints.maxWidth > 640 ? 560 : double.infinity;
}
