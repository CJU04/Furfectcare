import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vetcare_connect/models/sale_item.dart';
import 'package:vetcare_connect/models/sales.dart';
import 'package:vetcare_connect/models/product.dart';
import 'package:vetcare_connect/models/inventory_log.dart';
import 'package:vetcare_connect/models/user.dart';
import 'package:vetcare_connect/providers/auth_provider.dart';
import 'package:vetcare_connect/providers/firebase_user_provider.dart';
import 'package:vetcare_connect/providers/product_provider.dart';
import 'package:vetcare_connect/providers/sales_provider.dart';
import 'package:vetcare_connect/providers/sale_item_provider.dart';
import 'package:vetcare_connect/providers/inventory_log_provider.dart';
import 'package:vetcare_connect/services/database_service.dart';
import 'package:vetcare_connect/config/theme/app_theme.dart';
import 'package:vetcare_connect/views/widgets/drawer_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:vetcare_connect/utils/app_snackbar.dart';

class ProductCatalogScreen extends StatefulWidget {
  const ProductCatalogScreen({super.key});

  @override
  State<ProductCatalogScreen> createState() => _ProductCatalogScreenState();
}

class _ProductCatalogScreenState extends State<ProductCatalogScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortOption = 'Name (A-Z)';
  static const _sortOptions = <String>[
    'Name (A-Z)',
    'Name (Z-A)',
    'Price (low first)',
    'Price (high first)',
    'Stock (low first)',
    'Stock (high first)',
  ];
  final List<_CartEntry> _cart = [];
  double _total = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductProvider>(context, listen: false).loadProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    // Copy before sorting so the provider's internal list is never mutated.
    List<Product> products = List<Product>.from(productProvider.products);

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      products = products.where((product) {
        return product.productName.toLowerCase().contains(q) ||
            (product.productCode?.toLowerCase().contains(q) ?? false) ||
            product.description.toLowerCase().contains(q) ||
            product.category.toLowerCase().contains(q);
      }).toList();
    }

    switch (_sortOption) {
      case 'Name (Z-A)':
        products.sort((a, b) =>
            b.productName.toLowerCase().compareTo(a.productName.toLowerCase()));
        break;
      case 'Price (low first)':
        products.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'Price (high first)':
        products.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'Stock (low first)':
        products.sort((a, b) => a.stockQuantity.compareTo(b.stockQuantity));
        break;
      case 'Stock (high first)':
        products.sort((a, b) => b.stockQuantity.compareTo(a.stockQuantity));
        break;
      default:
        products.sort((a, b) =>
            a.productName.toLowerCase().compareTo(b.productName.toLowerCase()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () => _showCartSheet(context),
              ),
              if (_cart.isNotEmpty)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${_cart.fold(0, (s, e) => s + e.quantity)}',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/product_catalog'),
      body: RefreshIndicator(
        onRefresh: () async {
          await Provider.of<ProductProvider>(context, listen: false)
              .loadProducts();
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final crossCount = constraints.maxWidth > 600 ? 4 : 2;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            labelText: 'Search Products',
                            hintText: 'Name, code, description, category',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) =>
                              setState(() => _searchQuery = value),
                        ),
                      ),
                      const SizedBox(width: 12),
                      DropdownButton<String>(
                        value: _sortOption,
                        items: _sortOptions
                            .map((option) => DropdownMenuItem(
                                value: option, child: Text(option)))
                            .toList(),
                        onChanged: (value) {
                          if (value != null)
                            setState(() => _sortOption = value);
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    physics: const AlwaysScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossCount,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      final inCart = _cart
                          .where((e) => e.productId == product.productId)
                          .isNotEmpty;
                      return _ProductCard(
                        product: product,
                        onAdd: () => _addToCart(product),
                        inCart: inCart,
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: _cart.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Total: ₱${_total.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => _showCartSheet(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                          'View Cart (${_cart.fold(0, (s, e) => s + e.quantity)})'),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  void _addToCart(Product product) {
    if (product.stockQuantity <= 0) {
      AppSnackBar.error(context, '${product.productName} is out of stock');
      return;
    }

    setState(() {
      final existing =
          _cart.where((e) => e.productId == product.productId).firstOrNull;
      if (existing != null) {
        if (existing.quantity < product.stockQuantity) {
          existing.quantity++;
          existing.subtotal = existing.price * existing.quantity;
        } else {
          AppSnackBar.error(
              context, 'Max stock reached for ${product.productName}');
          return;
        }
      } else {
        _cart.add(_CartEntry(
          productId: product.productId!,
          productName: product.productName,
          price: product.price,
          quantity: 1,
          subtotal: product.price,
          stockQuantity: product.stockQuantity,
        ));
      }
      _calculateTotal();
    });
  }

  void _removeFromCart(String productId) {
    setState(() {
      _cart.removeWhere((e) => e.productId == productId);
      _calculateTotal();
    });
  }

  void _updateQuantity(String productId, int delta) {
    setState(() {
      final entry = _cart.where((e) => e.productId == productId).firstOrNull;
      if (entry == null) return;
      final newQty = entry.quantity + delta;
      if (newQty <= 0) {
        _cart.removeWhere((e) => e.productId == productId);
      } else if (newQty > entry.stockQuantity) {
        AppSnackBar.error(
            context, 'Only ${entry.stockQuantity} available in stock');
        return;
      } else {
        entry.quantity = newQty;
        entry.subtotal = entry.price * entry.quantity;
      }
      _calculateTotal();
    });
  }

  void _calculateTotal() {
    _total = _cart.fold(0.0, (sum, e) => sum + e.subtotal);
  }

  void _showCartSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => _CartSheet(
          cart: _cart,
          total: _total,
          scrollController: scrollController,
          onRemove: _removeFromCart,
          onUpdateQty: _updateQuantity,
          onCheckout: _checkout,
        ),
      ),
    );
  }

  String _generateOrderReference() {
    final year = DateTime.now().year;
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    final ref = String.fromCharCodes(
      Iterable.generate(
          4, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
    return 'ORD-$year-$ref';
  }

  Future<String?> _showPaymentMethodDialog() {
    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Select Payment Method'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Cash / Pay at Clinic'),
                subtitle: const Text('Pay when you pick up your order'),
                leading: const Icon(Icons.money),
                onTap: () => Navigator.pop(dialogContext, 'Cash'),
              ),
              ListTile(
                title: const Text('Online Banking'),
                subtitle: const Text('Bank transfer'),
                leading: const Icon(Icons.account_balance),
                onTap: () => Navigator.pop(dialogContext, 'Online Banking'),
              ),
              ListTile(
                title: const Text('GCash'),
                subtitle: const Text('Pay via GCash'),
                leading: const Icon(Icons.payment),
                onTap: () => Navigator.pop(dialogContext, 'GCash'),
              ),
              ListTile(
                title: const Text('Maya'),
                subtitle: const Text('Pay via Maya'),
                leading: const Icon(Icons.wallet),
                onTap: () => Navigator.pop(dialogContext, 'Maya'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<String?> _showPaymentReferenceDialog(String paymentMethod) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('$paymentMethod Reference'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Enter your $paymentMethod payment reference number:'),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'Reference Number',
                  border: const OutlineInputBorder(),
                  hintText: 'e.g. TXN-1234567890',
                ),
                inputFormatters: [
                  LengthLimitingTextInputFormatter(50),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Note: Proof of payment can be uploaded later by staff.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final ref = controller.text.trim();
                if (ref.isEmpty) {
                  AppSnackBar.error(context, 'Please enter a reference number');
                  return;
                }
                if (ref.length < 3) {
                  AppSnackBar.error(context, 'Reference number is too short');
                  return;
                }
                Navigator.pop(dialogContext, ref);
              },
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
  }

  Future<bool?> _showConfirmOrderDialog(
    String paymentMethod,
    String? paymentReference,
    String paymentStatus,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Order'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Please review the products below before placing the order:',
                  style: Theme.of(dialogContext).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                ..._cart.map((item) {
                  final lineTotal = item.price * item.quantity;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.productName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '₱${item.price.toStringAsFixed(2)} x ${item.quantity}',
                                style:
                                    Theme.of(dialogContext).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '₱${lineTotal.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total'),
                    Text(
                      '₱${_total.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Payment: $paymentMethod',
                    style: const TextStyle(fontSize: 12)),
                Text('Status: $paymentStatus',
                    style: const TextStyle(fontSize: 12)),
                if (paymentReference != null && paymentReference.isNotEmpty)
                  Text('Reference: $paymentReference',
                      style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Place Order'),
            ),
          ],
        );
      },
    );
  }

  Future<String?> _createOrderWithRollback(
    String uid,
    String paymentMethod,
    String paymentStatus,
    String orderStatus,
    String orderReference,
    String? paymentReference,
  ) async {
    String? saleId;
    final saleItemIds = <String>[];
    final stockRestorations = <_StockRestoration>[];

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = auth.firebaseUser;
      final firebaseUserProvider =
          Provider.of<FirebaseUserProvider>(context, listen: false);
      final profile = firebaseUserProvider.currentUser;

      final customerName = auth.displayName ?? profile?.name ?? '';
      final customerEmail = currentUser?.email ?? profile?.email ?? '';
      final customerContact = profile?.contactNumber ?? '';
      final customerAddress = profile?.address ?? '';

      final sale = Sales(
        saleId: null,
        ownerUid: uid,
        customerName: customerName,
        customerEmail: customerEmail,
        customerContact: customerContact,
        customerAddress: customerAddress,
        date: DateTime.now().toIso8601String().split('T')[0],
        totalAmount: _total,
        paymentStatus: paymentStatus,
        paymentMethod: paymentMethod,
        paymentDate: DateTime.now().toIso8601String(),
        orderStatus: orderStatus,
        orderReference: orderReference,
        paymentReference: paymentReference ?? '',
      );

      saleId = await DatabaseService().insertSales(sale);

      final productProvider =
          Provider.of<ProductProvider>(context, listen: false);

      for (final item in _cart) {
        final saleItem = SaleItem(
          salesItemId: null,
          saleId: saleId,
          productId: item.productId,
          quantity: item.quantity,
          price: item.price,
          subtotal: item.subtotal,
        );
        final saleItemId = await DatabaseService().insertSaleItem(saleItem);
        saleItemIds.add(saleItemId);

        final product = productProvider.products.firstWhere(
          (p) => p.productId == item.productId,
          orElse: () => Product(
            productId: null,
            productName: '',
            description: '',
            price: 0,
            stockQuantity: 0,
            category: '',
          ),
        );

        if (product.productId == null) {
          throw Exception('Product not found: ${item.productName}');
        }

        stockRestorations.add(_StockRestoration(
          productId: product.productId!,
          originalStockQuantity: product.stockQuantity,
          quantity: item.quantity,
          productName: product.productName,
          description: product.description,
          price: product.price,
          category: product.category,
        ));

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

      return saleId;
    } catch (e) {
      for (final restoration in stockRestorations) {
        try {
          final restored = Product(
            productId: restoration.productId,
            productName: restoration.productName,
            description: restoration.description,
            price: restoration.price,
            stockQuantity: restoration.originalStockQuantity,
            category: restoration.category,
          );
          await DatabaseService().updateProduct(restored);
        } catch (_) {}
      }

      for (final id in saleItemIds) {
        try {
          await DatabaseService().deleteSaleItem(id);
        } catch (_) {}
      }

      if (saleId != null) {
        try {
          await DatabaseService().deleteSales(saleId);
        } catch (_) {}
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create order: $e')),
      );
      return null;
    }
  }

  Future<void> _notifyStaffOfNewOrder(
      String orderReference, double total, String? saleId) async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('users').get();
      final staffUids = snapshot.docs
          .where((doc) {
            final role = doc.data()['role'] as String?;
            return role == 'admin' || role == 'staff';
          })
          .map((doc) => doc.data()['uid'] as String? ?? doc.id)
          .where((uid) => uid.isNotEmpty)
          .toList();

      if (staffUids.isEmpty) return;

      final now = DateTime.now();
      final notifications = staffUids.map((uid) {
        return AppNotification(
          recipientUserId: uid,
          title: 'New Order Placed',
          message:
              'Order $orderReference for ₱${total.toStringAsFixed(2)} has been placed.',
          type: 'order',
          // Link the sale record itself so the notification's "View purchase"
          // button lands on the order (ProductHistoryScreen filters by
          // saleId). Legacy references are kept as fallback.
          relatedDocumentId: saleId ?? orderReference,
          createdAt: now,
        );
      }).toList();

      await Future.wait(
        notifications.map((n) => DatabaseService().insertNotification(n)),
      );
    } catch (e) {
      debugPrint('Failed to send order notifications: $e');
    }
  }

  void _checkout() async {
    Navigator.pop(context);

    if (_cart.isEmpty) return;

    final uid =
        Provider.of<AuthProvider>(context, listen: false).firebaseUser?.uid;
    if (uid == null) {
      AppSnackBar.error(context, 'Please login to complete purchase');
      return;
    }

    final paymentMethod = await _showPaymentMethodDialog();
    if (paymentMethod == null) return;

    String? paymentReference = '';
    if (paymentMethod != 'Cash') {
      paymentReference = await _showPaymentReferenceDialog(paymentMethod);
      if (paymentReference == null) return;
    }

    final String paymentStatus;
    final String orderStatus;
    if (paymentMethod == 'Cash') {
      paymentStatus = 'Pending Confirmation';
      orderStatus = 'reserved';
    } else {
      paymentStatus = 'Awaiting Verification';
      orderStatus = 'pending_confirmation';
    }

    final confirmed = await _showConfirmOrderDialog(
        paymentMethod, paymentReference, paymentStatus);
    if (confirmed != true) return;

    final orderReference = _generateOrderReference();
    final saleId = await _createOrderWithRollback(
      uid,
      paymentMethod,
      paymentStatus,
      orderStatus,
      orderReference,
      paymentReference,
    );

    if (saleId == null) return;

    _notifyStaffOfNewOrder(orderReference, _total, saleId).catchError((e) {
      debugPrint('Failed to send notifications: $e');
    });

    setState(() {
      _cart.clear();
      _total = 0.0;
    });

    final salesProvider = Provider.of<SalesProvider>(context, listen: false);
    final saleItemProvider =
        Provider.of<SaleItemProvider>(context, listen: false);
    final productProvider =
        Provider.of<ProductProvider>(context, listen: false);
    final inventoryLogProvider =
        Provider.of<InventoryLogProvider>(context, listen: false);

    await Future.wait([
      salesProvider.loadSales(),
      saleItemProvider.loadSaleItems(),
      productProvider.loadProducts(),
      inventoryLogProvider.loadInventoryLogs(),
    ]);

    if (!mounted) return;

    final timestamp = DateTime.now();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 500),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(scale: value, child: child);
            },
            child: Icon(Icons.check_circle_rounded,
                color: Theme.of(context).colorScheme.primary, size: 56),
          ),
          title: const Text('Order placed successfully'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Order Reference: $orderReference'),
              const SizedBox(height: 8),
              Text(
                  'Order placed at ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}!'),
              if (paymentMethod != 'Cash')
                Text(
                  'Please wait for staff to verify your $paymentMethod payment.',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Done'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Place another order'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pushNamed('/product_history');
              },
              child: const Text('View products history'),
            ),
          ],
        );
      },
    );
  }
}

class _CartEntry {
  String productId;
  String productName;
  double price;
  int quantity;
  double subtotal;
  int stockQuantity;

  _CartEntry({
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.subtotal,
    required this.stockQuantity,
  });
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onAdd;
  final bool inCart;

  const _ProductCard({
    required this.product,
    required this.onAdd,
    required this.inCart,
  });

  @override
  Widget build(BuildContext context) {
    final outOfStock = product.stockQuantity <= 0;
    final imageUrl = product.imageUrl;
    return Card(
      elevation: 4,
      shadowColor: AppTheme.primaryGreen.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: outOfStock ? null : onAdd,
        borderRadius: BorderRadius.circular(16),
        onHover: (hovered) {
          if (hovered) {
            // Card hover handled by InkWell splash/elevation
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primaryGreen.withValues(alpha: 0.08),
                        AppTheme.secondaryTeal.withValues(alpha: 0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: _ProductImage(
                        imageUrl: imageUrl, outOfStock: outOfStock),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                product.productName,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '₱${product.price.toStringAsFixed(2)}',
                style: TextStyle(
                  color: AppTheme.primaryGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: outOfStock
                          ? Colors.red.shade100
                          : AppTheme.secondaryTeal.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      outOfStock
                          ? 'Out of stock'
                          : 'Stock: ${product.stockQuantity}',
                      style: TextStyle(
                        fontSize: 10,
                        color: outOfStock ? Colors.red : AppTheme.secondaryTeal,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (inCart)
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) {
                        return Transform.scale(scale: value, child: child);
                      },
                      child: const Icon(Icons.check_circle,
                          color: AppTheme.primaryGreen, size: 18),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: outOfStock ? null : onAdd,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        outOfStock ? Colors.grey : AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: Text(outOfStock ? 'Unavailable' : 'Add to Cart',
                      style: const TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  final String? imageUrl;
  final bool outOfStock;

  const _ProductImage({required this.imageUrl, required this.outOfStock});

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryGreen.withValues(alpha: 0.15),
              AppTheme.secondaryTeal.withValues(alpha: 0.15),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.image_not_supported,
          size: 48,
          color: outOfStock
              ? Colors.grey
              : AppTheme.primaryGreen.withValues(alpha: 0.6),
        ),
      );
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      builder: (context, value, child) {
        return FadeTransition(
          opacity: AlwaysStoppedAnimation(value),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: imageUrl!,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryGreen.withValues(alpha: 0.1),
                      AppTheme.secondaryTeal.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppTheme.primaryGreen)),
              ),
              errorWidget: (context, url, error) => Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryGreen.withValues(alpha: 0.15),
                      AppTheme.secondaryTeal.withValues(alpha: 0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.broken_image,
                  size: 48,
                  color: outOfStock
                      ? Colors.grey
                      : AppTheme.primaryGreen.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CartSheet extends StatelessWidget {
  final List<_CartEntry> cart;
  final double total;
  final ScrollController scrollController;
  final void Function(String productId) onRemove;
  final void Function(String productId, int delta) onUpdateQty;
  final VoidCallback onCheckout;

  const _CartSheet({
    required this.cart,
    required this.total,
    required this.scrollController,
    required this.onRemove,
    required this.onUpdateQty,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Your Cart',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Flexible(
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shrinkWrap: true,
              itemCount: cart.length,
              itemBuilder: (context, index) {
                final item = cart[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(item.productName),
                    subtitle: Text(
                        '₱${item.price.toStringAsFixed(2)} x ${item.quantity} = ₱${item.subtotal.toStringAsFixed(2)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () => onUpdateQty(item.productId, -1),
                        ),
                        Text('${item.quantity}',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () => onUpdateQty(item.productId, 1),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red),
                          onPressed: () => onRemove(item.productId),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total:',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '₱${total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onCheckout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Place Order',
                          style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StockRestoration {
  final String productId;
  final int originalStockQuantity;
  final int quantity;
  final String productName;
  final String description;
  final double price;
  final String category;

  _StockRestoration({
    required this.productId,
    required this.originalStockQuantity,
    required this.quantity,
    required this.productName,
    required this.description,
    required this.price,
    required this.category,
  });
}
