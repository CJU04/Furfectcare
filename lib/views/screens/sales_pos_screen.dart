import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vetcare_connect/models/inventory_log.dart';
import 'package:vetcare_connect/models/product.dart';
import 'package:vetcare_connect/models/sale_item.dart';
import 'package:vetcare_connect/models/sales.dart';
import 'package:vetcare_connect/providers/auth_provider.dart';
import 'package:vetcare_connect/providers/inventory_log_provider.dart';
import 'package:vetcare_connect/providers/product_provider.dart';
import 'package:vetcare_connect/providers/sale_item_provider.dart';
import 'package:vetcare_connect/providers/sales_provider.dart';
import 'package:vetcare_connect/services/database_service.dart';
import 'package:vetcare_connect/views/screens/access_denied_screen.dart';
import 'package:vetcare_connect/views/widgets/drawer_widget.dart';

class SalesPosScreen extends StatefulWidget {
  const SalesPosScreen({super.key});

  @override
  State<SalesPosScreen> createState() => _SalesPosScreenState();
}

class _SalesPosScreenState extends State<SalesPosScreen> {
  final List<SaleItem> _cart = [];
  double _total = 0.0;

  @override
  void initState() {
    super.initState();
    Provider.of<ProductProvider>(context, listen: false).loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final role = authProvider.role;
    final isCustomer = role?.value == 'customer';

    if (isCustomer) {
      return const AccessDeniedScreen();
    }

    final productProvider = Provider.of<ProductProvider>(context);
    final products = productProvider.products;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales POS'),
        backgroundColor: const Color.fromARGB(255, 13, 157, 30),
        foregroundColor: Colors.white,
      ),
      drawer: const AppDrawer(currentRoute: '/sales_pos'),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 600) {
            // Desktop layout: Row with products and cart side by side
            return Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'Products',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        child: GridView.builder(
                          padding: const EdgeInsets.all(16.0),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 16.0,
                            mainAxisSpacing: 16.0,
                          ),
                          itemCount: products.length,
                          itemBuilder: (context, index) {
                            final product = products[index];
                            return InkWell(
                              onTap: () => _addToCart(product),
                              child: Container(
                                padding: const EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      product.productName,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Text('₱${product.price.toStringAsFixed(2)}'),
                                    Text('Stock: ${product.stockQuantity}'),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'Cart',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: _cart.length,
                          itemBuilder: (context, index) {
                            final item = _cart[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8.0),
                              padding: const EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: ListTile(
                                title: Text(
                                  _getProductName(item.productId),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  'Qty: ${item.quantity} x ₱${item.price.toStringAsFixed(2)} = ₱${(item.price * item.quantity).toStringAsFixed(2)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.remove),
                                  onPressed: () => _removeFromCart(index),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text(
                              'Total: ₱${_total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _cart.isEmpty ? null : _checkout,
                              child: const Text('Checkout'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          } else {
            // Mobile layout: Column with products on top, cart below
            return Column(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'Products',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        child: GridView.builder(
                          padding: const EdgeInsets.all(16.0),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16.0,
                            mainAxisSpacing: 16.0,
                          ),
                          itemCount: products.length,
                          itemBuilder: (context, index) {
                            final product = products[index];
                            return InkWell(
                              onTap: () => _addToCart(product),
                              child: Container(
                                padding: const EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      product.productName,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Text('₱${product.price.toStringAsFixed(2)}'),
                                    Text('Stock: ${product.stockQuantity}'),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'Cart',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: _cart.length,
                          itemBuilder: (context, index) {
                            final item = _cart[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8.0),
                              padding: const EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: ListTile(
                                title: Text(
                                  _getProductName(item.productId),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  'Qty: ${item.quantity} x ₱${item.price.toStringAsFixed(2)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.remove),
                                  onPressed: () => _removeFromCart(index),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text(
                              'Total: ₱${_total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _cart.isEmpty ? null : _checkout,
                              child: const Text('Checkout'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  void _addToCart(Product product) {
    // Capture productId to avoid multiple accesses
    final String? productId = product.productId;

    // Defensive check - productId must not be null
    if (productId == null || productId.isEmpty) {
      debugPrint('DEBUG: Cannot add ${product.productName}: productId is null/empty');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot add ${product.productName}: invalid product data')),
      );
      return;
    }

    // Verify all product fields are valid before adding to cart
    if (product.productName.isEmpty) {
      debugPrint('DEBUG: Cannot add product: productName is empty');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid product: missing name')),
      );
      return;
    }

    // Check if item already in cart
    int existingIndex = -1;
    for (int i = 0; i < _cart.length; i++) {
      if (_cart[i].productId == productId) {
        existingIndex = i;
        break;
      }
    }

    final int currentQuantityInCart = existingIndex != -1 ? _cart[existingIndex].quantity : 0;
    final int stock = product.stockQuantity ?? 0;

    if (currentQuantityInCart + 1 > stock) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Insufficient stock for ${product.productName}')),
      );
      return;
    }

    setState(() {
      if (existingIndex != -1) {
        // Update existing cart item
        final existingItem = _cart[existingIndex];
        existingItem.quantity = existingItem.quantity + 1;
        existingItem.subtotal = existingItem.price * existingItem.quantity;
      } else {
        // Add new item to cart
        _cart.add(
          SaleItem(
            salesItemId: null,
            saleId: null,
            productId: productId,
            quantity: 1,
            price: product.price,
            subtotal: product.price,
          ),
        );
      }
      _calculateTotal();
    });
  }

  void _removeFromCart(int index) {
    setState(() {
      _cart.removeAt(index);
      _calculateTotal();
    });
  }

  void _calculateTotal() {
    _total = _cart.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  }

  String _getProductName(String productId) {
    if (productId.isEmpty) return 'Unknown Product';
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    try {
      final product = productProvider.products.firstWhere(
        (p) => p.productId == productId,
      );
      return product.productName;
    } catch (_) {
      return 'Unknown Product';
    }
  }

  Future<void> _checkout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final uid = authProvider.firebaseUser?.uid;

    if (uid == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
      return;
    }

    if (_cart.isEmpty) return;

    // Re-check stock before writing to Firebase.
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final latestProducts = productProvider.products;

    final List<String> insufficient = [];
    for (final item in _cart) {
      // Handle null productId comparison
      Product? p;
      for (final x in latestProducts) {
        if (x.productId == item.productId) {
          p = x;
          break;
        }
      }
      if (p == null) {
        insufficient.add('Missing product: ${item.productId}');
        continue;
      }
      if (item.quantity > p.stockQuantity) {
        insufficient.add('${p.productName} (requested ${item.quantity}, available ${p.stockQuantity})');
      }
    }

    if (insufficient.isNotEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot checkout: stock changed.\n${insufficient.join('\n')}'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Checkout'),
          content: Text('Proceed with this sale totaling ₱${_total.toStringAsFixed(2)}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final salesProvider = Provider.of<SalesProvider>(context, listen: false);
    final saleItemProvider = Provider.of<SaleItemProvider>(context, listen: false);
    final inventoryLogProvider = Provider.of<InventoryLogProvider>(context, listen: false);

    try {
      // Ensure all failures show user-friendly error + psychological reassurance.
      // (Network/Firestore errors are common; we handle them below.)
      final sale = Sales(
        saleId: null,
        ownerUid: uid,
        date: DateTime.now().toIso8601String().split('T')[0],
        totalAmount: _total,
        paymentStatus: 'paid',
        paymentMethod: 'cash',
        paymentDate: DateTime.now().toIso8601String(),
      );

      final saleId = await DatabaseService().insertSales(sale);

      for (final item in _cart) {
        final saleItem = SaleItem(
          salesItemId: null,
          saleId: saleId,
          productId: item.productId,
          quantity: item.quantity,
          price: item.price,
          subtotal: item.subtotal,
        );
        await DatabaseService().insertSaleItem(saleItem);

        // Find product by id with proper null handling
        Product? foundProduct;
        for (final p in latestProducts) {
          if (p.productId == item.productId) {
            foundProduct = p;
            break;
          }
        }

        if (foundProduct == null) {
          continue; // Skip if product not found
        }

        final product = foundProduct;
        final updatedProduct = Product(
          productId: product.productId,
          productName: product.productName,
          description: product.description,
          price: product.price,
          stockQuantity: product.stockQuantity - item.quantity,
          category: product.category,
        );
        await DatabaseService().updateProduct(updatedProduct);

        final log = InventoryLog(
          logId: null,
          productId: item.productId,
          quantityChange: -item.quantity,
          date: DateTime.now().toIso8601String().split('T')[0],
          reason: 'Sale',
        );
        await DatabaseService().insertInventoryLog(log);
      }

      setState(() {
        _cart.clear();
        _total = 0.0;
      });

      await salesProvider.loadSales();
      await saleItemProvider.loadSaleItems();
      await productProvider.loadProducts();
      await inventoryLogProvider.loadInventoryLogs();

      final now = DateTime.now();
      final timestamp =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sale completed successfully at $timestamp!')),
      );
    } catch (e) {
      if (!mounted) return;

      final errorText = e.toString().toLowerCase();
      final isNetwork = errorText.contains('network') || errorText.contains('timeout') || errorText.contains('unavailable') || errorText.contains('socket');
      final isPermission = errorText.contains('permission') || errorText.contains('denied') || errorText.contains('unauthorized');
      final isFormat = errorText.contains('format') || errorText.contains('invalid') || errorText.contains('argumenterror');

      final userMessage = isPermission
          ? 'We couldn\'t complete the sale due to your account access. Your cart was not saved.'
          : isFormat
              ? 'Something about the item details looks incorrect. Please review quantities and try again. Your cart was not saved.'
              : isNetwork
                  ? 'A network issue happened while saving. Please check your internet connection and try again. Your cart was not saved.'
                  : 'We couldn\'t complete the checkout right now. Please try again. Your cart was not saved.';

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userMessage),
          backgroundColor: Colors.red,
        ),
      );

      // Assurance/psychological note (separate dialog so user feels supported even if they dismiss SnackBar)
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('We\'re on it'),
            content: const Text(
              'Don\'t worry—no changes were saved.\n\nIf the problem continues, please wait a moment and try again. If you keep seeing this message, contact support.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Got it'),
              ),
            ],
          );
        },
      );
    }
  }
}

