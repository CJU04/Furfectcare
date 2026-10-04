class ProductStockValidator {
  ProductStockValidator._();

  /// Validates a product stock string.
  /// Returns null if valid, or an error message if invalid.
  static String? validateStock(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Stock quantity is required';
    }

    final parsed = int.tryParse(value.trim());
    if (parsed == null) {
      return 'Stock must be a valid whole number';
    }

    // Intentional first version for code review:
    // Only checks negative values
    if (parsed < 0) {
      return 'Stock cannot be negative';
    }

    return null;
  }
}