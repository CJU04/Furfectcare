import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vetcare_connect/models/product.dart';
import 'package:vetcare_connect/services/database_service.dart';
import 'package:vetcare_connect/utils/constants.dart';

class ProductProvider with ChangeNotifier {
  List<Product> _products = [];

  List<Product> get products => _products;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> loadProducts() async {
    if (_isLoading) return; // guard: ignore overlapping reload requests
    _isLoading = true;
    // Deferred: loadProducts() is often called from initState/build; a
    // synchronous notifyListeners() here marks the provider dirty during
    // the build phase and crashes with "setState() or markNeedsBuild()
    // called during build". scheduleMicrotask runs after the frame.
    scheduleMicrotask(notifyListeners);
    try {
      _products = await DatabaseService().getProducts();
    } finally {
      _isLoading = false;
      // Schedule the final notification: calling notifyListeners() inside
      // this synchronous finally block can fire during a build phase when
      // loadProducts() is awaited from initState/build, which crashes with
      // "setState() or markNeedsBuild() called during build".
      WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
    }
  }

  Future<void> addProduct(Product product) async {
    await DatabaseService().insertProduct(product);
    await loadProducts();
  }

  Future<void> updateProduct(Product product) async {
    await DatabaseService().updateProduct(product);
    await loadProducts();
  }

  Future<void> deleteProduct(String id) async {
    await DatabaseService().deleteProduct(id);
    await loadProducts();
  }

  List<Product> searchProducts(String query) {
    return _products
        .where((product) =>
            product.productName.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  List<Product> filterProductsByCategory(String category) {
    return _products.where((product) => product.category == category).toList();
  }

  Future<int> seedRealisticProducts() async {
    final current = await DatabaseService().getProducts();
    final existingCodes =
        current.map((p) => p.productCode?.toUpperCase()).toSet();
    final existingNames =
        current.map((p) => p.productName.toLowerCase()).toSet();

    int addedCount = 0;
    for (final item in Constants.realisticCatalog) {
      final code = (item['productCode'] as String).toUpperCase();
      final name = (item['productName'] as String).toLowerCase();

      if (!existingCodes.contains(code) && !existingNames.contains(name)) {
        final product = Product(
          productId: null,
          productCode: item['productCode'] as String,
          productName: item['productName'] as String,
          category: item['category'] as String,
          description: item['description'] as String,
          price: (item['price'] as num).toDouble(),
          stockQuantity: item['stockQuantity'] as int,
          minimumStock: item['minimumStock'] as int,
          unit: item['unit'] as String,
          imageUrl: item['imageUrl'] as String? ?? '',
        );
        await DatabaseService().insertProduct(product);
        addedCount++;
      }
    }

    if (addedCount > 0) {
      await loadProducts();
    } else {
      _products = current;
      notifyListeners();
    }
    return addedCount;
  }
}
